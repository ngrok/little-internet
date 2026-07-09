#!/bin/bash -e

# Install the OLED test scripts into the first user's home so they can be run
# straight off a freshly flashed card, against the venv built in 04-run.sh:
#   /opt/little-internet/venv/bin/python3 ~/oled-test/oled_test.py
#   /opt/little-internet/venv/bin/python3 ~/oled-test/oled_shrimp.py
#
# The scripts are staged into files/oled-test by build.sh from tools/oled-test
# (the single source of truth). Copy them in on the host, then fix ownership
# inside the chroot where ${FIRST_USER_NAME} resolves to its uid/gid.
install -d -m 755 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/oled-test"
install -m 755 files/oled-test/oled_test.py files/oled-test/oled_shrimp.py \
	"${ROOTFS_DIR}/home/${FIRST_USER_NAME}/oled-test/"

on_chroot << EOF
chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}/oled-test
EOF
