# Lesson 00 — two Pis, one cable: do it yourself

This is the runbook for [diary 00](../../diaries/00_two-pis-one-cable.md): two
machines, one link, and the question of whether they can just... talk. Here you
reproduce every beat on your own gear and watch each answer arrive on the wire.

This lesson is procedure, not theory. For the story and the *why*, read the
diary. For ARP frame by frame — cache states, padding, spoofing — read [ARP from
the ground up](LINK-TK).

## What you'll reproduce

The word "talk" hides three questions, and you'll watch each one answer itself on
the wire:

- whether there's a wire at all (Layer 1: a dead link waking up),
- whether frames are flowing (Layer 2: the burst of zero-config chatter the
  instant the link comes up), and
- whether the two nodes can reach each other by the address you'd type (Layer 3:
  why a wire with no identity is invisible to routing, and how ARP fixes it).

## Run it on hardware

You need two nodes flashed with the [little internet image](../../image/), an
Ethernet cable between their `eth0` ports, and an SSH session into each over
Wi-Fi. Parts are in [`BOM.md`](../../BOM.md).

The scripts in `scripts/` run the beats. Most run on pi-a; the addressing step
runs on both nodes. Each script prints what it's doing and the one line to watch
for.

```bash
# beat 1 — run this BEFORE and AFTER you seat the cable:
./scripts/00-link.sh

# beat 2 — capture the link-up burst (trigger the link while it runs):
./scripts/01-listen.sh

# beat 3 — the obvious thing fails, because the wire has no identity:
./scripts/02-no-address.sh

# beat 4 setup — give each node an identity (run on BOTH):
SELF_IP=10.10.0.1 ./scripts/03-address.sh   # on pi-a
SELF_IP=10.10.0.2 ./scripts/03-address.sh   # on pi-b

# beat 4 — watch ARP make the introduction:
./scripts/04-arp.sh

# put the wire back to blank when you're done:
./scripts/reset.sh
```

## Run it virtually, no hardware

You don't need Pis to see most of this. A veth pair is the closest software
analog to a single cable: two ends, nothing in between.
`scripts/virtual/lab-up.sh` builds two network namespaces (pi-a and pi-b) joined
by one veth, which gives you two independent network stacks on one wire with no
bridge, gateway, or DHCP in the way.

You need a Linux host and root. On macOS or Windows, run it inside a Linux VM
([colima](https://github.com/abiosoft/colima) and
[lima](https://github.com/lima-vm/lima) both work). The lab needs `ip`,
`tcpdump`, and `ping`.

```bash
sudo ./scripts/virtual/lab-up.sh     # build pi-a <--veth--> pi-b (blank link)
sudo ./scripts/virtual/demo.sh       # run beats 3-4 in one shot
sudo ./scripts/virtual/lab-down.sh   # tear it all down
```

To drive a node by hand instead, step into its namespace and run the same
commands the hardware runbook uses:

```bash
sudo ip netns exec pi-a bash         # you're now "on" pi-a
ip addr add 10.10.0.1/24 dev eth0    # ...and so on
```

## What survives virtualization, and what doesn't

The conceptual core transfers exactly, because a namespace runs the same Linux
network stack as the Pi. What doesn't transfer are the physical,
hardware-flavored details — which is the lesson's own point: Layer 1 is the one
layer you have to feel on real hardware.

| Beat | On hardware | In the namespace lab |
|---|---|---|
| 1 — Layer 1 | carrier, autonegotiation, Speed/Duplex | nothing to see: a veth has no PHY |
| 2 — link-up chatter | DAD, MLD, RS, mDNS, DHCP Discover | DAD, MLD, RS fire; mDNS and DHCP don't (nothing runs avahi or a DHCP client) |
| 3 — failed ping | leaks out `wlan0`, 0 received | "Network is unreachable" (no route at all) — same lesson |
| 4 — ARP ⭐ | who-has → is-at → echo, cache hit on seq 2 | identical, down to the cache hit |

Two specific facts from the diary are hardware-only:

- the 42-vs-60-byte tell (whether you sent or received a frame) doesn't appear,
  because a veth doesn't pad to Ethernet's 60-byte minimum — both the request and
  the reply come through at 42, and
- the `b8:27:eb` vendor prefix is gone, because virtual interfaces get random,
  locally-administered MACs (the kind whose LG bit is set to 1), so the "every Pi
  shares a prefix" observation inverts.

## Captures

`captures/` is where committed reference pcaps live, so a reader can open the
exchange in Wireshark without running anything. (Coming soon — these need a fresh
capture on the hardware.)
