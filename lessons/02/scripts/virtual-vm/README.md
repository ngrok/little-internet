# Lesson 02 VM lab

Follow the [lesson runbook](../../README.md) to install the tools, start the
VMs, and work through the lesson. This page describes how the VM lab works.

```bash
# From lessons/02:
./scripts/virtual-vm/lab-up.sh
./scripts/virtual-vm/ssh-a
./scripts/virtual-vm/ssh-b
./scripts/virtual-vm/ssh-dhcp
./scripts/virtual-vm/link.sh a off
./scripts/virtual-vm/link.sh a on
./scripts/virtual-vm/lab-down.sh
```

`common.sh` reuses lesson 01's host architecture detection, acceleration,
firmware discovery, and QEMU launcher. It overrides guest provisioning, ports,
MACs, and state directory for this lesson. It doesn't start lesson 01.

Each QEMU `socket` netdev connects to `switch.py` on loopback. The switch learns
source MACs, floods broadcasts/multicasts and unknown unicast, forwards learned
unicast only to its destination port, and ages entries after five minutes.
It has no IP identity, DHCP server, physical PHY, VLAN, STP, or web management.
The framing follows [QEMU's socket backend](https://github.com/qemu/qemu/blob/master/net/socket.c).

Cloud-init configures only `mgmt`. A systemd `.link` file matches the lesson
interface by MAC and names it `eth0`. The provisioning script applies the name
on first boot; systemd applies it on later boots. NetworkManager owns `eth0`
and uses `dhclient` to match the published build log's Option 50 behavior.

All three VMs get the same tools, but only the `pi-dhcp` lesson steps start
dnsmasq. Its configuration uses `bind-dynamic` on `eth0` so it can start before
the NIC is ready after a reboot. It disables DNS and omits gateway and
DNS DHCP options. This keeps the lesson LAN separate from the management NATs.

NetworkManager-wait-online is disabled: an intentionally addressless lab NIC
should not delay guest boot. The management interface retains its own cloud-init
configuration. The host checks SSH access, installed tools, provisioning, and
NetworkManager. The runner separately checks whether the lesson needs a reset.
