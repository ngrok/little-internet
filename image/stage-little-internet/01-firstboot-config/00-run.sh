#!/bin/bash -e

# Install the first-boot provisioner: one script + systemd service that, on boot,
# reads /boot/firmware/little-internet.txt (if the flasher dropped one onto the
# FAT boot partition) and sets the hostname and/or provisions a NetworkManager
# Wi-Fi connection from it. This is the customization path for *released* images
# — someone who flashes the published .img.xz never ran the build, so the
# build-time config.local / hostname options aren't theirs to set.

install -D -m 755 files/little-internet-provision \
	"${ROOTFS_DIR}/usr/local/sbin/little-internet-provision"

install -D -m 644 files/little-internet.service \
	"${ROOTFS_DIR}/etc/systemd/system/little-internet.service"

# Ship the template on the FAT boot partition so it's discoverable from any OS
# the moment the card is flashed — no need to boot the Pi to find out how.
install -D -m 644 files/little-internet.txt.example \
	"${ROOTFS_DIR}/boot/firmware/little-internet.txt.example"

on_chroot << 'EOF'
systemctl enable little-internet.service
EOF
