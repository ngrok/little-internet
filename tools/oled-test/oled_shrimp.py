#!/usr/bin/env python3
"""Show the Phosphor 'shrimp' icon on the SSD1306 128x64 OLED over I2C.

The icon is embedded as a 64x64 1-bit bitmap (rendered from the Phosphor
regular 'shrimp' SVG, https://phosphoricons.com/?q=shrimp), so this script
needs no network access or SVG libraries on the Pi.

    python3 oled_shrimp.py                 # bus 1, address 0x3C (the common case)
    python3 oled_shrimp.py --address 0x3D  # some modules strap to 0x3D
    python3 oled_shrimp.py --controller sh1106
"""
import argparse
import base64
import sys
import time

from PIL import Image

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106, ssd1306

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
    p = argparse.ArgumentParser(description="Show the Phosphor shrimp on an I2C OLED.")
    p.add_argument("--port", type=int, default=1,
                   help="I2C bus (default 1 / /dev/i2c-1)")
    p.add_argument("--address", type=lambda x: int(x, 0), default=0x3C,
                   help="I2C address (default 0x3C; some modules use 0x3D)")
    p.add_argument("--controller", choices=("ssd1306", "sh1106"), default="ssd1306",
                   help="display controller (default ssd1306; try sh1106 if garbled)")
    p.add_argument("--hold", type=float, default=10.0,
                   help="seconds to leave the icon on screen (default 10)")
    args = p.parse_args()

    try:
        serial = i2c(port=args.port, address=args.address)
        controller = sh1106 if args.controller == "sh1106" else ssd1306
        device = controller(serial, width=128, height=64)
    except Exception as e:
        print(f"Could not open the display: {e}")
        print(f"Check `i2cdetect -y {args.port}` for the address, the wiring, "
              "and that I2C is enabled.")
        sys.exit(1)

    icon = shrimp_image()
    frame = Image.new("1", (device.width, device.height))
    x = (device.width - icon.width) // 2
    y = (device.height - icon.height) // 2
    frame.paste(icon, (x, y))
    device.display(frame)
    print(f"Shrimp on I2C {args.port} @ {hex(args.address)}. "
          f"Holding {args.hold}s... 🦐")
    time.sleep(args.hold)
    print("Done.")


if __name__ == "__main__":
    main()
