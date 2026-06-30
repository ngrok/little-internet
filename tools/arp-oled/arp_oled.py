#!/usr/bin/env python3
"""Mirror the kernel ARP/neighbour state for the peer node onto the OLED.

This is a read-only window onto Linux's neighbour cache (the ARP table). It
polls `ip neigh` for one peer IP and paints that entry's NUD state on the
SSD1306 — REACHABLE, STALE, DELAY, PROBE, INCOMPLETE, FAILED, or ABSENT when
there's no entry at all. It never changes the cache; you drive the state
machine yourself from another shell and watch the panel follow along:

    curl http://10.10.0.2          # traffic to the peer: ABSENT/STALE -> REACHABLE
    ip neigh show 10.10.0.2        # the same thing this screen is reading
    sudo ip neigh del 10.10.0.2 dev eth0          # -> ABSENT
    sudo ip neigh replace 10.10.0.2 dev eth0 \
        lladdr <mac> nud stale                    # force it STALE
    # then leave it idle ~30s and REACHABLE decays to STALE on its own.

The peer defaults to the other half of the 10.10.0.1 <-> 10.10.0.2 lab pair
(auto-picked from this node's own address), or pass --peer.

    /opt/little-internet/venv/bin/python3 arp_oled.py
    arp_oled.py --peer 10.10.0.2 --interval 0.5
    arp_oled.py --address 0x3d --controller sh1106
    arp_oled.py --font /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf
"""
import argparse
import json
import os
import subprocess
import sys
import time

from PIL import Image, ImageDraw, ImageFont

from luma.core.interface.serial import i2c
from luma.oled.device import sh1106, ssd1306

# The Phase 1 lab pair. With no --peer we watch the *other* node, so the same
# image and service work unchanged on both cards.
PAIR = {"10.10.0.1": "10.10.0.2", "10.10.0.2": "10.10.0.1"}
DEFAULT_PEER = "10.10.0.2"

# NUD states worth a one-glance read. Anything else is shown verbatim.
KNOWN_STATES = {
    "REACHABLE", "STALE", "DELAY", "PROBE",
    "INCOMPLETE", "FAILED", "NOARP", "PERMANENT", "NONE",
}

# The Phase 1 BOM panel is a dual-colour 0.96" SSD1306: its top 16 pixel rows
# emit yellow and the bottom 48 emit blue — fixed in the glass, not settable in
# software. So we treat it as two bands: a yellow header strip (the peer label)
# and the blue body (the live MAC line + big state). There's an unlit ~2px gap
# at the seam, so nothing is drawn across it. Set to 0 for a single-colour panel.
YELLOW_H = 16
# Top of the blue body's big-state area (a MAC line sits just above it).
BODY_TOP = YELLOW_H + 14

# Monospace TrueType for the state readout, in preference order: JetBrains Mono
# (ngrok's mono, from fonts-jetbrains-mono on the image), then DejaVu Sans Mono
# as a fallback on stock systems. Bold first — heavier strokes survive 1-bit
# rendering better. Without any of these we fall back to PIL's bitmap font.
STATE_FONTS = (
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf",
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Regular.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
)
# Longest state we render; the auto-fit sizes to this so every state shares one
# size (and a fixed-width font keeps them column-aligned too).
WIDEST_STATE = "INCOMPLETE"


def load_state_font(width, max_h, path=None, size=None):
    """Largest monospace TTF that fits the widest state, or None for fallback.

    Tries `path` (else the bundled DejaVu Sans Mono). With an explicit `size`,
    loads at that size verbatim; otherwise picks the biggest size at which
    WIDEST_STATE still fits the panel. Returns None when no usable TTF exists,
    so the caller drops back to PIL's scaled bitmap font.
    """
    for fp in ([path] if path else STATE_FONTS):
        if not fp or not os.path.exists(fp):
            continue
        if size:
            return ImageFont.truetype(fp, size)
        for s in range(max_h * 2, 6, -1):
            font = ImageFont.truetype(fp, s)
            b = font.getbbox(WIDEST_STATE)
            if b[2] - b[0] <= width - 4 and b[3] - b[1] <= max_h:
                return font
    return None


def local_ipv4s():
    """Set of this node's IPv4 addresses, for auto-picking the peer."""
    try:
        out = subprocess.run(
            ["ip", "-json", "-4", "addr"],
            capture_output=True, text=True, check=True,
        ).stdout
        return {
            ai["local"]
            for iface in json.loads(out)
            for ai in iface.get("addr_info", [])
            if ai.get("family") == "inet" and "local" in ai
        }
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
        return set()


def pick_peer():
    """Default peer: the other node in the pair, else DEFAULT_PEER."""
    for ip in local_ipv4s():
        if ip in PAIR:
            return PAIR[ip]
    return DEFAULT_PEER


def read_neighbour(peer):
    """Return (state, mac, dev) for `peer` from the kernel neighbour cache.

    state is "ABSENT" when the kernel holds no entry for the peer. mac/dev are
    None when the cache has no link-layer address yet (INCOMPLETE/FAILED).
    """
    try:
        out = subprocess.run(
            ["ip", "-json", "neigh", "show", peer],
            capture_output=True, text=True, check=True,
        ).stdout
        entries = json.loads(out or "[]")
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError):
        return "ERROR", None, None

    if not entries:
        return "ABSENT", None, None

    # Prefer an entry that actually has a link-layer address (a resolved one)
    # so a stray INCOMPLETE on another device doesn't mask the real state.
    entry = next((e for e in entries if e.get("lladdr")), entries[0])
    states = entry.get("state") or ["NONE"]
    return " ".join(states), entry.get("lladdr"), entry.get("dev")


def render(device, peer, state, mac, dev, beat, state_font=None):
    """Draw one frame across the panel's two colour bands (see YELLOW_H).

    Yellow strip: the peer label. Blue body: the live MAC/dev line and the
    state in big type. Nothing crosses the seam at YELLOW_H. The state is drawn
    in `state_font` (a monospace TTF) when one is available, otherwise PIL's
    bitmap font scaled 2x.
    """
    small = ImageFont.load_default()
    frame = Image.new("1", (device.width, device.height))
    draw = ImageDraw.Draw(frame)
    draw.fontmode = "1"  # no antialiasing — crisp edges on a 1-bit panel

    # Yellow band: who we're watching, plus a heartbeat so a steady screen
    # still reads as "running".
    draw.text((2, 2), f"PEER {peer}", fill=1, font=small)
    if beat:
        draw.rectangle((device.width - 3, 1, device.width - 1, 3), fill=1)

    # Blue band: live link-layer line, then the state centred in the body.
    draw.text((2, YELLOW_H + 2),
              f"{mac} {dev or ''}".rstrip() if mac else "(no MAC yet)",
              fill=1, font=small)

    avail = device.height - BODY_TOP
    if state_font is not None:
        # TrueType: draw at native size, centring the inked bbox.
        b = state_font.getbbox(state)
        w, h = b[2] - b[0], b[3] - b[1]
        x = max(0, (device.width - w) // 2) - b[0]
        y = BODY_TOP + (avail - h) // 2 - b[1]
        draw.text((x, y), state, fill=1, font=state_font)
    else:
        # Fallback: blow the bitmap font up 2x with nearest-neighbour. The
        # longest state (INCOMPLETE) is exactly 2x the panel width, so every
        # state lands at the same 2x — no odd-one-out sizing.
        bbox = small.getbbox(state)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        if tw and th:
            glyph = Image.new("1", (tw, th))
            ImageDraw.Draw(glyph).text((-bbox[0], -bbox[1]), state, fill=1, font=small)
            scale = 2 if tw * 2 <= device.width else 1
            glyph = glyph.resize((tw * scale, th * scale), Image.NEAREST)
            gx = max(0, (device.width - glyph.width) // 2)
            gy = BODY_TOP + (avail - glyph.height) // 2
            frame.paste(glyph, (gx, gy))

    device.display(frame)


def main():
    p = argparse.ArgumentParser(
        description="Mirror the kernel ARP state for the peer node on the OLED.")
    p.add_argument("--peer", default=None,
                   help="peer IP to watch (default: the other 10.10.0.x node)")
    p.add_argument("--interval", type=float, default=1.0,
                   help="seconds between cache polls (default 1.0)")
    p.add_argument("--port", type=int, default=1,
                   help="I2C bus (default 1 / /dev/i2c-1)")
    p.add_argument("--address", type=lambda x: int(x, 0), default=0x3C,
                   help="I2C address (default 0x3C; some modules use 0x3D)")
    p.add_argument("--controller", choices=("ssd1306", "sh1106"), default="ssd1306",
                   help="display controller (default ssd1306; try sh1106 if garbled)")
    p.add_argument("--font", default=None,
                   help="path to a .ttf for the state text "
                        "(default: DejaVu Sans Mono if present, else bitmap font)")
    p.add_argument("--font-size", type=int, default=None,
                   help="state font size in px (default: auto-fit the longest state)")
    args = p.parse_args()

    peer = args.peer or pick_peer()

    try:
        serial = i2c(port=args.port, address=args.address)
        controller = sh1106 if args.controller == "sh1106" else ssd1306
        device = controller(serial, width=128, height=64)
    except Exception as e:
        print(f"Could not open the display: {e}")
        print(f"Check `i2cdetect -y {args.port}` for the address, the wiring, "
              "and that I2C is enabled.")
        sys.exit(1)

    state_font = load_state_font(device.width, device.height - BODY_TOP,
                                 args.font, args.font_size)
    if state_font is None and (args.font or args.font_size):
        print("Requested font unavailable; using the built-in bitmap font.")

    print(f"Watching ARP state for {peer} (poll {args.interval}s). Ctrl-C to stop.")
    beat = False
    try:
        while True:
            state, mac, dev = read_neighbour(peer)
            render(device, peer, state, mac, dev, beat, state_font)
            beat = not beat
            time.sleep(args.interval)
    except KeyboardInterrupt:
        device.clear()
        print("\nDone.")


if __name__ == "__main__":
    main()
