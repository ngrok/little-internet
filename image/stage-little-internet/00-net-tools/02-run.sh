#!/bin/bash -e

# Install a pre-provisioned Wi-Fi connection if build.sh generated one from
# image/config.local (LI_WIFI_SSID / LI_WIFI_PSK). No file means no Wi-Fi is
# baked in — which is the correct, credential-free default for the committed
# and publicly distributed image.
if [ -f files/preconfigured.nmconnection ]; then
	install -d -m 700 "${ROOTFS_DIR}/etc/NetworkManager/system-connections"
	install -m 600 files/preconfigured.nmconnection \
		"${ROOTFS_DIR}/etc/NetworkManager/system-connections/preconfigured.nmconnection"
fi
