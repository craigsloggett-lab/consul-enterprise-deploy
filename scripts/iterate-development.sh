#!/bin/sh
# Usage: ./iterate-development.sh
#
# Resets cluster coordination state so the next terraform apply
# triggers a fresh bootstrap. Run before replacing Consul instances.

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

  delete_coordination_ssm_parameters
}

main "$@"
