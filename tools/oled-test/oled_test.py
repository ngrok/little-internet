#!/usr/bin/env python3
"""Minimal smoke test for the SSD1306 128x64 OLED over 4-wire SPI.

Draws a border and "OLED OK" so you can confirm the display and wiring work.

    ls /dev/spidev*          # confirm SPI is enabled (expect spidev0.0)
    python3 oled_test.py     # uses CE0 + DC=GPIO24, RST=GPIO25 (luma defaults)
    python3 oled_test.py --device 1 --hold 8
"""
import argparse
import sys
import time

from luma.core.interface.serial import spi
from luma.core.render import canvas
from luma.oled.device import ssd1306


def main():
    p = argparse.ArgumentParser(description="Smoke test an SPI SSD1306 OLED.")
    p.add_argument("--port", type=int, default=0, help="SPI bus (default 0)")
    p.add_argument("--device", type=int, default=0,
                   help="SPI chip-select: 0=CE0 (pin 24), 1=CE1 (pin 26). Default 0.")
    p.add_argument("--dc", type=int, default=24, help="DC GPIO (default 24 / pin 18)")
    p.add_argument("--rst", type=int, default=25, help="RST GPIO (default 25 / pin 22)")
    p.add_argument("--hold", type=float, default=5.0,
                   help="seconds to leave the pattern on screen (default 5)")
    args = p.parse_args()

    try:
        serial = spi(port=args.port, device=args.device,
                     gpio_DC=args.dc, gpio_RST=args.rst)
        device = ssd1306(serial, width=128, height=64)
    except Exception as e:
        print(f"Could not open the display: {e}")
        print("Check `ls /dev/spidev*`, wiring, and that SPI is enabled.")
        sys.exit(1)

    with canvas(device) as draw:
        draw.rectangle(device.bounding_box, outline="white")
        draw.text((6, 8), "OLED OK", fill="white")
        draw.text((6, 26), f"SPI {args.port}.{args.device}", fill="white")
        draw.text((6, 44), f"{device.width}x{device.height}", fill="white")
    print(f"Drew test pattern on SPI {args.port}.{args.device}. "
          f"Holding {args.hold}s...")
    time.sleep(args.hold)
    print("Done.")


if __name__ == "__main__":
    main()
