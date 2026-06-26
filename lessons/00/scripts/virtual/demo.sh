#!/usr/bin/env bash
# One-shot virtual run: build the namespace lab, drive the steps through the
# SAME scripts the hardware path uses (MODE=netns), then tear it down. The
# Layer 1 step is skipped—a veth has no PHY. Run as a user who can sudo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(dirname "$HERE")"

# Linux-only (network namespaces). Bail before we touch anything on macOS/Windows.
if [ "$(uname -s)" != Linux ]; then
  echo "This lab needs Linux (network namespaces). On macOS or Windows, run it inside a Linux VM; see lessons/00/README.md." >&2
  exit 1
fi

sudo "$HERE/lab-down.sh" >/dev/null 2>&1 || true
sudo QUIET=1 "$HERE/lab-up.sh" || exit 1
echo
for step in 01-listen 02-no-address 03-address 04-arp; do
  echo "========== $step (MODE=netns) =========="
  MODE=netns "$SCRIPTS/$step.sh"
  echo
done
sudo "$HERE/lab-down.sh"
