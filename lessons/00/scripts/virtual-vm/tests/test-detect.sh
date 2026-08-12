#!/usr/bin/env bash
# Unit tests for the host-OS detection in common.sh: the accelerator, CPU model,
# and guest arch it picks per platform. Runs common.sh against a fake `uname` and
# fake QEMU binaries on PATH, so no real VM (or KVM/HVF) is needed. Covers the
# cross-platform branching only; the ISO-tool and browser-open fallbacks are plain
# `command -v` chains and are not unit-tested here.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
COMMON="$(dirname "$HERE")/common.sh"

# Scratch tree: fake uname + qemu binaries in bin/, a fake EDK2 firmware in
# share/qemu/ (where common.sh looks for the arm64 case). Removed on exit.
FAKE="$(mktemp -d)"
trap 'rm -rf "$FAKE"' EXIT
mkdir -p "$FAKE/bin" "$FAKE/share/qemu"
cat > "$FAKE/bin/uname" <<'SH'
#!/bin/sh
case "$1" in
  -s) echo "${FAKE_UNAME_S:-Darwin}" ;;
  -m) echo "${FAKE_UNAME_M:-x86_64}" ;;
  *)  echo Fake ;;
esac
SH
for q in qemu-system-x86_64 qemu-system-aarch64 qemu-img; do
  printf '#!/bin/sh\nexit 0\n' > "$FAKE/bin/$q"
done
chmod +x "$FAKE/bin/"*
: > "$FAKE/share/qemu/edk2-aarch64-code.fd"

KVM_YES="$FAKE/kvm-present"; : > "$KVM_YES"   # writable file -> KVM available
KVM_NO="$FAKE/kvm-absent"                      # does not exist -> no KVM

# detect UNAME_S UNAME_M KVM_DEV -> prints "ACCEL CPU GUEST_ARCH"
detect() {
  env -i HOME="$HOME" PATH="$FAKE/bin:/usr/bin:/bin" \
    FAKE_UNAME_S="$1" FAKE_UNAME_M="$2" KVM_DEV="$3" \
    bash -c 'source "'"$COMMON"'" >/dev/null 2>&1; echo "$ACCEL $CPU $GUEST_ARCH"'
}

pass=0; fail=0
check() { # description expected actual
  if [ "$2" = "$3" ]; then echo "PASS  $1"; pass=$((pass + 1))
  else echo "FAIL  $1 (expected [$2], got [$3])"; fail=$((fail + 1)); fi
}

check "macOS amd64 -> hvf/host"          "hvf host amd64"  "$(detect Darwin x86_64  "$KVM_NO")"
check "Linux amd64 with KVM -> kvm/host" "kvm host amd64"  "$(detect Linux  x86_64  "$KVM_YES")"
check "Linux amd64 no KVM -> tcg/max"    "tcg max amd64"   "$(detect Linux  x86_64  "$KVM_NO")"
check "Linux arm64 with KVM -> kvm/arm64" "kvm host arm64" "$(detect Linux  aarch64 "$KVM_YES")"

# A native Windows shell (Git Bash / MSYS) must refuse and point at WSL2.
env -i HOME="$HOME" PATH="$FAKE/bin:/usr/bin:/bin" \
  FAKE_UNAME_S="MINGW64_NT-10.0" FAKE_UNAME_M="x86_64" KVM_DEV="$KVM_NO" \
  bash -c 'source "'"$COMMON"'"' >/dev/null 2>&1
if [ "$?" -ne 0 ]; then echo "PASS  native Windows shell refused (use WSL2)"; pass=$((pass + 1))
else echo "FAIL  native Windows shell was not refused"; fail=$((fail + 1)); fi

echo "----"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
