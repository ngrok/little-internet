#!/usr/bin/env bash
# VM-only transport and evidence helpers. Beats pause at each observation.
set -euo pipefail
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS/virtual-vm/common.sh"
CAPTURE_DIR="${CAPTURE_DIR:-$LAB_HOME/captures}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
CAPTURE_NODES=""
LOCKED=false
DECODE_ID=0

# Color identifies a role: phases, commands, questions, prose, or raw output.
# SSH does not inherit a terminal; apply output styling on the workstation.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _B=$'\033[1m'; _C=$'\033[36m'; _M=$'\033[35m'; _Y=$'\033[93m'
  # Explicit RGB white: ANSI bright white (97) can be gray in terminal themes.
  _W=$'\033[38;2;255;255;255m'; _G=$'\033[90m'; _X=$'\033[0m'
else
  _B=; _C=; _M=; _Y=; _W=; _G=; _X=
fi
TRANSCRIPT="$LAB_HOME/transcripts/$RUN_ID.log"
# Bash otherwise reads a script file incrementally across learner pauses. Load
# the whole phase first so editing that file cannot shift its next read offset.
# Preserve $0 for the phase's relative source paths, and preserve its arguments.
run_script() {
  local script="$1" body
  shift
  body=$(cat "$script") || return $?
  bash -c "$body" "$script" "$@"
}
say() { printf '\n%s%s%s\n' "$_W" "$*" "$_X"; }
h() { printf '\n%s%s▸ %s%s\n' "$_B" "$_C" "$*" "$_X"; }
phase_banner() {
  local rule='================================================================'
  printf '\n\n%s%s%s\n  %s\n%s%s\n' "$_B" "$_M" "$rule" "$*" "$rule" "$_X"
}
note() { say "$*"; }
eye() { printf '\n%swhat just happened%s\n%s%s%s\n' "$_B$_W" "$_X" "$_W" "$*" "$_X"; }
pause() {
  printf '\n%s%s%s\n' "$_B$_Y" "$*" "$_X"
  if [ -t 0 ] && [ "${LESSON_AUTO:-0}" != 1 ]; then
    read -r -p '[press Enter] ' _
  fi
}
terminal_output() {
  local status
  printf '%s' "$_G"
  if "$@"; then status=0; else status=$?; fi
  printf '%s' "$_X"
  return "$status"
}
node() {
  local n="$1" block="$2"
  h "[pi-$n] $ $block"
  printf '%s\n' "$block" | terminal_output node_ssh "$n" 'sudo bash -se'
}
# Routine setup stays in a transcript. On failure, show the exact block and
# its complete output, preserving the remote exit status. Never hide errors.
setup() {
  local n="$1" block="$2" output status
  mkdir -p "$LAB_HOME/transcripts"
  output="$(mktemp "$LAB_HOME/transcripts/.output.XXXXXX")"
  printf '\n[pi-%s] $ %s\n' "$n" "$block" >> "$TRANSCRIPT"
  if printf '%s\n' "$block" | node_ssh "$n" 'sudo bash -se' > "$output" 2>&1; then
    status=0
  else
    status=$?
  fi
  cat "$output" >> "$TRANSCRIPT"
  if [ "$status" -ne 0 ] || [ "${LESSON_VERBOSE:-0}" = 1 ]; then
    h "[pi-$n] $ $block"
    terminal_output cat "$output"
  fi
  rm -f "$output"
  return "$status"
}
finish() {
  pause "$1"$'\nThink it through, then press Enter to reveal the answer.'
  note "$2"
  pause 'Ready to leave this phase?'
  printf '\n%s%sPhase %s complete.%s\n' "$_B" "$_M" "${PHASE_TITLE%% — *}" "$_X"
  if [ "${LESSON_RUNNER:-0}" = 1 ]; then
    {
      printf '\n%s\n' "$PHASE_TITLE"
      if [ -n "${CAPTURE_NAME:-}" ]; then
        printf 'Captures: %s/%s-{a,b,dhcp}.pcap\n' "$CAPTURE_DIR" "$CAPTURE_NAME"
      fi
      printf 'Setup transcript: %s\n' "$TRANSCRIPT"
    } >> "$LESSON_RUN_INDEX"
    # The runner advances for the learner. Keep the final exploration/stop
    # directions, but do not tell them to launch the next script themselves.
    case "$3" in 'Next: '*) ;; *) say "$3";; esac
  else
    if [ -n "${CAPTURE_NAME:-}" ]; then
      note "All three captures: $CAPTURE_DIR/$CAPTURE_NAME-{a,b,dhcp}.pcap"
    fi
    note "Setup transcript: $TRANSCRIPT"
    say "$3"
  fi
}
cleanup() {
  local status=$? n
  for n in $CAPTURE_NODES; do
    node_ssh "$n" 'sudo systemctl stop little-internet-02-capture' >/dev/null 2>&1 || true
  done
  if "$LOCKED"; then rmdir "$LAB_HOME/lesson.lock"; fi
  if [ "$status" -ne 0 ]; then
    echo 'This beat failed. Keep the error above; inspect check.sh and retry after correcting it.' >&2
    echo 'Partial captures remain in /home/pi/cap on the guests.' >&2
  fi
}
begin() {
  mkdir -p "$LAB_HOME"
  if ! mkdir "$LAB_HOME/lesson.lock" 2>/dev/null; then
    echo "Another beat is running (or was interrupted). See README recovery for $LAB_HOME/lesson.lock." >&2
    exit 1
  fi
  LOCKED=true
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  PHASE_TITLE="$1"
  phase_banner "$PHASE_TITLE"
  note "$2"
}

capture_start() {
  local n
  CAPTURE_NAME="$1-$RUN_ID"
  mkdir -p "$CAPTURE_DIR"
  for n in a b dhcp; do
    setup "$n" "mkdir -p /home/pi/cap
      sudo systemd-run --quiet --collect --unit=little-internet-02-capture \
        --property=RuntimeMaxSec=180 \
        /usr/bin/tcpdump --immediate-mode -i eth0 -n -U -Z pi -w /home/pi/cap/$CAPTURE_NAME-$n.pcap \
        'arp or icmp or (udp and (port 67 or port 68))'"
    CAPTURE_NODES="$CAPTURE_NODES $n"
    setup "$n" "for i in \$(seq 1 50); do
      test ! -s /home/pi/cap/$CAPTURE_NAME-$n.pcap || exit 0
      sleep 0.1
    done
    sudo journalctl -u little-internet-02-capture --no-pager
    exit 1"
  done
}
capture_stop() {
  local n
  # Allow final replies to reach the capture readers before stopping them.
  sleep 1
  for n in $CAPTURE_NODES; do
    setup "$n" 'sudo systemctl stop little-internet-02-capture'
    node_ssh "$n" "cat /home/pi/cap/$CAPTURE_NAME-$n.pcap" > "$CAPTURE_DIR/$CAPTURE_NAME-$n.pcap"
  done
  CAPTURE_NODES=""
}
# Page verbatim decoded rows, without dropping or rewriting any of them. Eight
# rows leave room for wrapping, the heading, and a question in a typical terminal.
packet_rows() {
  local n="$1" command="$2" label="$3" file display_file total first last
  DECODE_ID=$((DECODE_ID + 1))
  file="$CAPTURE_DIR/$CAPTURE_NAME-$n-$label-$DECODE_ID.txt"
  mkdir -p "$CAPTURE_DIR" "$LAB_HOME/transcripts"
  printf '\n[pi-%s] $ %s\n' "$n" "$command" >> "$TRANSCRIPT"
  if [ "${LESSON_VERBOSE:-0}" = 1 ]; then h "[pi-$n] $ $command"; fi
  if ! printf '%s\n' "$command" | node_ssh "$n" 'sudo bash -se' > "$file"; then
    h "Failed: [pi-$n] $ $command"
    terminal_output cat "$file"
    return 1
  fi
  total=$(awk 'END {print NR}' "$file")
  if [ "$total" -eq 0 ]; then
    say '(No packets matched this filter.)'
    return
  fi
  display_file="$file"
  if [ "$label" = fields ]; then
    display_file="${file%.txt}-table.txt"
    dhcp_table < "$file" > "$display_file"
  fi
  first=1
  while [ "$first" -le "$total" ]; do
    last=$((first + 7))
    [ "$last" -le "$total" ] || last="$total"
    if [ "$label" = fields ]; then
      terminal_output printf '%5s  %-11s  %-12s  %-15s  %s\n' \
        Frame Transaction Message 'Requested (50)' yiaddr
    fi
    terminal_output sed -n "${first},${last}p" "$display_file"
    if [ "$last" -lt "$total" ]; then
      pause "Rows ${first}–${last} of $total. Inspect these before the next page."
    fi
    first=$((last + 1))
  done
}
dhcp_table() {
  # Keep the raw tshark fields file; this is its aligned display companion.
  awk -F '|' '
    BEGIN {name[1]="Discover"; name[2]="Offer"; name[3]="Request"; name[5]="ACK"}
    {
      message = ($3 in name) ? name[$3] " (" $3 ")" : $3
      requested = ($4 == "") ? "-" : $4
      printf "%5s  %-11s  %-12s  %-15s  %s\n", $1, $2, message, requested, $5
    }'
}
capture_show() {
  local n="$1" filter="${2:-arp or icmp or dhcp}"
  h "pi-$n packets · filter: $filter"
  packet_rows "$n" "sudo -u pi tshark -n -r /home/pi/cap/$CAPTURE_NAME-$n.pcap -Y '$filter'" packets
}
dhcp_fields() {
  local n="$1"
  h "pi-$n DHCP fields · this client's exchange only"
  note 'Requested (50) is the preference; yiaddr is the offered/assigned address.
A dash means Option 50 is absent. 0.0.0.0 is the actual value in that packet.'
  packet_rows "$n" "sudo -u pi tshark -n -r /home/pi/cap/$CAPTURE_NAME-$n.pcap -Y 'dhcp && dhcp.hw.mac_addr == $(cable_mac "$n")' -T fields -E separator='|' \
    -e frame.number -e dhcp.id -e dhcp.option.dhcp \
    -e dhcp.option.requested_ip_address -e dhcp.ip.your" fields
}
client_down() {
  setup "$1" 'if nmcli -t -f NAME connection show --active | grep -qx eth-dhcp; then
  nmcli connection down eth-dhcp
fi'
}
forget_client() {
  setup "$1" 'lease_uuid=$(nmcli -g connection.uuid connection show eth-dhcp)
rm -f "/var/lib/NetworkManager/dhclient-${lease_uuid}-eth0.lease"'
}
client_ip() {
  node_ssh "$1" "ip -4 -o addr show dev eth0 | awk '{split(\$4,a,\"/\"); print a[1]}'"
}
# Read-only: stdout contains reset reasons, while transport/probe failures keep
# their nonzero status. A failed inspection must never be treated as a dirty lab.
starting_state() {
  local n reasons
  for n in a b dhcp; do
    reasons=$(node_ssh "$n" 'sudo bash -se' -- "$n" <<'REMOTE'
reasons=()
link=$(ip -o link show dev eth0)
case "$link" in *LOWER_UP*) ;; *) reasons+=("Ethernet link is down");; esac
addresses=$(ip -4 -o addr show dev eth0)
[ -z "$addresses" ] || reasons+=("IPv4 address still assigned")
profiles=$(nmcli -t -f NAME connection show)
if printf '%s\n' "$profiles" | grep -Eq '^eth-(manual|server)$'; then
  reasons+=("lesson profiles remain")
fi
if printf '%s\n' "$profiles" | grep -qx eth-dhcp; then
  baseline=$(nmcli -g ipv4.method,connection.autoconnect connection show eth-dhcp)
  [ "$baseline" = $'auto\nno' ] || reasons+=("DHCP profile changed")
else
  reasons+=("DHCP profile is missing")
fi
active=$(nmcli -t -f NAME connection show --active)
if printf '%s\n' "$active" | grep -qx eth-dhcp; then
  reasons+=("DHCP client is active")
fi
if [ -e /etc/NetworkManager/dhclient-eth0.conf ]; then
  reasons+=("address preference remains")
fi
for lease in /var/lib/NetworkManager/dhclient-*-eth0.lease; do
  if [ -s "$lease" ]; then reasons+=("remembered client lease"); break; fi
done
if [ "$1" = dhcp ]; then
  if systemctl is-active --quiet dnsmasq || systemctl is-enabled --quiet dnsmasq; then
    reasons+=("DHCP server is running or enabled")
  fi
  [ ! -s /var/lib/misc/dnsmasq.leases ] || reasons+=("server leases remain")
fi
if [ "${#reasons[@]}" -gt 0 ]; then
  printf '%s' "${reasons[0]}"
  for ((i=1; i<${#reasons[@]}; i++)); do printf '; %s' "${reasons[i]}"; done
  printf '\n'
fi
REMOTE
    ) || return $?
    if [ -n "$reasons" ]; then printf 'pi-%s: %s\n' "$n" "$reasons"; fi
  done
}
prepare_start() {
  local reasons
  if [ -d "$LAB_HOME/lesson.lock" ]; then
    echo 'Another beat is running (or was interrupted). See README lock recovery before restarting.' >&2
    return 1
  fi
  reasons=$(starting_state) || return $?
  if [ -z "$reasons" ]; then
    note 'The lab is at the starting line.'
    return
  fi
  h 'Reset needed before phase 01'
  printf '%s\n' "$reasons"
  if [ ! -t 0 ] && [ "${LESSON_AUTO:-0}" != 1 ]; then
    echo 'Run ./scripts/run.sh in a terminal to reset with Enter, or use --auto for an unattended reset and run.' >&2
    return 1
  fi
  # reset.sh owns the one Enter prompt and the lesson lock.
  run_script "$SCRIPTS/reset.sh" || return $?
  reasons=$(starting_state) || return $?
  if [ -n "$reasons" ]; then
    printf 'Reset did not restore the starting state:\n%s\n' "$reasons" >&2
    return 1
  fi
}
require_clients() {
  local n addr
  for n in a b; do
    addr="$(client_ip "$n")"
    case "$addr" in 10.10.0.[1-9]|10.10.0.10) ;;
      *) echo "pi-$n needs a DHCP address first; run 04-dora.sh. Found: $addr" >&2; exit 1;;
    esac
  done
}
