# The node image

Every Raspberry Pi in the little internet boots the same custom image: a
headless **Raspberry Pi OS Lite** with the networking tools the lessons need
already installed (`tcpdump`, `tshark`, `arping`, `ethtool`, VLAN/bridge
tooling, and I2C enabled for the OLED displays).

You don't have to build it. Every release ships a ready-to-flash image, so the
quickstart below is all most people need. Building from source is only for
changing what's *in* the image — that's covered further down, under
[Building the image yourself](#building-the-image-yourself).

## Quickstart: flash a prebuilt image

Download the image, write it to a microSD card, then drop a couple of optional
text files on the card to set Wi-Fi and a hostname. No build, no Imager
customization screen, no command line required.

### 1. Download the image

Grab the latest `.img.xz` from the **[Releases page](../../releases/latest)** —
it's attached to each release as a plain download. That's the whole file you
need; hand it straight to Raspberry Pi Imager, which writes `.xz` without
unpacking. Don't decompress it yourself.

The image is credential-free: no Wi-Fi baked in, and the default `pi` login.

### 2. Flash the card

**With Raspberry Pi Imager (recommended):**

1. Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. **Choose OS → Use custom** and select the `.img.xz` you downloaded. Imager
   decompresses it as it writes, so feed it the `.img.xz` as-is.
3. **Choose Storage** and pick your microSD card.
4. **Write**, then leave the card in the reader for step 3.

> Skip Imager's "OS customisation" / Edit-settings step — it doesn't reliably
> apply to custom images. SSH is already enabled; the boot-partition file in
> step 3 is how you set Wi-Fi and the hostname.

**Or with the command line (`dd`):** find your SD card device first
(`diskutil list` on macOS, `lsblk` on Linux) and be certain you've got the right
one — `dd` to the wrong disk will wipe it.

```bash
# macOS — unmount (not eject) the card first; replace diskN with your card.
diskutil unmountDisk /dev/diskN
xzcat *-little-internet.img.xz | sudo dd of=/dev/rdiskN bs=4m
diskutil eject /dev/diskN
```

```bash
# Linux — replace sdX with your card.
xzcat *-little-internet.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
sudo sync
```

A freshly flashed card already boots and is reachable over Ethernet
(`ssh pi@pi-node.local`, password `little-internet`); step 3 is optional.

### 3. Configure the card (optional)

After flashing, the card's FAT boot partition mounts as a removable drive named
**`bootfs`** (on macOS, Windows, and Linux; re-insert the card if you don't see
it). On it is one template, **`little-internet.txt.example`** — copy it to
**`little-internet.txt`** (drop the `.example`), fill in the parts you want, then
eject and boot. Everything in it is optional and independent.

```
SSID=YourNetwork
PSK=YourPassword
COUNTRY=US
HOSTNAME=pi-a
```

- **Wi-Fi** — `SSID`, `PSK`, and `COUNTRY`, all three together. `COUNTRY` is the
  two-letter ISO code for where the Pi runs (US, GB, DE, …) and is **required** —
  it unblocks the radio and can't be guessed. On a successful join the Pi strips
  these three lines from the file so your password doesn't linger in plaintext;
  to switch networks later, add them back and reboot. No Wi-Fi? Use Ethernet, or
  `sudo nmcli device wifi connect "SSID" password "PASS"` once it's up.
- **Hostname** — `HOSTNAME=`, or just a bare line like `pi-a`. Every card
  defaults to `pi-node`, so set a unique name or multiple nodes collide on
  `pi-node.local`. Unlike the Wi-Fi lines it's kept and re-read every boot, so it
  doubles as a label for the card; edit and reboot to rename.

A bad value is logged to `systemctl status little-internet`, which leaves the
file in place so you can fix it and reboot.

### 4. First boot

- SSH is enabled. From another machine on the same network:
  `ssh pi@<hostname>.local` (or `ssh pi@pi-node.local` if you skipped the
  hostname in step 3), password `little-internet`.
- Confirm the networking tools are present: `which tcpdump tshark arping`.
- Check the I2C bus (for the OLED): `i2cdetect -y 1`.

> The image ships with user `pi` / password `little-internet`. Fine for a closed
> lab; change the password for anything exposed.

---

## Building the image yourself

Everything below is for changing what's in the image. If you just want to flash
a node, the quickstart above is all you need.

The image is built with [pi-gen](https://github.com/RPi-Distro/pi-gen), the same
tool the Raspberry Pi Foundation uses for its official images. This directory
holds our pi-gen config and a custom stage; `build.sh` clones pi-gen, drops our
config and stage in, and runs the build.

### What's here

```
image/
├── README.md                     This file.
├── config                        pi-gen config: release, hostname, user, SSH, WLAN country, stages.
├── config.local.example          Template for untracked local overrides (Wi-Fi creds, etc.).
├── build.sh                      Clones pi-gen, applies our config + stage, builds.
└── stage-little-internet/        Our custom pi-gen stage.
    ├── prerun.sh                 Seeds the stage rootfs from the previous stage.
    ├── EXPORT_IMAGE              Marks this stage as exporting the final image.
    ├── 00-net-tools/
    │   ├── 00-debconf            Preseeds iperf3 to not autostart (keeps the build non-interactive).
    │   ├── 00-packages           apt packages to install (capture, ARP, VLAN, I2C…).
    │   ├── 01-run.sh             Enables the I2C bus for the SSD1306 OLED displays.
    │   └── 02-run.sh             Installs a pre-provisioned Wi-Fi connection, if one was generated.
    └── 01-firstboot-config/      First-boot hostname + Wi-Fi provisioner for flashed (released) images.
        ├── 00-run.sh             Installs the provisioner script, service, and boot-partition template.
        └── files/                The script, systemd unit, and little-internet.txt.example.
```

There are two Wi-Fi paths, for two audiences:

- **Flashing a released image** (the quickstart): the image ships
  credential-free; the flasher drops a `little-internet.txt` on the boot
  partition and the first-boot service (`01-firstboot-config/`) provisions the
  hostname and Wi-Fi on first boot.
- **Building from source:** set `LI_WIFI_*` in `config.local` and the
  credentials are baked in at build time (`00-net-tools/02-run.sh`). See
  [Optional: pre-provision Wi-Fi](#optional-pre-provision-wi-fi).

### The build environment

pi-gen needs a Debian-based Linux environment; it doesn't run natively on macOS.
Build Bookworm pi-gen on a Debian Bookworm host specifically: on a non-Debian
host (Ubuntu, etc.) `debootstrap` can't populate Debian's archive keys into the
build chroot, and the build dies with `NO_PUBKEY ... bookworm` /
`repository ... is not signed` errors.

On an Apple Silicon Mac, the clean path is a small Debian VM via
[Lima](https://lima-vm.io/). Because the VM is arm64, the arm64 image builds
natively, with no emulation.

#### 1. Create a Debian VM (run on the Mac)

```bash
brew install lima        # if you don't already have it
limactl start --name=pigen --cpus=4 --memory=6 --disk=40 template://debian
limactl shell pigen      # drop into the VM — everything below runs *inside* it
```

Lima auto-mounts your Mac home read-only inside the VM at the same path, so the
repo is already visible in there.

#### 2. Install the build dependencies (inside the VM)

```bash
sudo apt update
sudo apt install -y quilt parted qemu-user-static qemu-user-binfmt debootstrap \
  zerofree zip dosfstools libarchive-tools rsync xxd bc gpg pigz arch-test
```

#### 3. Build straight from the mounted repo

No need to copy or clone the repo into the VM. Run `build.sh` directly from the
read-only host mount and send pi-gen's build directory to the VM's local disk via
`LI_BUILD_DIR` (pi-gen loop-mounts the image, which a read-only/virtio mount
can't do). Edit any file on your Mac with your normal editor and the next run
picks up the change, with no re-copy and no in-VM editor:

```bash
cd /Users/<you>/path/to/little-internet/image    # the Lima-mounted repo
LI_BUILD_DIR=~/pigen-build ./build.sh
```

This clones pi-gen's `bookworm-arm64` branch into `~/pigen-build`, applies our
config and stage, and builds. Expect roughly 20–40 minutes.

To start fresh, clear the build artifacts. They're root-owned (pi-gen builds as
root), so it needs sudo: `sudo rm -rf ~/pigen-build`.

#### 4. Copy the image back to the Mac

The finished, compressed image lands in `~/pigen-build/pi-gen/deploy/` (named
like `image_YYYY-MM-DD-little-internet.img.xz`). Hand it back to the Mac through
Lima's writable shared mount; the home mount is read-only, so you can't write
straight into a Mac folder from the VM:

```bash
cp ~/pigen-build/pi-gen/deploy/*.img.xz /tmp/lima/
```

On the Mac it's now in `/tmp/lima/`, ready to move and flash. (Or pull it
directly from the Mac with `limactl copy '<instance>:<path-to-img>' ~/Downloads/`.)

#### Alternatives

- **Docker:** `USE_DOCKER=1 ./build.sh` runs pi-gen's container build (a Debian
  image with the correct keyrings, so it dodges the trap above). Reliable on a
  Linux host/VM; finicky through Docker Desktop on macOS.
- **A real Debian/Ubuntu box or cloud instance:** clone the repo and run
  `./build.sh`. On a non-Debian host, prefer the Docker path.

### Optional: pre-provision Wi-Fi

Raspberry Pi Imager's "OS customisation" is unreliable for custom images: it
shows the screen but silently skips applying the settings, so don't rely on it
for Wi-Fi. Bake the connection into the build instead. On your Mac, set up
credentials once, then rebuild (step 3):

```bash
cp config.local.example config.local     # config.local is gitignored
# edit config.local on your Mac: set LI_WIFI_SSID / LI_WIFI_PSK
LI_BUILD_DIR=~/pigen-build ./build.sh     # run in the VM as in step 3
```

`build.sh` writes a NetworkManager connection into the image from those values,
and `WPA_COUNTRY` in `config` unblocks the radio. Every card flashed from that
build joins your Wi-Fi headless on first boot. Credentials live only in
`config.local` (never committed), so the public image stays Wi-Fi-free.

### Notes & knobs

- **Architecture.** Builds 64-bit (arm64) Raspberry Pi OS Lite by default. It
  runs well on the Pi 3 Model B+ and, on an Apple Silicon Mac, builds natively
  without emulation. Both 32-bit and 64-bit flash and boot identically on the Pi
  3 B+, so this is purely a build-host convenience.
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
  `debian-archive-keyring`, so the build fails with `NO_PUBKEY ... bookworm` /
  `repository ... is not signed` during stage0's `apt-get update`. `build.sh`
  patches the freshly cloned pi-gen to add `debian-archive-keyring` to the
  bootstrap. Nothing to do by hand.

### Releasing and CI

A GitHub Actions workflow (`.github/workflows/build-image.yml`) builds the image
with pi-gen and publishes the compressed `.img.xz`:

- **Releases.** Tagged builds (`v*`) attach the `.img.xz` to a
  [GitHub Release](../../releases) as a plain asset — this is what the quickstart
  links to. Cut one with `git tag v1.0.0 && git push origin v1.0.0`.
- **Workflow artifacts.** Every run also uploads the image under the **Actions**
  tab (a run → *Artifacts*). Handy for testing an unreleased build, but GitHub
  wraps artifacts in a `.zip` on download — unzip *once* to the `.img.xz` and
  stop there (Imager wants the `.img.xz`, not the ~3 GB raw `.img`). Trigger a
  test build with **Actions → Build node image → Run workflow**.

> **Build host.** The workflow uses pi-gen's Docker path, which builds inside a
> Debian container, so it dodges the non-Debian-host keyring trap even though
> GitHub's runners are Ubuntu. While this repo is private it runs on an x86
> runner and emulates arm64 (slower). Once it's public, flip `runs-on` to
> `ubuntu-24.04-arm` (a one-line change, noted in the workflow) for free, native
> arm64 builds.
