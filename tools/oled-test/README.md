# OLED test scripts

Quick smoke tests for the **SSD1306 128×64** OLEDs over **4-wire SPI** (8-pin modules).

- `oled_test.py` — draws a border + "OLED OK" so you can confirm the display works.
- `oled_shrimp.py` — shows the Phosphor [`shrimp`](https://phosphoricons.com/?q=shrimp)
  icon. The icon is baked in as a 64×64 1-bit bitmap, so no network or SVG libs
  are needed on the Pi.

> **These are SPI displays, not I2C.** They will **not** appear in `i2cdetect`.

## Wiring (8-pin SPI SSD1306 → Pi 40-pin header)

Read the labels on your board; common names are listed. This matches luma's SPI
defaults, so the scripts run with no extra flags.

| OLED pin            | Pi pin | GPIO         |
|---------------------|--------|--------------|
| GND                 | 6      | —            |
| VCC                 | 1      | 3.3V         |
| D0 / SCK / CLK      | 23     | GPIO11 (SCLK)|
| D1 / MOSI / SDA/DIN | 19     | GPIO10 (MOSI)|
| RES / RST           | 22     | GPIO25       |
| DC                  | 18     | GPIO24       |
| CS                  | 24     | GPIO8 (CE0)  |

## On the Pi

> **On the official little-internet image (v0.4.0+)** SPI is already enabled and
> the library is pre-installed at `/opt/little-internet/venv`. Skip straight to
> running the scripts with that interpreter:
> `/opt/little-internet/venv/bin/python3 oled_test.py`. The steps below are for a
> stock Raspberry Pi OS where you set this up yourself.

```sh
# 1. Enable SPI (one-time), then reboot
sudo raspi-config nonint do_spi 0
sudo reboot
ls /dev/spidev*           # expect /dev/spidev0.0 and /dev/spidev0.1

# 2. Install the OLED library + a GPIO backend (Pi OS Bookworm blocks
#    system-wide pip, so use a venv). rpi-lgpio drives the DC/RST pins and
#    works on all Pi models under Bookworm (the old RPi.GPIO is broken on Pi 5).
python3 -m venv ~/oledvenv
~/oledvenv/bin/pip install luma.oled rpi-lgpio

# 3. Run a test — IMPORTANT: use the venv's python, not the system one.
#    `python3 oled_test.py` uses /usr/bin/python3, which lacks these packages
#    and fails with "No module named 'RPi'".
~/oledvenv/bin/python3 oled_test.py
~/oledvenv/bin/python3 oled_shrimp.py
```

> Quick-and-dirty alternative to the venv:
> `sudo pip3 install luma.oled rpi-lgpio --break-system-packages` (then plain `python3` works).

## Nothing on the screen?

SPI has no acknowledgment, so the scripts print "Done" whether or not a display
is actually there. A clean run with a dark panel means a **hardware** fault:

- These are hand-soldered bare breakouts — a **cold solder joint** is the most
  common cause. Power-off the board and continuity-test each joint
  (OLED pad ↔ Pi header pin) with a multimeter on the Ω/200 range: near-0 = good,
  `1`/overrange = open. Reflow any that fail. Also check adjacent pins aren't
  bridged (those should read open).
- **RST** and **D/C** are the usual culprits — open RST = controller never
  resets; open D/C = every byte misread. Both yield a clean run and a dark screen.
- Some 128×64 modules are **SH1106**, not SSD1306. If wiring checks out but the
  image is garbled/offset, try `from luma.oled.device import sh1106`.
- `3.3Vo` is a regulator **output** — leave it unconnected; only `VIN` gets power.

## Options (both scripts)

- `--device N` — SPI chip-select: `0`=CE0 (pin 24), `1`=CE1 (pin 26). Use this to
  drive a **second** display wired to CE1 (sharing SCLK/MOSI/DC/RST).
- `--port N` — SPI bus (default `0`).
- `--dc N` / `--rst N` — DC / RST GPIO numbers (defaults 24 / 25).
- `--hold SECONDS` — how long to leave the image up.
