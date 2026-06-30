# Diary 00: Two Pis, connected—can they just... talk?

"Talk" sounds so simple, but it requires concrete answers to three questions
that both lack intuitive answers and require a deeper understanding of
networking fundamentals than you might expect.

- Is there a wire?
- Are frames flowing?
- Can they reach each other by the address you type?

Let's learn _just as much as we need_ to answer those questions as we actually
build our way to a working connection.

## BC: Before Connection

In the beginning, the two Pis are not connected by an Ethernet cable.

I can verify that with the
[`ip`](https://man7.org/linux/man-pages/man8/ip.8.html) and
[`ethtool`](https://man7.org/linux/man-pages/man8/ethtool.8.html) Linux
utilities.

```bash
$ ip link show eth0

2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
    link/ether b8:27:eb:3a:e2:c8 brd ff:ff:ff:ff:ff:ff
```

```
$ sudo ethtool eth0

Settings for eth0:
        Supported ports: [ TP    MII ]
        Supported link modes:   10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
        Supported pause frame use: Symmetric Receive-only
        Supports auto-negotiation: Yes
        Supported FEC modes: Not reported
        Advertised link modes:  10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
        Advertised pause frame use: No
        Advertised auto-negotiation: Yes
        Advertised FEC modes: Not reported
        Speed: Unknown!
        Duplex: Unknown! (255)
        Auto-negotiation: on
        Port: Twisted Pair
        PHYAD: 1
        Transceiver: internal
        MDI-X: Unknown (auto)
        Supports Wake-on: pumbag
        Wake-on: d
        Current message level: 0x00000007 (7)
                               drv probe link
        Link detected: no
```

Your dead giveaways: `NO-CARRIER`, `DOWN`, and `Link detected: no`.

## Bring the Pis to life

Now, what do those same tools show on `pi-foo-01` when I connect the Ethernet
cable on both ends?

```bash
$ ip link show eth0

2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether b8:27:eb:3a:e2:c8 brd ff:ff:ff:ff:ff:ff
```

```bash
$ sudo ethtool eth0

Settings for eth0:
        Supported ports: [ TP    MII ]
        Supported link modes:   10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
        Supported pause frame use: Symmetric Receive-only
        Supports auto-negotiation: Yes
        Supported FEC modes: Not reported
        Advertised link modes:  10baseT/Half 10baseT/Full
                                100baseT/Half 100baseT/Full
        Advertised pause frame use: No
        Advertised auto-negotiation: Yes
        Advertised FEC modes: Not reported
        Link partner advertised link modes:  10baseT/Half 10baseT/Full
                                             100baseT/Half 100baseT/Full
        Link partner advertised pause frame use: No
        Link partner advertised auto-negotiation: Yes
        Link partner advertised FEC modes: Not reported
        Speed: 100Mb/s
        Duplex: Full
        Auto-negotiation: on
        Port: Twisted Pair
        PHYAD: 1
        Transceiver: internal
        MDI-X: Unknown (auto)
        Supports Wake-on: pumbag
        Wake-on: d
        Current message level: 0x00000007 (7)
                               drv probe link
        Link detected: yes
```

Aside from the lights on the Ethernet port giving you a clue that _something_
happened, these tools also reveal:

- `<NO-CARRIER,BROADCAST,MULTICAST,UP>` -> `<BROADCAST,MULTICAST,UP,LOWER_UP>`
- `DOWN` -> `UP`
- `Speed: Unknown!` -> `Speed: 100Mb/s`
- `Duplex: Unknown! (255)` -> `Duplex: Full`
- `Link detected: no` -> `Link detected: yes`

**Okay, I have Layer 1 of networking: a live wire.**

### What kind of "talking" do the Pis do on the wire at the moment of connection?

Capturing all this chatter, in the form of network frames, is exactly what tools
like `tshark` were designed for. With both Pis unplugged, I start up `tshark` on
both Pis to listen and capture everything in `.pcapng` files.

```bash
$ tshark -i eth0 -nPtd --color -w ~/cap/link-up_$(hostname).pcapng
```

What shows up in `tshark` when I plug the Ethernet cables back in?

```
1 0.000000000      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0xb41599cb
2 0.000083490      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x96cc4fa5
3 0.014863826           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
4 0.003233495           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
5 0.684038463           :: → ff02::1:ff18:e263 ICMPv6 86 Neighbor Solicitation for fe80::600f:9f10:ee18:e263
6 0.036725268           :: → ff02::1:ff25:a21c ICMPv6 86 Neighbor Solicitation for fe80::18d5:ef5b:eb25:a21c
7 0.251291608           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
8 0.004677976           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
9 0.731423368 fe80::600f:9f10:ee18:e263 → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
10 0.036680788 fe80::18d5:ef5b:eb25:a21c → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
11 0.073094337 fe80::18d5:ef5b:eb25:a21c → ff02::2      ICMPv6 62 Router Solicitation
12 0.108444393 fe80::600f:9f10:ee18:e263 → ff02::2      ICMPv6 62 Router Solicitation
13 0.057646759 fe80::18d5:ef5b:eb25:a21c → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::18d5:ef5b:eb25:a21c PTR, cache flush pi-foo-01.local SRV, cache flush 0 0 9 pi-foo-01.local
14 0.122903737 fe80::600f:9f10:ee18:e263 → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::600f:9f10:ee18:e263 PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
15 0.138246262      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x19cb3d5f
16 0.235561833 fe80::18d5:ef5b:eb25:a21c → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
17 0.012260488      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x15d971bf
18 0.207084184 fe80::600f:9f10:ee18:e263 → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
19 0.724115933 fe80::18d5:ef5b:eb25:a21c → ff02::fb     MDNS 249 Standard query response 0x0000 PTR _workstation._tcp.local PTR pi-foo-01 [b8:27:eb:3a:e2:c8]._workstation._tcp.local TXT, cache flush SRV, cache flush 0 0 9 pi-foo-01.local AAAA, cache flush fe80::18d5:ef5b:eb25:a21c
20 0.208121264 fe80::600f:9f10:ee18:e263 → ff02::fb     MDNS 212 Standard query response 0x0000 PTR pi-foo-02 [b8:27:eb:7d:e8:ee]._workstation._tcp.local TXT, cache flush SRV, cache flush 0 0 9 pi-foo-02.local AAAA, cache flush fe80::600f:9f10:ee18:e263
21 0.474254125 fe80::18d5:ef5b:eb25:a21c → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::18d5:ef5b:eb25:a21c PTR, cache flush pi-foo-01.local SRV, cache flush 0 0 9 pi-foo-01.local
22 0.183605909 fe80::600f:9f10:ee18:e263 → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::600f:9f10:ee18:e263 PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
23 1.587357382 fe80::600f:9f10:ee18:e263 → ff02::2      ICMPv6 62 Router Solicitation
24 0.292672889 fe80::18d5:ef5b:eb25:a21c → ff02::2      ICMPv6 62 Router Solicitation
25 0.395784084      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x9b447e7e
26 0.628896512      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0xcfc7ff48
27 6.522848232 fe80::600f:9f10:ee18:e263 → ff02::2      ICMPv6 62 Router Solicitation
28 1.017035781 fe80::18d5:ef5b:eb25:a21c → ff02::2      ICMPv6 62 Router Solicitation
29 0.033977233      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x272236f2
30 1.313535829      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x24a40786
```

You have two categories of frames here. First, attempts to find a DHCP server
that can give the Pi an IP address. The first two frames look like one device
retrying—but a retry would reuse its transaction ID, and these two differ. The
default columns hide the other half of the story, so I read the saved capture
back asking for just three fields: the frame number, the Ethernet source, and
the DHCP transaction ID.

```
$ tshark -r ~/cap/link-up_pi-foo-01.pcapng -n -c 2 -T fields \
  -e frame.number -e eth.src -e dhcp.id

1	b8:27:eb:7d:e8:ee	0xb41599cb
2	b8:27:eb:3a:e2:c8	0x96cc4fa5
```

Same transaction IDs as frames `1` and `2` up top, but two different Ethernet
sources. This capture is running on `pi-foo-01`, whose MAC is
`b8:27:eb:3a:e2:c8`. Frame `1` came from `b8:27:eb:7d:e8:ee`—that's `pi-foo-02`.
The very first frame `pi-foo-01` recorded wasn't even its own; it was its
neighbor already shouting for an address. Only on frame `2` does `pi-foo-01`
itself pipe up. The moment I seated the cable, `pi-foo-01` started listening,
and it could already hear `pi-foo-02` introducing itself over this single shared
link.

The wire is alive _and_ passing frames.

What's all the other mumbo-jumbo, then? Two important clues: `ICMPv6` and
`fe80::18d5:ef5b:eb25:a21c`. This isn't actually mumbo-jumbo, but rather the
diagnostic portion of the IPv6 protocol doing its job: announcing the device's
name, giving itself an IPv6 address, and finding neighbors.

By the end of this capture, both Pis are passing frames across the wire to
chatter about names and multicast DNS (mDNS) handshakes.

**I have Layer 2 of networking: my devices are broadcasting frames and using MAC
addresses to identify multiple devices.**

So...

## They really can `ping` each other now, right?

Let's try from `pi-foo-01`:

```
$ ping -c1 10.10.0.2

PING 10.10.0.2 (10.10.0.2) 56(84) bytes of data.

--- 10.10.0.2 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

No dice.

But what _really_ happened here? Let me look at the routing table for that IP
address.

```
$ ip route get 10.10.0.2

10.10.0.2 via 192.168.1.1 dev wlan0 src 192.168.1.5 uid 1000
    cache
```

I intended this `ping` to go out on the wire, but there's no route to
`10.10.0.2` because `eth0` has no address on that network. The Pi did the next
best thing: It sent the request out through `wlan0`. Wi-Fi! Fie!

**I'm learning the hard way that connectivity does not equal reachability.
Connectivity requires identity, too.**

Before we fix that, two quick asides.

### Why doesn't the `ping` work over Wi-Fi?

That one's easy to answer.

I baked firewall rules into the Pi images that prevent them from communicating
to anything through my Wi-Fi router. The reason is that I want to still `ssh`
into them remotely from my main workstation without adding an Ethernet-to-USB
adapter to each Pi and stringing cable all around my office, which is chaotic
enough as is.

Wi-Fi is the network on which I administer the little internet.

The little internet is only allowed to communicate over Ethernet.

Sneaky little trick.

### Well, what about IPv6?

The truth is that I _do_ know I could ping one Pi with another over IPv6. I saw
the `fe80::18d5:ef5b:eb25:a21c` and `fe80::600f:9f10:ee18:e263` from before.

But... that's not the experience I expected. That's not the way I've dealt with
local networks ever since I had more than one device on the local network, and
that's not about to change any time soon... even though mDNS seems quite sweet
and I need to learn more about it (very likely nerd snipe).

I expect IPs like `10.10.0.1`. I expect IPv4. That's the protocol I'm about to
fight with to get the experience I expect.

## Connectivity requires identity

Devices within networks are only reachable if they have an identity. It's time
to fix that.

I use [NetworkManager](https://networkmanager.dev/) to create new connections on
`eth0` with the specific IP addresses I expected to see from before.

```bash
# on pi-foo-01
$ sudo nmcli connection add type ethernet ifname eth0 con-name eth \
  ipv4.method manual ipv4.addresses 10.10.0.1/24 \
  ipv4.never-default yes ipv6.method link-local connection.autoconnect yes

# on pi-foo-02
$ sudo nmcli connection add type ethernet ifname eth0 con-name eth \
  ipv4.method manual ipv4.addresses 10.10.0.2/24 \
  ipv4.never-default yes ipv6.method link-local connection.autoconnect yes
```

Then, I start `tshark` on both Pis.

```bash
$ tshark -i eth0 -nPtd --color -f "arp or icmp" -w ~/cap/arp_$(hostname).pcapng
```

From another session on `pi-foo-01`, I can _finally_ ping the other Pi.

```bash
$ ping -c2 10.10.0.2

PING 10.10.0.2 (10.10.0.2) 56(84) bytes of data.
64 bytes from 10.10.0.2: icmp_seq=1 ttl=64 time=1.38 ms
64 bytes from 10.10.0.2: icmp_seq=2 ttl=64 time=0.704 ms

--- 10.10.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.704/1.044/1.384/0.340 ms
```

And `tshark` has captured all sorts of goodness for me. Here's `pi-foo-01`:

```
1 0.000000000 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 Who has 10.10.0.2? Tell 10.10.0.1
2 0.000593124 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 10.10.0.2 is at b8:27:eb:7d:e8:ee
3 0.000027552    10.10.0.1 → 10.10.0.2    ICMP 98 Echo (ping) request  id=0x0010, seq=1/256, ttl=64
4 0.000555988    10.10.0.2 → 10.10.0.1    ICMP 98 Echo (ping) reply    id=0x0010, seq=1/256, ttl=64 (request in 3)
5 0.999792156    10.10.0.1 → 10.10.0.2    ICMP 98 Echo (ping) request  id=0x0010, seq=2/512, ttl=64
6 0.000669842    10.10.0.2 → 10.10.0.1    ICMP 98 Echo (ping) reply    id=0x0010, seq=2/512, ttl=64 (request in 5)
7 4.160625093 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 Who has 10.10.0.1? Tell 10.10.0.2
8 0.000077604 b8:27:eb:3a:e2:c8 → b8:27:eb:7d:e8:ee ARP 42 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

And `pi-foo-02`:

```
1 0.000000000 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 60 Who has 10.10.0.2? Tell 10.10.0.1
2 0.000092811 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 42 10.10.0.2 is at b8:27:eb:7d:e8:ee
3 0.000457073    10.10.0.1 → 10.10.0.2    ICMP 98 Echo (ping) request  id=0x0010, seq=1/256, ttl=64
4 0.000130882    10.10.0.2 → 10.10.0.1    ICMP 98 Echo (ping) reply    id=0x0010, seq=1/256, ttl=64 (request in 3)
5 1.000266128    10.10.0.1 → 10.10.0.2    ICMP 98 Echo (ping) request  id=0x0010, seq=2/512, ttl=64
6 0.000153747    10.10.0.2 → 10.10.0.1    ICMP 98 Echo (ping) reply    id=0x0010, seq=2/512, ttl=64 (request in 5)
7 4.160484416 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 42 Who has 10.10.0.1? Tell 10.10.0.2
8 0.000597122 b8:27:eb:3a:e2:c8 → b8:27:eb:7d:e8:ee ARP 60 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

Let's break this down frame by frame from the perspective of `pi-foo-01`:

1. I ask the network (`ff:ff:ff:ff:ff:ff` is the MAC address reserved for such
   broadcasts) who has the IPv4 address I'm looking for: `10.10.0.2`.
2. I get a response back, not from the broadcast MAC, but another device with
   the MAC address `b8:27:eb:7d:e8:ee`, saying, "hey, it me."
3. Now that I have an answer, I send my ping.
4. I get a reply from `10.10.0.2`. Fantastic.
5. I send another, but this time, I don't need to ask again where `10.10.0.2`
   is, since I still have `b8:27:eb:7d:e8:ee` in memory.
6. I get _another_ reply. Wow!
7. I get a question from my friend over at `b8:27:eb:7d:e8:ee` about where
   `b8:27:eb:3a:e2:c8`.
8. I say back, "still here, pal."

That's a lot to ingest. I'll go through all this later, but for now:

**I now have Layer 3 of networking: the Pis can reach each other over IPv4.**

Seems like this ARP thing had something to do with that.

## Thanks, ARP. Who're you?

If Layer 2 of networking is MAC addresses and Layer 3 is IP addresses, then the
Address Resolution Protocol (ARP) is the bridge that gave our `pings` a route
out of the un-reachable doldrums.

I got nerd-sniped so hard by ARP that it's getting its own article. If you want
ARP frame by frame, with all the Ethernet padding, the cache states, and even
how it can be abused and poisoned—_ARP from the ground up_ is coming soon.

### Frame size tells you "did I send or hear that?"

Let me remind you of what a `tshark` capture from `pi-foo-01` looks like at the
moment of ARPing and pinging:

```
1 0.000000000 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 Who has 10.10.0.2? Tell 10.10.0.1
2 0.000593124 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 10.10.0.2 is at b8:27:eb:7d:e8:ee
...
7 4.160625093 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 Who has 10.10.0.1? Tell 10.10.0.2
8 0.000077604 b8:27:eb:3a:e2:c8 → b8:27:eb:7d:e8:ee ARP 42 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

The first ARP frame comes in at 42 bytes as it's leaving `pi-foo-01`. The second
frame, which indicates the ARP reply from `pi-foo-02`, is 60 bytes. That tells
us _something_. Now, if I superimpose another capture from `pi-foo-02` onto that
one and you're willing to squint a little...

```
1 ARP 42 Who has 10.10.0.2? Tell 10.10.0.1 | ARP 60 Who has 10.10.0.2? Tell 10.10.0.1
2 ARP 60 10.10.0.2 is at b8:27:eb:7d:e8:ee | ARP 42 10.10.0.2 is at b8:27:eb:7d:e8:ee
...
7 ARP 60 Who has 10.10.0.1? Tell 10.10.0.2 | ARP 42 Who has 10.10.0.1? Tell 10.10.0.2
8 ARP 42 10.10.0.1 is at b8:27:eb:3a:e2:c8 | ARP 60 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

It turns out Ethernet frames have a 60-byte minimum. When the ARP request heads
out, `pi-foo-01`'s kernel captures it and shows it in `tshark`, then stuffs the
frame with another 18 bytes before it hits the wire. Replies have already been
padded, so they show up at `60`.

Fun.

## So... can they talk?

When I started, "talk" was hiding three questions. I've now watched each one
answer itself on the wire:

- **Is there a wire?** Instantly. The moment I seated the cable, Layer 1 woke up
  without any input from me.
- **Did they start chatting?** Yes—but through only IPv6, which I didn't know to
  listen for at the very beginning.
- **Can they reach each other by the IPv4 address I've been trained to type?**
  Only after I gave each Pi an identity and let ARP make the introduction.
  That's the one answer I had to actually _work_ for rather than sniff out what
  was already happening.

So—yes, of course they can talk. It just wasn't working in the way _I_ expected,
which was to type `ping 10.10.0.2`, hit `Enter`, and watch a packet find its way
there. But that wasn't a wire or frame problem, but an **identity** problem.
Turns out ARP is the solution to that problem over Ethernet.

The connectivity was free. The reachability I wanted needed an identity.

## What's next?

Two Pis on one cable is the smallest network there is: a broadcast domain of
two. When `pi-foo-01` screamed `who has 10.10.0.2?` into the room, there was
exactly one other device to hear it—so "broadcast to everyone" and "ask the only
other guy in the room" looked like the same thing.

That stops being true the moment I add a third node and a switch. Now a
broadcast really does hit _everyone_, and the switch has to make a call it never
had to make before: a frame comes in addressed to one specific MAC—which port
does it send it out? How does it even know?

That's lesson 01.
