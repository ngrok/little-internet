#!/usr/bin/env python3
"""Show the Phosphor 'shrimp' icon on the SSD1306 128x64 OLED over 4-wire SPI.

The icon is embedded as a 64x64 1-bit bitmap (rendered from the Phosphor
regular 'shrimp' SVG, https://phosphoricons.com/?q=shrimp), so this script
needs no network access or SVG libraries on the Pi.

    python3 oled_shrimp.py                # uses CE0 + DC=GPIO24, RST=GPIO25
    python3 oled_shrimp.py --device 1
"""
import argparse
import base64
import sys
import time

from PIL import Image

from luma.core.interface.serial import spi
from luma.oled.device import ssd1306

# 64x64, 1-bit, MSB-first packed (PIL mode "1"). Phosphor "shrimp" (regular).
SHRIMP_64_B64 = (
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAADwAAAAAAAAAPA"
    "AAAAAAAAA+AAAAAAAAAB////8AAAAAH////4AAAAAP////wAAAAAP////gAAAAAAAAAfAA"
    "AAAAAAAA8AAAAAAAAADwAAAAAAAAAPAAAAAAAAAA8AAAAAAAAAHwAAAP/////+AAAP////"
    "//wAAD//////+AAAf//////wAAH/A8AAAPAAA/gDwAAA8AAH4APAAAHgAA/AA8AAAeAAD4"
    "ADweAB4AAfAAPD8APgAD4AA8PwA8AAPAADw/AHwAB8AAPD8A+AAHwAA8HgHwAAfwADwAA/"
    "AAD/wAPAAH4AAP/wA8AB/AAA9/4DwA/4AADx/4f//+AAAPB/7///wAAA8B////8AAADwA/"
    "//8AAAAPAA/AAAAAAA8AB4AAAAAAB4AHgAAAAAAHgAeAAAAAAAeAH4AAAAAAB8A/wAAAAA"
    "ADwH///+AAAAPh////8AAAAfP4///wAAAA/+B//+AAAAD/wDwAAAAAAH+APAAAAAAAP4A8"
    "AAAAAAAf8DwAAAAAAAf///4AAAAAA////wAAAAAA////AAAAAAAP//4AAAAAAAAAAAAAAA"
    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
)


def shrimp_image():
    raw = base64.b64decode(SHRIMP_64_B64)
    return Image.frombytes("1", (64, 64), raw)


def main():
    p = argparse.ArgumentParser(description="Show the Phosphor shrimp on an SPI OLED.")
    p.add_argument("--port", type=int, default=0, help="SPI bus (default 0)")
    p.add_argument("--device", type=int, default=0,
                   help="SPI chip-select: 0=CE0 (pin 24), 1=CE1 (pin 26). Default 0.")
    p.add_argument("--dc", type=int, default=24, help="DC GPIO (default 24 / pin 18)")
    p.add_argument("--rst", type=int, default=25, help="RST GPIO (default 25 / pin 22)")
    p.add_argument("--hold", type=float, default=10.0,
                   help="seconds to leave the icon on screen (default 10)")
    args = p.parse_args()

    try:
        serial = spi(port=args.port, device=args.device,
                     gpio_DC=args.dc, gpio_RST=args.rst)
        device = ssd1306(serial, width=128, height=64)
    except Exception as e:
        print(f"Could not open the display: {e}")
        print("Check `ls /dev/spidev*`, wiring, and that SPI is enabled.")
        sys.exit(1)

    icon = shrimp_image()
    frame = Image.new("1", (device.width, device.height))
    x = (device.width - icon.width) // 2
    y = (device.height - icon.height) // 2
    frame.paste(icon, (x, y))
    device.display(frame)
    print(f"Shrimp on SPI {args.port}.{args.device}. Holding {args.hold}s... 🦐")
    time.sleep(args.hold)
    print("Done.")


if __name__ == "__main__":
    main()
