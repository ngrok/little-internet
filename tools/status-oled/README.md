# Status OLED

`status_oled.py` paints the node's identity on the SSD1306 from boot: the
hostname in the yellow strip, and eth0's MAC plus its current IPv4 address in
the blue body — the address in the biggest font that fits, because that's the
thing you read from across the bench. With a rack of identical Pis, the panel
is what tells you which one is which — and whose ARP entry you're looking at.

```
pi-foo-01              ← yellow strip: hostname
──────────────────
d8:3a:dd:4e:aa:10      ← eth0's MAC (the node's layer-2 identity), small
10.10.0.1              ← eth0's IPv4 (the lab wire), big
```

It refreshes once a second, so a DHCP lease landing or a cable pull shows up
live: the address line reads `(down)` with no cable, `(no IPv4)` while it
waits for an address — the difference lesson 00 is built on. Only eth0 shows
by default; `--interfaces eth0 wlan0` adds a line with the Wi-Fi address (your
SSH path) back.

## On the image

The little-internet image runs it as a boot service, so a powered node always
shows who it is:

```sh
systemctl status little-internet-oled    # the service driving the panel
sudo systemctl stop little-internet-oled # blank the panel until next boot
```

The service installs the script at `/opt/little-internet/status-oled/`.

## Sharing the panel

There's one panel and sometimes two things that want it. The on-demand scripts
(`~/arp-oled`, `~/oled-test`) borrow it by creating
`/run/little-internet/oled.claim` while they run; this display pauses while
that file exists and resumes when the script exits and removes it. No sudo
involved: the claim directory is group-writable by `i2c`, which the lab user
is already in.

## Options

- `--interfaces IF [IF ...]`: interfaces to show, one IPv4 line each; the
  first one's MAC is shown too (default: `eth0`)
- `--interval N`: seconds between refreshes (default `1.0`)
- `--port N`: I2C bus (default `1`)
- `--address 0xNN`: I2C address (default `0x3c`; some modules use `0x3d`)
- `--controller ssd1306|sh1106`: try `sh1106` if the display is garbled
- `--font PATH`: TTF (default: JetBrains Mono, then DejaVu Sans Mono, then PIL's bitmap font)
- `--claim-file PATH`: pause while this file exists (default `/run/little-internet/oled.claim`)

If no display answers on the bus, it exits 0 (a node without a panel is fine;
the service goes quietly inactive rather than restart-looping).

## Trouble

Blank, garbled, or wrong address? See [`../oled-test/README.md`](../oled-test/README.md):
same panel, same wiring.
