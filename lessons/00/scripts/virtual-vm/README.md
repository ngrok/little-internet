# Lesson 00 — the VM lab: two machines, one bare cable

This is the heavier virtual lab: two **separate Debian VMs** (their own kernels)
joined by one **bare QEMU socket cable**, driven from **two terminals side by
side** so you can watch a frame leave one machine and arrive on the other. It
sits alongside the lighter [`../virtual/`](../virtual) namespace lab.

Use the namespace lab for an instant, zero-boot look at ARP. Use this one when
you want two genuinely separate machines and — the payoff the namespace lab
can't give you — a **Layer 1 carrier you can seat and unseat by hand**.

## How it maps to the hardware

| Physical bench | This lab |
|---|---|
| a Raspberry Pi | a QEMU process (its own Linux kernel) |
| the `eth0` Ethernet port | a virtio NIC renamed `eth0` |
| the Ethernet cable | a QEMU `socket` netdev — pure L2, nothing in between |
| `wlan0` Wi-Fi you SSH over | a per-VM user-mode NAT (`ssh-a` / `ssh-b`) |
| the image's Wi-Fi isolation | automatic — the two NATs can't reach each other |
| seating / pulling the cable | `./link.sh a on` / `off` (real carrier change) |

The two nodes can reach each other **only** over the cable, exactly as the
hardware image enforces — so anything you see on `eth0` really crossed the wire.

## Requirements

- A Mac with **QEMU**: `brew install qemu` (HVF acceleration, no sudo needed).
  Apple Silicon and Intel both work — the lab picks the matching QEMU binary
  and Debian image automatically.
- Built-in `hdiutil`, `python3`, and `curl` — already present on macOS.
- ~2GB RAM free and ~2GB disk. First boot needs internet (downloads the image
  and installs `tcpdump` in the guests).

## Bring it up

```bash
./lab-up.sh        # downloads Debian once, boots pi-a + pi-b, waits for SSH
```

It prints the two SSH commands when the nodes are ready. Everything it creates
lives in `~/.little-internet/lab00-vm/`, not in the repo.

## Run it in two terminals

Open two panes. Left is pi-a, right is pi-b.

```bash
# LEFT pane                          # RIGHT pane
./ssh-a                              ./ssh-b
```

**Beat 1 — is there a wire?** On pi-a: `ip link show eth0` (expect `LOWER_UP` —
the cable is seated). From a third pane on the Mac, `./link.sh a off`, then look
again: `NO-CARRIER`. Bring it back with `./link.sh a on`.

**Beat 3 — the wire has no identity.** On pi-a:

```bash
ip -4 addr show eth0        # no inet — blank
ping -c1 -W1 10.10.0.2      # leaks out the mgmt NAT, 0 received (like wlan0 on a Pi)
```

**Beat 4 — ARP makes the introduction.** Leave a capture running on the right,
then address both ends and ping from the left:

```bash
# RIGHT pane (pi-b): leave this running
sudo tcpdump -i eth0 -n -e

# LEFT pane (pi-a):
sudo ip addr add 10.10.0.1/24 dev eth0
#   and on pi-b:  sudo ip addr add 10.10.0.2/24 dev eth0
ping -c2 10.10.0.2
```

On the right you'll watch the exchange arrive, frame by frame:

```
ARP, Request who-has 10.10.0.2 tell 10.10.0.1
ARP, Reply  10.10.0.2 is-at b8:27:eb:00:00:02
IP 10.10.0.1 > 10.10.0.2: ICMP echo request
IP 10.10.0.2 > 10.10.0.1: ICMP echo reply
```

Note `seq 2` is faster than `seq 1` — that's the ARP cache. Check it with
`ip neigh show dev eth0` on pi-a (expect `10.10.0.2 ... REACHABLE`), and note the
`b8:27:eb` Pi vendor prefix, reproduced here on purpose.

## Or watch it on the dashboard

One command stands up the lab (if it isn't already) and opens a live
black-and-white view of both nodes in your browser:

```bash
./dashboard.sh         # serves http://127.0.0.1:8099 and opens it
```

- **pi-a and pi-b side by side**: link state (`LINK UP` / `NO CARRIER`), the
  `eth0` address, and the ARP cache, with each neighbor's state color-coded
  (`REACHABLE` green, `STALE`/`DELAY` amber, `FAILED` red).
- **Each node's serial console**, following the newest lines.
- **The wire**: every frame crossing `eth0`, streamed via `tshark` and
  color-coded (ARP amber, ICMP request green, ICMP reply cyan).

Panels refresh once a second with sticky auto-scroll: pinned to the newest
line, but you can scroll up to read without it snapping back. It pairs well
with the runbook above: run the beats in the two SSH panes and watch the
dashboard react, or `./link.sh a off` and watch pi-a flip to `NO CARRIER`.

Ctrl-C stops the dashboard; the lab keeps running. `dashboard.py` is Python
stdlib only (nothing to install), and the wire view uses the `tshark` that
`lab-up.sh` puts on the nodes. Set `DASH_PORT` to serve on a different port.

## Reset a node to the blank wire

```bash
sudo ip addr flush dev eth0
sudo ip neigh flush dev eth0
```

## Tear down

```bash
./lab-down.sh          # stop both VMs (keeps disks, so next boot is fast)
./lab-down.sh --wipe   # also delete the node disks for a factory-fresh boot
```

## What still doesn't transfer

Two kernels and a real carrier close most of the gap, but a virtio NIC has **no
PHY**, so link speed / duplex / autonegotiation aren't real (only the carrier
up/down event is). And short frames likely aren't padded to Ethernet's 60-byte
minimum, so the diary's 42-vs-60-byte "did I send or receive this?" tell may not
appear. Layer 1's physical texture is still the part you only fully feel on metal.
