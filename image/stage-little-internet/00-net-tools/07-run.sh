#!/bin/bash -e

# Install the boot-time OLED status display: hostname in the yellow strip,
# eth0's MAC and each interface's IPv4 in the blue body, painted from boot so
# a rack of identical Pis is tellable-apart at a glance. Runs as a systemd
# service (little-internet-oled.service) against the venv built in 04-run.sh.
#
# The script lives in /opt/little-internet (not the user's home) because a
# root service shouldn't execute user-editable files. The on-demand scripts
# installed by 05-/06-run.sh share the panel with it through the claim file
# described in the service unit.
#
# Staged into files/status-oled by build.sh from tools/status-oled (source of
# truth).
install -d -m 755 "${ROOTFS_DIR}/opt/little-internet/status-oled"
install -m 755 files/status-oled/status_oled.py \
	"${ROOTFS_DIR}/opt/little-internet/status-oled/"

install -m 644 files/little-internet-oled.service \
	"${ROOTFS_DIR}/etc/systemd/system/little-internet-oled.service"

on_chroot << 'EOF'
systemctl enable little-internet-oled.service
EOF
