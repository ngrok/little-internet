#!/bin/bash -e

# Build a virtualenv with the OLED display library so the SSD1306 I2C panels in
# the Phase 1 BOM work out of the box. luma.oled isn't packaged in apt, so it's
# installed via pip; Pillow comes from apt (see 00-packages) and is exposed
# through --system-site-packages, so no compiler runs inside the image. For I2C
# luma pulls in the pure-python smbus2, so there's nothing else to build.
#
# The pip step needs network and is best-effort: if it fails the image still
# builds with I2C enabled and Pillow present, and luma can be added later with
# `sudo /opt/little-internet/venv/bin/pip install luma.oled`.
on_chroot << 'EOF'
python3 -m venv --system-site-packages /opt/little-internet/venv
/opt/little-internet/venv/bin/pip install --no-input luma.oled \
	|| echo "WARNING: luma.oled pip install failed; install it on-device later."
EOF
