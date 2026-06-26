#!/usr/bin/env bash
# Walk the whole lesson start to finish, pausing between each step. The individual
# step scripts still stand alone (run or re-run any one of them); this just chains
# them into one guided pass.
#
#   ./run.sh                 # drive two real Pis over SSH (set A_HOST / B_HOST)
#   ./run.sh --virtual       # stand up the local namespace lab, walk it, tear down
#
# --virtual needs Linux + root + the virtual/ deps (tcpdump, ping). On macOS or
# Windows, run that inside a Linux VM. See lessons/00/README.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "${1:-}" in
  "")        VIRTUAL= ;;
  --virtual) VIRTUAL=1 ;;
  *)         echo "usage: run.sh [--virtual]" >&2; exit 2 ;;
esac

# 00-link is hardware-only (Layer 1 needs a real PHY); it self-skips under netns.
BEATS=(00-link 01-listen 02-no-address 03-address 04-arp)

if [ -n "$VIRTUAL" ]; then
  sudo "$HERE/virtual/lab-down.sh" >/dev/null 2>&1 || true
  sudo QUIET=1 "$HERE/virtual/lab-up.sh" || exit 1
  export MODE=netns
  # tear the lab down on any exit, including Ctrl-C partway through
  trap 'sudo "$HERE/virtual/lab-down.sh" >/dev/null 2>&1 || true' EXIT
fi

for i in "${!BEATS[@]}"; do
  [ "$i" -gt 0 ] && printf '\n────────────────────────────────────────────────────\n'
  "$HERE/${BEATS[$i]}.sh"
done
