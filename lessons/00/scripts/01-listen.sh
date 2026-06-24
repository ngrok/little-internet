#!/usr/bin/env bash
# Beat 2 + 3 (raw) — They're already talking. Capture the burst the instant the
# link comes up.
#
# The chatter only fires when the interface comes UP, so start this capture
# FIRST, then trigger the link (plug the cable, or toggle it with
# `sudo nmcli device disconnect eth0 && sudo nmcli device connect eth0`).
#
# Watch for:
#   ICMPv6  — IPv6 claiming its own fe80:: (DAD), MLD group joins, router
#             solicitations that never get answered.
#   MDNS    — the node announcing its own hostname, in the clear, to the link.
#   DHCP    — Discover after Discover, with no Offer ever coming back.
# All talk, no answers. Then it goes quiet. Ctrl-C to stop.
set -uo pipefail
IFACE="${IFACE:-eth0}"
OUT="${OUT:-$HOME/cap/link-up_$(hostname).pcap}"
mkdir -p "$(dirname "$OUT")"

echo ">>> Capturing on $IFACE -> $OUT"
echo ">>> Trigger the link now (plug the cable or toggle the interface)."
echo ">>> Ctrl-C when the burst has died down. Read it back with:"
echo ">>>   tcpdump -n -e -r $OUT   (or open it in Wireshark)"
echo
exec sudo tcpdump -i "$IFACE" -n -e -w "$OUT"
