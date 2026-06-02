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
# pi-gen ties each Debian release to its own branch, and the branch must match
# the RELEASE set in ./config or pi-gen warns and may break on packages. We
# default to bookworm-arm64 (64-bit Bookworm) to match config's RELEASE=bookworm
# and to build natively/fast on Apple Silicon. Other useful branches:
#   bookworm-arm64  64-bit Bookworm (default)   bookworm  32-bit Bookworm
#   arm64           64-bit Trixie (newest)      master    32-bit Trixie (newest)
# If you switch to a *-arm64/master/arm64 branch, set RELEASE in ./config to match.
#
# Env overrides:
#   PIGEN_REF   pi-gen branch/tag to build from (default: bookworm-arm64)

set -euo pipefail

PIGEN_REPO="https://github.com/RPi-Distro/pi-gen.git"
PIGEN_REF="${PIGEN_REF:-bookworm-arm64}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${HERE}/build"
PIGEN_DIR="${WORK}/pi-gen"
STAGE_NAME="stage-little-internet"

mkdir -p "${WORK}"

# 1. Fetch pi-gen (shallow clone of the requested ref). If an existing checkout
#    is on a different branch (e.g. from an earlier run), re-clone it.
if [ -d "${PIGEN_DIR}/.git" ]; then
	current_ref="$(git -C "${PIGEN_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
	if [ "${current_ref}" != "${PIGEN_REF}" ]; then
		echo ">> Existing pi-gen checkout is on '${current_ref}', want '${PIGEN_REF}' — re-cloning"
		rm -rf "${PIGEN_DIR}"
	fi
fi
if [ ! -d "${PIGEN_DIR}/.git" ]; then
	echo ">> Cloning pi-gen (${PIGEN_REF}) into ${PIGEN_DIR}"
	git clone --depth 1 --branch "${PIGEN_REF}" "${PIGEN_REPO}" "${PIGEN_DIR}"
else
	echo ">> Reusing existing pi-gen checkout at ${PIGEN_DIR} (${PIGEN_REF})"
fi

# 2. Drop our config into the pi-gen tree.
cp "${HERE}/config" "${PIGEN_DIR}/config"

# 3. Sync our custom stage into the pi-gen tree.
rm -rf "${PIGEN_DIR:?}/${STAGE_NAME}"
cp -R "${HERE}/${STAGE_NAME}" "${PIGEN_DIR}/${STAGE_NAME}"

# 4. Only export our final image, not the intermediate Lite image.
touch "${PIGEN_DIR}/stage2/SKIP_IMAGES"

# 5. Ensure debian-archive-keyring lands in the bootstrapped chroot. pi-gen
#    debootstraps with only --include gnupg,ca-certificates, and on current
#    Debian the archive keyring no longer comes in by default — so the chroot
#    can't verify deb.debian.org and stage0's apt-get update dies with
#    "NO_PUBKEY ... bookworm" / "repository ... is not signed". (debootstrap
#    itself is verified by the host keyring, so it can still fetch it.)
if grep -q -- '--include=ca-certificates)' "${PIGEN_DIR}/scripts/common"; then
	echo ">> Patching pi-gen to include debian-archive-keyring in the bootstrap"
	sed -i 's/--include=ca-certificates)/--include=ca-certificates,debian-archive-keyring)/' \
		"${PIGEN_DIR}/scripts/common"
fi

# 6. Build.
cd "${PIGEN_DIR}"
if [ "${USE_DOCKER:-0}" = "1" ]; then
	echo ">> Building with pi-gen's Docker wrapper"
	./build-docker.sh
else
	echo ">> Building natively (requires a Debian-based host)"
	sudo ./build.sh
fi

echo ">> Done. Images are in ${PIGEN_DIR}/deploy/"
