#!/usr/bin/env bash
#
# Build the little-internet Raspberry Pi OS image with pi-gen.
#
# pi-gen runs on a Debian-based Linux host (Bookworm recommended) or via its
# Docker wrapper. It does NOT run natively on macOS — see image/README.md for
# the recommended build environments.
#
# Usage:
#   ./build.sh              # native build (Debian host); uses sudo
#   USE_DOCKER=1 ./build.sh # build via pi-gen's Docker wrapper
#
# Env overrides:
#   PIGEN_REF   pi-gen branch/tag to build from (default: master)

set -euo pipefail

PIGEN_REPO="https://github.com/RPi-Distro/pi-gen.git"
PIGEN_REF="${PIGEN_REF:-master}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${HERE}/build"
PIGEN_DIR="${WORK}/pi-gen"
STAGE_NAME="stage-little-internet"

mkdir -p "${WORK}"

# 1. Fetch pi-gen (shallow clone of the requested ref).
if [ ! -d "${PIGEN_DIR}/.git" ]; then
	echo ">> Cloning pi-gen (${PIGEN_REF}) into ${PIGEN_DIR}"
	git clone --depth 1 --branch "${PIGEN_REF}" "${PIGEN_REPO}" "${PIGEN_DIR}"
else
	echo ">> Reusing existing pi-gen checkout at ${PIGEN_DIR}"
fi

# 2. Drop our config into the pi-gen tree.
cp "${HERE}/config" "${PIGEN_DIR}/config"

# 3. Sync our custom stage into the pi-gen tree.
rm -rf "${PIGEN_DIR:?}/${STAGE_NAME}"
cp -R "${HERE}/${STAGE_NAME}" "${PIGEN_DIR}/${STAGE_NAME}"

# 4. Only export our final image, not the intermediate Lite image.
touch "${PIGEN_DIR}/stage2/SKIP_IMAGES"

# 5. Build.
cd "${PIGEN_DIR}"
if [ "${USE_DOCKER:-0}" = "1" ]; then
	echo ">> Building with pi-gen's Docker wrapper"
	./build-docker.sh
else
	echo ">> Building natively (requires a Debian-based host)"
	sudo ./build.sh
fi

echo ">> Done. Images are in ${PIGEN_DIR}/deploy/"
