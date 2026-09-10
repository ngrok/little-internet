#!/bin/bash -e

# Staged by build.sh from tools/tsharkie, the single source of truth.
install -d -m 755 "${ROOTFS_DIR}/usr/local/bin"
install -m 755 files/tsharkie/tsharkie "${ROOTFS_DIR}/usr/local/bin/tsharkie"
