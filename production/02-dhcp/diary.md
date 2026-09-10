# Diary 02: Who the heck hands out IP addresses on a local network?

Okay, we're finally back for a little more of the little internet.

Last time, I plugged two Raspberry Pis together over Ethernet, manually gave them identities in the form of IPv4 addresses, and got them to chat with one another over `ping`. I also promised that, next, I'd throw a switch into the mix to see what happens.

Why? Well, connecting two Pis directly doesn't work the way I expect a local network to. It doesn't *just work*. And it's only two devices connected directly together, which means no room for any other devices or, eventually, a way for them to communicate with the rest of the internet. It doesn't work the way my home Wi-Fi does. Or, can you imagine having to ask the baristas at the coffee shop not just for the Wi-Fi password, but for them to manually configure the Wi-Fi for your phone and laptop?

There's something else going on here.

Today, we're bringing in the switch to answer one seemingly simple question:

*Who the heck hands out IP addresses on a local network?*

## What the switch can do (and can't)

Before I jump right in, a refresher: I'm building a little internet out of Raspberry Pis so that I can understand exactly how the internet works. I want to make this whole thing deeply tangible not just for myself, but for you, so everything has to be recorded, visualized, and reproducible. I'll consider this little internet done when one Pi, on one network, can ping a Pi on any other network, without knowing the whole "map."

Okay. With that out of the way, it's time to say hello to the TP-Link TL-SG108E, an 8-port switch. I got it for this build because it's relatively inexpensive and has more than enough ports to hook up *anything* I could possibly want here. If I need more than 8 ports, I've gone off the rails completely.

When I bought this switch, I assumed that it was capable of handing out IP addresses. I thought this lesson would be very short and sweet. Boy, was I wrong! Just before embarking on this build, I realized this particular one doesn't have a DHCP server built in. That's actually _good news_. It means that I need to figure out a different way to run said DHCP server. It also means I can record, visualize, and reproduce how it works.

But for now, I want to know exactly what happens when I plug the two Pis into the switch. Do they just start working now?

If not, *why not*?

### A short aside and reminder about the setup

All the Pis start with the same little-internet image. I connect over Wi-Fi for SSH, leaving Ethernet for the experiments. I've named the two existing Pis `pi-foo-01` and `pi-foo-02`, and they start with their cables unplugged.

Said image prepared for this diary includes [`tsharkie`](../../tools/tsharkie/README.md), a little utility I made to make captures more readable. It also configures NetworkManager to use dhclient for DHCP. NetworkManager manages the interfaces throughout, and later, I'll configure the Pis to request particular addresses.

Every packet excerpt below links to its saved capture, recorded on `eth0`. The frame numbers match those files, and the times are seconds since the first packet in each capture, rounded to three decimal places.

### Time to test the switch

On both Pis, I have two SSH terminals running. One keeps `tsharkie` running, and I use the second for configuration and `ping` commands. That keeps the capture recording even as I change things.

```shell
# on both pi-foo-01 and pi-foo-02
$ tsharkie lesson-02_link-switch_$(hostname).pcapng -f ''
```

When I plug them into the switch, their OLEDs flip from **(down)** to **(no IPv4)**. That much hasn't changed, at least.

I see the familiar flood of frames. There's mDNS! There's IPv6! Perhaps most importantly, [the capture from pi-foo-01](evidence/captures/2026-09-09/pi-foo-01/lesson-02_link-switch_pi-foo-01.pcapng) includes frames sent by `pi-foo-02`, which proves the switch has given these Pis **connectivity**. Here's one of them. I saved [pi-foo-02's view](evidence/captures/2026-09-09/pi-foo-02/lesson-02_link-switch_pi-foo-02.pcapng), too.

```txt
19 |    3.253 | fe80::ba27:ebff:fe7d:e8ee  | ff02::fb                   | MDNS     | Standard query response 0x0000 TXT, cache flush AAAA, cache flush fe80::ba27:ebff:fe7d:e8ee PTR, cache flush pi-foo-02.local SRV, cache flush 0 0 9 pi-foo-02.local
```

But can they reach each other using the IPv4 addresses I want them to have?

If I try to ping `pi-foo-02` from `pi-foo-01`, the result is _total packet loss_.

```shell
$ ping -c1 10.10.0.2
PING 10.10.0.2 (10.10.0.2) 56(84) bytes of data.

--- 10.10.0.2 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

Not yet. This switch carries frames between them, but neither Pi has the IPv4 address I'm trying to use. I can confirm that by assigning those manually and trying again... but not before starting to capture frames.

```shell
# on both pi-foo-01 and pi-foo-02
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

And I can see the ARP introduction and ICMP `ping` on both Pis, meaning they can now communicate. Here's how it looks [from pi-foo-01](evidence/captures/2026-09-09/pi-foo-01/lesson-02_link-switch-manual_pi-foo-01.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
   2 |    0.001 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0012, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0012, seq=1/256, ttl=64 (request in 3)
   5 |    5.196 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
   6 |    5.196 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

And here's [the same exchange from pi-foo-02](evidence/captures/2026-09-09/pi-foo-02/lesson-02_link-switch-manual_pi-foo-02.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
   2 |    0.000 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0012, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0012, seq=1/256, ttl=64 (request in 3)
   5 |    5.195 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
   6 |    5.196 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

The switch provides connectivity, and the IPv4 addresses I assigned let them communicate just as they had before, but I still had to do it all myself. What could do that job automatically?

## A third Pi enters the ring: `pi-foo-dhcp`

I've confirmed this switch can connect the Pis, but I still need something else to answer their requests for IPv4 addresses.

I need another Raspberry Pi. This is a blessing in disguise: I can SSH into it, configure the DHCP service, read its logs, and capture all its traffic. Together, we can inspect and unravel exactly how this process works.

Here's the plan: This third Pi, which I've named `pi-foo-dhcp`, will run [dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq) operating as this network's DHCP server.

### What's DHCP?

The Dynamic Host Configuration Protocol automatically assigns IP addresses and other settings to each device on a network. It's what makes the Wi-Fi at home feel seamless. You don't have to choose an address yourself.

For the little internet, the DHCP server will hand out identities to individual Pis. It'll work over this four-step process known as **DORA**:

1. **D**iscover: The Pi asks, "Does anyone out there have an IPv4 address for me?"
2. **O**ffer: The DHCP server says, "Sure, I've got one at `10.10.0.1`."
3. **R**equest: The Pi accepts the address.
4. **A**cknowledge: The DHCP server confirms this and leases the IP address to the Pi.

A **lease** assigns an IP address to a device for a configurable amount of time. If the assignments were permanent, then many DHCP servers would simply run out of IP addresses to hand out. A coffee shop certainly doesn't want to be figuring _that_ out while also trying to make a flat white.

Once DORA's wrapped up and the lease is given, the DHCP client on the Pi adds that address to its networking stack.

Earlier, I told NetworkManager which address to use with `nmcli`. With DHCP in play, NetworkManager will simply apply the lease it receives, automating the entire process.

Exciting. What configuration will let `pi-foo-dhcp` serve as the DHCP server?

## A quick tour through dnsmasq configuration

To start, before I even consider plugging this new Pi into the switch, I need to install dnsmasq and start the service.

```
sudo apt install dnsmasq
sudo service dnsmasq start
```

I also need to reset my two Pis to the original state, which means first disconnecting them from the switch and deleting the `eth` profiles I created manually with NetworkManager. The image's baked-in `eth-dhcp` profile is still ready to request an address when I reconnect the cable.

```
sudo nmcli connection delete eth
sudo nmcli connection modify eth-dhcp connection.autoconnect yes
```

Next, I want to capture the moment I get DHCP working. I'm watching for ARP, ICMP, and DHCP—the `udp and (port 67 or port 68)` bit selects DHCP traffic. I'm doing this on _all three Pis_.

```
$ tsharkie lesson-02_dhcp_$(hostname).pcapng -f 'arp or icmp or (udp and (port 67 or port 68))'
```

I can now pop into `/etc/dnsmasq.conf` and configure it to do two things: listen for DHCP requests on `eth0`, and offer a pool of ten IP addresses with 12-hour leases.

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

I'll also watch the dnsmasq service on `pi-foo-dhcp` to capture how it reacts, and in a second terminal, restart it so it picks up the new configuration.

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

Boom. _Magic_. Take a look at all that goodness [from pi-foo-01](evidence/captures/2026-09-09/pi-foo-01/lesson-02_dhcp_pi-foo-01.pcapng). The full file also preserves the earlier acquisition attempts.

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

And [from pi-foo-dhcp](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp_pi-foo-dhcp.pcapng)!

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

And finally, [the DHCP server’s log](evidence/2026-09-09-server-no-address-warning.md) records the whole DORA handshake.

```
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPREQUEST(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPACK(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8 pi-foo-01
```

What about `pi-foo-02`? It's been sitting here, not plugged in, waiting for its moment to shine. I plug it in, and [watch its capture](evidence/captures/2026-09-09/pi-foo-02/lesson-02_dhcp_pi-foo-02.pcapng), with [the server recording its side](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp-02_pi-foo-dhcp.pcapng), too...

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

[On pi-foo-01, the cycle of ARP and ICMP begins](evidence/captures/2026-09-09/pi-foo-01/lesson-02_dhcp-ping_pi-foo-01.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
   2 |    0.001 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.8 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.8                  | ICMP     | Echo (ping) request  id=0x0013, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.8                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0013, seq=1/256, ttl=64 (request in 3)
   5 |    5.158 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.8
   6 |    5.158 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

[Pi-foo-02 records the same exchange from the other end](evidence/captures/2026-09-09/pi-foo-02/lesson-02_dhcp-ping_pi-foo-02.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
   2 |    0.000 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.8 is at b8:27:eb:7d:e8:ee
   3 |    0.001 | 10.10.0.1                  | 10.10.0.8                  | ICMP     | Echo (ping) request  id=0x0013, seq=1/256, ttl=64
   4 |    0.001 | 10.10.0.8                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0013, seq=1/256, ttl=64 (request in 3)
   5 |    5.158 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.8
   6 |    5.158 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

Even [pi-foo-dhcp hears the broadcast ARP request](evidence/captures/2026-09-09/pi-foo-dhcp/lesson-02_dhcp-ping_pi-foo-dhcp.pcapng).

```
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.8? Tell 10.10.0.1
```

Now here's an interesting bit: `pi-foo-02` got an IP address of `10.10.0.8`. That's a little... unexpected. What happened there? It bugs me to no end because I'm a bit of a stickler for consistency. I want `pi-foo-02` to end in `.2`.

Is there anything that I can do about the IP addresses these devices get?

## You can just ask for what you want

With DHCP, you have two ways of getting a specific IPv4 address: first, by the client _politely_ requesting it; and second, by configuring the DHCP server itself to associate specific MAC addresses with specific IPs. The former has to be polite, because the DHCP server gets the final say as to which addresses go where.

Still, I'd like to have the Pis politely ask. Doing so requires a single line of configuration.

```
# /etc/NetworkManager/dhclient-eth0.conf
send dhcp-requested-address 10.10.0.2;
```

Changing that preference doesn't replace the lease I already have for `.8`. If I clear that and reactivate the profile, I can watch a fresh exchange.

```
$ sudo nmcli connection down eth-dhcp
$ lease_uuid=$(nmcli -g connection.uuid connection show eth-dhcp)
$ sudo rm -f "/var/lib/NetworkManager/dhclient-${lease_uuid}-eth0.lease"
```

I also need to clean up dnsmasq on `pi-foo-dhcp`:

```
sudo systemctl stop dnsmasq
sudo truncate -s 0 /var/lib/misc/dnsmasq.leases
sudo systemctl start dnsmasq
```

With everything reset, I can restart `tsharkie` on `pi-foo-02` and `pi-foo-dhcp`.

```
$ tsharkie lesson-02_nm-request_$(hostname).pcapng -f 'arp or icmp or (udp and (port 67 or port 68))'
```

In the second terminal on `pi-foo-02`, I reactivate the existing connection.

```
$ sudo nmcli connection up eth-dhcp
```

BAM! `pi-foo-02` immediately requests and receives `.2`.

Here's [pi-foo-02's side of the exchange](evidence/captures/2026-09-09-nm-preference/lesson-02_nm-request_pi-foo-02.pcapng). These excerpts were regenerated from the saved captures with tsharkie's formatting. They show only transaction `0x7289b37f`, with the original frame numbers intact.

```text
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x7289b37f
   3 |    3.005 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP Offer    - Transaction ID 0x7289b37f
   4 |    3.006 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x7289b37f
   5 |    3.013 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x7289b37f
```

And here’s [the server’s view](evidence/captures/2026-09-09-nm-preference/lesson-02_nm-request_pi-foo-dhcp.pcapng).

```text
 No. |  Time(s) | Source                     | Destination                | Proto    | Info
   1 |    0.000 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x7289b37f
   3 |    3.004 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP Offer    - Transaction ID 0x7289b37f
   4 |    3.006 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x7289b37f
   5 |    3.013 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x7289b37f
```

The same transaction ID connects all four messages in both views. The
[decoded client fields](evidence/captures/2026-09-09-nm-preference/pi-foo-02-dhcp-fields.tsv)
show `.2` in the requested-address option in Discover and Request, and `.2`
in the address assigned by Offer and ACK.

I can also use `tshark` to look inside a single frame. What happens if I take a look at just that first frame? Will I see the preference I set there?

```shell
$ tshark -n -r ~/cap/lesson-02_nm-request_pi-foo-02.pcapng \
    -Y 'frame.number == 1' \
    -O dhcp

...

      Option: (53) DHCP Message Type (Discover)
          Length: 1
          DHCP: Discover (1)
      Option: (50) Requested IP Address (10.10.0.2)
          Length: 4
          Requested IP Address: 10.10.0.2
```

Yep. The Pi politely asks for `10.10.0.2`. In the frames that follow, the server offers it, the Pi requests it, and the server ACKs it. Amazing. Stunning. _Perfect_.

I can now give `pi-foo-01` the matching preference for `10.10.0.1`. Both Pis will ask for addresses that match their names, and the server will decide whether to grant them. Time to put the whole network back together and see it happen.

## Ready for an end-to-end rip?

That begins by unplugging all the Ethernet cables and clearing the clients' leases. Their `.1` and `.2` preferences stay.

```shell
$ sudo nmcli connection down eth-dhcp
$ lease_uuid=$(nmcli -g connection.uuid connection show eth-dhcp)
$ sudo rm -f "/var/lib/NetworkManager/dhclient-${lease_uuid}-eth0.lease"
```

On `pi-foo-dhcp`, I stop `dnsmasq` and empty its lease file. Its configuration and the `10.10.0.254/24` address I added earlier stay in place.

```shell
$ sudo systemctl stop dnsmasq
$ sudo truncate -s 0 /var/lib/misc/dnsmasq.leases
```

One final check to make sure that everything is down. Yep? Yep.

Time to rip it. Start `tsharkie` everywhere.

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

They come up on `10.10.0.1` and `10.10.0.2`. I send a ping from `pi-foo-01` to `pi-foo-02`. It works. And the whole story is recorded in the captures.

Here’s [pi-foo-01 getting its address and sending a ping](evidence/captures/2026-09-09-e2e/lesson-02_dhcp-e2e_pi-foo-01.pcapng).

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

And [pi-foo-02 getting its address and answering](evidence/captures/2026-09-09-e2e/lesson-02_dhcp-e2e_pi-foo-02.pcapng).

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

Meanwhile, [pi-foo-dhcp sees both clients asking for addresses](evidence/captures/2026-09-09-e2e/lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng).

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

I can now plug in both Pis, watch them automatically receive their IPv4 addresses, and `ping` between them. The switch carries their frames, DHCP supplies their addresses, and the successful `ping` proves they can communicate.

I could've also done that by buying a fancier router and plopping that in place of the switch, but then I wouldn't have gotten all these amazing captures. I wouldn't have seen it end to end. I wouldn't have watched it all come together on this old desk. And I wouldn't be able to share it all here to make this project tangible, visual, and reproducible anywhere else.

To me, that's well worth the extra trouble.

### What happened, frame by frame

Let's look at this from [pi-foo-01's point of view](evidence/captures/2026-09-09-e2e/lesson-02_dhcp-e2e_pi-foo-01.pcapng).

#### Frames 2, 6, 7, and 8: DORA in one go

```
   2 |    0.071 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Discover - Transaction ID 0x3449fa25
   6 |    5.910 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP Offer    - Transaction ID 0x3449fa25
   7 |    5.911 | 0.0.0.0                    | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3449fa25
   8 |    5.926 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25 
```

Remember how I described the four steps of DORA? Discover, Offer, Request, and Acknowledge? Here they are in the frames themselves.

In frame 2, `pi-foo-01` broadcasts its Discover from `0.0.0.0`, because it doesn't have an IPv4 address on `eth0` yet. In frame 6, the server offers `10.10.0.1`. The Pi requests that offer in frame 7, and the server confirms the lease with an ACK in frame 8. NetworkManager then applies the address to `eth0`.

All four steps of DORA share the same transaction ID, `0x3449fa25`, which makes it easier to follow individual exchanges even as they overlap with others.

#### Frame 10: a gratuitous shout (of ARP)

```
  10 |    5.981 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | ARP Announcement for 10.10.0.1
```

Less than a tenth of a second after the server acknowledges the lease, `pi-foo-01` announces it to the network.

#### Frames 20–26 (minus 24): The ARP and ICMP/ping handshakes

```text
  20 |   18.210 | b8:27:eb:3a:e2:c8          | ff:ff:ff:ff:ff:ff          | ARP      | Who has 10.10.0.2? Tell 10.10.0.1
  21 |   18.210 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
  22 |   18.210 | 10.10.0.1                  | 10.10.0.2                  | ICMP     | Echo (ping) request  id=0x0014, seq=1/256, ttl=64
  23 |   18.211 | 10.10.0.2                  | 10.10.0.1                  | ICMP     | Echo (ping) reply    id=0x0014, seq=1/256, ttl=64 (request in 22)
  25 |   23.349 | b8:27:eb:7d:e8:ee          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.2
  26 |   23.349 | b8:27:eb:3a:e2:c8          | b8:27:eb:7d:e8:ee          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
```

About 18 seconds after starting the capture, I fire off a ping from one Pi to the next. Through ARP, it asks the network who has `10.10.0.2`, gets an answer, caches it, fires off its ping, and then responds when `pi-foo-02` asks the same question back.

We're cookin'.

Now, two fun oddities I want to point out among all these captures.

### Even the DHCP server uses ARP

Back in [the server’s capture](evidence/captures/2026-09-09-e2e/lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng), there’s something else going on.

```
  17 |   38.840 | 10.10.0.254                | 10.10.0.2                  | DHCP     | DHCP ACK      - Transaction ID 0x329ce6b
  18 |   38.846 | 10.10.0.254                | 10.10.0.1                  | DHCP     | DHCP ACK      - Transaction ID 0x3449fa25
  ...
  26 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:3a:e2:c8          | ARP      | Who has 10.10.0.1? Tell 10.10.0.254
  27 |   44.019 | b8:27:eb:ba:c7:ba          | b8:27:eb:7d:e8:ee          | ARP      | Who has 10.10.0.2? Tell 10.10.0.254
  28 |   44.020 | b8:27:eb:3a:e2:c8          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.1 is at b8:27:eb:3a:e2:c8
  29 |   44.020 | b8:27:eb:7d:e8:ee          | b8:27:eb:ba:c7:ba          | ARP      | 10.10.0.2 is at b8:27:eb:7d:e8:ee
```

In frames 17–18, you see `pi-foo-dhcp` ACK-ing and handing out two leases.

Roughly 5 seconds later, it sends ARP requests, but unlike many of these requests we've seen already, these go directly to the MAC addresses of the Pis instead of the broadcast. They both answer with the IPs they've just been given.

This looks like Linux double-checking the ARP cache it already has. Handing out an IPv4 address and keeping track of it are _two different jobs_, and here I can see it all happening in the frames passing across the network.

Very cool.

### The switch is a DHCP client, too

I've neglected the switch a bit in this whole exercise, haven't I? Well, it turns out the switch wants an IPv4 address for its management interface, even though it doesn't need one to do the job of passing Ethernet frames around. In many of the captures, it's repeatedly asking to keep `10.10.0.12`.

```
   1 |    0.000 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddb
   2 |    5.001 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddc
   3 |   10.005 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddd
   4 |   15.008 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3dde
   5 |   20.014 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3ddf
   6 |   25.015 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de0
   7 |   30.019 | 10.10.0.12                 | 255.255.255.255            | DHCP     | DHCP Request  - Transaction ID 0x3de1
```

An earlier version of my DHCP configuration had set dnsmasq's `dhcp-range` from `.1-.50`, which could explain where it got `.12` from. I don't have a record of the original lease assignment, but this does definitively show that just because I reset all the Pis and their DHCP leases, I didn't reset _everything_ on the network.

Time will tell whether I can figure out how to reset the switch, too.

Later, the server log records a fresh DORA for the switch, assigning it `.3`.

```
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPDISCOVER(eth0) 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPOFFER(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPREQUEST(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPACK(eth0) 10.10.0.3 3c:78:95:3e:f4:62 TL-SG108E
```

## Where does the little internet stand now?

Okay. Let's turn back to the question that started this session.

*Who the heck hands out IP addresses on a local network?*

For a time, I thought the switch would do this work for me. Turns out for two Pis, that switch provides all the same connectivity as a single Ethernet cable, but costs about $30 extra and doesn't do anything for Layer 3 identity, because it can't hand out addresses. It did give me some fun frames to watch, made the DHCP server possible (and observable), and enables everything that comes next. Overall, it was a win.

The answer is actually a **DHCP server**. I now know much more tangibly that a DHCP server isn't some magical property of network hardware, but a program that runs on a machine with an address of its own. In this little internet, that's a $35 Pi running `dnsmasq` with a ten-address pool.

What's become very clear to me now is that "it just works" is many frames, using many protocols, across many services. No single one of them carries the burden; only together, through all those questions asked and answers written down, does this intricate system work.

And I can see it all happen in the packet capture _and_ the OLEDs. The little internet is starting to feel like a lot more than a tiny demo or silly art project.

It would be tempting to lean into that energy and buy a _second_ switch, plus a handful more Pis, and really
start to make this one minuscule network part of something much larger. I really do want to know what happens when a packet from
`pi-foo-01` doesn't just stop at the local network.

That's routing, and it's coming soon.

But, for now, there are some more obvious questions to ask, ranging from
practical to utterly ridiculous:

- **What else can I visualize on the OLEDs?** Maybe what happens when two DHCP clients ask for the same IP address?
- **How does the switch actually decide which port to send frames to?** Now that the
  switch sits on `10.10.0.3`, I can answer that with port mirroring.
- **What happens if I plug the switch into itself?** Endless recursion?
- **What happens if there are two DHCP servers on the same local network?**
  Apparently, this is a real thing that happens on occasion and I'd love to know
  what the packet chatter looks like.
- **How many feet of Ethernet cable before it fails?** I've heard that's around
  300 feet, but I have the perfect testbed in which to see _exactly_ where... or
  at least to the nearest multiple of 50 (feet).

Have ideas of your own? Drop an
[issue](https://github.com/ngrok/little-internet/issues) or an
[email](mailto:joel@ngrok.com).
