#!/bin/sh
# Usage: ./manual-get-cloud-init-logs.sh <bastion_ip> <asg_name> [ami_name]
#
# Reads cloud-final logs without Terraform outputs, for debugging when state is
# unavailable. Takes the bastion IP and ASG name as arguments; the AMI name only
# selects the SSH user and defaults to an Ubuntu image.

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
  _bastion_ip="$1"
  _asg_name="$2"
  _ami_name="${3:-ubuntu}"

  log "Resolving nodes from the ASG."

  case "${_ami_name}" in
    *ubuntu*) ssh_user="ubuntu" ;;
    *debian*) ssh_user="admin" ;;
    *)
      log "ERROR: Unsupported AMI:" "${_ami_name}"
      exit 1
      ;;
  esac

  log "  ASG:" "${_asg_name}"
  # Resolve instance IDs from ASG, then private IPs from EC2.
  instance_ids="$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "${_asg_name}" \
    --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
    --output text)"

  if [ -z "${instance_ids}" ]; then
    log "ERROR: No InService instances found in ASG:" "${_asg_name}"
    exit 1
  fi

  # shellcheck disable=SC2086
  node_ips="$(aws ec2 describe-instances \
    --instance-ids ${instance_ids} \
    --query "Reservations[].Instances[].PrivateIpAddress" \
    --output text | tr '\t' '\n')"

  log "  Bastion IP:" "${_bastion_ip}"
  log "  Consul nodes:" "$(printf '%s\n' "${node_ips}" | tr '\n' ' ')"
  log "  SSH user:" "${ssh_user}"
}

main() {
  set -ef

  # Read from input parameters.
  bastion_ip="${1:?usage: manual-get-cloud-init-logs.sh <bastion_ip> <asg_name> [ami_name]}"
  asg_name="${2:?usage: manual-get-cloud-init-logs.sh <bastion_ip> <asg_name> [ami_name]}"
  ami_name="${3:-ubuntu}"

  # Get host IPs
  read_terraform_outputs "${bastion_ip}" "${asg_name}" "${ami_name}"

  # Remove stale bastion host key
  ssh-keygen -R "${bastion_ip}" >/dev/null 2>&1

  # Add Bastion host key to known_hosts without confirmation
  set -- -o StrictHostKeyChecking=no -o LogLevel=ERROR
  ssh "${@}" "${ssh_user}@${bastion_ip}" ':'

  # Set SSH options for all SSH commands
  set -- "${@}" -o UserKnownHostsFile=/dev/null

  for ip in ${node_ips}; do
    log "Showing cloud-init log messages for:" "${ip}"
    ssh "${@}" -J "${ssh_user}@${bastion_ip}" "${ssh_user}@${ip}" 'sudo journalctl -u cloud-final'
  done

  # Present SSH jump commands for convenience.
  for ip in ${node_ips}; do
    log "To login to ${ip}:" "ssh -J ubuntu@${bastion_ip} ubuntu@${ip}"
  done
}

main "$@"
