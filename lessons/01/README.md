# Lesson 01: two Pis, one cable—do it yourself

This is the hands-on version of [build log
01](../../build-log/01_two-pis-one-cable.md): two machines, one cable, and a
question that sounds trivial until you try it: _Can they just... talk?_ You run
each step yourself and watch every answer show up on the wire.

For the story behind the experiment, read the
[build log](../../build-log/01_two-pis-one-cable.md) or [watch the video](https://www.youtube.com/watch?v=XIlKS4TVt74).
This lesson focuses on running the commands and reading their output.

## What you'll watch happen

"Talk" sounds simple, but it's hiding three questions, and you'll see each one
answer itself on the wire:

- Is there even a wire? (Layer 1: a dead port coming to life.)
- Are frames flowing? (Layer 2: the burst of chatter the instant the link comes
  up.)
- Can they reach each other by the address you'd type? (Layer 3: assign IPv4
  addresses, inspect the route, and watch ARP find the destination MAC.)

## How it runs

Run the scripts on the machine where you cloned this repo. They send commands
to two nodes: your [Raspberry Pis](../../BOM.md), two Debian VMs, or two Linux
network namespaces. Choose the setup that matches your environment.

### On hardware

You'll need two nodes flashed with the [little internet image](../../image/), an
Ethernet cable between their `eth0` ports, and SSH reachability to each over
Wi-Fi.

The scripts are in this lesson's [`scripts/`](./scripts/) directory. Point them
at your nodes with `A_HOST` / `B_HOST` (they default to `pi@pi-foo-01.local` /
`pi@pi-foo-02.local`), then

```bash
./scripts/check.sh --hardware
./scripts/run.sh        # walks every step, pausing between each
```

If you renamed the Pis, set their SSH destinations first:

```bash
export A_HOST=pi@pi-foo-01.local B_HOST=pi@pi-foo-02.local
./scripts/run.sh        # walks every step, pausing between each
```

Run an individual step to repeat an observation:

```bash
./scripts/01-link.sh        # is there a wire? unplug, then seat, the cable
./scripts/02-listen.sh      # capture link-up traffic, then try a ping
./scripts/03-no-address.sh  # inspect the route used by that ping
./scripts/04-address.sh     # give each node an identity
./scripts/05-arp.sh         # watch ARP resolve the peer’s MAC address
./scripts/reset.sh          # back to a blank wire
```

### Virtually

The [VM lab](./scripts/virtual-vm/) runs two Debian machines, each with its own
kernel, joined by a QEMU socket cable. Toggle the virtual carrier with
`./link.sh a off` or `on` and watch `eth0` change state. QEMU models the link
state; it doesn't reproduce physical speed negotiation.

The lab also has a [web dashboard](./scripts/virtual-vm/README.md#or-watch-it-on-the-dashboard)
for link state, addresses, ARP caches, serial consoles, and packet captures.
Follow its [runbook](./scripts/virtual-vm/README.md) for macOS or Linux/WSL2.

For a lighter Linux lab, use `./scripts/run.sh --virtual`. It creates two
network namespaces (`pi-a` and `pi-b`) joined by a veth pair, pauses through
the lesson, and removes the namespaces when you're done.

```bash
sudo ./scripts/check.sh --virtual
sudo ./scripts/run.sh --virtual
```

Network namespaces require Linux. On macOS, run this path inside a Linux VM;
on Windows, use WSL2.

### Pacing and color

Use `./scripts/run.sh` for hardware, `./scripts/run.sh --vm` for VMs, or
`sudo ./scripts/run.sh --virtual` for namespaces. Each phase starts with a
magenta banner, introduces a question, and pauses while you inspect the
output. Reading guides appear before packet tables. Explanations follow an
observation question, so you have time to interpret the evidence yourself.

Each phase ends with a review: think through your answer, press Enter to
reveal the explanation, then press Enter again to advance. The runner moves
between phases automatically. Individual scripts print the next command.

Both lessons use the same colors: white explanations, gray command output
and packet rows, teal command headings, bright yellow questions, and magenta
phase boundaries. `NO_COLOR=1` disables color; redirected output is plain text.
Packet tables pause every eight rows and retain every decoded row.

The link phase shows only the `ip` link summary and the relevant `ethtool`
fields. Run `ethtool eth0` in a node shell for the complete device report.
On hardware, the script still waits for you to unplug and reconnect the cable.
SSH and sudo prompts remain visible.

Link-up and ARP captures stay on pi-a under `/tmp/little-internet-01-*.pcap`.
Decoded rows are also saved on your workstation in
`~/.little-internet/lesson01/`; set `LESSON_OUTPUT_DIR` to change that directory.
The runner prints one evidence index at the end, including on failure.
Copy guest captures before deleting a guest disk; guest `/tmp` files may also
disappear on reboot. The workstation's decoded rows remain.

For an unattended virtual demonstration, add `--auto`:

```bash
./scripts/run.sh --vm --auto
sudo ./scripts/run.sh --virtual --auto
```

Hardware requires the cable handoffs and does not accept `--auto`. Without an
interactive terminal, ordinary reading prompts are skipped; an agent must
supply the pacing in the conversation. The runner stops on a failed phase.
Each phase is loaded before it starts, so editing a paused script takes effect
on its next launch. Virtual runners still create and stop their labs as before.

### Inspect the recorded captures

Inspect the recorded captures without running a lab. Compare the same
exchange from both ends of the cable:

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

For a read-only walkthrough with a coding agent, ask it to show these decoded
rows before explaining what they mean.

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

An agent with an interactive terminal can drive the runner one checkpoint at
a time. It must wait for your answer or physical action before advancing.
Use individual scripts when the tool cannot keep an interactive terminal open,
and supply the pacing in the conversation. `--auto` is for an explicitly
unattended virtual demonstration or development test.

#### What you can't see with virtualization

Virtual interfaces have no physical Ethernet transceiver (PHY), so they don't
reproduce speed negotiation or the 42-versus-60-byte padding difference in
hardware ARP captures. Link-up traffic also depends on the services installed
in each guest; it can differ from the Pis' mDNS and DHCP traffic.

The namespace lab has no cable control and uses randomly assigned MAC
addresses. The VM lab adds controllable carrier events and deliberately assigns
the Pi vendor prefix, `b8:27:eb`, to its virtual Ethernet interfaces.

## Developer checks

```bash
python3 -m unittest discover -s lessons/01/tests -v  # from the repo root
python3 -m unittest discover -s lessons/02/tests -v
```

The presentation checks use simulated transports and real terminal prompts.
They do not connect to Pis, change namespaces, or start VMs. Both lessons share
`lessons/shared/presentation.sh` for colors, packet paging, and review pacing.
