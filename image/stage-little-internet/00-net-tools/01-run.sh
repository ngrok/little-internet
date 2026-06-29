#!/bin/bash -e

# Enable the I2C bus so the 4-pin SSD1306 OLED displays from the Phase 1 BOM
# work out of the box. They show up on /dev/i2c-1 (usually at address 0x3c).
# (raspi-config's "do_i2c 0" means *enable*.)
on_chroot << 'EOF'
raspi-config nonint do_i2c 0
EOF

# Let the default user reach the I2C bus without sudo. Use an *unquoted*
# heredoc so ${FIRST_USER_NAME} expands on the host before running in the chroot.
on_chroot << EOF
adduser ${FIRST_USER_NAME} i2c
EOF
