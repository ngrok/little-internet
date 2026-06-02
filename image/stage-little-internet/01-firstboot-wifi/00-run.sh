#!/bin/bash -e

# Install the first-boot Wi-Fi provisioner: a small script + systemd service
# that, on boot, reads /boot/firmware/little-internet-wifi.txt (if the flasher
# dropped one onto the FAT boot partition) and provisions a NetworkManager
# connection from it. This is the customization path for *released* images —
# someone who flashes the published .img.xz never ran the build, so the
# build-time config.local path isn't available to them.

install -D -m 755 files/little-internet-provision-wifi \
	"${ROOTFS_DIR}/usr/local/sbin/little-internet-provision-wifi"

install -D -m 644 files/little-internet-wifi.service \
	"${ROOTFS_DIR}/etc/systemd/system/little-internet-wifi.service"

# Ship the template on the FAT boot partition so it's discoverable from any OS
# the moment the card is flashed — no need to boot the Pi to find out how.
install -D -m 644 files/little-internet-wifi.txt.example \
	"${ROOTFS_DIR}/boot/firmware/little-internet-wifi.txt.example"

on_chroot << 'EOF'
systemctl enable little-internet-wifi.service
EOF
