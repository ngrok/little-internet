#!/bin/bash -e

# Enable the I2C bus so the SSD1306 OLED displays from the Phase 1 BOM work
# out of the box. (raspi-config's "do_i2c 0" means *enable*.)
on_chroot << 'EOF'
raspi-config nonint do_i2c 0
EOF
