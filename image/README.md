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
    └── 01-firstboot-wifi/        First-boot Wi-Fi provisioner for flashed (released) images.
        ├── 00-run.sh             Installs the provisioner script, service, and boot-partition template.
        └── files/                The script, systemd unit, and little-internet-wifi.txt.example.
```

Two separate Wi-Fi paths, for two separate audiences:

- **Building from source** (you): set `LI_WIFI_*` in `config.local` and the
  credentials are baked in at build time (`00-net-tools/02-run.sh`).
- **Flashing a released image** (anyone): the image ships credential-free; the
  flasher drops a `little-internet-wifi.txt` on the boot partition and the
  first-boot service (`01-firstboot-wifi/`) provisions Wi-Fi on first boot. See
  *Customizing a flashed image* below.

## Getting the image

You don't have to build it yourself. Each tagged release publishes a ready-to-flash
image; building from source is for changing what's in the image.

### Download a prebuilt image (easiest)

A GitHub Actions workflow (`.github/workflows/build-image.yml`) builds the image
with pi-gen and publishes the compressed `.img.xz` two ways:

- **From a Release (recommended).** Tagged builds (`v*`) attach the `.img.xz` to
  a [GitHub Release](../../releases) as a plain asset — you download the
  `.img.xz` exactly as-is and hand it straight to Raspberry Pi Imager (it
  flashes `.xz` without unpacking). This is the path to point people at.
- **From a workflow run's artifact.** Every run also uploads the image under the
  **Actions** tab → a run → *Artifacts*. Handy for testing an unreleased build,
  but GitHub **always wraps artifacts in a `.zip`** on download (there's no way
  around it), so you have to unzip it to get the `.img.xz` before flashing.
  Unzip *once* to the `.img.xz` and stop there — Imager wants the `.img.xz`, not
  the ~3 GB raw `.img` you'd get by decompressing further.

The published image is **credential-free** — no Wi-Fi, the default `pi` login.
Customize Wi-Fi (and anything else) *after* flashing; see *Customizing a flashed
image* below.

To cut a release: `git tag v1.0.0 && git push origin v1.0.0`. To test the build
without releasing, trigger the workflow manually (**Actions → Build node image →
Run workflow**) and grab the artifact.

> **Build host.** The workflow uses pi-gen's **Docker** path, which builds inside
> a Debian container — so it dodges the non-Debian-host keyring trap described
> below even though GitHub's runners are Ubuntu. While this repo is **private**
> it runs on an x86 runner and emulates arm64 (slower). Once it's **public**,
> flip `runs-on` to `ubuntu-24.04-arm` (a one-line change, noted in the
> workflow) for free, native, no-emulation arm64 builds.

## Building the image yourself

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

### 2. Install the build dependencies (inside the VM)

```bash
sudo apt update
sudo apt install -y quilt parted qemu-user-static qemu-user-binfmt debootstrap \
  zerofree zip dosfstools libarchive-tools rsync xxd bc gpg pigz arch-test
```

### 3. Build — straight from the mounted repo

No need to copy or clone the repo into the VM. Run `build.sh` directly from the
read-only host mount and send pi-gen's build directory to the VM's **local**
disk via `LI_BUILD_DIR` (pi-gen loop-mounts the image, which a read-only/virtio
mount can't do). This way you edit any file on your Mac with your normal editor
and the change is picked up on the next run — no re-copy, no in-VM editor:

```bash
cd /Users/<you>/path/to/little-internet/image    # the Lima-mounted repo
LI_BUILD_DIR=~/pigen-build ./build.sh
```

This clones pi-gen's `bookworm-arm64` branch into `~/pigen-build`, applies our
config and stage, and builds. Expect roughly 20–40 minutes.

To start fresh, note the build artifacts are **root-owned** (pi-gen builds as
root), so clearing them needs sudo: `sudo rm -rf ~/pigen-build`.

### 4. Copy the image back to the Mac

The finished, compressed image lands in `~/pigen-build/pi-gen/deploy/` (named
like `image_YYYY-MM-DD-little-internet.img.xz`). Hand it back to the Mac through
Lima's **writable** shared mount (the home mount is read-only, so you can't
write straight into a Mac folder from the VM):

```bash
cp ~/pigen-build/pi-gen/deploy/*.img.xz /tmp/lima/
```

On the Mac it's now in `/tmp/lima/`, ready to move and flash. (Or pull it
directly from the Mac with `limactl copy '<instance>:<path-to-img>' ~/Downloads/`.)

### Alternatives

- **Docker:** `USE_DOCKER=1 ./build.sh` runs pi-gen's container build (a Debian
  image with the correct keyrings, so it dodges the trap above). Reliable on a
  Linux host/VM; finicky through Docker Desktop on macOS.
- **A real Debian/Ubuntu box or cloud instance:** clone the repo and run
  `./build.sh`. On a non-Debian host, prefer the Docker path.

### Optional: pre-provision Wi-Fi

Raspberry Pi Imager's "OS customisation" is unreliable for *custom* images —
it'll show the screen but silently skip applying the settings — so don't rely
on it to set up Wi-Fi. Instead, bake the connection into the build. On your Mac
(where you have an editor), set up credentials once, then rebuild (step 3):

```bash
cp config.local.example config.local     # config.local is gitignored
# edit config.local on your Mac: set LI_WIFI_SSID / LI_WIFI_PSK
LI_BUILD_DIR=~/pigen-build ./build.sh     # run in the VM as in step 3
```

`build.sh` writes a NetworkManager connection into the image from those values,
and `WPA_COUNTRY` in `config` unblocks the radio. Every card flashed from that
build joins your Wi-Fi headless on first boot. Credentials live only in
`config.local` (never committed), so the public image stays Wi-Fi-free.

Already flashed a card without Wi-Fi? Bring it up on Ethernet (SSH is enabled),
then `sudo nmcli device wifi connect "SSID" password "PASS"` — NetworkManager
persists it, so it auto-joins on later boots.

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
2. **Choose OS → Use custom** and select the `.img.xz` (from a Release, from
   `deploy/` if you built it, or unzipped from a workflow artifact). Imager
   decompresses `.xz` as it writes — feed it the `.img.xz`, not a raw `.img`.
3. **Choose Storage** and pick your microSD card.
4. **Write**, then move the card to the Pi.

> Imager's "OS customisation" / Edit-settings step doesn't reliably apply to
> custom images, so don't depend on it. SSH is already enabled in the image; set
> up Wi-Fi via the boot-partition file instead (see *Customizing a flashed image*
> below); and give each card a **unique hostname at first boot** (next section)
> so multiple nodes don't collide on `pi-node.local`.

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

## Customizing a flashed image

The published image is **credential-free** and ships with SSH enabled — so a
freshly flashed card is reachable over Ethernet (`ssh pi@pi-node.local`,
password `little-internet`) with no further setup. To get it onto **Wi-Fi**
headless, you don't rebuild and you don't use Imager's customization screen —
you drop one file on the boot partition:

1. Flash the card (above). The FAT **boot partition** stays mounted afterward
   and shows up as a removable drive named **`bootfs`** (macOS/Windows/Linux —
   FAT mounts everywhere; if it's not mounted, re-insert the card).
2. On it you'll find **`little-internet-wifi.txt.example`**. Copy it to
   **`little-internet-wifi.txt`** (drop the `.example`) and set all three lines:

   ```
   SSID=YourNetwork
   PSK=YourPassword
   COUNTRY=US
   ```

   `COUNTRY` is the two-letter ISO code for where the Pi runs (US, GB, DE, …).
   It's **required**: it sets the WLAN regulatory domain and unblocks the radio,
   and the right value is region-specific, so the image can't guess it. All
   three must be filled in — if any is missing, the Pi logs the problem (visible
   via `systemctl status little-internet-wifi`), leaves the file so you can fix
   it, and stays Wi-Fi-free for that boot.
3. Eject the card and boot the Pi. On first boot it reads the file, sets the
   country, creates the Wi-Fi connection, and **deletes the file** so your
   password doesn't linger in plaintext on the card. The node joins your Wi-Fi
   headless.

To switch networks later, drop a fresh `little-internet-wifi.txt` on the boot
partition and reboot. Leave the file out entirely and the card simply boots
Wi-Fi-free — use Ethernet, or `sudo nmcli device wifi connect "SSID" password
"PASS"` once it's up.

> Building from source instead? You can bake Wi-Fi straight into the image at
> build time with `config.local` — see *Optional: pre-provision Wi-Fi* above.
> The boot-partition file here is the path for images you didn't build yourself.

## First boot

- SSH is enabled. From another machine on the same network:
  `ssh pi@<hostname>.local` (or `ssh pi@pi-node.local`), password
  `little-internet`.
- If you didn't set a unique hostname while flashing, set one now so multiple
  nodes don't clash: `sudo raspi-config` → System Options → Hostname, or
  `sudo hostnamectl set-hostname pi-a`.
- Confirm the networking tools are present: `which tcpdump tshark arping`.
- Check the I2C bus (for the OLED): `i2cdetect -y 1`.
