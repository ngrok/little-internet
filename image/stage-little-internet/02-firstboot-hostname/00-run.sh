#!/bin/bash -e

# Install the first-boot hostname provisioner: a small script + systemd service
# that, on boot, reads /boot/firmware/little-internet-hostname.txt (if the
# flasher dropped one onto the FAT boot partition) and sets the system hostname
# from it *before* avahi-daemon advertises, so each card comes up as its own
# <name>.local instead of every card colliding on the default pi-node.local.
#
# Sibling to 01-firstboot-wifi and built the same way: this is the customization
# path for *released* images — someone who flashes the published .img.xz never
# ran the build, so the build-time TARGET_HOSTNAME in config isn't theirs to set.

install -D -m 755 files/little-internet-provision-hostname \
	"${ROOTFS_DIR}/usr/local/sbin/little-internet-provision-hostname"

install -D -m 644 files/little-internet-hostname.service \
	"${ROOTFS_DIR}/etc/systemd/system/little-internet-hostname.service"

# Ship the template on the FAT boot partition so it's discoverable from any OS
# the moment the card is flashed — no need to boot the Pi to find out how.
install -D -m 644 files/little-internet-hostname.txt.example \
	"${ROOTFS_DIR}/boot/firmware/little-internet-hostname.txt.example"

on_chroot << 'EOF'
systemctl enable little-internet-hostname.service
EOF
