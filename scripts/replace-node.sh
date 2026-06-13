#!/bin/sh
# replace-node.sh
#
# Node replacement test for a running Consul cluster. Terminates one follower (any
# InService node that is not the elected bootstrap node), lets the Auto Scaling
# group launch a replacement, then verifies the new node rejoins raft and obtains
# a Vault PKI certificate, and that Raft Autopilot retires the terminated node out
# of the voter set so the cluster returns to a healthy quorum.
#
# The replacement exercises the module's auto-join + Vault Agent PKI path: it
# authenticates to the external Vault with the AWS auth method, the Vault Agent
# issues its server certificate from the external Vault PKI and renders the gossip
# key, then it joins via AWS cloud auto-join (retry_join) and becomes a voter.
#
# Reads these Terraform outputs from the deploy repo root:
#   bastion_public_ip, consul_asg_name, ec2_ami_name, consul_url,
#   acl_management_token_secret_arn,
#   bootstrap_consul_pki_ca_chain_ssm_parameter_name,
#   bootstrap_consul_cluster_state_ssm_parameter_name,
#   bootstrap_instance_id_ssm_parameter_name
#
# The raft check runs from the deploy host against consul_url, so that endpoint
# (the NLB) must be reachable from here.

log() {
  # Colors are automatically disabled if output is not a terminal
  ! [ -t 2 ] || {
    c1='\033[1;33m'
    c2='\033[1;34m'
    c3='\033[m'
  }

  printf '%b%s %b%s%b %s\n' \
    "${c1}" "${3:-->}" "${c3}${2:+$c2}" "$1" "${c3}" "$2" >&2
}

require_tools() {
  for tool in aws jq terraform ssh consul; do
    command -v "${tool}" >/dev/null 2>&1 ||
      {
        log "ERROR: required tool not found:" "${tool}"
        exit 1
      }
  done
}

read_terraform_outputs() {
  log "Reading Terraform outputs."

  # Switch to the Terraform root directory.
  cd "$(dirname "$0")/.."

  terraform_output="$(terraform output -json)"

  asg_name="$(printf '%s\n' "${terraform_output}" | jq -r '.consul_asg_name.value')"
  ami_name="$(printf '%s\n' "${terraform_output}" | jq -r '.ec2_ami_name.value')"
  bastion_ip="$(printf '%s\n' "${terraform_output}" | jq -r '.bastion_public_ip.value')"
  consul_url="$(printf '%s\n' "${terraform_output}" | jq -r '.consul_url.value')"
  ca_chain_param="$(printf '%s\n' "${terraform_output}" | jq -r '.bootstrap_consul_pki_ca_chain_ssm_parameter_name.value')"
  cluster_state_param="$(printf '%s\n' "${terraform_output}" | jq -r '.bootstrap_consul_cluster_state_ssm_parameter_name.value')"
  bootstrap_id_param="$(printf '%s\n' "${terraform_output}" | jq -r '.bootstrap_instance_id_ssm_parameter_name.value')"
  mgmt_token_arn="$(printf '%s\n' "${terraform_output}" | jq -r '.acl_management_token_secret_arn.value')"

  case "${ami_name}" in
    *ubuntu*) ssh_user="ubuntu" ;;
    *debian*) ssh_user="admin" ;;
    *)
      log "ERROR: Unsupported AMI:" "${ami_name}"
      exit 1
      ;;
  esac

  log "  ASG:" "${asg_name}"
  log "  Bastion IP:" "${bastion_ip}"
  log "  Consul URL:" "${consul_url}"
}

inservice_ids() {
  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "${asg_name}" \
    --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
    --output text | tr '\t' '\n'
}

ensure_cluster_ready() {
  state="$(aws ssm get-parameter --name "${cluster_state_param}" \
    --query 'Parameter.Value' --output text 2>/dev/null || true)"

  [ "${state}" = "Ready" ] ||
    {
      log "ERROR: cluster state is not Ready (got '${state:-none}'); is a cluster applied?"
      exit 1
    }
}

select_victim() {
  bootstrap_id="$(aws ssm get-parameter --name "${bootstrap_id_param}" \
    --query 'Parameter.Value' --output text 2>/dev/null || true)"

  victim=""
  for id in ${original_ids}; do
    [ "${id}" = "${bootstrap_id}" ] && continue
    victim="${id}"
    break
  done

  [ -n "${victim}" ] ||
    {
      log "ERROR: no non-bootstrap InService node available to replace."
      exit 1
    }

  victim_ip="$(aws ec2 describe-instances --instance-ids "${victim}" \
    --query 'Reservations[].Instances[].PrivateIpAddress' --output text)"

  log "Selected follower to terminate:" "${victim} (${victim_ip})"
}

# setup_consul_env exports CONSUL_HTTP_ADDR/CONSUL_CACERT/CONSUL_HTTP_TOKEN for the
# raft checks. The management token is read into the environment and never written
# to stdout. The CA chain is the Vault Agent-issued bundle the bootstrap node
# published to SSM.
setup_consul_env() {
  aws ssm get-parameter --name "${ca_chain_param}" \
    --query 'Parameter.Value' --output text >"${workdir}/ca.pem"

  CONSUL_HTTP_ADDR="${consul_url}"
  CONSUL_CACERT="${workdir}/ca.pem"
  CONSUL_HTTP_TOKEN="$(aws secretsmanager get-secret-value --secret-id "${mgmt_token_arn}" \
    --query 'SecretString' --output text)"
  export CONSUL_HTTP_ADDR CONSUL_CACERT CONSUL_HTTP_TOKEN
}

raft_peers() {
  consul operator raft list-peers
}

# autopilot_state returns Raft Autopilot state as JSON. Servers are keyed by raft
# id; each carries the node Name (the module sets node_name to the EC2 instance id),
# its Status (voter/non-voter/leader), and Healthy. Voters is the list of voting
# raft ids.
autopilot_state() {
  consul operator autopilot state -format=json
}

terminate_victim() {
  log "Terminating follower (ASG keeps desired capacity, so it replaces it):" "${victim}"

  aws autoscaling terminate-instance-in-auto-scaling-group \
    --instance-id "${victim}" \
    --no-should-decrement-desired-capacity \
    --query 'Activity.StatusCode' --output text >/dev/null
}

wait_for_replacement() {
  log "Waiting for the ASG to launch a replacement."

  timeout_seconds=600
  waited=0
  new_id=""

  while [ -z "${new_id}" ]; do
    for id in $(inservice_ids); do
      case " ${original_ids} " in
        *" ${id} "*) ;;
        *)
          new_id="${id}"
          break
          ;;
      esac
    done

    [ -n "${new_id}" ] && break

    [ "${waited}" -ge "${timeout_seconds}" ] &&
      {
        log "ERROR: no replacement reached InService after ${timeout_seconds}s."
        exit 1
      }

    sleep 15
    waited=$((waited + 15))
  done

  new_ip="$(aws ec2 describe-instances --instance-ids "${new_id}" \
    --query 'Reservations[].Instances[].PrivateIpAddress' --output text)"

  log "  Replacement is InService:" "${new_id} (${new_ip})"
}

ssh_node() {
  ip="$1"
  shift

  ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=15 \
    -J "${ssh_user}@${bastion_ip}" \
    "${ssh_user}@${ip}" "$@"
}

wait_for_cloud_init() {
  log "Waiting for SSH and cloud-init on:" "${new_ip}"

  timeout_seconds=600
  waited=0

  while ! ssh_node "${new_ip}" 'true' >/dev/null 2>&1; do
    [ "${waited}" -ge "${timeout_seconds}" ] &&
      {
        log "ERROR: SSH to ${new_ip} not ready after ${timeout_seconds}s."
        exit 1
      }
    sleep 15
    waited=$((waited + 15))
  done

  ci_status="$(ssh_node "${new_ip}" 'cloud-init status --wait' 2>/dev/null || true)"
  ci_status="$(printf '%s' "${ci_status}" | tr -d '.')"
  log "  cloud-init:" "${ci_status}"

  case "${ci_status}" in
    *done*) ;;
    *) log "WARNING: cloud-init did not report 'done' on" "${new_ip}" ;;
  esac
}

show_join_log() {
  log "Replacement node bootstrap log (cloud-final):" "${new_ip}"

  ssh_node "${new_ip}" 'sudo journalctl -u cloud-final --no-pager' 2>/dev/null |
    grep -E '\[INFO\]|\[WARN\]|\[ERROR\]|Finished cloud-final' || true
}

# verify_raft polls until the cluster is back to a healthy quorum: the replacement
# is promoted to voter, the expected number of voters is present, and the terminated
# node has left the voter set (Autopilot retires the failed server). The replacement
# is matched by node Name, which the module sets to the EC2 instance id.
verify_raft() {
  log "Verifying raft convergence (replacement promoted, dead node retired, quorum healthy)."

  timeout_seconds=420
  waited=0

  while :; do
    state="$(autopilot_state 2>/dev/null || true)"

    # An empty/invalid read leaves the vars blank (|| true), so a transient CLI
    # hiccup just fails the comparisons and the loop retries.
    voters="$(printf '%s' "${state}" | jq -r '[.Voters[]?] | length' 2>/dev/null || true)"
    voters_healthy="$(printf '%s' "${state}" | jq -r '.Servers as $s | (.Voters // []) as $v | (($v | length) > 0) and ([$v[] | $s[.].Healthy] | all)' 2>/dev/null || true)"
    new_is_voter="$(printf '%s' "${state}" | jq -r --arg n "${new_id}" 'any(.Servers[]?; .Name == $n and (.Status == "voter" or .Status == "leader"))' 2>/dev/null || true)"
    victim_is_voter="$(printf '%s' "${state}" | jq -r --arg v "${victim}" 'any(.Servers[]?; .Name == $v and (.Status == "voter" or .Status == "leader"))' 2>/dev/null || true)"

    if [ "${voters_healthy}" = "true" ] && [ "${new_is_voter}" = "true" ] &&
      [ "${victim_is_voter}" = "false" ] && [ "${voters}" = "${expected_voters}" ]; then
      log "Final autopilot state:"
      consul operator autopilot state || true
      log "  PASS:" "replacement ${new_id} is a voter, ${victim} retired, healthy quorum of ${voters} voters"
      return 0
    fi

    if [ "${waited}" -ge "${timeout_seconds}" ]; then
      log "Final autopilot state:"
      consul operator autopilot state || true
      [ -n "${voters}" ] || log "  FAIL:" "could not read autopilot state (empty or invalid JSON)"
      [ "${voters}" = "${expected_voters}" ] || log "  FAIL:" "voter count ${voters:-?} != expected ${expected_voters}"
      [ "${new_is_voter}" = "true" ] || log "  FAIL:" "replacement ${new_id} was not promoted to voter"
      [ "${victim_is_voter}" = "false" ] || log "  FAIL:" "terminated ${victim} is still a voter (not retired)"
      [ "${voters_healthy}" = "true" ] || log "  FAIL:" "one or more voters are unhealthy"
      return 1
    fi

    sleep 15
    waited=$((waited + 15))
  done
}

main() {
  set -ef

  # The aws calls below carry no --region flag and rely on the ambient region. Honor an
  # explicit AWS_REGION/AWS_DEFAULT_REGION, otherwise default to us-east-1 (the region
  # pinned in providers.tf) so the script works regardless of the caller's shell env.
  AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
  AWS_DEFAULT_REGION="${AWS_REGION}"
  export AWS_REGION AWS_DEFAULT_REGION

  require_tools

  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' EXIT INT TERM HUP

  read_terraform_outputs
  ensure_cluster_ready

  original_ids="$(inservice_ids | tr '\n' ' ')"

  # shellcheck disable=SC2086
  set -- ${original_ids}
  [ "$#" -ge 3 ] ||
    {
      log "ERROR: need at least 3 InService nodes to replace one and keep quorum (have $#)."
      exit 1
    }

  # After the replacement converges the cluster should have the same number of
  # voters it started with.
  expected_voters="$#"

  select_victim
  setup_consul_env

  # Read peers before terminating: proves the Consul endpoint and token work, so a
  # failure here aborts before anything destructive happens.
  log "Baseline raft peers:"
  raft_peers

  terminate_victim
  wait_for_replacement
  wait_for_cloud_init
  show_join_log

  if verify_raft; then
    log "RESULT:" "PASS - node replacement verified."
    exit 0
  fi

  log "RESULT:" "FAIL - see raft output above."
  exit 1
}

main "$@"
