# Switch DHCP requests and later lease

Read-only investigation prompted by Joel's repeated five-second DHCP Requests.
No lab settings changed. Source: the archived server e2e capture and a later
SSH read of dnsmasq configuration, leases, and journal on pi-foo-dhcp.

The e2e server capture begins at 2026-09-09 21:11:14 local time. Its thirteen
DHCP packets for MAC 3c:78:95:3e:f4:62 are Requests, every approximately five
seconds, through frame 34 at relative 60.044500405. They identify TL-SG108E in
hostname/vendor options, use IP source and ciaddr 10.10.0.12, broadcast to
255.255.255.255, and omit requested-address and server-identifier options.
No Discover, Offer, ACK, or NAK for the switch appears in that capture.

Those fields match the REBINDING message shape in
[RFC 2131 section 4.3.2](https://www.rfc-editor.org/rfc/rfc2131.html#section-4.3.2).
Interpretation: the switch is trying to extend/retain an existing address,
not demonstrating a freshly granted lease. Its firmware state and the origin
of .12 remain unverified; do not infer the exact retry algorithm from timing.

## Follow-up: where could .12 have come from?

The [pre-reflash server inventory](2026-09-09-server-inventory.md) preserved
this active configuration from `/etc/dnsmasq.d/little-internet.conf`:

```text
/etc/dnsmasq.d/little-internet.conf:101:dhcp-range=10.10.0.1,10.10.0.50,12h
```

Its saved journal also confirms the running server advertised the .1–.50 pool
at 13:12:14 on Sep 09. Thus .12 was eligible under that earlier setup, making
a retained pre-reflash lease a concrete possibility. The inventory's lease
snapshot contains only the two Pis, however, and no switch .12 ACK has been
located. The eleven initial fresh-build captures contain no DHCP packets for
the switch MAC. The current server journal records .1–.10 pool starts and the
later .3 grant, but no .12 grant. The old pool explains how .12 could have
been assigned; it does not prove that it was the source.

## Current server and later successful assignment

The inspected dnsmasq configuration has interface=eth0 and
dhcp-range=10.10.0.1,10.10.0.10,12h, with no dhcp-authoritative directive.
.12 is outside that dynamic pool. A remembered lease no longer known to the
server is a plausible explanation for unanswered requests after resets;
[dnsmasq's manual](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)
documents ignoring unknown-lease requests without authoritative mode.
The capture alone does not prove the exact server decision.

Later journal excerpt, verbatim:

```text
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPDISCOVER(eth0) 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPOFFER(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPREQUEST(eth0) 10.10.0.3 3c:78:95:3e:f4:62
Sep 09 21:58:49 pi-foo-dhcp dnsmasq-dhcp[26951]: DHCPACK(eth0) 10.10.0.3 3c:78:95:3e:f4:62 TL-SG108E
```

Current lease-file entry:

```text
1789059529 3c:78:95:3e:f4:62 10.10.0.3 TL-SG108E 01:3c:78:95:3e:f4:62
```

This confirms a later server grant of .3, about 47 minutes after the e2e
recording began. It does not establish whether five-second requests continue
after that ACK; a later capture would be needed. The switch's management
interface uses DHCP as a client; Ethernet forwarding itself does not require
that management IPv4 address.
