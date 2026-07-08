# The little internet

A hardware-based, reproducible **little internet** for learning how networking
actually works.

Networking is one of the most global and durable technologies you'll ever touch.
Its fundamentals are going nowhere, and when you make all those invisible layers
of the internet visible and intuitive to you, you become a better developer.

Everything here is meant to be **reproduced**. The bill of materials, the OS
image tooling, and the lesson scripts all live in this repo so you can build
your own little internet and follow along.

_And have some fun along the way._

## How I'm rolling out the little internet

I'm going from single network, then two networks, and then a working facsimile
of the internet you know and love.

As I go, I'll write [diaries](./diaries/) that track questions I'm asking about
the little internet and the paths I've taken to unpuzzle and understand them.
Each of those gets a hands-on [lesson](./lessons) you can run yourself. I'll
also peel off particularly tasty deep-dives on different protocols over to the
[ngrok blog](https://ngrok.com/blog) and
[YouTube](https://www.youtube.com/@ngrokHQ).

Here's the whole big picture:

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

## Want to build your own little internet?

1. Gather the hardware. See [`BOM.md`](./BOM.md) for the full parts list by
   phase.
2. Download a prebuilt image from [Releases](../../releases), or build your own.
   Either way, see [`image/`](./image/) for getting the Raspberry Pi OS image
   (built with [pi-gen](https://github.com/RPi-Distro/pi-gen)) and flashing it
   to your microSD cards.
3. Follow the lessons. Start with [`lesson 00`](./lessons/00/), "two Pis, one
   cable: can they just talk?"
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
├── lessons/      One directory per lesson: an explainer, the scripts to run
│                 it yourself, and recorded packet captures. Start with
│                 lessons/00.
└── AGENTS.md     Guidance for coding agents that teach or operate the labs.
```

## Using a coding agent

Coding agents can teach from the docs, run the Linux virtual lab, or drive real
Pis over SSH while you handle the cable and hardware. Point them at
[`AGENTS.md`](./AGENTS.md) first; lesson 00 also has a machine-readable
[`manifest.json`](./lessons/00/manifest.json) with beats, commands, expected
observations, and recovery steps.

## Contributing

Want to help? Open an issue or email me at joel@ngrok.com.

A few directions I'd especially love help with:

- **Virtualization.** This is the big one. I build on real hardware and base
  everything on the reality of the hardware, but plenty of people won't want to
  buy the kit (or spend the money) and should still be able to learn what
  everyone else is learning. How do we virtualize the little internet (VMs,
  containers, network namespaces, whatever fits) without losing the things that
  make the hardware version click?
- **Agent accessibility.** How do we make these lessons work alongside coding
  agents? Maybe that's agent skills built around each lesson that help you
  understand the material, or maybe it's something else entirely. Open to ideas.
- **The learning experience.** I could use advice on making this sticky and
  tangible: other modes of learning, other ways of teaching, anything that helps
  the ideas stick.
