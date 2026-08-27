# Diary 02: A switch, a third Pi, and who hands out the addresses?

At the end of the last diary, I promised I'd throw a switch into the mix and see
what changed.

Spoiles: _nothing_.

That's a bit disappointing at first glace, but it's also the _right kind_ of
disappointing, because it's forced me to reckon with how little the Little
Internet feels networks I've been using since a kid. Here, I have to type out IP
addresses to make Pis reachable, but that's not it work when you plug a NUC into
your router or join the coffee shop Wi-Fi.

So this one is three questions again:

- Does a switch buy me anything that one cable didn't?
- If not, who hands out the addresses?
- Can I watch that happen, frame by frame, the way I watched ARP?

<!-- TK: video link once the cut is published. Same pattern as diary 01:
[![Diary 02 as a video: ...](https://img.youtube.com/vi/TKTKTKTK/maxresdefault.jpg)](https://www.youtube.com/watch?v=TKTKTKTK)
-->

## First, the desk got nicer

I'll get this out of the way quick.

The Pis used to just slide freely around the desk, and the OLEDs flopped around
on their wires, which meant I was holding them down with something akin to Silly
Putty. It's a fun aesthetic, but terribly annoying.

I've now 3D-printed half-shell cases that screw straight into the desk, with
little pins that hold the board so it can't wiggle around. Each case also has an
OLED "tower" the panel snaps into and an escape hatch so the wires can sneak out
while staying clean.

_And it's color-coded._

<!-- TK: insert picture of the cases
[![]()
-->

That matters, because the with the OLEDs, I can quickly see every Pi's identity
without SSHing anywhere. When an address gets assigned, it appears on the desk.

The new networking hardware is one [TP-Link TL-SG108E](BOM.md#): eight ports,
about $30. I picked the cheapest managed switch I could find that still does
VLANs and port mirroring, because I know I'll want both of those later.

Remember the word "managed."

## Question 1: does the switch change anything?

I start with both Pis powered on, both OLEDs reading `eth0 (down)`, nothing
plugged into the switch.

I already learned in [diary 01](./01_two-pis-one-cable.md) how to prove there's
no wire, so I'm not running `ip link` and `ethtool` again. `NO-CARRIER`, `DOWN`,
`Link detected: no`. We know. What I want this time is the frames, so I start
`tshark` on both Pis before I touch a cable.

```bash
$ tshark -i eth0 -nPtd -w ~/cap/lesson-02_link-switch_$(hostname).pcapng
```

Then I plug both Pis into the switch, and get a familiar flood.

Here's a slice from `pi-foo-01`:

```
148 0.830323998 fe80::9f6b:39f6:7299:8c81 → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
149 0.021505074 fe80::ba27:ebff:fe3a:e2c8 → ff02::2      ICMPv6 62 Router Solicitation
150 0.151921810 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
151 0.022595962 fe80::9f6b:39f6:7299:8c81 → ff02::2      ICMPv6 62 Router Solicitation
152 0.121537136 fe80::9f6b:39f6:7299:8c81 → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::9f6b:39f6:7299:8c81 PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
153 0.546290783 fe80::9f6b:39f6:7299:8c81 → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
154 0.307131821 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
155 0.197981416      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0xcedca005
156 0.339808741 fe80::9f6b:39f6:7299:8c81 → ff02::fb     MDNS 249 Standard query response 0x0000 PTR _workstation._tcp.local PTR pi-foo-02 [b8:27:eb:7d:e8:ee]._workstation._tcp.local TXT, cache flush SRV, cache flush 0 0 9 pi-foo-02.local AAAA, cache flush fe80::9f6b:39f6:7299:8c81
157 0.369525854      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0xbd08d08
158 0.093715326 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
159 0.232418321 fe80::9f6b:39f6:7299:8c81 → ff02::fb     MDNS 284 Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::9f6b:39f6:7299:8c81 PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
160 0.768017688 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
161 0.004437353  192.168.0.1 → 255.255.255.255 DHCP 321 DHCP Discover - Transaction ID 0x3167
162 0.999070299 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
163 0.070596945 fe80::9f6b:39f6:7299:8c81 → ff02::2      ICMPv6 62 Router Solicitation
164 0.927527051 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
165 0.594772119      0.0.0.0 → 255.255.255.255 DHCP 329 DHCP Discover - Transaction ID 0x8bee0bb4
166 0.406249257 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
167 0.069371904           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
168 0.512043920           :: → ff02::16     ICMPv6 110 Multicast Listener Report Message v2
169 0.419024910 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
170 1.003741847 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
171 0.004427928  192.168.0.1 → 255.255.255.255 DHCP 321 DHCP Discover - Transaction ID 0x2eac
```

I've seen most of that before. `DHCP Discover` from `0.0.0.0`, because a Pi with
no address can only shout into the room. And remember how they use mDNS and
ICMPv6 to find each other over IPv6 right away? That's all still there.

And it's _exactly_ th esame as what happened with one cable and no switch.

**The switch gave me Layer 1 and Layer 2 and not one thing more. For two nodes,
it's a $30 replacement for a $2 cable.**

## But the switch has opinions of its own

I found two new rows in that capture that act as compelling evidence that that
every device on a shared link can hear every other device's questions.

The first is that `Realtek 60` line, showing up roughly once a second:

```
150 0.151921810 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff Realtek 60
```

`3c:78:95:3e:f4:62` isn't a Pi, but the switch. It's hanging out, introducing
itself to no one in particular, on a proprietary Realtek layer-2 protocol, in a
60-byte frame, to the broadcast address. _Forever_.

<!-- TK: confirm from the pcap which ethertype these carry before I state it as fact.
My read is loop detection: a switch that can't see its own frames come back
around is a switch that isn't wired into a loop. It could also be a plain
keepalive.
-->

The second one is the good one:

```
161 0.004437353  192.168.0.1 → 255.255.255.255 DHCP 321 DHCP Discover - Transaction ID 0x3167
```

That's the switch asking for an IP address.

Remember "managed"? A managed switch has a web UI, and a web UI needs an address
to live at. So the switch boots, asks the network for one, gets no answer, and
falls back to its hardcoded default of `192.168.0.1`. Then it asks again. And
again. For the entire recording, this thing is standing in my little internet
holding up a sign that says _does anybody here hand out addresses_, and the
answer is no.

**Nothing on this network can give anything else an identity. Not the Pis, not
the switch, not me until I type it.**

## Fine, I'll type it... again

I wanted to quickly check whether the manual approach from the lesson 01 still
worked through a switch instead of a bare cable. My gut said _yes_, but I had to
be extra sure. Unplug both, create the profiles, restart the captures, `ping`.

```bash
# on pi-foo-01
$ sudo nmcli connection add type ethernet ifname eth0 con-name eth \
  ipv4.method manual ipv4.addresses 10.10.0.1/24 \
  ipv4.never-default yes ipv6.method link-local \
  connection.autoconnect yes connection.autoconnect-priority 10

# on pi-foo-02, same but 10.10.0.2/24
```

The ping went through, and I saw the same ARP request<>reply and echo
request<>reply as before. The switch is just, as I said before, a longer and
more expensive cable path.

That confirmed two things for me.

**A switch moves frames, not create identities. When people say "router," most
of what they mean is the part that hands out identities, and this box does not
have that part.**

## So, who the heck hands out the addresses?

The obvious move is to buy a switch that _does_ have that part. That's pretty
much any $80 home router with a DHCP server baked in.

Plug it in, done.

But I'm not going to do that, for the same reason I'm not just virtualizing all
this with [Kathara](https://www.kathara.org/) or something similar. If I'm going
to hold onto any of this, I need it to be tangible. Memorable! If a black box I
don't understand and can't observe does all the work for me, I don't learn a
thing. If a Raspberry Pi hands out the addresses, I get to run `tshark` on both
ends of every conversation and see exactly how a device goes from "no identity"
to "identity" in four frames.

So, it's time for a _third Pi_. New case, new OLED, new microSD, hostname
`pi-foo-dhcp`. Its entire job in life (so far) is to run a DHCP server.

I plug it into the switch and, exactly as expected, it gets no address, because
of course it doesn't. Nothing has changed yet. But it looks lovely.

Then I reset all three nodes back to nothing: no profiles, addresses, or
identities; a blank wire; and a Pi with `dnsmasq` installed on it.

## Failure 1: dnsmasq is installed but does absolutely nothing

I picked [`dnsmasq`](https://thekelleys.org.uk/dnsmasq/doc.html) because it's
the small and boring choice. It comes packaged with Raspberry Pi OS.

I install it, but it's not handing out anything. I open `/etc/dnsmasq.conf`,
which turns out to be a genuinely enormous file where nearly every line is a
comment explaining an option that is not on.

At this point, I figured I would most likely stumble into a working DHCP setup
rather than nail it exactly right, so I started up `tshark` on the Pis just to
feel safe I'd record them in the momennt.

```bash
$ tshark -i eth0 -f "arp or (udp and (port 67 or port 68))" \
  -w ~/cap/dhcp_$(hostname).pcapng
```

That filter is ARP, plus UDP on ports 67 and 68, which is where DHCP lives.

## Failure 2: `/etc/init.d/dnsmasq restart`, denied

Down around line 143 of `dnsmasq.conf`, under a comment block that says
"Uncomment this to enable the integrated DHCP server," there's a commented
example range. I add mine right underneath it:

```
#dhcp-range=192.168.0.50,192.168.0.150,12h
dhcp-range=10.10.0.0,10.10.0.10,12h
```

Ten addresses and a twelve-hour lease. I picked ten because if the little
internet ever needs eleven addresses on one segment, I have gone fully off the
deep end with this project.

Save, restart, and:

<!-- AGENT: We need to replace this with the not-fat-fingered password version. Just not worth the effort. -->

```
pi@pi-foo-dhcp:~ $ /etc/init.d/dnsmasq restart

Restarting dnsmasq (via systemctl): dnsmasq.service==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
Authentication is required to restart 'dnsmasq.service'.
Authenticating as: ,,, (pi)
Password:
polkit-agent-helper-1: pam_authenticate failed: Authentication failure
==== AUTHENTICATION FAILED ====
Failed to restart dnsmasq.service: Access denied
See system logs and 'systemctl status dnsmasq.service' for details.
 failed!
```

## Failure 3: the server is running and nothing is happening

Now `dnsmasq` is up with a range configured. The two Pis are plugged into the
switch. The OLEDs still say `eth0 (no IPv4)`. The captures on both Pis are
counting frames but nothing matching my filter is showing up.

I go poking. SSH into `pi-foo-01`, try a ping, nothing. Watch the OLEDs,
nothing. Read more of the config, find the `interface=` option that the Debian
wiki says tells `dnsmasq` which interface it's allowed to serve on, and start to
circle the actual answer.

For a DHCP server to answer a `DHCPDISCOVER` and hand out an address to anyone
else, it first needs to have a live interface _with an address of its own_.

But my new DHCP had no address at all. It had a pool of ten identities it was
willing to give away, but couldn't hand out reachability because it wasn't
reachable itself.

So I used `nmcli` one more time, on the server this time:

```bash
pi@pi-foo-dhcp:~ $ sudo nmcli connection add type ethernet ifname eth0 con-name eth \
  ipv4.method manual ipv4.addresses 10.10.0.0/24 \
  ipv4.never-default yes ipv6.method link-local \
  connection.autoconnect yes connection.autoconnect-priority 10

Connection 'eth' (d3ed4e53-42da-42d0-885a-b2f667276a2b) successfully added.
```

<!-- TK: I should probably account for this in the video, too -->

`10.10.0.0`. The OLED lights up with it. (Yes, `.0`. Assigning the network
address to a host is a weird flex that Linux will happily let you do, and it's
sitting inside the range I'm handing out. It has caused me exactly zero problems
and I am going to fix it anyway, on principle, at some point. TK: decide whether
the lab standard becomes `.0` or something saner before this ships as a lesson.)

**A server that hands out identity needs one first. Obvious in hindsight; not
obvious at all while staring at a config file.**

## It worked, and I didn't notice for two minutes

I was still mid-sentence explaining what I was going to try next when I glanced
down at the desk.

Both Pis had addresses on their OLEDs.

I did not type those. Nobody typed those. `pi-foo-01` asked the room for an
identity, `pi-foo-dhcp` answered, and the OLED on the case printed the result a
second later. That's the thing I've been trying to build for weeks: not "I can
configure a network," but "I can plug a thing in and the network absorbs it."

Then I looked closer:

- `pi-foo-01` → `10.10.0.4`
- `pi-foo-02` → `10.10.0.1`

Hostname says one, address says four. Hostname says two, address says one.

It works perfectly and it is deeply, personally offensive. Park that; it becomes
the last act.

## Failure 4: I broke my own capture

I went to show the DHCP conversation that had just made all this happen, and my
`tshark` panes had nothing in them but a rising frame count.

Look at the command again:

```bash
$ tshark -i eth0 -f "arp or (udp and (port 67 or port 68))" \
  -w ~/cap/dhcp_$(hostname).pcapng
```

Compare it to the one I ran at the top of this diary:

```bash
$ tshark -i eth0 -nPtd -w ~/cap/lesson-02_link-switch_$(hostname).pcapng
```

I dropped `-nPtd`. `-w` writes packets to a file, and on its own it writes them
_instead_ of printing them. `-P` is what says "also print the summary line while
you're writing." No `-P`, no show.

So the frames were saved and I never got to watch them land, which is the entire
reason I'm doing this on Raspberry Pis instead of buying a router. The pcap is
fine. My timing was not.

Honestly, the mistake made the next part better, because the fix isn't "read the
file I already have," it's "do the whole thing again and watch it happen live."
Which is what I wanted anyway.

Before I did, one quick check that everything really was as good as it looked:

```
pi@pi-foo-01:~ $ ping -c1 10.10.0.1

PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.
64 bytes from 10.10.0.1: icmp_seq=1 ttl=64 time=1.25 ms

--- 10.10.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.251/1.251/1.251/0.000 ms

pi@pi-foo-01:~ $ ping -c1 10.10.0.0

PING 10.10.0.0 (10.10.0.0) 56(84) bytes of data.
64 bytes from 10.10.0.0: icmp_seq=1 ttl=64 time=0.631 ms

--- 10.10.0.0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.631/0.631/0.631/0.000 ms
```

Both Pis reach each other, and both reach the DHCP server at `10.10.0.0`. The
weird `.0` address answers pings like any other host. Noted, still cursed,
moving on.

Then the corrected command on both Pis:

```bash
$ tshark -i eth0 -nPtd -f "arp or (udp and (port 67 or port 68))" \
  -w ~/cap/dhcp_$(hostname).pcapng
```

## The whole thing, on the wire

Captures running. Both Pis unplugged from the switch, panes at zero. Then I plug
in `pi-foo-01` alone, wait, and plug in `pi-foo-02`.

It comes up instantly. Not "after a while." The moment the plug seats, the
exchange happens and the OLED prints an address. Here is the entire thing from
`pi-foo-01`:

```
 1 0.000000000       0.0.0.0 → 255.255.255.255 DHCP 335 DHCP Request  - Transaction ID 0x468c6499
 2 0.007838680     10.10.0.0 → 10.10.0.4       DHCP 345 DHCP ACK      - Transaction ID 0x468c6499
 3 0.032706610 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 ARP Announcement for 10.10.0.4
 4 2.000235920 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 ARP Announcement for 10.10.0.4
 5 2.000182612 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 ARP Announcement for 10.10.0.4
 6 1.220636594 b8:27:eb:ba:c7:ba → b8:27:eb:3a:e2:c8 ARP 60 Who has 10.10.0.4? Tell 10.10.0.0
 7 0.000074949 b8:27:eb:3a:e2:c8 → b8:27:eb:ba:c7:ba ARP 42 10.10.0.4 is at b8:27:eb:3a:e2:c8
 8 20.306591821      0.0.0.0 → 255.255.255.255 DHCP 335 DHCP Request  - Transaction ID 0x31f7ccff
 9 0.036814386 b8:27:eb:7d:e8:ee → ff:ff:ff:ff:ff:ff ARP 60 ARP Announcement for 10.10.0.1
10 2.000190283 b8:27:eb:7d:e8:ee → ff:ff:ff:ff:ff:ff ARP 60 ARP Announcement for 10.10.0.1
11 2.000200211 b8:27:eb:7d:e8:ee → ff:ff:ff:ff:ff:ff ARP 60 ARP Announcement for 10.10.0.1
12 5.476044755 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff ARP 60 Who has 10.10.0.0? Tell 10.10.0.3
13 16.918619212 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 Who has 10.10.0.1? Tell 10.10.0.4
14 0.000644589 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 10.10.0.1 is at b8:27:eb:7d:e8:ee
15 5.161814058 b8:27:eb:7d:e8:ee → b8:27:eb:3a:e2:c8 ARP 60 Who has 10.10.0.4? Tell 10.10.0.1
16 0.000044115 b8:27:eb:3a:e2:c8 → b8:27:eb:7d:e8:ee ARP 42 10.10.0.4 is at b8:27:eb:3a:e2:c8
```

Sixteen frames, three devices, and the entire life cycle of an identity. There
are five separate things in there I didn't expect, so let's go slowly.

### Frames 1 and 2: where's the four-step handshake?

Every explanation of DHCP you will ever read describes four messages, usually
called DORA: `DISCOVER`, `OFFER`, `REQUEST`, `ACK`. The client shouts, servers
offer, the client picks one, the server confirms.

I got two. `Request`, then `ACK`.

That's because these Pis are not new. They already had leases from my fumbled
run, and a client with a lease it thinks is still valid doesn't start over. It
skips `DISCOVER` and `OFFER` entirely and goes straight to "I had `10.10.0.4`
last time, can I keep it?" The server checks the lease file, agrees, and ACKs.

You can see it in the addresses. Frame 1 still comes from `0.0.0.0`, because the
Pi hasn't confirmed it's allowed to use `.4` yet, so it can't source from it.
Frame 2 comes from `10.10.0.0` and goes to `10.10.0.4` directly, because by then
the server has decided that address is the Pi's.

Two frames from "no identity" to "identity," 7.8 milliseconds apart. I'll take
that over four.

**This is also the seed of the entire last act of this diary, and I didn't
realize it at the time.** A DHCP server's strongest instinct is to give a
returning client the same address it had before. Remember that.

### Frames 3, 4, and 5: shouting your own name

```
 3 0.032706610 b8:27:eb:3a:e2:c8 → ff:ff:ff:ff:ff:ff ARP 42 ARP Announcement for 10.10.0.4
```

Thirty-two milliseconds after the ACK, `pi-foo-01` broadcasts an ARP frame that
isn't a question. It's an announcement: _I am `10.10.0.4`, at
`b8:27:eb:3a:e2:c8`, and I'm telling everyone whether you asked or not._ Then it
does it again two seconds later, and again two seconds after that.

This is the flip side of the ARP I learned in diary 01. There, ARP was a device
asking a question because it needed an answer. Here it's a device making a
statement so nobody has to ask. Every machine on the segment gets to update its
ARP table for free, and any machine already using `.4` gets a chance to object.

The address arrived at frame 2. The _introduction_ is frames 3 through 5.

### Frames 6 and 7: the server checks its own work

```
 6 1.220636594 b8:27:eb:ba:c7:ba → b8:27:eb:3a:e2:c8 ARP 60 Who has 10.10.0.4? Tell 10.10.0.0
 7 0.000074949 b8:27:eb:3a:e2:c8 → b8:27:eb:ba:c7:ba ARP 42 10.10.0.4 is at b8:27:eb:3a:e2:c8
```

`b8:27:eb:ba:c7:ba` is a MAC I hadn't seen before in this project. It's
`pi-foo-dhcp`.

The server just handed out `10.10.0.4`, and now it's asking the network who has
`10.10.0.4`. Which sounds absurd until you think about what it's actually doing:
confirming that the address it gave away is where it thinks it is, and filling
in its own ARP table so it can reach that client later without asking.

The DHCP server is the first device to introduce itself to a new node. Of course
it is. It's the one that gave it a name.

### Frame 12: the switch, finally

```
12 5.476044755 3c:78:95:3e:f4:62 → ff:ff:ff:ff:ff:ff ARP 60 Who has 10.10.0.0? Tell 10.10.0.3
```

`3c:78:95:3e:f4:62` is the switch. The one that spent the opening ten minutes of
this recording broadcasting `does anybody here hand out addresses` into an empty
room.

It's not `192.168.0.1` any more. It's `10.10.0.3`, and it's ARPing for
`10.10.0.0` because it now has a DHCP server it wants to talk to.

Somewhere in the middle of me fighting a config file, the switch quietly got
what it had been asking for the whole time. Nobody told me. It just took a lease
like everybody else.

### Frames 13 through 16: business as usual

Two ARP question-and-answer pairs between the Pis, and the 42/60 byte split from
diary 01 all over again: 42 bytes for the frame I sent, because my own kernel
handed it to `tshark` before padding it out to Ethernet's minimum, and 60 for
the frame I received, because it came off the wire already padded.

This part I already understood. It's nice when a diary has a part you already
understand.

**I now have a network that assigns identity by itself. Plug a node in, it gets
an address, it announces itself, and it can reach its neighbors by that
address.**

## A switch is not a router. A switch plus this Pi is.

Here's the mental model I walked away with, and it's the one I actually wanted
out of this session.

The box in your house labeled "router" is doing at least three separate jobs:

1. Moving frames between the devices on your network.
2. Handing out identities to those devices.
3. Being the door to a different network.

The TL-SG108E does job one and _only_ job one. `pi-foo-dhcp` does job two. Held
together, the switch and that Pi are the thing I've been calling a router my
whole life, and I can now point at which half does which.

Job three doesn't exist on my desk yet. There's no second network to be a door
to. That's the next diary.

And the lease file says the quiet part out loud:

```
pi@pi-foo-dhcp:~ $ sudo cat /var/lib/misc/dnsmasq.leases

1786430977 3c:78:95:3e:f4:62 10.10.0.3 TL-SG108E 01:3c:78:95:3e:f4:62
1786432127 b8:27:eb:7d:e8:ee 10.10.0.1 pi-foo-02 01:b8:27:eb:7d:e8:ee
1786431543 b8:27:eb:3a:e2:c8 10.10.0.4 pi-foo-01 01:b8:27:eb:3a:e2:c8
```

Three leases, not two. Expiry timestamp, MAC, address, hostname, client ID.

`TL-SG108E`. The switch told my Raspberry Pi its model number as its hostname,
and my Raspberry Pi wrote it down. Its management UI now lives at `10.10.0.3` on
my little internet, which means I can go configure VLANs on it later without
ever plugging it into the real world.

That last column matters in about four paragraphs, so look at it now: every
entry is `01:` followed by the device's MAC. That's a DHCP client identifier,
where `01` means "this ID is an Ethernet MAC." All three devices are announcing
themselves the same way.

## The .4 problem

`pi-foo-01` at `10.10.0.4` and `pi-foo-02` at `10.10.0.1` is not a bug. It's an
aesthetic problem, and aesthetic problems bug the hell out of me, so it gets its
own act.

The first thing I learned is the important thing:

**A DHCP client cannot tell a DHCP server what address to give it. It can only
suggest. The server has final authority.**

That's not a limitation, that's the design. If clients could name their own
addresses, the server couldn't guarantee anything about its pool, and you'd have
two devices claiming the same identity the first time somebody typo'd a config.
So the client is allowed to say "if it's going nowhere, I'd love `.1`," and the
server is allowed to say no.

The knob for making that suggestion lives in the client's config, so on each Pi:

```bash
$ sudo nvim /etc/dhcp/dhclient.conf
```

and at the bottom of the file, one line:

```
send dhcp-requested-address 10.10.0.1;
```

`10.10.0.1` on `pi-foo-01`, `10.10.0.2` on `pi-foo-02`. Then release the lease
and ask again:

```bash
$ sudo dhclient -r eth0    # give the address back
$ sudo dhclient eth0       # ask for a new one
```

`pi-foo-02` has to go first, because `pi-foo-02` is squatting on the `.1` I want
for `pi-foo-01`.

Three failures, in order.

### Failure 5: address already assigned

```
pi@pi-foo-02:~ $ sudo dhclient eth0
Error: ipv4: Address already assigned.
pi@pi-foo-02:~ $ sudo dhclient eth0
Error: ipv4: Address already assigned.
pi@pi-foo-02:~ $ sudo dhclient -r eth0
Killed old client process
```

I tried to ask for a new address while still holding the old one, twice, before
I did the release first. `-r` isn't optional politeness. It's the step where you
actually hand the identity back.

And it does hand it back. Here's `eth0` before:

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:7d:e8:ee brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.1/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 42656sec preferred_lft 42656sec
    inet6 fe80::9f6b:39f6:7299:8c81/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

And after the release:

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:7d:e8:ee brd ff:ff:ff:ff:ff:ff
    inet6 fe80::9f6b:39f6:7299:8c81/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

The `inet` line is gone. The MAC is still there, the link is still up, the IPv6
link-local address is still there. Layer 1 and Layer 2 don't care. Only the IPv4
identity went away, which is a very clean demonstration of exactly which layer
DHCP operates at.

Two details in that first block I'd never looked at before:

- **`dynamic`.** `ip addr` labels an address `dynamic` when it came from a lease
  instead of from a config file. Everything I set with `nmcli` in diary 01 was
  static. This one has a landlord.
- **`valid_lft 42656sec`.** That's the lease countdown, ticking down from the
  twelve hours I put in `dhcp-range`. About 11 hours 51 minutes left. The
  identity is rented, not owned, and `ip addr` will tell you how much time is on
  the clock if you ask.

### Failure 6: a typo, and then the same address anyway

Released, requested, and `pi-foo-02` came back as `10.10.0.1`. The address I was
trying to get rid of.

First cause, my own fault: I'd fat-fingered the address in `dhclient.conf`.
Fixed it.

Released, requested, and it came back as `10.10.0.1` again.

Which is where I said out loud that `dnsmasq` doesn't want to respect my
suggestion, and where the lease file showed me I was wrong:

```
pi@pi-foo-dhcp:~ $ sudo cat /var/lib/misc/dnsmasq.leases

1786432349 b8:27:eb:7d:e8:ee 10.10.0.1 pi-foo-02 *
1786430977 3c:78:95:3e:f4:62 10.10.0.3 TL-SG108E 01:3c:78:95:3e:f4:62
1786431543 b8:27:eb:3a:e2:c8 10.10.0.4 pi-foo-01 01:b8:27:eb:3a:e2:c8
```

Two things there.

The lease for `pi-foo-02` is still in the file, with a fresh expiry timestamp.
Release, request, and the server does the most helpful thing it knows how to do:
hands the returning MAC address the address it had last time. Same instinct that
gave me `Request`/`ACK` instead of the four-step handshake at the top of this
section. From the server's point of view it isn't ignoring my suggestion, it's
recognizing an old friend.

And that `*` in the last column, where the other two rows have `01:` and a MAC.
I flagged it on camera as a mystery and moved on, so let me answer it here: that
column is the DHCP client identifier, and `*` is what `dnsmasq` writes when the
client didn't send one. NetworkManager sends one (`01:` plus the MAC). Bare
`dhclient` doesn't, unless you ask it to.

So the `*` is a fingerprint. Every row with `01:` is a lease NetworkManager
asked for. The row with `*` is the one I asked for by hand. I switched DHCP
clients halfway through my own experiment and the lease file noticed before I
did.

### Failure 7: a missing semicolon

Here's what was actually in the file:

```
send dhcp-requested-address 10.10.0.2
```

No semicolon. `dhclient.conf` terminates its statements, and mine didn't, so the
option I was certain I'd set was, as far as the client was concerned, not set at
all. It never made the suggestion. `dnsmasq` was never given anything to
respect.

Killed the client process, released the address, added the semicolon, asked
again.

Boom. It works.

Just configuration typos. Classic.

### And one thing I still don't love

After all that, `pi-foo-01` looked like this:

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:3a:e2:c8 brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.4/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 42184sec preferred_lft 42184sec
    inet 10.10.0.1/24 brd 10.10.0.255 scope global secondary dynamic eth0
       valid_lft 43167sec preferred_lft 43167sec
    inet6 fe80::ba27:ebff:fe3a:e2c8/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

Two IPv4 addresses on one interface. Two `dynamic` leases with two different
countdowns. `.4` is the old one, still `noprefixroute`, still held by
NetworkManager. `.1` is the new one, marked `secondary`, held by the `dhclient`
I ran by hand.

Nothing is broken. Both leases are real, both are in the lease file, and the box
answers on both. But I now have two DHCP clients on one machine with two
opinions about who it is, and that's not a thing I want to ship in a lesson.
Releasing `.4` cleaned it up. Figuring out whether the fix is "tell
NetworkManager to make the suggestion" or "stop using NetworkManager on `eth0`"
is a job for another day.

Final state, read straight off the desk:

```
pi-foo-01     10.10.0.1
pi-foo-02     10.10.0.2
pi-foo-dhcp   10.10.0.0
```

`pi-foo-01` asks for `.1`. The server checks that nobody else is holding it,
says sure, and hands it over. `pi-foo-02` asks for `.2` and gets the same
treatment. Names match numbers. I can breathe again.

## So: who hands out the addresses?

Back to the three questions.

- **Does a switch buy me anything that one cable didn't?** For two nodes, no.
  It's connectivity, at a higher price and a longer cable path. It gave me
  nothing at Layer 3, which is where my problem lived. What it did give me was a
  third opinionated device on the segment, which turned out to be the most
  interesting thing about it.
- **Who hands out the addresses?** A DHCP server, which is not a magic property
  of network hardware but a program running on a machine that has an address of
  its own. On my desk it's a $35 Pi running `dnsmasq` with a ten-address pool.
- **Can I watch it happen?** Yes, once I stopped dropping `-P` from my own
  `tshark` command. Sixteen frames covering a request, an answer, three
  self-introductions, a server double-checking its work, and a switch getting on
  with its life.

The thing I keep circling back to is that "it just works" is not one feature. It
is a switch moving frames, plus a server willing to answer a shout from
`0.0.0.0`, plus a client polite enough to ask instead of assume, plus a lease
file remembering who you were last time, plus ARP doing the introductions
afterward. Every one of those is a separate box on my desk now, and I can unplug
any of them to watch which part of "it just works" stops working.

That's the first time the little internet has felt like an internet instead of a
demo.

## What's next?

The obvious next move is job three: the door.

`pi-foo-dhcp` is already the most privileged node on this network. It's the one
every other node has to talk to before it can say anything at all. Give it a
second network interface and a second network to sit on, and it stops being a
DHCP server that lives on my network and starts being the gateway between two
networks. A packet leaves `pi-foo-01`, hits the switch, goes out a different
port, and arrives somewhere that isn't here.

That's routing, and it's the next diary.

Three threads I left hanging on purpose:

- **The switch question I actually promised.** I said last time that adding a
  third node would force the switch to make a decision it never had to make with
  two: a frame arrives for one specific MAC, which port does it go out? It does
  make that decision, constantly, and I didn't look at it once this session
  because DHCP ate the whole video. Port mirroring on the TL-SG108E is how I get
  to see it, and it's sitting right there at `10.10.0.3` waiting for me.
- **Two DHCP clients on one Pi.** NetworkManager and `dhclient` both holding
  leases on `eth0` is a mess I made and then papered over. The lab needs one
  answer about who owns `eth0`.
- **The OLEDs.** There is so much more to show on those panels than an address.
  A lease countdown, live off `valid_lft`. The ARP table. Which port just lit
  up. I have ideas.

<!-- TK for Joel:
1. Video embed at the top.
2. Confirm the Realtek 60 frames are loop detection (check the ethertype in
   ~/cap/lesson-02_link-switch_*.pcapng).
3. Decide whether 10.10.0.0/24 stays the DHCP server's address, and whether the
   dhcp-range should still start at .0.
4. Copy ~/cap/dhcp_pi-foo-0{1,2}.pcapng (the 11:58 run) into
   lessons/02/captures/ the way lesson 01 did.
Also: BOM.md phase 1 lists two Pis and three SD cards. This diary adds a third
Pi, an OLED, a case, and a PSU. Didn't touch BOM.md; say the word.
-->
