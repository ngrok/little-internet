# OLED test scripts

Quick smoke tests for the **SSD1306 128×64** OLEDs over **I2C** (4-pin modules).

- `oled_test.py` — draws a border + "OLED OK" so you can confirm the display works.
- `oled_shrimp.py` — shows the Phosphor [`shrimp`](https://phosphoricons.com/?q=shrimp)
  icon. The icon is baked in as a 64×64 1-bit bitmap, so no network or SVG libs
  are needed on the Pi.

## Wiring (4-pin I2C SSD1306 → Pi 40-pin header)

| OLED pin | Pi pin | GPIO        |
|----------|--------|-------------|
| GND      | 6      | —           |
| VCC      | 1      | 3.3V        |
| SCL      | 5      | GPIO3 (SCL) |
| SDA      | 3      | GPIO2 (SDA) |

## On the Pi

> **On the official little-internet image** I2C is already enabled and the
> library is pre-installed at `/opt/little-internet/venv`. Skip straight to
> running the scripts with that interpreter:
> `/opt/little-internet/venv/bin/python3 oled_shrimp.py`. The steps below are for
> a stock Raspberry Pi OS where you set this up yourself.

```sh
# 1. Enable I2C (one-time), then reboot
sudo raspi-config nonint do_i2c 0
sudo reboot
i2cdetect -y 1            # expect the panel at 0x3c (sometimes 0x3d)

# 2. Install the OLED library. Pi OS Bookworm blocks system-wide pip, so use a
#    venv. luma.oled pulls in smbus2 (pure-python I2C), so no GPIO backend or
#    compiler is needed for I2C panels.
python3 -m venv ~/oledvenv
~/oledvenv/bin/pip install luma.oled

# 3. Run a test — IMPORTANT: use the venv's python, not the system one.
#    `python3 oled_test.py` uses /usr/bin/python3, which lacks these packages
#    and fails with "No module named 'luma'".
~/oledvenv/bin/python3 oled_test.py
~/oledvenv/bin/python3 oled_shrimp.py
```

> Quick-and-dirty alternative to the venv:
> `sudo pip3 install luma.oled --break-system-packages` (then plain `python3` works).

## Nothing on the screen?

- Run `i2cdetect -y 1` first. **No address shown** = a wiring/power problem
  (these are often hand-soldered bare breakouts — a cold solder joint or
  swapped SDA/SCL is the usual cause). Power off and continuity-test each joint
  (OLED pad ↔ Pi header pin) with a multimeter on the Ω/200 range: near-0 = good,
  `1`/overrange = open.
- **Address shows at 0x3d, not 0x3c?** Pass `--address 0x3d`.
- **Image garbled or offset?** Some 128×64 modules are **SH1106**, not SSD1306.
  Pass `--controller sh1106`.

## Options (both scripts)

- `--port N` — I2C bus (default `1` / `/dev/i2c-1`).
- `--address 0xNN` — I2C address (default `0x3c`).
- `--controller ssd1306|sh1106` — display controller (default `ssd1306`).
- `--hold SECONDS` — how long to leave the image up.
