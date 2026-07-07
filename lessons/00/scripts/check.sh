#!/usr/bin/env bash
# Preflight lesson 00 before running it. This script is intentionally read-only:
# it checks tools, reachability, privileges, and current lab state, but it does
# not create namespaces, change addresses, delete profiles, or prompt for SSH
# passwords.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
A_HOST="${A_HOST:-pi@pi-foo-01.local}"
B_HOST="${B_HOST:-pi@pi-foo-02.local}"

FAILS=0
WARNS=0

usage() {
  cat <<EOF
usage: check.sh [--virtual|--hardware]

  --virtual   check this machine for the Linux namespace lab
  --hardware  check SSH access and tools on A_HOST/B_HOST

Without a mode, check.sh auto-selects --virtual when a pi-a namespace already
exists, otherwise --hardware.
EOF
}

ok() { printf 'OK   %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*"; WARNS=$((WARNS + 1)); }
fail() { printf 'FAIL %s\n' "$*"; FAILS=$((FAILS + 1)); }
info() { printf 'INFO %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

check_cmd() {
  if have "$1"; then ok "found $1"; else fail "missing $1"; fi
}

check_optional_cmd() {
  if have "$1"; then ok "found $1"; else warn "missing optional $1"; fi
}

remote() {
  # Noninteractive by design. If the user's SSH needs a password, this reports
  # that clearly instead of hanging an agent or CI run.
  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=accept-new \
    -o LogLevel=ERROR \
    "$1" "$2"
}

remote_check() {
  local host="$1"
  local label="$2"

  info "$label host: $host"

  if ! have ssh; then
    fail "local ssh command is missing"
    return
  fi

  if remote "$host" "true" >/dev/null 2>&1; then
    ok "$label SSH reachable without an interactive password"
  else
    fail "$label SSH is not reachable noninteractively"
    info "set ${label}_HOST or export A_HOST/B_HOST, and make sure SSH keys or agent auth are available"
    return
  fi

  local report
  if ! report="$(remote "$host" 'bash -s' <<'REMOTE'
set -u
status=0
warns=0
check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "OK found %s\n" "$1"
  else
    printf "FAIL missing %s\n" "$1"
    status=1
  fi
}
optional() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "OK found %s\n" "$1"
  else
    printf "WARN missing optional %s\n" "$1"
    warns=$((warns + 1))
  fi
}

check ip
check ping
check tcpdump
check ethtool
optional tshark

if ip link show eth0 >/dev/null 2>&1; then
  printf "OK eth0 exists\n"
else
  printf "FAIL eth0 is missing\n"
  status=1
fi

if sudo -n true >/dev/null 2>&1; then
  printf "OK sudo works without a password prompt\n"
else
  printf "WARN sudo needs a password or is unavailable noninteractively\n"
  warns=$((warns + 1))
fi

if command -v nmcli >/dev/null 2>&1; then
  if nmcli -t -f NAME con show 2>/dev/null | grep -qx eth; then
    printf "WARN NetworkManager profile 'eth' already exists; run ./scripts/reset.sh before a fresh hardware lesson\n"
    warns=$((warns + 1))
  else
    printf "OK no lesson NetworkManager profile named eth\n"
  fi
else
  printf "WARN nmcli missing; hardware image normally has NetworkManager\n"
  warns=$((warns + 1))
fi

if ip -4 addr show eth0 2>/dev/null | grep -q 'inet '; then
  printf "WARN eth0 already has an IPv4 address; run ./scripts/reset.sh for a blank-wire start\n"
  warns=$((warns + 1))
else
  printf "OK eth0 has no IPv4 address\n"
fi

exit "$status"
REMOTE
)"; then
    fail "$label remote probe failed"
    printf '%s\n' "$report" | sed "s/^/     $label: /"
    return
  fi

  while IFS= read -r line; do
    case "$line" in
      OK*) ok "$label ${line#OK }" ;;
      WARN*) warn "$label ${line#WARN }" ;;
      FAIL*) fail "$label ${line#FAIL }" ;;
      *) info "$label $line" ;;
    esac
  done <<EOF
$report
EOF
}

check_virtual() {
  info "checking virtual lesson prerequisites"

  if [ "$(uname -s)" = Linux ]; then
    ok "host OS is Linux"
  else
    fail "virtual lab needs Linux; run it inside a Linux VM on macOS or Windows"
  fi

  if [ "$(id -u)" -eq 0 ]; then
    ok "running as root"
  else
    fail "virtual lab needs root; run with sudo"
  fi

  check_cmd ip
  check_cmd ping
  check_cmd tcpdump
  check_optional_cmd tshark

  if have ip && ip netns list >/dev/null 2>&1; then
    ok "ip netns is available"
  else
    fail "ip netns is unavailable"
  fi

  if [ -e /run/netns/pi-a ] || [ -e /var/run/netns/pi-a ]; then
    ok "namespace pi-a exists"
  else
    info "namespace pi-a is not up yet; run sudo ./scripts/run.sh --virtual to create it"
  fi

  if [ -e /run/netns/pi-b ] || [ -e /var/run/netns/pi-b ]; then
    ok "namespace pi-b exists"
  else
    info "namespace pi-b is not up yet; run sudo ./scripts/run.sh --virtual to create it"
  fi
}

check_hardware() {
  info "checking hardware lesson prerequisites"
  info "A_HOST=$A_HOST"
  info "B_HOST=$B_HOST"

  check_cmd ssh
  remote_check "$A_HOST" "A"
  remote_check "$B_HOST" "B"
}

MODE="${1:-auto}"
case "$MODE" in
  --virtual) check_virtual ;;
  --hardware) check_hardware ;;
  -h|--help) usage; exit 0 ;;
  auto)
    if [ -e /run/netns/pi-a ] || [ -e /var/run/netns/pi-a ]; then
      check_virtual
    else
      check_hardware
    fi
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [ "$FAILS" -gt 0 ]; then
  printf '\n%d failed check(s), %d warning(s).\n' "$FAILS" "$WARNS"
  exit 1
fi

printf '\nAll required checks passed'
if [ "$WARNS" -gt 0 ]; then
  printf ' with %d warning(s)' "$WARNS"
fi
printf '.\n'
