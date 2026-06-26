#!/usr/bin/env bash
# A live "two displays, side by side" dashboard for the namespace lab:
#
#   +---------------------------+---------------------------+
#   |  pi-a's ARP cache         |  pi-b's ARP cache         |
#   |  (arp-watch.py)           |  (arp-watch.py)           |
#   +---------------------------+---------------------------+
#   |  a shell "on" pi-a — poke the lab and watch it react  |
#   +-------------------------------------------------------+
#
# Recreates the spatial, glanceable feel the OLEDs give on hardware. Needs Linux,
# root, and tmux, with the lab already up. Address the nodes first (run
# 03-address.sh, MODE=netns) if you want pings to land.
#
#   sudo ./lab-up.sh
#   sudo ./watch.sh        # you land in the bottom shell; Ctrl-b d to detach
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WATCH="$(dirname "$HERE")/arp-watch.py"
SESSION="little-internet"

[ "$(uname -s)" = Linux ] || { echo "Linux only (network namespaces). See lessons/00/README.md." >&2; exit 1; }
[ "$(id -u)" -eq 0 ]       || { echo "Needs root (namespaces + tmux server). Re-run with sudo." >&2; exit 1; }
command -v tmux >/dev/null || { echo "Needs tmux. Install it, e.g. sudo apt-get install -y tmux." >&2; exit 1; }
ip netns list | grep -qw pi-a || { echo "The lab isn't up. Run 'sudo ./lab-up.sh' first." >&2; exit 1; }

# Newer terminals (Ghostty, kitty, ...) often have no terminfo entry in the VM, and
# tmux then refuses with "missing or unsuitable terminal". Fall back to a universal
# entry when the current TERM is unknown here.
if ! infocmp "${TERM:-dumb}" >/dev/null 2>&1; then
  echo "note: TERM='${TERM:-}' has no terminfo here; using xterm-256color for tmux." >&2
  export TERM=xterm-256color
fi

tmux kill-session -t "$SESSION" 2>/dev/null || true

# top-left: pi-a's cache
tmux new-session -d -s "$SESSION" -x 220 -y 50 "ip netns exec pi-a python3 \"$WATCH\" --name pi-a"
# bottom (full width): a shell on pi-a. Capture its stable pane id — tmux renumbers
# positional indices after each split, but %id is forever.
bottom=$(tmux split-window -v -t "$SESSION" -l 30% -P -F '#{pane_id}' "ip netns exec pi-a bash")
tmux send-keys -t "$bottom" \
  'clear; echo "You are on pi-a. Try: ping -c1 10.10.0.2 (REACHABLE), ping -c1 10.10.0.99 (FAILED). Watch both panes."' Enter
# top-right: pi-b's cache (split the top-left pane)
tmux select-pane -t "$SESSION:0.0"
tmux split-window -h -t "$SESSION" "ip netns exec pi-b python3 \"$WATCH\" --name pi-b"
# land focus on the shell so you can type right away
tmux select-pane -t "$bottom"

if [ -t 1 ] && [ -z "${NO_ATTACH:-}" ]; then
  tmux attach -t "$SESSION"
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  echo "Dashboard closed. The lab is still up (tear it down with: sudo ./lab-down.sh)."
else
  echo "Dashboard session '$SESSION' created (detached)."
  echo "  attach:    sudo tmux attach -t $SESSION"
  echo "  poke pi-a:  sudo tmux send-keys -t $bottom 'ping -c1 10.10.0.2' Enter"
  echo "  kill:      sudo tmux kill-session -t $SESSION"
fi
