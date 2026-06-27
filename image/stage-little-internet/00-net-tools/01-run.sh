#!/bin/bash -e

# Enable the SPI bus so the SSD1306 OLED displays from the Phase 1 BOM work
# out of the box. The Phase 1 OLEDs are 4-wire SPI (not I2C), so they show up
# at /dev/spidev0.0 and /dev/spidev0.1 rather than on the I2C bus.
# (raspi-config's "do_spi 0" means *enable*.)
on_chroot << 'EOF'
raspi-config nonint do_spi 0
EOF
