#!/bin/bash -e

# Install NetworkManager connection profiles into the image.

# eth0's stock resting state: a DHCP, autoconnect wired profile (eth-dhcp). It's
# what lets a freshly flashed Pi chatter the instant the cable is seated (DHCP
# Discover, IPv6 SLAAC, mDNS) with nothing configured by the reader — the opening
# beat of lesson 01. It never claims the default route, so management stays on
# wlan0. NM ignores keyfiles that are group/world readable, hence mode 600.
install -d -m 700 "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
install -m 600 files/eth-dhcp.nmconnection \
	"${ROOTFS_DIR}/etc/NetworkManager/system-connections/eth-dhcp.nmconnection"

# The DHCP server's identity on the lab wire, shipped with autoconnect=false so
# no node comes up holding it. Lesson 02 turns a node into the lab's DHCP server
# by bringing this profile up by hand; until then every node's eth0 rests on
# eth-dhcp and stays blank. See the comments in the file itself.
install -m 600 files/eth-lab-static.nmconnection \
	"${ROOTFS_DIR}/etc/NetworkManager/system-connections/eth-lab-static.nmconnection"

# Install a pre-provisioned Wi-Fi connection if build.sh generated one from
# image/config.local (LI_WIFI_SSID / LI_WIFI_PSK). No file means no Wi-Fi is
# baked in — which is the correct, credential-free default for the committed
# and publicly distributed image.
if [ -f files/preconfigured.nmconnection ]; then
	install -m 600 files/preconfigured.nmconnection \
		"${ROOTFS_DIR}/etc/NetworkManager/system-connections/preconfigured.nmconnection"
fi
