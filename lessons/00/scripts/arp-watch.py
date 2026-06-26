#!/usr/bin/env python3
"""Live view of the ARP / IPv4 neighbor cache as a state machine.

Polls `ip neigh` for a device and renders each neighbor's position in the Linux
neighbor lifecycle, refreshing in place:

    NONE -> INCOMPLETE -> REACHABLE -> STALE -> DELAY -> PROBE -> FAILED

This is the first "terminal backend" for the little internet's displays. The
collector (read_neighbors) and the state model (LIFECYCLE) are deliberately kept
separate from the rendering so an OLED backend can reuse them later. See
.context/displays-and-virtual-tangibility.md.

Run it ON a node. In the namespace lab:

    sudo ip netns exec pi-a python3 lessons/00/scripts/arp-watch.py --name pi-a

Then, from another shell, poke the cache and watch the states move:

    sudo ip netns exec pi-a ping -c1 10.10.0.2     # -> REACHABLE
    sudo ip netns exec pi-a ping -c1 10.10.0.99    # -> FAILED

Usage: arp-watch.py [--dev eth0] [--name HOST] [--interval 1.0] [--once] [--all]
"""
import argparse
import json
import os
import subprocess
import sys
import time

# The Linux neighbor lifecycle, in order. (NONE is the conceptual start — "not in
# the cache" — so it never highlights for an entry that exists.)
LIFECYCLE = ["NONE", "INCOMPLETE", "REACHABLE", "STALE", "DELAY", "PROBE", "FAILED"]

# Colors, TTY-aware — matches lessons/00/scripts/lib.sh. Off when piped or NO_COLOR.
if sys.stdout.isatty() and not os.environ.get("NO_COLOR"):
    BOLD, CYAN, YEL, DIM, RST = "\033[1m", "\033[36m", "\033[33m", "\033[2m", "\033[0m"
else:
    BOLD = CYAN = YEL = DIM = RST = ""


def read_neighbors(dev, include_v6=False):
    """Collector: return [{ip, mac, state}] for `dev` from `ip neigh`."""
    rows = _read_json(dev)
    if rows is None:
        rows = _read_text(dev)
    if not include_v6:
        rows = [r for r in rows if ":" not in r["ip"]]  # IPv4 (ARP) only
    rows.sort(key=lambda r: tuple(int(o) for o in r["ip"].split(".")) if "." in r["ip"] else (r["ip"],))
    return rows


def _read_json(dev):
    try:
        out = subprocess.run(["ip", "-json", "neigh", "show", "dev", dev],
                             capture_output=True, text=True, check=True).stdout
        entries = json.loads(out or "[]")
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
        return None
    rows = []
    for e in entries:
        st = e.get("state", [])
        state = st[0] if isinstance(st, list) and st else (st or "NONE")
        rows.append({"ip": e.get("dst", ""), "mac": e.get("lladdr"), "state": state})
    return rows


def _read_text(dev):
    """Fallback for iproute2 without -json: parse the plain text."""
    try:
        out = subprocess.run(["ip", "neigh", "show", "dev", dev],
                             capture_output=True, text=True, check=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    rows = []
    for line in out.splitlines():
        parts = line.split()
        if not parts:
            continue
        mac = parts[parts.index("lladdr") + 1] if "lladdr" in parts else None
        state = next((t for t in reversed(parts) if t.isupper()), "NONE")
        rows.append({"ip": parts[0], "mac": mac, "state": state})
    return rows


def lifecycle_bar(state):
    """The lifecycle, with the entry's current `state` lit."""
    cells = []
    for s in LIFECYCLE:
        if s == state:
            cells.append(f"{BOLD}{YEL}[{s}]{RST}")
        else:
            cells.append(f"{DIM}{s}{RST}")
    return f"{DIM} -> {RST}".join(cells)


def render(rows, dev, host, interval):
    """Renderer (terminal backend): state -> a frame of text."""
    out = [f"{BOLD}{CYAN}ARP / neighbor cache  ·  {host}  ·  {dev}{RST}"
           f"    {DIM}refresh {interval}s · Ctrl-C to quit{RST}", ""]
    if not rows:
        out.append(f"{DIM}(cache empty — nothing learned yet. Try: ping a neighbor.){RST}")
    for r in rows:
        mac = r["mac"] if r["mac"] else "—"
        out.append(f"  {BOLD}{r['ip']:<15}{RST} {mac:<19} {r['state']}")
        out.append(f"    {lifecycle_bar(r['state'])}")
        out.append("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description="Live ARP neighbor state-machine watcher.")
    ap.add_argument("--dev", default="eth0", help="interface to watch (default eth0)")
    ap.add_argument("--name", default=os.uname().nodename, help="node name to show")
    ap.add_argument("--interval", type=float, default=1.0, help="refresh seconds")
    ap.add_argument("--once", action="store_true", help="print one frame and exit")
    ap.add_argument("--all", action="store_true", help="include IPv6 (NDP) neighbors")
    args = ap.parse_args()

    def frame():
        return render(read_neighbors(args.dev, args.all), args.dev, args.name, args.interval)

    if args.once or not sys.stdout.isatty():
        print(frame())
        return

    sys.stdout.write("\033[2J")  # clear once; then repaint from home each tick
    try:
        while True:
            # \033[K clears each line's tail, so a shorter line can't leave debris
            # from a longer previous frame; \033[J then clears any lines below.
            f = frame().replace("\n", "\033[K\n")
            sys.stdout.write("\033[H" + f + "\033[K\033[J")
            sys.stdout.flush()
            time.sleep(args.interval)
    except KeyboardInterrupt:
        sys.stdout.write(RST + "\n")


if __name__ == "__main__":
    main()
