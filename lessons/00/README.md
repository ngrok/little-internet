# Lesson 00: two Pis, one cable—do it yourself

This is the hands-on version of [diary 00](../../diaries/00_two-pis-one-cable.md):
two machines, one cable, and a question that sounds trivial until you try it—can
they just... talk? You run each step yourself and watch every answer show up on
the wire.

It's procedure, not the story. For the *why*, read the diary. For ARP frame by
frame—cache states, padding, even how to poison it—read [ARP from the ground
up](LINK-TK).

## What you'll watch happen

"Talk" sounds simple, but it's hiding three questions, and you'll see each one
answer itself on the wire:

- Is there even a wire? (Layer 1: a dead port coming to life.)
- Are frames flowing? (Layer 2: the burst of chatter the instant the link comes up.)
- Can they reach each other by the address you'd type? (Layer 3: why a wire with
  no identity is invisible to the routing table, and how ARP fixes it.)

## How it runs

The scripts live here, on your machine, and reach *into* the two nodes to run each
step. Nothing gets installed on the nodes—they only need SSH and the networking
tools the [little internet image](../../image/) already ships. Pick a backend with
`MODE`:

- `MODE=ssh` (the default) drives two real Pis over SSH.
- `MODE=netns` drives a local namespace lab, no hardware required.

Each step runs as one privileged block per node, so on real hardware you're asked
for that node's sudo password once per step. Don't want to be prompted? Set up
passwordless sudo on the nodes. That's opt-in; the default assumes you haven't.

### On hardware (two Raspberry Pis)

You'll need two nodes flashed with the [little internet image](../../image/), an
Ethernet cable between their `eth0` ports, and SSH reachability to each over Wi-Fi.
Parts are in [`BOM.md`](../../BOM.md). Point the scripts at your nodes with
`A_HOST` / `B_HOST` (they default to `pi@pi-foo-01.local` / `pi@pi-foo-02.local`):

```bash
export A_HOST=pi@pi-foo-01.local B_HOST=pi@pi-foo-02.local

./scripts/00-link.sh        # is there a wire? unplug, then seat, the cable
./scripts/01-listen.sh      # the link-up burst
./scripts/02-no-address.sh  # the ping fails—the wire has no identity
./scripts/03-address.sh     # give each node an identity
./scripts/04-arp.sh         # ARP makes the introduction
./scripts/reset.sh          # back to a blank wire
```

### Virtually (no hardware, one Linux host)

A veth pair is the closest thing to a single cable in software: two ends, nothing
in between. `scripts/virtual/lab-up.sh` builds two network namespaces (pi-a and
pi-b) joined by one veth, with no bridge, gateway, or DHCP in the way. You'll need
a Linux host and root; on macOS or Windows, run it inside a Linux VM
([colima](https://github.com/abiosoft/colima) and
[lima](https://github.com/lima-vm/lima) both work). The lab needs `ip`, `tcpdump`,
and `ping`.

```bash
sudo ./scripts/virtual/demo.sh    # build the lab, run the steps, tear it down
```

Or drive the steps yourself against the lab:

```bash
sudo ./scripts/virtual/lab-up.sh
MODE=netns ./scripts/02-no-address.sh
MODE=netns ./scripts/03-address.sh
MODE=netns ./scripts/04-arp.sh
sudo ./scripts/virtual/lab-down.sh
```

## What survives virtualization, and what doesn't

The conceptual core transfers exactly, because a namespace runs the very same Linux
network stack as the Pi. What doesn't transfer are the physical details—which is
the whole point: Layer 1 is the one layer you have to feel with real hardware.

| Stage | On hardware | In the namespace lab |
|---|---|---|
| Layer 1 | carrier, autonegotiation, Speed/Duplex | nothing to see: a veth has no PHY |
| Link-up chatter | DAD, MLD, RS, mDNS, DHCP Discover | DAD, MLD, RS fire; mDNS and DHCP don't (nothing runs avahi or a DHCP client) |
| Failed ping | leaks out `wlan0`, 0 received | "Network is unreachable" (no route at all), same lesson |
| ARP ⭐ | who-has → is-at → echo, cache hit on seq 2 | identical, down to the cache hit |

Two details from the diary are hardware-only:

- The 42-vs-60-byte tell (whether you sent or received a frame) vanishes, because a
  veth doesn't pad to Ethernet's 60-byte minimum—both the question and the answer
  come through at 42.
- The `b8:27:eb` vendor prefix is gone: virtual interfaces get random,
  locally-administered MACs (the kind with the LG bit flipped to 1), so the "every
  Pi shares a prefix" trick inverts.

## Captures

`captures/` is where committed reference pcaps will live, so anyone can open the
exchange in Wireshark without running a thing. (Coming soon—they need a fresh
capture on the hardware.)
