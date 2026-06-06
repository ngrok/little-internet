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
#   PIGEN_REF      pi-gen branch/tag to build from (default: bookworm-arm64)
#   LI_BUILD_DIR   where pi-gen's checkout + build artifacts go (default:
#                  ./build). pi-gen loop-mounts the image during the build, so
#                  this MUST be a real local, writable filesystem. When running
#                  the repo straight from a read-only host mount (e.g. Lima on
#                  macOS), point this at writable local storage in the VM, e.g.
#                  LI_BUILD_DIR=~/pigen-build ./build.sh

set -euo pipefail

PIGEN_REPO="https://github.com/RPi-Distro/pi-gen.git"
PIGEN_REF="${PIGEN_REF:-bookworm-arm64}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${LI_BUILD_DIR:-${HERE}/build}"
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

# 2. Drop our config into the pi-gen tree, plus any untracked local overrides
#    (e.g. Wi-Fi credentials in image/config.local — see config.local.example).
cp "${HERE}/config" "${PIGEN_DIR}/config"
if [ -f "${HERE}/config.local" ]; then
	echo ">> Applying image/config.local overrides"
	cat "${HERE}/config.local" >> "${PIGEN_DIR}/config"
	# shellcheck disable=SC1091
	. "${HERE}/config.local"
fi

# 2c. Stamp the image filename with a version label instead of pi-gen's build
#     date, so a flashed card is traceable to an exact build. Prefer an explicit
#     override (LI_IMG_VERSION); otherwise derive it from git — a clean tag like
#     'v0.3.1' on a release build, or '<tag>-<n>-g<sha>' / a bare short SHA in
#     between (CI fetches tags via fetch-depth: 0 so release builds resolve to
#     the tag). The version takes the date's slot (prefix), so the name stays
#     '<version>-little-internet' — matching the *-little-internet.img.xz globs
#     in the flashing docs. We also override ARCHIVE_FILENAME to drop pi-gen's
#     redundant 'image_' prefix on the compressed output. Only the version
#     literal expands here; \${IMG_NAME} is left for pi-gen to expand when it
#     sources config (it's set above), and pi-gen defaults these only when
#     unset, so ours win. Result, e.g.: v0.3.1-little-internet.img.xz
version="${LI_IMG_VERSION:-}"
if [ -z "${version}" ]; then
	version="$(git -C "${HERE}" describe --tags --always --dirty 2>/dev/null || true)"
fi
version="${version:-unknown}"
echo ">> Labeling image as version '${version}'"
{
	echo ""
	echo "# Version label written by build.sh — replaces pi-gen's date stamp."
	echo "IMG_FILENAME=\"${version}-\${IMG_NAME}\""
	echo "ARCHIVE_FILENAME=\"${version}-\${IMG_NAME}\""
} >> "${PIGEN_DIR}/config"

# 3. Sync our custom stage into the pi-gen tree.
rm -rf "${PIGEN_DIR:?}/${STAGE_NAME}"
cp -R "${HERE}/${STAGE_NAME}" "${PIGEN_DIR}/${STAGE_NAME}"

# 3a. Guard against a silent footgun: pi-gen runs a sub-stage's *-run.sh only if
#     it's executable, and SKIPS it without error otherwise — the build stays
#     green while the script's work never happens. That's exactly how the
#     wlan0-isolation stage shipped empty in v0.3.0 (its 00-run.sh had lost its
#     +x bit). Fail loud here instead. `-perm -100` (owner-execute) is portable
#     across GNU/BSD find.
non_exec="$(find "${PIGEN_DIR}/${STAGE_NAME}" -name '*-run.sh' ! -perm -100 -print)"
if [ -n "${non_exec}" ]; then
	echo "!! Stage run scripts are missing their executable bit — pi-gen would" >&2
	echo "!! silently skip these, shipping a stage that does nothing:" >&2
	echo "${non_exec}" >&2
	echo "!! Fix with: chmod +x <file> (and 'git update-index --chmod=+x')." >&2
	exit 1
fi

# 3b. Optionally pre-provision Wi-Fi so nodes are reachable headless over Wi-Fi
#     on first boot. Credentials come only from image/config.local (never
#     committed); without LI_WIFI_SSID set, no Wi-Fi is baked in. The radio is
#     unblocked by WPA_COUNTRY in ./config.
if [ -n "${LI_WIFI_SSID:-}" ]; then
	echo ">> Baking in Wi-Fi connection for SSID '${LI_WIFI_SSID}'"
	wifi_files="${PIGEN_DIR}/${STAGE_NAME}/00-net-tools/files"
	mkdir -p "${wifi_files}"
	cat > "${wifi_files}/preconfigured.nmconnection" <<EOF
[connection]
id=preconfigured
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=${LI_WIFI_SSID}

[wifi-security]
key-mgmt=wpa-psk
psk=${LI_WIFI_PSK}

[ipv4]
method=auto

[ipv6]
method=auto
EOF
fi

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
