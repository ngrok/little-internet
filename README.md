# The little internet

A hardware-based, reproducible **little internet** for learning how networking
*actually* works — built from Raspberry Pis, managed switches, and a pile of
Ethernet cables you can hold in your hands.

Most networking education is either too surface-level to be useful or too
academic to stick. This project takes the opposite approach: make the invisible
visible. Plug two Pis together and ask *why can't they just talk?* Then watch an
ARP request fly across the wire, a switch learn a MAC address, a router decide
where a packet goes next, and — eventually — a handful of autonomous systems
announce themselves to each other over BGP.

Everything here is meant to be **reproduced**. The bill of materials, the OS
image, the scripts, and the captured packets all live in this repo so you can
build your own little internet and follow along.

## How it's organized

The project grows in three phases. Each phase adds just enough hardware to make
the next set of ideas tangible.

- **Phase 1 — A network.** Two Pis and a managed switch. How do devices on the
  same network find and talk to each other? *ARP, MAC addresses, broadcast
  domains, Ethernet frames, packet capture, how switches work, VLANs, port
  mirroring, ARP cache poisoning.*
- **Phase 2 — Two networks.** Add a router. A Pi in network A can't reach a Pi
  in network B, so something has to decide where the packet goes next. *Routers,
  IPs, subnets, routing tables, NAT, traceroute.*
- **Phase 3 — The little internet.** Multiple autonomous networks that have to
  advertise their reachability to one another. *Autonomous systems, BGP, path
  selection, convergence* — plus side quests like DNS, TLS, and Pi-hole.

## Repo layout

```
.
├── README.md     You are here.
├── BOM.md        Bill of materials — every part, by phase, with vendors.
├── image/        pi-gen config that builds the Raspberry Pi OS image the
│                 nodes run, plus instructions for building and flashing it.
└── lessons/      (coming soon) One directory per lesson: an explainer, the
                  scripts to run it yourself, and recorded packet captures.
```

## Getting started

1. Gather the hardware. See [`BOM.md`](./BOM.md) for the full parts list by phase.
2. Get the node image. Download a prebuilt image from
   [Releases](../../releases), or build your own — either way, see
   [`image/`](./image/) for getting the Raspberry Pi OS image (built with
   [pi-gen](https://github.com/RPi-Distro/pi-gen)) and flashing it to your
   microSD cards.
3. Follow the lessons. (Coming soon — start with lesson 00, "why can't these two
   Pis just talk to each other?")

## Why we're building this

Networking is one of the most global and durable technologies a developer will
ever touch, and it isn't going anywhere. When its fundamentals are intuitive to
you, you become a better developer. This is our attempt to teach those
fundamentals in a way that's hands-on, reproducible, and — honestly — fun.
