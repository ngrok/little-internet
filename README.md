# The little internet

A hardware-based, reproducible **little internet** for learning how networking
actually works.

Networking is one of the most global and durable technologies you'll ever touch.
Its fundamentals are going nowhere, and when you make all those invisible layers
of the internet visible and intuitive to you, you become a better developer.

_And have some fun along the way._

## How I'm rolling out the little internet

We start with a single network, then two networks, and then a working facsimile
of the internet you know and love. Each phase comes with lessons as technical
write-ups ([ngrok blog](https://ngrok.com/blog)), YouTube videos
([ngrok @ YouTube](https://www.youtube.com/@ngrokHQ)), and follow-along scripts
in this repo.

Each phase includes just enough hardware to make the next set of ideas tangible.

- **Phase 1: a network.** Two Pis and a managed switch. How do devices on the
  same network find and talk to each other? _ARP, MAC addresses, broadcast
  domains, Ethernet frames, packet capture, how switches work, VLANs, port
  mirroring, ARP cache poisoning._
- **Phase 2: two networks.** Add a router. A Pi in network A can't reach a Pi in
  network B, so something has to decide where the packet goes next. _Routers,
  IPs, subnets, routing tables, NAT, traceroute._
- **Phase 3: the little internet.** Multiple autonomous networks that have to
  advertise their reachability to one another. _Autonomous systems, BGP, path
  selection, convergence_, plus side quests like DNS, TLS, and Pi-hole.

## Want to build your own?

1. Gather the hardware. See [`BOM.md`](./BOM.md) for the full parts list by
   phase.
2. Download a prebuilt image from [Releases](../../releases), or build your own.
   Either way, see [`image/`](./image/) for getting the Raspberry Pi OS image
   (built with [pi-gen](https://github.com/RPi-Distro/pi-gen)) and flashing it
   to your microSD cards.
3. Follow the lessons. Start with [`lesson 00`](./lessons/00/), "why can't these
   two Pis just talk to each other?"
4. Read the diaries for the story behind it all. They're the running build log
   of putting this together, in the order each piece came to life.

## Repo layout

```
.
├── README.md     You are here.
├── BOM.md        Bill of materials — every part, by phase, with vendors.
├── image/        pi-gen config that builds the Raspberry Pi OS image the
│                 nodes run, plus instructions for building and flashing it.
├── diaries/      Running build log of how the network came together, one
│                 prose file per session, in the order things happened.
└── lessons/      One directory per lesson: an explainer, the
                  scripts to run it yourself, and recorded packet captures.
```
