#!/bin/bash -e

# Install NetworkManager connection profiles into the image.

# eth0's stock resting state: a DHCP, autoconnect wired profile (eth-dhcp). It's
# what lets a freshly flashed Pi chatter the instant the cable is seated (DHCP
# Discover, IPv6 SLAAC, mDNS) with nothing configured by the reader — the opening
# beat of lesson 00. It never claims the default route, so management stays on
# wlan0. NM ignores keyfiles that are group/world readable, hence mode 600.
install -d -m 700 "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
install -m 600 files/eth-dhcp.nmconnection \
	"${ROOTFS_DIR}/etc/NetworkManager/system-connections/eth-dhcp.nmconnection"

# Install a pre-provisioned Wi-Fi connection if build.sh generated one from
# image/config.local (LI_WIFI_SSID / LI_WIFI_PSK). No file means no Wi-Fi is
# baked in — which is the correct, credential-free default for the committed
# and publicly distributed image.
if [ -f files/preconfigured.nmconnection ]; then
	install -m 600 files/preconfigured.nmconnection \
		"${ROOTFS_DIR}/etc/NetworkManager/system-connections/preconfigured.nmconnection"
fi
