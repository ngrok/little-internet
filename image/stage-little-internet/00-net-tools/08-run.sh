#!/bin/bash -e

# Ship the lab's DHCP configuration inert, and keep the daemon off until a
# reader promotes a node to server.
#
# Lesson 02's whole arc is discovering that a wire full of frames still hands
# out no identities, and that fixing it takes a server with an address of its
# own. So the image ships everything needed and activates none of it: the
# package (00-packages), the server's static profile (02-run.sh), and the
# drop-in below, whose dhcp-range line is commented out.

# The lab's DHCP config goes in a drop-in, not in /etc/dnsmasq.conf. The stock
# config is ~700 mostly-commented lines, and asking a reader to find line 143 of
# it teaches nothing about DHCP. World-readable (644) because it holds no
# secrets and it's meant to be read.
install -d -m 755 "${ROOTFS_DIR}/etc/dnsmasq.d"
install -m 644 files/little-internet-dnsmasq.conf \
	"${ROOTFS_DIR}/etc/dnsmasq.d/little-internet.conf"

on_chroot << 'EOF'
set -e

# Debian's dnsmasq reads /etc/dnsmasq.d/*.conf through a conf-dir line in
# /etc/dnsmasq.conf, and ships it enabled. Assert it rather than trust it: if
# that line is ever commented out, the drop-in above becomes a 50-line file that
# silently does nothing, which is a miserable thing to debug on someone else's
# Pi. Idempotent, and a no-op on a stock config.
if [ -f /etc/dnsmasq.conf ]; then
	# Uncomment an existing commented conf-dir line, or append one if the
	# stock config somehow has neither form.
	sed -i 's|^[[:space:]]*#[[:space:]]*\(conf-dir=/etc/dnsmasq.d/,\*\.conf\)|\1|' \
		/etc/dnsmasq.conf
	if ! grep -Eq '^[[:space:]]*conf-dir=/etc/dnsmasq\.d/' /etc/dnsmasq.conf; then
		printf '\n# Added by little-internet: read drop-ins from /etc/dnsmasq.d.\nconf-dir=/etc/dnsmasq.d/,*.conf\n' \
			>> /etc/dnsmasq.conf
	fi
fi

# Off by default. Installing the package enables the unit, which would put a
# DHCP daemon on every node in the lab and turn any startup failure into a red
# unit on a stranger's first boot. Lesson 02 starts it deliberately, on one node,
# with `systemctl enable --now dnsmasq`.
systemctl disable dnsmasq || true
EOF
