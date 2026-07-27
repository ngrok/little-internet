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

## Where this is going

The little internet is "done" when I have three networks, one acting as a
transit AS between the other two, and every host can talk to every other host
over BGP without any of them knowing the whole map. Getting there happens in
three phases:

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

Each step along the way is a question I'm unpuzzling. The [diary](./diaries/)
tells the story and the [lesson](./lessons) is the version you run yourself.
Particularly tasty protocol deep-dives get peeled off to the
[ngrok blog](https://ngrok.com/blog) and
[YouTube](https://www.youtube.com/@ngrokHQ). Read them in order, or jump to
whatever question hooks you:

| #   | The question                            | Read the story                                | Run it yourself            | Watch it                                             |
| --- | --------------------------------------- | --------------------------------------------- | -------------------------- | ---------------------------------------------------- |
| 00  | Two Pis, one cable: can they just talk? | [Diary 00](./diaries/00_two-pis-one-cable.md) | [Lesson 00](./lessons/00/) | [Video](https://www.youtube.com/watch?v=XIlKS4TVt74) |

## Want to build your own little internet?

1. Gather the hardware. See [`BOM.md`](./BOM.md) for the full parts list by
   phase.
2. Download a prebuilt image from [Releases](../../releases), or build your own.
   Either way, see [`image/`](./image/) for getting the Raspberry Pi OS image
   (built with [pi-gen](https://github.com/RPi-Distro/pi-gen)) and flashing it
   to your microSD cards.
3. Optionally, print a stand. Every release also has an STL for a
   [Pi 3 half-case with an integrated OLED stand](./hardware/pi3-oled-case/):
   the Pi drops in without screws and the display sits up where you can read it.
4. Follow the lessons. Start with [`lesson 00`](./lessons/00/), "two Pis, one
   cable: can they just talk?"
5. Read the diaries for the story behind it all. They're the running build log
   of putting this together, in the order each piece came to life. The
   [table above](#where-this-is-going) pairs each diary with its lesson.

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
├── tools/        Small scripts that run on a node: OLED smoke tests, the
│                 boot-time status display, the ARP-state viewer.
├── hardware/     Things you make: 3D-printable models for mounting the kit.
│                 See hardware/pi3-oled-case for the Pi 3 half-case with an
│                 integrated OLED stand.
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
