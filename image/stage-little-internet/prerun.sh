#!/bin/bash -e

# Standard pi-gen stage prerun: seed this stage's rootfs from the previous
# stage's output if it hasn't been copied yet.
if [ ! -d "${ROOTFS_DIR}" ]; then
	copy_previous
fi
