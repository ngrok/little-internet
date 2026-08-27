#!/usr/bin/env python3
"""Paint this node's identity — hostname, MAC, IPv4 — on the OLED.

This is the boot-time resident of the panel: little-internet-oled.service
starts it at boot so a powered node permanently shows who it is. The yellow
strip gets the hostname; the blue body gets eth0's MAC (the node's layer-2
identity in the lessons) and the current IPv4 address of each interface —
eth0 (the lab wire) and wlan0 (your SSH path). Everything refreshes once a
second, so a DHCP lease landing or a cable pull shows up as it happens.

On-demand scripts (~/arp-oled, ~/oled-test) borrow the panel by dropping a
claim file at /run/little-internet/oled.claim; while it exists this display
paints nothing, and when the script exits and removes it, this one resumes.

Run it by hand the same way the service does:

    /opt/little-internet/venv/bin/python3 status_oled.py
    status_oled.py --address 0x3d --controller sh1106
    status_oled.py --interfaces eth0        # lab wire only
"""
import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time

from PIL import Image, ImageDraw, ImageFont

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106, ssd1306

# On-demand OLED scripts create this to pause us; see the module docstring.
# The directory is the service's RuntimeDirectory (root:i2c, 0775), so the
# unprivileged lab user can create and remove the file.
CLAIM_FILE = "/run/little-internet/oled.claim"

# The Phase 1 BOM panel is a dual-colour 0.96" SSD1306: its top 16 pixel rows
# emit yellow and the bottom 48 emit blue — fixed in the glass, not settable in
# software. Yellow band: the hostname. Blue body: MAC + one IPv4 line per
# interface. Set to 0 for a single-colour panel.
YELLOW_H = 16

# Monospace TrueType, in preference order: JetBrains Mono (ngrok's mono, from
# fonts-jetbrains-mono on the image), then DejaVu Sans Mono as a fallback on
# stock systems. Bold first — heavier strokes survive 1-bit rendering better.
# Without any of these we fall back to PIL's bitmap font.
FONTS = (
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf",
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Regular.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
)
# The body font is sized once against the widest line we might render, so the
# layout doesn't jump when an address arrives (a fixed-width font keeps the
# columns steady too).
WIDEST_BODY = "wlan0 255.255.255.255"


def fit_font(sample, max_w, max_h, path=None):
    """Largest monospace TTF at which `sample` fits, or None for the bitmap font."""
    for fp in ([path] if path else FONTS):
        if not fp or not os.path.exists(fp):
            continue
        for s in range(max_h * 2, 6, -1):
            font = ImageFont.truetype(fp, s)
            b = font.getbbox(sample)
            if b[2] - b[0] <= max_w and b[3] - b[1] <= max_h:
                return font
    return None


def claim_active(path):
    """True while a live process holds the claim; clean up a stale one.

    The claim file holds its writer's PID. A claim whose writer is gone (the
    script was SIGKILLed or crashed before its cleanup ran) would pause this
    display forever, so treat it as released and remove it.
    """
    try:
        with open(path) as fh:
            pid = int(fh.read().strip() or "0")
    except FileNotFoundError:
        return False
    except (OSError, ValueError):
        pid = 0
    if pid > 0 and os.path.exists(f"/proc/{pid}"):
        return True
    try:
        os.remove(path)
    except OSError:
        pass
    return False


def interfaces():
    """Map ifname -> (mac, first IPv4 or None, operstate) from `ip -json addr`."""
    try:
        out = subprocess.run(
            ["ip", "-json", "addr"],
            capture_output=True, text=True, check=True,
        ).stdout
        table = {}
        for iface in json.loads(out):
            ips = [ai["local"] for ai in iface.get("addr_info", [])
                   if ai.get("family") == "inet" and "local" in ai]
            table[iface.get("ifname")] = (
                iface.get("address"),
                ips[0] if ips else None,
                iface.get("operstate", ""),
            )
        return table
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
        return {}


def body_lines(ifnames):
    """The blue-body text: the first interface's MAC, then one IPv4 line each.

    An interface with no address distinguishes "no cable" (down) from "no
    lease yet" (no IPv4) — the difference lesson 01 is built on.
    """
    table = interfaces()
    mac = (table.get(ifnames[0]) or (None,))[0]
    lines = [mac or f"(no {ifnames[0]})"]
    for name in ifnames:
        entry = table.get(name)
        if entry is None:
            lines.append(f"{name} (missing)")
        elif entry[1]:
            lines.append(f"{name} {entry[1]}")
        elif entry[2] == "DOWN":
            lines.append(f"{name} (down)")
        else:
            lines.append(f"{name} (no IPv4)")
    return lines


def render(device, hostname, lines, beat, head_font, body_font):
    """Draw one frame across the panel's two colour bands (see YELLOW_H).

    Yellow strip: the hostname, plus a heartbeat so a steady screen still
    reads as "running". Blue body: the MAC/IPv4 lines, one per row slot.
    """
    small = ImageFont.load_default()
    frame = Image.new("1", (device.width, device.height))
    draw = ImageDraw.Draw(frame)
    draw.fontmode = "1"  # no antialiasing — crisp edges on a 1-bit panel

    font = head_font or small
    b = font.getbbox(hostname)
    draw.text((2 - b[0], (YELLOW_H - (b[3] - b[1])) // 2 - b[1]),
              hostname, fill=1, font=font)
    if beat:
        draw.rectangle((device.width - 3, 1, device.width - 1, 3), fill=1)

    pitch = (device.height - YELLOW_H) // len(lines)
    font = body_font or small
    for i, line in enumerate(lines):
        b = font.getbbox(line)
        y = YELLOW_H + i * pitch + (pitch - (b[3] - b[1])) // 2 - b[1]
        draw.text((2 - b[0], y), line, fill=1, font=font)

    device.display(frame)


def open_display(args, tries=5, delay=2.0):
    """Open the panel, retrying briefly — at boot the I2C bus can lag us."""
    for attempt in range(tries):
        try:
            serial = i2c(port=args.port, address=args.address)
            controller = sh1106 if args.controller == "sh1106" else ssd1306
            return controller(serial, width=128, height=64)
        except Exception as e:
            if attempt + 1 < tries:
                time.sleep(delay)
                continue
            print(f"Could not open the display: {e}")
            print(f"Check `i2cdetect -y {args.port}` for the address, the "
                  "wiring, and that I2C is enabled.")
    return None


def main():
    p = argparse.ArgumentParser(
        description="Show this node's hostname, MAC, and IPv4 on the OLED.")
    p.add_argument("--interfaces", nargs="+", default=["eth0", "wlan0"],
                   help="interfaces to show, one IPv4 line each; the first "
                        "one's MAC is shown too (default: eth0 wlan0)")
    p.add_argument("--interval", type=float, default=1.0,
                   help="seconds between refreshes (default 1.0)")
    p.add_argument("--port", type=int, default=1,
                   help="I2C bus (default 1 / /dev/i2c-1)")
    p.add_argument("--address", type=lambda x: int(x, 0), default=0x3C,
                   help="I2C address (default 0x3C; some modules use 0x3D)")
    p.add_argument("--controller", choices=("ssd1306", "sh1106"), default="ssd1306",
                   help="display controller (default ssd1306; try sh1106 if garbled)")
    p.add_argument("--font", default=None,
                   help="path to a .ttf (default: JetBrains Mono, then DejaVu "
                        "Sans Mono, else the bitmap font)")
    p.add_argument("--claim-file", default=CLAIM_FILE,
                   help="pause while this file exists (default %(default)s)")
    args = p.parse_args()

    device = open_display(args)
    if device is None:
        # A node without a panel is fine — exit 0 so the service goes quietly
        # inactive instead of restart-looping against an empty bus.
        sys.exit(0)

    body_h = (device.height - YELLOW_H) // (len(args.interfaces) + 1)
    head_font = fit_font(socket.gethostname(), device.width - 4, YELLOW_H - 3,
                         args.font)
    body_font = fit_font(WIDEST_BODY, device.width - 4, body_h - 2, args.font)

    # systemd stops us with SIGTERM; turn it into a clean exit so the finally
    # below blanks the panel instead of leaving a ghost frame.
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    print(f"Showing status for {', '.join(args.interfaces)} "
          f"(refresh {args.interval}s). Ctrl-C to stop.")
    beat = False
    paused = False
    try:
        while True:
            # An on-demand script holds the panel while the claim file exists;
            # paint nothing and keep checking until it's released.
            if claim_active(args.claim_file):
                paused = True
            else:
                if paused:
                    # The departing script's luma atexit cleanup switched the
                    # panel OFF (hide), not just blank; wake it or every frame
                    # we paint lands on dark glass.
                    device.show()
                    paused = False
                render(device, socket.gethostname(),
                       body_lines(args.interfaces), beat, head_font, body_font)
                beat = not beat
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nDone.")
    finally:
        device.clear()


if __name__ == "__main__":
    main()
