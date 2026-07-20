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
can't build the hardware version, there are two **virtualized versions**: a
two-VM lab on macOS, and a lighter network-namespace lab on Linux.

### On hardware

You'll need two nodes flashed with the [little internet image](../../image/), an
Ethernet cable between their `eth0` ports, and SSH reachability to each over
Wi-Fi. Walk the whole lesson with one command:

The scripts are in this lesson's [`scripts/`](./scripts/) directory. Point them
at your nodes with `A_HOST` / `B_HOST` (they default to `pi@pi-foo-01.local` /
`pi@pi-foo-02.local`), then

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

No Pis? The closest thing to the real bench is the VM lab in
[`scripts/virtual-vm/`](./scripts/virtual-vm/): two separate Debian VMs (two
real kernels) joined by one QEMU socket cable. It costs a QEMU install and a
few minutes to boot, but it delivers the beats no lighter setup can: a Layer 1
carrier you can seat and unseat by hand (`./link.sh a off`), so the "is there
even a wire?" question is live in software too; two genuinely independent
machines; and cable NICs that wear the Pi's `b8:27:eb` vendor prefix. It also
ships a live web dashboard (`./dashboard.sh`): both nodes' link state, address,
ARP cache, and serial console, plus every frame crossing the wire. It runs on
macOS today; see its [`README.md`](./scripts/virtual-vm/README.md) for the
two-terminal runbook.

Want something quicker, or you're on Linux (or CI)? `./scripts/run.sh
--virtual` recreates the lesson with network namespaces instead. A veth pair is
the closest thing to a single cable—two ends, nothing in between—so it stands
up two namespaces (`pi-a` and `pi-b`) joined by one veth, walks the same steps
(pausing for you between each, just like the hardware path), and tears it all
down when you're done.

```bash
sudo ./scripts/check.sh --virtual
sudo ./scripts/run.sh --virtual
```

Network namespaces are a Linux feature, so this path needs a Linux machine—on
macOS or Windows, a Linux VM ([colima](https://github.com/abiosoft/colima) and
[lima](https://github.com/lima-vm/lima) both work).

### Inspect the recorded captures

You can inspect captures from the real Pis without running either lab. Each
exchange was recorded at both ends of the cable, so you can compare what
`pi-foo-01` and `pi-foo-02` observed:

- Link-up chatter: [`pi-foo-01`](./captures/link-up_pi-foo-01.pcapng) and
  [`pi-foo-02`](./captures/link-up_pi-foo-02.pcapng)
- ARP and ping: [`pi-foo-01`](./captures/arp_pi-foo-01.pcapng) and
  [`pi-foo-02`](./captures/arp_pi-foo-02.pcapng)

Open a capture in Wireshark, or read it from the lesson directory with
`tshark`:

```bash
tshark -r captures/link-up_pi-foo-01.pcapng -n
tshark -r captures/arp_pi-foo-02.pcapng -n
```

These are also the canonical evidence for a read-only walkthrough with a coding
agent: ask it to show you the decoded rows before explaining what they mean.

### With a coding agent

Agents should read the root [`AGENTS.md`](../../AGENTS.md) and this lesson's
[`manifest.json`](./manifest.json) before running anything. The manifest lists
the lesson beats, which scripts drive them, what output to look for, and how to
recover from interrupted hardware or virtual runs.

Ask the agent to **teach the lesson one beat at a time**. It should show you the
command and the relevant raw output, help you read the evidence, and wait for
your prediction or questions before continuing. A collapsed tool message like
"Ran 4 shell commands" is not the experiment—you should see the `ip`,
`ethtool`, routing, capture, and ARP evidence that supports each conclusion.

For packet captures in particular, expect to see the actual `tshark` or
`tcpdump` rows in a code block before the agent explains them. Frame-by-frame
prose is useful only when you can look back at the corresponding timestamps,
source and destination addresses, protocols, and summaries yourself. If the
capture is too long, the agent should label any excerpt and tell you what it
left out—not silently replace the capture with its conclusions.

For an interactive walkthrough, the agent should use the individual step
scripts rather than batch-running `scripts/run.sh`. The full runner is handy for
an unattended demonstration or functional check, but a coding agent's job here
is to provide the pacing and instruction that a shell script cannot.

#### What you can't see with virtualization

Even the VM lab ([`scripts/virtual-vm/`](./scripts/virtual-vm/)) has no PHY, so
some physical details are gone in any virtual run:

- Speed/Duplex details on the `eth0` device
- mDNS or DHCP firing on link-up
- the 42-vs-60-byte tell on whether your device sent or received ARP frames

The namespace lab loses two more. There's no carrier to seat or unseat, and no
`b8:27:eb`<->Raspberry Pi vendor prefix on MACs, because virtual interfaces get
random ones. The VM lab keeps both: it drives a real carrier, so the link
up/down beat is live, and it assigns the `b8:27:eb` prefix to its cable NICs on
purpose.
