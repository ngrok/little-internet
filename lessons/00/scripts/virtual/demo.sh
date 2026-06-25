#!/usr/bin/env bash
# One-shot virtual run: build the namespace lab, drive the steps through the
# SAME scripts the hardware path uses (MODE=netns), then tear it down. The
# Layer 1 step is skipped—a veth has no PHY. Run as a user who can sudo.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(dirname "$HERE")"

sudo "$HERE/lab-down.sh" >/dev/null 2>&1 || true
sudo QUIET=1 "$HERE/lab-up.sh"
echo
for step in 01-listen 02-no-address 03-address 04-arp; do
  echo "========== $step (MODE=netns) =========="
  MODE=netns "$SCRIPTS/$step.sh"
  echo
done
sudo "$HERE/lab-down.sh"
