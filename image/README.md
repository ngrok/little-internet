# The node image

Every Raspberry Pi in the little internet boots the same custom image: a
headless **Raspberry Pi OS Lite** with the networking tools the lessons need
already installed (`tcpdump`, `tshark`, `arping`, `ethtool`, VLAN/bridge
tooling, and I2C enabled for the OLED displays).

The image is built with [pi-gen](https://github.com/RPi-Distro/pi-gen), the same
tool the Raspberry Pi Foundation uses to build the official images. This
directory holds our pi-gen config and a custom stage; `build.sh` clones pi-gen,
drops our config and stage in, and runs the build.

## What's here

```
image/
├── README.md                     This file.
├── config                        pi-gen config: release, hostname, user, SSH, stages.
├── build.sh                      Clones pi-gen, applies our config + stage, builds.
└── stage-little-internet/        Our custom pi-gen stage.
    ├── prerun.sh                 Seeds the stage rootfs from the previous stage.
    ├── EXPORT_IMAGE              Marks this stage as exporting the final image.
    └── 00-net-tools/
        ├── 00-packages           apt packages to install (capture, ARP, VLAN, I2C…).
        └── 01-run.sh             Enables the I2C bus for the SSD1306 OLED displays.
```

## Building the image

> **pi-gen needs Linux.** It runs on a Debian-based host (Bookworm recommended)
> or through its Docker wrapper. It does **not** run natively on macOS. Pick one
> of the environments below.

### Option A — A Debian/Ubuntu host (simplest, most reliable)

On a Debian Bookworm or recent Ubuntu machine (a VM, a spare box, or a cloud
instance):

```bash
cd image
./build.sh
```

pi-gen needs a handful of host packages; if the build complains, install them:

```bash
sudo apt install -y quilt qemu-user-static debootstrap zerofree zip \
  dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc \
  binfmt-support ca-certificates qemu-utils kpartx fdisk gpg pigz
```

### Option B — Docker (works on Linux; finicky on macOS)

```bash
cd image
USE_DOCKER=1 ./build.sh
```

This uses pi-gen's own `build-docker.sh`. On Linux it Just Works. On macOS the
Docker build is unreliable (it needs privileged mode + binfmt/qemu that Docker
Desktop's VM doesn't expose cleanly) — prefer Option A or C from a Mac.

### Option C — GitHub Actions / a cloud Linux runner

Run `build.sh` on a Linux CI runner and upload `build/pi-gen/deploy/*` as an
artifact. Good for reproducible, hands-off builds. (A workflow may be added to
this repo later.)

### Output

The finished, compressed image lands in:

```
image/build/pi-gen/deploy/
```

as something like `little-internet-YYYY-MM-DD.img.xz`. The whole `build/`
directory is gitignored.

### Notes & knobs

- **Architecture.** This builds 32-bit (armhf) Raspberry Pi OS Lite, which runs
  on every Pi in the BOM (the Pi 3 Model B+). To build 64-bit instead, point at
  pi-gen's arm64 branch: `PIGEN_REF=arm64 ./build.sh`.
- **pi-gen version.** `build.sh` clones pi-gen's `master` by default. Override
  with `PIGEN_REF` (a branch or tag) for a pinned, reproducible build.
- **Defaults to change.** The image ships with user `pi` / password
  `little-internet` and hostname `pi-node`, baked in via `config`. Fine for a
  closed lab; change the password for anything else.

## Flashing the image

### With Raspberry Pi Imager (recommended)

1. Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. **Choose OS → Use custom** and select the `.img.xz` from `deploy/`.
3. **Choose Storage** and pick your microSD card.
4. Click the gear / **Edit settings** to customize this card before flashing —
   this is the easy way to give each node a **unique hostname** (e.g.
   `pi-a`, `pi-b`), set Wi-Fi (if used), and configure SSH. Do this per card so
   the nodes don't collide on the network.
5. **Write**, then move the card to the Pi.

### With the command line (`dd`)

Find your SD card device first (`diskutil list` on macOS, `lsblk` on Linux) and
be **certain** you've got the right one — `dd` to the wrong disk will wipe it.

macOS:

```bash
# Unmount (not eject) the card first; replace diskN with your card.
diskutil unmountDisk /dev/diskN
xzcat little-internet-YYYY-MM-DD.img.xz | sudo dd of=/dev/rdiskN bs=4m
diskutil eject /dev/diskN
```

Linux:

```bash
# Replace sdX with your card.
xzcat little-internet-YYYY-MM-DD.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
sudo sync
```

## First boot

- SSH is enabled. From another machine on the same network:
  `ssh pi@<hostname>.local` (or `ssh pi@pi-node.local`), password
  `little-internet`.
- If you didn't set a unique hostname while flashing, set one now so multiple
  nodes don't clash: `sudo raspi-config` → System Options → Hostname, or
  `sudo hostnamectl set-hostname pi-a`.
- Confirm the networking tools are present: `which tcpdump tshark arping`.
- Check the I2C bus (for the OLED): `i2cdetect -y 1`.
