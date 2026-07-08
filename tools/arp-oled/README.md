# ARP-state OLED

`arp_oled.py` paints the kernel's neighbour-cache (ARP) state for the peer node
onto the SSD1306, polling `ip neigh` once a second. It's read-only: drive the
state machine from another shell and watch the panel follow.

## Run it

It ships in `~/arp-oled` on the little-internet image. No `sudo` needed (reading
the cache is unprivileged, and the `pi` user is already in the `i2c` group):

```sh
/opt/little-internet/venv/bin/python3 ~/arp-oled/arp_oled.py
```

By default it watches the other half of the `10.10.0.x` pair (on `.1` it watches
`.2`, and vice versa); override with `--peer`. Ctrl-C clears the panel and exits.
It's a script, not a service, so it won't fight the `oled-test` scripts for the
display.

## Drive the state machine

From a second shell, change what the peer is doing and watch the state flip:

```sh
ping -c1 10.10.0.2                 # resolve the peer -> REACHABLE
ip neigh show 10.10.0.2            # the entry this screen reads

# Force a state by hand (root):
sudo ip neigh replace 10.10.0.2 dev eth0 lladdr <PEER_MAC> nud stale
sudo ip neigh replace 10.10.0.2 dev eth0 lladdr <PEER_MAC> nud failed
sudo ip neigh del     10.10.0.2 dev eth0          # -> ABSENT

# Pull the peer's cable, then ping it: ABSENT -> INCOMPLETE -> FAILED.
```

`REACHABLE` decays to `STALE` on its own after ~30s. Shorten that to watch it
happen:

```sh
sudo sysctl -w net.ipv4.neigh.eth0.base_reachable_time_ms=5000
sudo ip neigh flush dev eth0       # apply it to existing entries now
```

## States

| State | Meaning |
|-------|---------|
| `ABSENT` | No entry yet; the kernel hasn't needed to resolve the peer. |
| `INCOMPLETE` | ARP request sent, no reply yet (no MAC). |
| `REACHABLE` | Confirmed reachable recently. |
| `STALE` | Held but unconfirmed; revalidated on next use. |
| `DELAY` | In use while stale, waiting before it probes. |
| `PROBE` | Sending unicast ARP probes to reconfirm. |
| `FAILED` | The peer didn't answer. |

## Options

- `--peer IP`: peer to watch (default: the other `10.10.0.x` node)
- `--interval N`: seconds between polls (default `1.0`)
- `--port N`: I2C bus (default `1`)
- `--address 0xNN`: I2C address (default `0x3c`; some modules use `0x3d`)
- `--controller ssd1306|sh1106`: try `sh1106` if the display is garbled
- `--font PATH`: state-text TTF (default: JetBrains Mono, then DejaVu Sans Mono, then PIL's bitmap font)
- `--font-size N`: fix the state size in px (default: auto-fit to the longest state)

## Two-colour panel

The BOM display glows yellow in its top 16 pixel rows and blue in the bottom 48,
fixed in the glass and not changeable in software. The layout puts the peer label
in the yellow strip and the live MAC and state in the blue body. If your panel
splits at a different row or is single-colour, set `YELLOW_H` at the top of
`arp_oled.py` (`0` treats the whole panel as one band).

## Trouble

Blank, garbled, or wrong address? See [`../oled-test/README.md`](../oled-test/README.md):
same panel, same wiring.
