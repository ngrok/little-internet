# Agent guide

This repo teaches networking by pairing story, runnable lessons, and Raspberry
Pi image tooling. If you are a coding agent asked to guide someone through it,
act as a tutor and lab operator: explain what each command is proving, run only
the mode that matches the user's environment, and stop for physical actions.

## Start here

Read these in order before making changes or walking a user through the lab:

1. `README.md` for the project shape and phases.
2. `diaries/00_two-pis-one-cable.md` for the story behind lesson 00.
3. `lessons/00/README.md` for the hands-on run path.
4. `lessons/00/manifest.json` for the machine-readable lesson beats, expected
   observations, and recovery commands.

Use `rg --files` to inspect the repo. The `.context/` directory is private
workspace scratch space; do not assume external users or future agents can see
it.

## Teaching modes

- Read-only tutoring: use the diary, lesson README, and manifest to explain the
  lesson without running commands. This works from any machine.
- Virtual lab: run lesson 00 in Linux with network namespaces. This is the best
  mode when there is no hardware. From `lessons/00`, use
  `sudo env NO_COLOR=1 ./scripts/run.sh --virtual`.
- Hardware lab: drive two real Pis over SSH. Confirm the user has two nodes
  flashed with `image/`, an Ethernet cable between their `eth0` ports, and SSH
  access over Wi-Fi before running scripts.

## Commands and safety

Lesson 00 scripts live in `lessons/00/scripts/`.

- `./scripts/check.sh --hardware` checks SSH access, required tools, sudo
  readiness, and whether `eth0` already has lesson state.
- `sudo ./scripts/check.sh --virtual` checks the Linux namespace lab
  prerequisites.
- `./scripts/run.sh` walks the hardware lesson over SSH.
- `sudo ./scripts/run.sh --virtual` creates, runs, and tears down the namespace
  lab.
- `./scripts/reset.sh` deletes the lesson's `eth` NetworkManager profile on
  both hardware nodes, returning `eth0` to a blank lab wire.
- `sudo ./scripts/virtual/lab-down.sh` removes the virtual namespaces if a
  virtual run is interrupted.

Do not run hardware scripts without confirming `A_HOST` and `B_HOST`; they
default to `pi@pi-foo-01.local` and `pi@pi-foo-02.local`. Do not run image build
or flashing commands unless explicitly asked; those can take a long time and can
write to disks if misused.

When scripting or capturing output for another agent, prefer:

```bash
NO_COLOR=1 ./scripts/<step>.sh
```

The scripts pause only when stdin is a terminal, so noninteractive runs continue
through prompts automatically. Hardware runs may still need SSH and sudo access.

## Human handoffs

Stop and ask the user to perform physical work when the lesson requires it:

- Unplug or seat the Ethernet cable.
- Check link lights.
- Flash or move microSD cards.
- Confirm the correct SD card device before any `dd` command.

The agent can interpret output and troubleshoot, but it cannot verify physical
state directly.

## Expected lesson 00 arc

The lesson answers three questions:

- Layer 1: a real cable changes `eth0` from `NO-CARRIER` / `DOWN` to
  `LOWER_UP` / `UP`, with speed and duplex negotiated.
- Layer 2: the link emits frames immediately, including IPv6 neighbor discovery,
  multicast listener reports, router solicitation, and on real Pis often mDNS
  and DHCP discovery.
- Layer 3: `ping 10.10.0.2` fails until both ends receive IPv4 identities on
  `eth0`; then ARP maps the typed IP address to the peer's MAC address.

If the virtual lab is unavailable on macOS or Windows, tell the user to run it
inside a Linux VM or use read-only tutoring mode.
