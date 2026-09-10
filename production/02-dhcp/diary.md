# DHCP walkthrough diary — production draft

Status: walkthrough documented through DHCP assignment and client communication;
B07 address preferences is next. These are new observations from the chosen
repository image. Historical evidence is identified separately in research.md.

The [capture archive](evidence/captures/2026-09-09/README.md) contains all eleven
files in diary order, with source paths and verified checksums. Capture links
below identify the recording Pi and frame numbers; all captures use `eth0`.

For each checkpoint, record the question and prediction, starting state,
exact action/command, raw evidence or capture path, and supported explanation.
Record surprises and remaining questions honestly. Note what viewers need to
see, including OLED improvements suggested by the experiment. Develop prose
and script passages from these observations.

Record the image artifact/checksum and fresh-boot verification with the first
session. See [runbook.md](runbook.md) for preparation and pacing.

## B01: Introduction

Okay, we're finally back for a little more of the little internet.

Last time, I left off with plugging in two Raspberry Pis together over Ethernet, manually set identities for them in the form of IPv4 addresses, and got them to chat with one another over `ping`. I also promised that, next, I'd throw a switch into the mix to see what happens.

Why? Well, two Pis connected to one another directly doesn't work the way I expect a local network to. It doesn't *just work*. And it's only two devices connected directly together, which means no room for any other devices or, eventually, a way for them to communicate with the rest of the internet. It doesn't work the way my home Wi-Fi does. Or, can you imagine having to ask the baristas at the coffee shop not just for the Wi-Fi password, but for them to manually configure the Wi-Fi for your phone and laptop?

There's something else going on here.

Today, we're bringing in the switch to answer one seemingly question:

*Who the heck hands out IP addresses on a local network?*

## B02: What the switch can do (and can't)

Before I jump right in, a refresher: I'm building a little internet out of Raspberry Pis so that I can understand exactly how the internet works. I want to make this whole thing deeply tangible not just for myself, but for you, so everything has to be recorded, visualized, and reproducible. I'll consider this little internet done when one Pi, on one network, can ping a Pi on any other network, without knowing the whole "map."

Okay. With that out of the way, it's time to say hello the TP-Link TG-SG108E: 8-port switch. I got it for this build because it's relatively inexpensive and has more than enough ports to hook up *anything* I could possibly want here. If I need more than 8 ports, I've gone off the rails completely.

When I bought this switch, I assumed that it was capable of handing out IP addresses. I thought this lesson would be very short and sweet. Boy was I wrong! Just before embarking on this build, I realized that because it's such an inexpensive switch, it doesn't come with a DHCP server, which is something we'll cover in a lot more depth later on.

That's actually good news. It means that I need figure out a different way to run said DHCP server. It also means that way can, as i said before, be recorded, visualized, and reproduced.

But for now, I want to know exactly what happens when I plug the two Pis in to the switch. Do they just start working now?

If not, *why not*?

{/* VIDEO: At this point, we transition into a screen recording of the following content, down to the end of the beat, to show the packet capture. There will be interspersed close-ups of plugging in the Pis and the OLEDs going from (down)->(no IPv4)->IP address. */}

On both Pis, I'll start up `tshark` exactly as I have before—

Actually, I've actually developed a little utililty called [`tsharkie`](/tools/tsharkie) to make the output more readable.

```shell
# equivalent to:
# tshark -i eth0 -nPtd -f '' -w ~/cap/lesson-02_link-switch_$(hostname).pcapng

$ tsharkie lesson-02_link-switch_$(hostname).pcapng -f ''
```

When I plug them in to the switch, their OLEDs flip from **(down)** to **(no IPv4)**. That much hasn't changed, at least.

I see the familiar flood of frames. There's mDNS! There's IPv6! Perhaps most importantly, there are frames sent by `pi-foo-02`, which proves the switch has given these Pis **connectivity**.

**Capture:** [pi-foo-01 · frame 19](evidence/captures/2026-09-09/pi-foo-01/lesson-02_link-switch_pi-foo-01.pcapng). Companion view: [pi-foo-02 · full capture](evidence/captures/2026-09-09/pi-foo-02/lesson-02_link-switch_pi-foo-02.pcapng).

> Archive check: frame 19 matches the addresses, protocol, and message below,
> but its relative time in the saved file is **3.253 s**, not **10.825 s**.
> The original excerpt is retained; its timing provenance needs resolving.

```txt
19 |   10.825 | fe80::ba27:ebff:fe7d:e8ee  | ff02::fb                   | MDNS     | Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::ba27:ebff:fe7d:e8ee PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
```

But do they have **identities**? Can they reach each other?

If I try to ping `pi-foo-02` from `pi-foo-01`, the result is _total packet loss_.

```shell
$ ping -c1 10.10.0.2
PING 10.10.0.2 (10.10.0.2) 56(84) bytes of data.

--- 10.10.0.2 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

The answer is **no**. This switch offers only connectivity, not identity. Now I can confirm that by running `tshark` again on both Pis, this time focused just on ARP and ICMP, which prove that two devices can reach each other over IPv4.

```shell
# on both pi-foo-01 and pi-foo-02
# equivalent to:
# tshark -i eth0 -nPtd -f 'arp or icmp' -w ~/cap/lesson-02_link-switch-manual_$(hostname).pcapng

$ tsharkie lesson-02_link-switch-manual_$(hostname).pcapng -f 'arp or icmp'
```

Then I manually create IPv4 identities, just as I did in the previous diary.

```shell
# on pi-foo-01
$ sudo nmcli connection add type ethernet ifname eth0 con-name eth \
  ipv4.method manual ipv4.addresses 10.10.0.1/24 \
  ipv4.never-default yes ipv6.method link-local \
  connection.autoconnect yes connection.autoconnect-priority 10

# same on pi-foo-02, but 10.10.0.2/24
```

Then, I can `ping` successfully.

```shell
# from pi-foo-01
$ ping -c1 10.10.0.2
PING 10.10.0.2 (10.10.0.2) 56(84) bytes of data.
64 bytes from 10.10.0.2: icmp_seq=1 ttl=64 time=1.30 ms

--- 10.10.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.302/1.302/1.302/0.000 ms
```

And I can see the ARP introduction and ICMP `ping` on both Pis, meaning they can now communicate.

**Capture:** [pi-foo-01 · frames 1–6](evidence/captures/2026-09-09/pi-foo-01/lesson-02_link-switch-manual_pi-foo-01.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
   2 |    0.001 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0012, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0012, seq=1/256, ttl=64 (request in 3)
   5 |    5.196 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
   6 |    5.196 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

**Capture:** [pi-foo-02 · frames 1–6](evidence/captures/2026-09-09/pi-foo-02/lesson-02_link-switch-manual_pi-foo-02.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
   2 |    0.000 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0012, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0012, seq=1/256, ttl=64 (request in 3)
   5 |    5.195 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
   6 |    5.196 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

The Pis now have both connectivity and identity, but _not because of the switch_. I still had to do that myself. So, if the switch can't give these Pis the identities they need, what can?

## B03: A third Pi enters the ring: `pi-foo-dhcp`

{/* VIDEO: We step back into the overhead shot to point this out as it's happening and explain why the Raspberry Pi has been sitting there all along. */}

Now that I know this switch can't give out IPv4 addresses, and thus identitity and connectivity, I need something else to do that job for me. I need something else that can answer when a device on this local network reaches out and asks for an IPv4 address.

I need another Raspberry Pi. This is a total blessing in disguise: Instead of all of this answering and address-handing happening inside of the switch, which I can't log into and observe, I _can_ do that with a Pi! Together, we can inspect and unravel every frame and handshake along the way.

Here's the plan: This third Pi, which I've named `pi-foo-dhcp`, will run [dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq) operating as this network's DHCP server.

### What's DHCP?

{/* VIDEO: We move into a Remotion-style visualization of this. */}

The Dynamic Host Configuration Protocol automatically assignes IP addresses and other settings to each device on a network. It's what makes your the Wi-Fi at home or anywhere else feel  seamless. The moment there's a live wire, your device gets an IPv4 address and can reach any other device—or the public internet.

For the little internet, the DHCP server will hand out identities to individual Pis. It'll work over this four-step process known as **DORA**:

1. **D**iscover: The Pi asks, "Does anyone out there have an IPv4 address for me?"
2. **O**ffer: The DHCP server says, "Sure, I've got one at `10.10.0.1`."
3. **R**equest: The Pi accepts the address.
4. **A**cknowledge: The DCHP server confirms this and leases the IP address to the Pi.

A **lease** is a temporary assignment of IP address to device with a configurable unit of time. If the assignments were permanent, then many DHCP servers would simply run out of IP addresses to hand out. A coffee shop certainly doesn't want to be figuring _that_ out while also trying to make a flat white.

Once DORA's wrapped up and the lease is given, the DHCP client on the Pi adds that address to its networking stack.

Earlier, I told NetworkManager which address to use with `nmcli`. With DHCP in play, NetworkManager will simply apply the lease it receives, automating the entire process.

{/* VIDEO: Cut back to the table. */}

Exciting. What configuration will let `pi-foo-dhcp` serve as the DHCP server?

## B04: A quick tour through dnsmasq configuration

To start, before I even consider plugging this new Pi into the switch, I need to install dnsmasq and start the service (and install neovim!).

```
sudo apt install dnsmasq
sudo service dnsmasq start
```

I also need to reset my two Pis to the original state, which means first disconnecting them from the switch and deleting the `eth` profiles I created manually with NetworkManager.

```
MODE=ssh NO_COLOR=1 \
A_HOST=pi@pi-foo-01.local \
B_HOST=pi@pi-foo-02.local \
./lessons/00/scripts/reset.sh
```

Next, I want to start capturing frames, particularly those related to ARP or DHCP, which is what the `udp and (port 67 or port 68)` bit is all about, to capture the moment I get DHCP working. I'm doing this on _all three Pis_.

```
$ tsharkie lesson-02_dhcp_$(hostname).pcapng -f 'arp or icmp or (udp and (port 67 or port 68))'
```

I can now pop into `/etc/dnsmasq.conf` and configure it in two meaningful ways. First, to listen for DHCP requests on its `eth0` interface, and to create a pool of 10 IP addresses available to lease out, for 12 hours each, to clients.

```conf
...
# If you want dnsmasq to listen for DHCP and DNS requests only on
# specified interfaces (and the loopback) give the name of the
# interface (eg eth0) here.
# Repeat the line for more than one interface.
interface=eth0
...
# Uncomment this to enable the integrated DHCP server, you need
# to supply the range of addresses available for lease and optionally
# a lease time. If you have more than one network, you will need to
# repeat this for each network on which you want to supply DHCP
# service.
dhcp-range=10.10.0.1,10.10.0.10,12h
```

I'll also watch the dnsmasq service on `pi-foo-dhcp` to capture how it reacts, then restart it so it picks up the new configuration.

```
# Terminal 1: keep watching the server log
sudo journalctl -u dnsmasq -f -n 20

# Terminal 2, also on pi-foo-dhcp: load the new configuration
sudo systemctl restart dnsmasq
```

Now it's time to assemble. I start by plugging in both `pi-foo-01` and `pi-foo-dhcp`. Nothing changes on the Pis except for the fact their OLEDs recognize that there's now a wire but no IPv4 address. When I look in the dnsmasq logs, I see an interesting warning:

```
Sep 09 17:14:48 pi-foo-dhcp dnsmasq[13798]: warning: interface eth0 does not currently exist
```

I'd configured dnsmasq to hand out IP addresses on an interface, but maybe it needs an IP address of its own to do so? I give the server `10.10.0.254/24`, which is an address on the same subnet as the clients, but outside the `.1-.10` pool it can hand out.

```
sudo ip addr add 10.10.0.254/24 dev eth0
```

All I have to do now is ask `pi-foo-01` to try finding a DHCP server again, because by now, it's given up.

```
sudo nmcli --wait 0 connection up eth-dhcp
```

Boom. _Magic_. Take a look at all that goodness from `pi-foo-01`.

**Capture:** [pi-foo-01 · frames 51–64](evidence/captures/2026-09-09/pi-foo-01/lesson-02_dhcp_pi-foo-01.pcapng). The full file also preserves the earlier acquisition attempts.

```
  51 |  457.648 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  52 |  458.650 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  53 |  459.674 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  54 |  459.979 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x1e3cdc8e
  55 |  460.651 | 10.10.0.254                | 10.10.0.1                  | ICMP     | Echo (ping) request  id=0x9150, seq=0/0, ttl=64
  56 |  460.651 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x7226adbe
  57 |  460.652 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x1e3cdc8e
  58 |  460.652 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x1e3cdc8e
  59 |  460.666 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x1e3cdc8e
  60 |  460.688 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  61 |  462.688 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  62 |  464.688 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  63 |  465.754 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  64 |  465.754 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

And from `pi-foo-dhcp`!

**Capture:** [pi-foo-dhcp · frames 53–66](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp_pi-foo-dhcp.pcapng).

```
  53 |  463.562 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  54 |  464.564 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  55 |  465.588 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  56 |  465.894 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x1e3cdc8e
  57 |  466.565 | 10.10.0.254                | 10.10.0.1                  | ICMP     | Echo (ping) request  id=0x9150, seq=0/0, ttl=64
  58 |  466.566 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x7226adbe
  59 |  466.566 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x1e3cdc8e
  60 |  466.566 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x1e3cdc8e
  61 |  466.580 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x1e3cdc8e
  62 |  466.603 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  63 |  468.603 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  64 |  470.603 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  65 |  471.668 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  66 |  471.668 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

And finally, the DHCP server acknowledging the whole DORA handshake.

**Log source:** [Server experiment record](evidence/2026-09-09-server-no-address-warning.md), including the no-address diagnostic and the successful exchange.

```
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPREQUEST(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPACK(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8 pi-foo-01
```

What about `pi-foo-02`? It's been sitting here, not plugged in, waiting for its moment to shine. I plug it in, and...

**Capture:** [pi-foo-02 · frames 1–15](evidence/captures/2026-09-09/pi-foo-02/lesson-02_dhcp_pi-foo-02.pcapng). Companion server view: [pi-foo-dhcp · full capture](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp-02_pi-foo-dhcp.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0xec64f4a8
   2 |    0.001 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.254
   3 |    1.006 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.254
   4 |    2.030 | b8:27:eb:ba:c7:ba          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.254
   5 |    2.291 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0xff28f61f
   6 |    3.005 | 10.10.0.254                | 10.10.0.8                  | ICMP     | Echo (ping) request  id=0xfcc7, seq=0/0, ttl=64
   7 |    3.005 | 10.10.0.254                | 10.10.0.8                  | DHCP     | DHCP Offer    - Transaction ID 0xec64f4a8
   8 |    3.005 | 10.10.0.254                | 10.10.0.8                  | DHCP     | DHCP Offer    - Transaction ID 0xff28f61f
   9 |    3.005 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0xff28f61f
  10 |    3.012 | 10.10.0.254                | 10.10.0.8                  | DHCP     | DHCP ACK      - Transaction ID 0xff28f61f
  11 |    3.031 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.8
  12 |    5.032 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.8
  13 |    7.032 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.8
  14 |    8.206 | b8:27:eb:ba:c7:ba          | b8:27:eb:7d:e8:ee          | ARP      | Who has 10.10.0.8? Tell 10.10.0.254
  15 |    8.206 | b8:27:eb:7d:e8:ee          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.8 is at b8:27:eb:7d:e8:ee
```

It automatically got an IP address of its own! Now, why it landed on `10.10.0.8`, I couldn't tell you... yet.

Finally, we can come to the whole point of this: **Can the Pis now communicate with IPv4 addresses assigned by a DHCP server?**

**Yes!**

`pi-foo-01` starts the cycle of ARP and ICMP...

**Capture:** [pi-foo-01 · frames 1–6](evidence/captures/2026-09-09/pi-foo-01/lesson-02_dhcp-ping_pi-foo-01.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
   2 |    0.001 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.8 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.8                  | ICMP     | Echo (ping) request  id=0x0013, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.8                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0013, seq=1/256, ttl=64 (request in 3)
   5 |    5.158 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.8
   6 |    5.158 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

And `pi-foo-02` responds with a mirror image...

**Capture:** [pi-foo-02 · frames 1–6](evidence/captures/2026-09-09/pi-foo-02/lesson-02_dhcp-ping_pi-foo-02.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
   2 |    0.000 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.8 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.8                  | ICMP     | Echo (ping) request  id=0x0013, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.8                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0013, seq=1/256, ttl=64 (request in 3)
   5 |    5.158 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.8
   6 |    5.158 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

Even `pi-foo-dhcp` hears a bit, once again proving how observable a local network is.

**Capture:** [pi-foo-dhcp · frame 1 (entire capture)](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp-ping_pi-foo-dhcp.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
```

Now here's an intesting bit: `pi-foo-02` got an IP address of `10.10.0.8`. That's a little... unexpected. What happened there? It bugs me to no end because I'm a bit of a stickler for consistenty. I want `pi-foo-02` to end in `.2`.

Is there anything that I can do about the IP addresses these devices get?

## B07: You can just ask for what you want

With DHCP, you have two ways getting a specific IPv4 address: first, by the client _politely_ requesting it; and second, by configuring the DHCP server itself to associate specific MAC addresses with specific IPs. The former has to be polite, because the DHCP server gets final say as to what addresses go where.

Still, I'd like to have the Pis politely ask.

Starting with `pi-foo-02`, I can configure `sudo nvim /etc/dhcp/dhclient.conf` to 

```
send dhcp-requested-address 10.10.0.2;
```

I manually release the address alraedy given and ask for a new one.

```bash
$ sudo dhclient -r eth0    # give the address back
$ sudo dhclient eth0       # ask for a new one
```

But the OLED still ends in `.8`. What gives?

All the packet capture suggests there's been a new DORA handshake involving `10.10.0.2`!

```
# NEED TO REPLACE THIS WITH A REAL ONE
1 0.000000000      0.0.0.0 → 255.255.255.255 DHCP 342 DHCP Discover -
Transaction ID 0x7289b37f
3 3.004971917  10.10.0.254 → 10.10.0.2    DHCP 342 DHCP Offer    - Transaction
ID 0x7289b37f
4 3.005587290      0.0.0.0 → 255.255.255.255 DHCP 342 DHCP Request  -
Transaction ID 0x7289b37f
5 3.013355984  10.10.0.254 → 10.10.0.2    DHCP 345 DHCP ACK      - Transaction
ID 0x7289b37f
```

The DHCP journal _seems_ to agree:

```
Sep 09 17:52:24 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 17:52:24 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.8 b8:27:eb:7d:e8:ee
Sep 09 17:52:24 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPREQUEST(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 17:52:24 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPACK(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee pi-foo-02
```

Turns out that `pi-foo-02` actually now has _two_ IP addresses:

```
$ ip addr

...
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:7d:e8:ee brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.8/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 41525sec preferred_lft 41525sec
    inet 10.10.0.2/24 brd 10.10.0.255 scope global secondary dynamic eth0
       valid_lft 43092sec preferred_lft 43092sec
```

They're both present, but `.8` takes precedence. What happened here, as I stumbled my way through this process, is that I started using `dhclient`, thinking it was a quick workaround for releasing leases and getting new ones, when in reality it's an entirely diffeent DHCP client than NetworkManager.

Two DHCP clients can hold two different IPv4 addresses. Neat! But also annoying, because it's directly in my path to perfectly, beautifully matched hostnames and IP addresses.

The answer is go back to NetworkManager. It can't request IPs on its own, but it can drive dhclient to do so on its behalf. I need to tweak a few configuration files, first to ask NetworkManager to use `dhclient` as its DHCP client.

```
# /etc/NetworkManager/conf.d/20-little-internet-dhcp-client.conf
[main]
dhcp=dhclient
```

Then ask this invoked client to request the address instead.

```
# /etc/NetworkManager/dhclient-eth0.conf
send dhcp-requested-address 10.10.0.2;
```

Next, I deactivate the profile and recreate it using the new configuration.

```shell
sudo nmcli connection down eth-dhcp
sudo nmcli connection up eth-dhcp
```

BAM! `pi-foo-02` immediately requests and receives `.2`.

```
TK PACKET CAPTURE GOES HERE I NEED TO COLLECT IT MYSELF MAYBE
```

Amazing. Stunning. _Perfect_.

I can now bring this same configuration to `pi-foo-01` to lock in future leases from the DHCP server. That means I now have two Pis on this local network that automatically receive the IPv4 addresses they politely ask for _the moment I plug in an Ethernet capble_. That, to me, is very cool.

## It's time to rip this whole thing end to end

That begins by unplugging all those Ethernet cables and bringing the two client Pis back to their original state.

```shell
$ sudo nmcli connection down eth-dhcp
$ sudo rm -f /var/lib/NetworkManager/*.lease
```

For `pi-foo-dhcp`. We need to say bye-bye to its DHCP server and current leases.

```shell
$ sudo systemctl stop dnsmasq
$ sudo truncate -s 0 /var/lib/misc/dnsmasq.leases
```

One final check to make sure that everything is down. Yep? Yep.

Time to rip it. Start `tshark` everywhere.

```shell
# on pi-foo-01, pi-foo-02, and pi-foo-dhcp
$ tsharkie lesson-02_dhcp-e2e_$(hostname).pcapng -f 'arp or icmp or (udp and (port 67 or port 68))'
```

Bring dnsmasq back up.

```
$ sudo systemctl start dnsmasq
```

And then plug the Pis in.

...
...
...

They come up on `10.10.0.1` and `10.0.0.2`. I send a ping from `pi-foo-01` to `pi-foo-02`. It works. And the whole story is recorded in the captures.

On `pi-foo-01` as it gets `10.10.0.1` and sends a ping to `10.10.0.2`.

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x329ce6b
   2 |    0.071 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x3449fa25
   3 |    2.103 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de2
   4 |    2.906 | 10.10.0.254                | 10.10.0.1                  | ICMP     | Echo (ping) request  id=0xe293, seq=0/0, ttl=64
   5 |    2.907 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x329ce6b
   6 |    5.910 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x3449fa25
   7 |    5.911 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3449fa25
   8 |    5.926 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25
   9 |    5.955 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  10 |    5.981 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  11 |    7.110 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de3
  12 |    7.956 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  13 |    7.982 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  14 |    9.956 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  15 |    9.982 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  16 |   11.099 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  17 |   11.099 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  18 |   12.111 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de4
  19 |   17.115 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de5
  20 |   18.210 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
  21 |   18.210 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  22 |   18.210 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0014, seq=1/256, ttl=64
  23 |   18.211 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0014, seq=1/256, ttl=64 (request in 22)
  24 |   22.119 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de6
  25 |   23.349 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
  26 |   23.349 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  27 |   27.126 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de7
```

On `pi-foo-02` as it gets `10.10.0.2` and receives a ping from `10.10.0.1`.

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x329ce6b
   2 |    0.001 | 10.10.0.254                | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0xb872, seq=0/0, ttl=64
   3 |    0.171 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x3449fa25
   4 |    2.203 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de2
   5 |    3.005 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP Offer    - Transaction ID 0x329ce6b
   6 |    3.006 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x329ce6b
   7 |    6.010 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3449fa25
   8 |    6.019 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x329ce6b
   9 |    6.054 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  10 |    6.081 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  11 |    7.209 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de3
  12 |    8.054 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  13 |    8.081 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  14 |   10.055 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  15 |   10.081 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  16 |   11.198 | b8:27:eb:ba:c7:ba          | b8:27:eb:7d:e8:ee          | ARP      | Who has 10.10.0.2? Tell 10.10.0.254
  17 |   11.198 | b8:27:eb:7d:e8:ee          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  18 |   12.210 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de4
  19 |   17.214 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de5
  20 |   18.309 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
  21 |   18.309 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  22 |   18.309 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0014, seq=1/256, ttl=64
  23 |   18.309 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0014, seq=1/256, ttl=64 (request in 22)
  24 |   22.218 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de6
  25 |   23.447 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
  26 |   23.448 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  27 |   27.224 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de7
```

On `pi-foo-dhcp` as it receives multiple DHCP Discover frames in a matter of milliseconds.

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddb
   2 |    5.001 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddc
   3 |   10.005 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddd
   4 |   15.008 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3dde
   5 |   20.014 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddf
   6 |   25.015 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de0
   7 |   30.019 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de1
   8 |   32.822 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x329ce6b
   9 |   32.822 | 10.10.0.254                | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0xb872, seq=0/0, ttl=64
  10 |   32.993 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x3449fa25
  11 |   35.024 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de2
  12 |   35.826 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP Offer    - Transaction ID 0x329ce6b
  13 |   35.827 | 10.10.0.254                | 10.10.0.1                  | ICMP     | Echo (ping) request  id=0xe293, seq=0/0, ttl=64
  14 |   35.827 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x329ce6b
  15 |   38.831 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x3449fa25
  16 |   38.832 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3449fa25
  17 |   38.840 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x329ce6b
  18 |   38.846 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25
  19 |   38.876 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  20 |   38.902 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  21 |   40.031 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de3
  22 |   40.876 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  23 |   40.902 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  24 |   42.876 | b8:27:eb:7d:e8:ee          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.2
  25 |   42.902 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
  26 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  27 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:7d:e8:ee          | ARP      | Who has 10.10.0.2? Tell 10.10.0.254
  28 |   44.020 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  29 |   44.020 | b8:27:eb:7d:e8:ee          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  30 |   45.031 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de4
  31 |   50.035 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de5
  32 |   51.130 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
  33 |   55.038 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de6
  34 |   60.045 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de7
```

And, finally, in the dnsmasq logs as it hands out identities.

```
Sep 09 21:11:50 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPDISCOVER(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 21:11:50 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPOFFER(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPDISCOVER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPREQUEST(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPACK(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee pi-foo-02
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPREQUEST(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 21:11:53 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPACK(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8 pi-foo-01
```

I can now plug in a Pi and get an IPv4 address, which means I have both connectivity and identity and thus reachability to any other Pi on the local network.

I couldn't also done that by buying a fancier router and plopping that in place of the switch, but then I wouldn't have gotten all these amazing captures. I wouldn't have seen it end to end. I wouldn't have been able to visaully see it all come together on this old desk. And I wouldn't be able to share all that into this project to make it tangible, visual, and reproducible anywhere else.

To me, that's well worth the extra trouble.

### What happened, frame by frame

Let's look at this from the point of view of `pi-foo-01`.

#### Frames 2, 6, 7, and 8: DORA in one go

```
   2 |    0.071 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x3449fa25
   6 |    5.910 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x3449fa25
   7 |    5.911 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3449fa25
   8 |    5.926 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25 
```

Rembemer how I described the 4 steps of DORA? Discover, Offer, Request, and Acknowledge? Here it is in the frames themselves.

`pi-foo-01` starts with a source address of `0.0.0.0`, which is the same as having no address at all... because it doesn't have one. The DHCP server, on `10.10.0.254`, responds with an offer, and once it's been acknowledged on both ends, the lease is signed and the IP address given out.

#### Frame 10: a gratuitous shout (of ARP)

```
  10 |    5.981 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
```

About a hundredth of a second after receiving this new IP address, `pi-foo-01` announces it to the network.

#### Frames 20-26 (minus 24): The ARP and ICMP/ping handshakes

  20 |   18.210 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
  21 |   18.210 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  22 |   18.210 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0014, seq=1/256, ttl=64
  23 |   18.211 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0014, seq=1/256, ttl=64 (request in 22)
  25 |   23.349 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
  26 |   23.349 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8

About 18 seconds after starting the capture, I fire off a ping from one Pi to the next. Through ARP, it asks the network for who has `10.10.0.2`, gets an answer, caches it, fires off its ping, and then responds when `pi-foo-02` asks the same question back.

We're cookin'.

Now, two fun oddities I want to point out amongs all these captures.

### The DHCP server hands out addresses... then checks its work

```
  17 |   38.840 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x329ce6b
  18 |   38.846 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25
  ...
  26 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  27 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:7d:e8:ee          | ARP      | Who has 10.10.0.2? Tell 10.10.0.254
  28 |   44.020 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  29 |   44.020 | b8:27:eb:7d:e8:ee          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
```

In frames 17-18, you see `pi-foo-dhcp` ACK-ing and handing out two leases.

Roughly 5 seconds later, it's asking the network who has these addresses. It's confirming that the address it gave away is where it thinks it is, and filling in its own ARP table so it can reach that client later without asking.

I just happen to think that's incredibly cool.

### These repeated DHCP Discover frames come from the switch!

I've neglected the switch a bit in this whole exercise, I haven't I? I turns out that the switch is a device on this network just like any other, which means it also wants an IPv4 address just like any other. At some point in my session, I accidentally set dnsmasq's `dhcp-range` from `.0-.50`, which meant it got `.12`... and then kept asking, every 5 seconds, to renew it.

```
   1 |    0.000 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddb
   2 |    5.001 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddc
   3 |   10.005 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddd
   4 |   15.008 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3dde
   5 |   20.014 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddf
   6 |   25.015 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de0
   7 |   30.019 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de1
```

Finally, it gave up on retrying, kicked off a fresh DORA handshake, and eventually setted on `.3`.

```
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPDISCOVER(eth0) 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPOFFER(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPREQUEST(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPACK(eth0) 10.10.0.3 3c:78:95:3e:f4:62 TL-SG108E
```

## B06: Where does the little internet stand now?

Okay. Let's turn back to the question that started this session.

*Who the heck hands out IP addresses on a local network?*

For a time, I thought the switch would do this work for me. Turns out for two Pis, that switch provides all the same connectivity as a single Ethernet cable, but costs about $30 extra and doesn't do anything for Layer 3 identity, because it can't hand out addresses. It did give me some fun frames to watch, made the DHCP server possible (and observable), and enables everything that comes next. Overall, it was a win.

The answer is actually a **DHCP server**. I now know much more tangibly that a DHCP server isn't some magical property of network hardware, but a program that runs on a machine with an address of its own. In this little internet, that's a $35 Pi running `dnsmasq` with a ten-address pool.

What's become very clear to me now is that "it just works" is many frames, using many protocols, across many services. No single one of them carries the burden; only together, through much many questions asked and answers written down, does this intricate system work.

And I can see it all happen in the packet capture _and_ the OLEDs. The little internet is starting to feel like a lot more than a tiny demo or silly art project.

It would be tempting to lean into that energy and buy a _second_ switch, plus a handful more Pis, and really
start to make this one minuscule network part of something much larger. I really do want to know what happens when a packet from
`pi-foo-01` doesn't just stop at the local network.

That's routing, and it's coming soon.

But, for now, there are some more obvious questions to ask, ranging from
practical to utterly ridiculous:

- **What else can I visualize on the OLEDs?** Maybe what happens when two DHCP clients ask for the same IP address?
- **How does the switch actually decide what port to send frames?** Now that the
  switch sits on `10.10.0.3`, I can answer that with port mirroring.
- **What happens if I plug the switch into itself?** Endless recursion?
- **What happens if there's two DHCP servers on the same local network?**
  Apparently, this is a real thing that happens on occasion and I'd love to know
  what the packet chatter looks like.
- **How many feet of Ethernet cable before it fails?** Standard practice says
  300 feet, but I have the perfect testbed in which to see _exactly_ where... or
  at least to the nearest multiple of 50 (feet).

Have ideas of your own? Drop an
[issue](https://github.com/ngrok/little-internet/issues) or an
[email](mailto:joel@ngrok.com).
