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
        ├── 00-debconf            Preseeds iperf3 to not autostart (keeps the build non-interactive).
        ├── 00-packages           apt packages to install (capture, ARP, VLAN, I2C…).
        └── 01-run.sh             Enables the I2C bus for the SSD1306 OLED displays.
```

## Building the image

pi-gen needs a **Debian-based Linux** environment — it does **not** run natively
on macOS. And it's worth building Bookworm pi-gen *on a Debian Bookworm host*
specifically: on a non-Debian host (Ubuntu, etc.) `debootstrap` can't populate
Debian's archive keys into the build chroot, and the build dies inside the
chroot with `NO_PUBKEY ... bookworm` / `repository ... is not signed` errors.

So on an Apple Silicon Mac, the clean path is a small **Debian VM** via
[Lima](https://lima-vm.io/). Because the VM is arm64, the arm64 image builds
**natively — no emulation**.

### 1. Create a Debian VM (run on the Mac)

```bash
brew install lima        # if you don't already have it
limactl start --name=pigen --cpus=4 --memory=6 --disk=40 template://debian
limactl shell pigen      # drop into the VM — everything below runs *inside* it
```

Lima auto-mounts your Mac home **read-only** inside the VM at the same path, so
the repo is already visible from in there.

### 2. Get the repo onto the VM's own disk

pi-gen does loop-mounts during the build and needs a real local filesystem (not
the read-only host mount), so copy the repo in:

```bash
cp -r ~/path/to/little-internet ~/little-internet
cd ~/little-internet/image
```

### 3. Install the build dependencies

```bash
sudo apt update
sudo apt install -y git
sudo apt install -y quilt parted qemu-user-static qemu-user-binfmt debootstrap \
  zerofree zip dosfstools libarchive-tools rsync xxd bc gpg pigz arch-test
```

### 4. Build

```bash
./build.sh
```

This clones pi-gen's `bookworm-arm64` branch, applies our config and stage, and
builds. Expect roughly 20–40 minutes.

### 5. Copy the image back to the Mac

The finished, compressed image lands in
`~/little-internet/image/build/pi-gen/deploy/` (named like
`image_YYYY-MM-DD-little-internet.img.xz`). The whole `build/` tree is
gitignored. Lima mounts your Mac home **read-only**, so you can't copy the
image straight into a Mac folder from inside the VM — hand it back through
Lima's **writable** shared mount instead:

```bash
cp build/pi-gen/deploy/*.img.xz /tmp/lima/
```

On the Mac it's now in `/tmp/lima/`, ready to move and flash. (Or pull it
directly from the Mac with `limactl copy '<instance>:<path-to-img>' ~/Downloads/`.)

### Alternatives

- **Docker:** `USE_DOCKER=1 ./build.sh` runs pi-gen's container build (a Debian
  image with the correct keyrings, so it dodges the trap above). Reliable on a
  Linux host/VM; finicky through Docker Desktop on macOS.
- **A real Debian/Ubuntu box or cloud instance:** clone the repo and run
  `./build.sh`. On a non-Debian host, prefer the Docker path.

### Notes & knobs

- **Architecture.** This builds **64-bit (arm64) Raspberry Pi OS Lite** by
  default — it runs great on the Pi 3 Model B+ and, on an Apple Silicon Mac,
  builds natively (no slow emulation). Both 32-bit and 64-bit flash and boot
  identically on the Pi 3 B+, so this is purely a build-host convenience.
- **pi-gen branch must match the release.** pi-gen pairs each Debian release
  with its own branch, and the branch must match `RELEASE` in `config` or pi-gen
  warns (`RELEASE does not match the intended option for this branch`) and may
  hit package errors. `build.sh` defaults to the `bookworm-arm64` branch to
  match `RELEASE='bookworm'`. Other options (set both together):

  | Want | `PIGEN_REF` | `RELEASE` in `config` |
  | -- | -- | -- |
  | 64-bit Bookworm (default) | `bookworm-arm64` | `bookworm` |
  | 32-bit Bookworm | `bookworm` | `bookworm` |
  | 64-bit Trixie (newest) | `arm64` | `trixie` |
  | 32-bit Trixie (newest) | `master` | `trixie` |

  e.g. `PIGEN_REF=bookworm ./build.sh` (after setting `RELEASE='bookworm'`).
- **Defaults to change.** The image ships with user `pi` / password
  `little-internet` and hostname `pi-node`, baked in via `config`. Fine for a
  closed lab; change the password for anything else.
- **Keyring patch (automatic).** pi-gen debootstraps the chroot with only
  `gnupg` + `ca-certificates`, and on current Debian that leaves out
  `debian-archive-keyring` — so the build fails with `NO_PUBKEY ... bookworm` /
  `repository ... is not signed` during stage0's `apt-get update`. `build.sh`
  patches the freshly cloned pi-gen to add `debian-archive-keyring` to the
  bootstrap, which fixes it. Nothing to do by hand.

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
xzcat image_YYYY-MM-DD-little-internet.img.xz | sudo dd of=/dev/rdiskN bs=4m
diskutil eject /dev/diskN
```

Linux:

```bash
# Replace sdX with your card.
xzcat image_YYYY-MM-DD-little-internet.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
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
