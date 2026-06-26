# Lesson 00: two Pis, one cable—do it yourself

This is the hands-on version of [diary
00](../../diaries/00_two-pis-one-cable.md): two machines, one cable, and a
question that sounds trivial until you try it: _Can they just... talk?_ You run
each step yourself and watch every answer show up on the wire.

This part is all procedure, not story. For the _why_, read the
[diary](../../diaries/00_two-pis-one-cable.md). For a frame-by-frame deep-dive
into what the Address Resolution Protocol is, from cache states to actually
poisoning it, read _ARP from the ground up_ (coming soon!).

## What you'll watch happen

"Talk" sounds simple, but it's hiding three questions, and you'll see each one
answer itself on the wire:

- Is there even a wire? (Layer 1: a dead port coming to life.)
- Are frames flowing? (Layer 2: the burst of chatter the instant the link comes
  up.)
- Can they reach each other by the address you'd type? (Layer 3: why a wire with
  no identity is invisible to the routing table, and how ARP fixes it.)

## How it runs

The scripts live on your machine where you clone this repo and drive two nodes.

For anyone who's built a [hardware version](../../BOM.md) of the little internet
themselves (bless you), those nodes will be your two Pis. If you don't want or
can't built the hardware version, there's also a **virtualized version** you can
run on any Linux machine (or a VM on Windows or macOS).

### On hardware

You'll need two nodes flashed with the [little internet image](../../image/), an
Ethernet cable between their `eth0` ports, and SSH reachability to each over
Wi-Fi. Walk the whole lesson with one command:

Point the scripts at your nodes with `A_HOST` / `B_HOST` (they default to
`pi@pi-foo-01.local` / `pi@pi-foo-02.local`), then

```bash
./scripts/check.sh --hardware
./scripts/run.sh        # walks every step, pausing between each
```

If you changed your Pi's names from the default, you'll need to set them.

```bash
export A_HOST=pi@pi-foo-01.local B_HOST=pi@pi-foo-02.local
./scripts/run.sh        # walks every step, pausing between each
```

Each step is also its own script, so you can run or re-run just one:

```bash
./scripts/00-link.sh        # is there a wire? unplug, then seat, the cable
./scripts/01-listen.sh      # the link-up burst, then a naive ping that flops
./scripts/02-no-address.sh  # so where did that packet actually go?
./scripts/03-address.sh     # give each node an identity
./scripts/04-arp.sh         # the ping works now—watch the ARP that made it
./scripts/reset.sh          # back to a blank wire
```

### Virtually

No Pis? `./scripts/run.sh --virtual` recreates the whole thing in software. A
veth pair is the closest thing to a single cable—two ends, nothing in between—so
it stands up two network namespaces (`pi-a` and `pi-b`) joined by one veth,
walks the same steps (pausing for you between each, just like the hardware
path), and tears it all down when you're done.

Network namespaces are a Linux feature, so on macOS or Windows, run it inside a
Linux VM ([colima](https://github.com/abiosoft/colima) and
[lima](https://github.com/lima-vm/lima) both work).

```bash
sudo ./scripts/check.sh --virtual
sudo ./scripts/run.sh --virtual
```

### With a coding agent

Agents should read the root [`AGENTS.md`](../../AGENTS.md) and this lesson's
[`manifest.json`](./manifest.json) before running anything. The manifest lists
the lesson beats, which scripts drive them, what output to look for, and how to
recover from interrupted hardware or virtual runs.

#### What you can't see with virtualization

A network namespace runs the same Linux stack as the Pi, but you can't see the
physical details. That includes no:

- Carrier or Speed/Duplex details on the `eth0` device
- mDNS or DHCP firing on link-up
- 42-vs-60-byte tell on whether your device sent or received ARP frames, because
  veth doesn't pad to Ethernet's 60-byte minimum
- `b8:27:eb`<->Raspberry Pi vendor prefix on MACs, because virtual interfaces
  get random MACs.
