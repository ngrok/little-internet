#!/bin/bash -e

# Install the wlan0 management-isolation firewall. WiFi is the operator's
# out-of-band management path (your SSH); the lessons run on the wired lab
# network (eth0). Without this, two nodes on the same home WiFi can ping and SSH
# each other out of the box, contaminating lesson 00 and blurring the
# management/data-plane split. This bakes in the isolation so it's true on every
# card, every boot, with no per-card configuration.
#
# Three pieces, mirroring how the other stages ship a script + unit:
#   - the generator script that reads wlan0's live gateway/subnet and loads the
#     nftables ruleset (and fails open if wlan0 isn't up yet),
#   - a systemd oneshot that runs it at boot, and
#   - a NetworkManager dispatcher that re-runs it whenever wlan0 gets an address,
#     which is when the rule can actually be built from the DHCP-assigned values.
#
# Unlike WiFi and the hostname there's no boot-partition file: the rule is
# identical on every card and self-configures from the live network, so there's
# nothing per-card to drop in.

install -D -m 755 files/little-internet-wlan0-isolate \
	"${ROOTFS_DIR}/usr/local/sbin/little-internet-wlan0-isolate"

install -D -m 644 files/little-internet-wlan0-isolation.service \
	"${ROOTFS_DIR}/etc/systemd/system/little-internet-wlan0-isolation.service"

# NetworkManager requires dispatcher scripts to be owned by root and executable
# (and not group/world writable); the build runs as root, so install root-owned.
install -D -m 755 files/50-little-internet-wlan0-isolate \
	"${ROOTFS_DIR}/etc/NetworkManager/dispatcher.d/50-little-internet-wlan0-isolate"

on_chroot << 'EOF'
systemctl enable little-internet-wlan0-isolation.service
EOF
