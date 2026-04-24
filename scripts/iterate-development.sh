#!/bin/sh
# Usage: ./iterate-development.sh
#
# Scales down the Consul ASG, terminates instances, and resets
# cluster coordination state so the next terraform apply triggers
# a fresh bootstrap.

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

read_terraform_outputs() {
  log "Reading Terraform outputs."

  # Switch to the Terraform root directory.
  cd "$(dirname "$0")/.."

  terraform_output="$(terraform output -json)"
  asg_name="$(
    printf '%s\n' "${terraform_output}" |
      jq -r '.consul_asg_name.value'
  )"
  bootstrap_token_secret_arn="$(
    printf '%s\n' "${terraform_output}" |
      jq -r '.consul_bootstrap_token_secret_arn.value // empty'
  )"
  agent_token_secret_arn="$(
    printf '%s\n' "${terraform_output}" |
      jq -r '.consul_agent_token_secret_arn.value // empty'
  )"
  log "  ASG:" "${asg_name}"
  log "  Bootstrap token secret:" "${bootstrap_token_secret_arn}"
  log "  Agent token secret:" "${agent_token_secret_arn}"
}

wait_for_asg_empty() {
  log "Waiting for ASG to scale down."
  while :; do
    count="$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "${asg_name}" \
      --query 'length(AutoScalingGroups[0].Instances)' \
      --output text)"
    [ "${count}" = "0" ] && break
    sleep 10
  done
  log "  ASG is empty."
}

delete_consul_secrets() {
  log "Deleting Consul Secrets Manager secrets."

  for arn in "${bootstrap_token_secret_arn}" "${agent_token_secret_arn}"; do
    if [ -z "${arn}" ]; then
      continue
    fi

    aws secretsmanager delete-secret \
      --secret-id "${arn}" \
      --force-delete-without-recovery >/dev/null 2>&1 || true

    log "  Deleted:" "${arn}"
  done
}

delete_coordination_ssm_parameters() {
  log "Deleting coordination SSM parameters."

  names="$(aws ssm describe-parameters \
    --parameter-filters "Key=Name,Option=BeginsWith,Values=/lab/consul/" \
    --query 'Parameters[].Name' --output text)"

  if [ -z "${names}" ]; then
    log "  Nothing to delete."
    return 0
  fi

  log "  Deleting:" "$(printf '%s' "${names}" | tr '\t' ' ')"
  # shellcheck disable=SC2086
  aws ssm delete-parameters --names ${names} >/dev/null
}

main() {
  set -ef

  read_terraform_outputs

  # Scale the ASG down to 0
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "${asg_name}" \
    --min-size 0 --desired-capacity 0

  # Grab the current instance IDs
  ids="$(
    aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "${asg_name}" \
      --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
      --output text |
      tr '\t' '\n'
  )"

  # shellcheck disable=SC2086
  # Nuke them to speed up the scale down
  [ -n "${ids}" ] && aws ec2 terminate-instances --instance-ids ${ids}

  wait_for_asg_empty
  delete_consul_secrets
  delete_coordination_ssm_parameters
}

main "$@"
