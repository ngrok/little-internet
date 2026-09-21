# Lesson 01 VM lab: two machines, one cable

Run two Debian VMs, each with its own kernel, joined by a QEMU socket cable.
Open two terminals to watch a frame leave one machine and arrive on the other.
Toggle the carrier to inspect how the interface responds to a disconnected link.

The [namespace lab](../virtual/) starts faster and uses fewer resources. Use
this VM lab to explore independent machines and controllable carrier events.

## How it maps to the hardware

| Physical bench | This lab |
|---|---|
| a Raspberry Pi | a QEMU process (its own Linux kernel) |
| the `eth0` Ethernet port | a virtio NIC renamed `eth0` |
| the Ethernet cable | a QEMU `socket` netdev: a direct Ethernet link |
| `wlan0` Wi-Fi you SSH over | a per-VM user-mode NAT (`ssh-a` / `ssh-b`) |
| the image's Wi-Fi isolation | automatic: the two NATs can't reach each other |
| seating / pulling the cable | `./link.sh a on` / `off` (real carrier change) |

The nodes reach each other over the lesson cable. Each also has a separate
management interface for SSH; captures on `eth0` show the lesson traffic.

## Requirements

Runs on **macOS** and **Linux**, and on **Windows** via WSL2 (which is Linux). The
lab auto-detects your CPU and picks the matching QEMU binary and Debian image
(Apple Silicon / arm64 or Intel / amd64).

- **QEMU**, plus a tool to build the seed ISO:
  - macOS: `brew install qemu` (uses HVF, no sudo; `hdiutil` is built in).
  - Debian/Ubuntu: `sudo apt-get install qemu-system xorriso` (uses KVM; you need
    access to `/dev/kvm`, e.g. add yourself to the `kvm` group).
  - Windows: do everything inside **WSL2** (Ubuntu), then follow the Linux steps.
- `python3` and `curl` (built into macOS; preinstalled on most Linux).
- About 2GB RAM free and 2GB disk. First boot needs internet (downloads the image
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

**Step 1: inspect the link.** On pi-a: `ip link show eth0` (expect `LOWER_UP`;
the cable is seated). From a third pane on the Mac, `./link.sh a off`, then look
again: `NO-CARRIER`. Bring it back with `./link.sh a on`.

**Step 3: inspect the address and route.** On pi-a:

```bash
ip -4 addr show eth0        # no inet — blank
ping -c1 -W1 10.10.0.2      # leaks out the mgmt NAT, 0 received (like wlan0 on a Pi)
```

**Steps 4–5: assign addresses, then watch ARP.** Leave a capture running on the right,
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

Compare the two echo sequences. The second can reuse the cached MAC address,
though scheduling and network delays mean it isn't always faster. Inspect the
cache with `ip neigh show dev eth0` on pi-a. The `b8:27:eb` Pi vendor prefix
is assigned deliberately to these virtual interfaces.

## Or watch it on the dashboard

One command stands up the lab (if it isn't already) and opens a live
black-and-white view of both nodes in your browser:

```bash
./dashboard.sh         # serves http://127.0.0.1:8099 and opens it
```

The dashboard shows:

- Both nodes' link state, `eth0` address, and ARP cache. Neighbor states use
  green for `REACHABLE`, amber for `STALE`/`DELAY`, and red for `FAILED`.
- Each node's serial console, following the newest lines.
- Frames crossing `eth0`, decoded by `tshark`. ARP is amber, ICMP requests
  are green, and ICMP replies are cyan.

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

A virtio network interface has no physical Ethernet transceiver (PHY).
QEMU changes its carrier state, but it doesn't negotiate physical speed or
duplex. Virtual frames also lack the hardware padding behavior that produces
the build log's 42-versus-60-byte ARP comparison. Use real hardware to observe
those details.
