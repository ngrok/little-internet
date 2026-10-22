#!/bin/bash -e

# Refresh the trust store even when earlier pi-gen stages were cached. Refuse
# to publish a Bookworm image without the certificate fix shipped in v0.6.1.
on_chroot <<'EOF'
set -eu
apt-get update
apt-get install -y --only-upgrade ca-certificates
version="$(dpkg-query -W -f='${Version}' ca-certificates)"
echo "Installed ca-certificates: ${version}"
if ! dpkg --compare-versions "$version" ge '20250419~deb12u2'; then
    echo "ca-certificates must be 20250419~deb12u2 or later" >&2
    exit 1
fi
EOF
