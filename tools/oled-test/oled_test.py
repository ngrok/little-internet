#!/usr/bin/env python3
"""Minimal smoke test for the SSD1306 128x64 OLED over I2C.

Draws a border and "OLED OK" so you can confirm the display and wiring work.

    i2cdetect -y 1          # confirm the panel shows up (usually at 0x3c)
    python3 oled_test.py    # bus 1, address 0x3C
    python3 oled_test.py --address 0x3d --hold 8
"""
import argparse
import sys
import time

from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import sh1106, ssd1306


def main():
    p = argparse.ArgumentParser(description="Smoke test an I2C SSD1306 OLED.")
    p.add_argument("--port", type=int, default=1,
                   help="I2C bus (default 1 / /dev/i2c-1)")
    p.add_argument("--address", type=lambda x: int(x, 0), default=0x3C,
                   help="I2C address (default 0x3C; some modules use 0x3D)")
    p.add_argument("--controller", choices=("ssd1306", "sh1106"), default="ssd1306",
                   help="display controller (default ssd1306; try sh1106 if garbled)")
    p.add_argument("--hold", type=float, default=5.0,
                   help="seconds to leave the pattern on screen (default 5)")
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

    with canvas(device) as draw:
        draw.rectangle(device.bounding_box, outline="white")
        draw.text((6, 8), "OLED OK", fill="white")
        draw.text((6, 26), f"I2C {args.port} @ {hex(args.address)}", fill="white")
        draw.text((6, 44), f"{device.width}x{device.height}", fill="white")
    print(f"Drew test pattern on I2C {args.port} @ {hex(args.address)}. "
          f"Holding {args.hold}s...")
    time.sleep(args.hold)
    print("Done.")


if __name__ == "__main__":
    main()
