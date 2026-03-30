#!/bin/sh
# Usage: ./initialize-cluster.sh

log() {
  printf '%b%s %b%s%b %s\n' \
    "${c1}" "${3:-->}" "${c3}${2:+$c2}" "$1" "${c3}" "$2" >&2
}

read_terraform_outputs() {
  log "Reading Terraform outputs."

  repo_root="$(cd "$(dirname "$0")/.." && pwd)"
  bastion_ip=$(cd "${repo_root}" && terraform output -raw bastion_public_ip)
  consul_ips=$(cd "${repo_root}" && terraform output -json consul_private_ips | jq -r '.[]')
  ami_name=$(cd "${repo_root}" && terraform output -raw ec2_ami_name)

  first_consul_ip=$(printf '%s\n' "${consul_ips}" | head -1)

  case "${ami_name}" in
    *ubuntu*) ssh_user="ubuntu" ;;
    *debian*) ssh_user="admin" ;;
    *)
      log "ERROR: Unsupported AMI:" "${ami_name}"
      exit 1
      ;;
  esac

  log "  Bastion IP:" "${bastion_ip}"
  log "  Consul nodes:" "$(printf '%s\n' "${consul_ips}" | tr '\n' ' ')"
  log "  SSH user:" "${ssh_user}"
}

accept_host_keys() {
  log "Accepting SSH host keys."

  # Accept the bastion host key directly.
  if ! ssh-keygen -F "${bastion_ip}" >/dev/null 2>&1; then
    ssh-keyscan -H "${bastion_ip}" >>~/.ssh/known_hosts 2>/dev/null
  fi

  # Accept internal node keys by running ssh-keyscan on the bastion.
  printf '%s\n' "${consul_ips}" | while read -r ip; do
    if ! ssh-keygen -F "${ip}" >/dev/null 2>&1; then
      # shellcheck disable=SC2086
      ssh ${ssh_opts} "${ssh_user}@${bastion_ip}" \
        "ssh-keyscan -H ${ip} 2>/dev/null" >>~/.ssh/known_hosts
    fi
  done
}

remote_exec() {
  target_ip="${1:?target IP required}"
  shift
  # shellcheck disable=SC2086
  ssh ${ssh_opts} -J "${ssh_user}@${bastion_ip}" "${ssh_user}@${target_ip}" "$@"
}

wait_for_consul() {
  log "Waiting for Consul to be reachable."

  attempts=0
  max_attempts=30
  while ! remote_exec "${first_consul_ip}" \
    "sudo curl -sf --cacert /opt/consul/tls/ca.crt --cert /opt/consul/tls/server.crt --key /opt/consul/tls/server.key https://127.0.0.1:8501/v1/status/leader" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "${attempts}" -ge "${max_attempts}" ]; then
      log "ERROR: Consul not reachable after ${max_attempts} attempts."
      exit 1
    fi
    sleep 2
  done

  log "Consul is reachable."
}

bootstrap_acl() {
  init_file="$(cd "$(dirname "$0")" && pwd)/consul-init.json"

  # Check if ACL system is already bootstrapped.
  if [ -f "${init_file}" ]; then
    log "ACL system already bootstrapped (${init_file} exists)."
    return
  fi

  log "Bootstrapping Consul ACL system."

  if remote_exec "${first_consul_ip}" \
    "sudo consul acl bootstrap -format=json -ca-file=/opt/consul/tls/ca.crt -client-cert=/opt/consul/tls/server.crt -client-key=/opt/consul/tls/server.key -http-addr=https://127.0.0.1:8501" \
    >"${init_file}" 2>/dev/null; then
    log "ACL bootstrap complete."
    log "IMPORTANT: The bootstrap token has been saved to consul-init.json." "" "!!"
    log "           Store this file securely and delete it from disk." "" "  "
  else
    log "ERROR: ACL bootstrap failed (system may already be bootstrapped)."
    rm -f "${init_file}"
    exit 1
  fi
}

configure_snapshot_agent() {
  log "Configuring snapshot agent token on all nodes."

  init_file="$(cd "$(dirname "$0")" && pwd)/consul-init.json"
  bootstrap_token=$(jq -r '.SecretID' "${init_file}")

  for ip in ${consul_ips}; do
    log "  Writing snapshot token on ${ip}."
    remote_exec "${ip}" \
      "sudo sed -i 's|^CONSUL_HTTP_TOKEN=.*|CONSUL_HTTP_TOKEN=${bootstrap_token}|' /etc/consul.d/snapshot-token && sudo systemctl enable --now consul-snapshot-agent"
  done

  log "Snapshot agent started on all nodes."
}

main() {
  set -ef

  ssh_opts="-o ConnectTimeout=10 -o LogLevel=ERROR"

  # Colors are automatically disabled if output is not a terminal.
  ! [ -t 2 ] || {
    c1='\033[1;33m'
    c2='\033[1;34m'
    c3='\033[m'
  }

  read_terraform_outputs
  accept_host_keys
  wait_for_consul
  bootstrap_acl
  configure_snapshot_agent
}

main "$@"
