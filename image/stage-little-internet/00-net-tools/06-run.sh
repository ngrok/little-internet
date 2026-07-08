#!/bin/bash -e

# Install the ARP-state OLED viewer into the first user's home, next to the
# oled-test scripts, so it's there off a fresh flash. It's a read-only window
# onto the kernel neighbour cache for the peer node (the other half of the
# 10.10.0.x lab pair) — you run it when you want it and watch the panel follow
# the ARP state machine you drive from another shell.
#
# Run it by hand against the venv built in 04-run.sh (no sudo: reading the
# neighbour cache is unprivileged and the first user is already in the i2c
# group). It deliberately is NOT a boot service — that would permanently claim
# the OLED and fight the oled-test smoke scripts over the one I2C panel:
#   /opt/little-internet/venv/bin/python3 ~/arp-oled/arp_oled.py
#
# Staged into files/arp-oled by build.sh from tools/arp-oled (source of truth);
# copy on the host, then fix ownership in the chroot where ${FIRST_USER_NAME}
# resolves to its uid/gid (mirrors 05-run.sh).
install -d -m 755 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/arp-oled"
install -m 755 files/arp-oled/arp_oled.py \
	"${ROOTFS_DIR}/home/${FIRST_USER_NAME}/arp-oled/"

on_chroot << EOF
chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}/arp-oled
EOF
