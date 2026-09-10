# Server inventory — 2026-09-09

Read-only inspection of `pi@pi-foo-dhcp.local`. No service, address,
configuration, or lease changes were made. Client hosts were confirmed by
Joel but have not been inspected yet. These are actual output excerpts;
configuration and lease data do not establish current client-side ownership.

## Initial address and service check

From `hostname` and `ip -4 addr show dev eth0`:

```text
pi-foo-dhcp
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.254/24 brd 10.10.0.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
```

The initial unqualified version command failed:

```text
bash: line 3: dnsmasq: command not found
```

`systemctl show dnsmasq` reported ActiveState=active, SubState=running,
MainPID=11401, and FragmentPath=/lib/systemd/system/dnsmasq.service.
The unit launches /usr/share/dnsmasq/systemd-helper. Reading the running
process executable resolved /usr/sbin/dnsmasq; the corrected version command
succeeded below. The shell lookup failure was not a service failure.

## Configuration

All active lines returned from `/etc/dnsmasq.conf`:

```text
685:conf-dir=/etc/dnsmasq.d/,*.conf
```

All active lines returned by
`sudo -n grep -nHEv '^[[:space:]]*(#|$)' /etc/dnsmasq.d/*.conf`:

```text
/etc/dnsmasq.d/little-internet.conf:33:interface=eth0
/etc/dnsmasq.d/little-internet.conf:34:bind-dynamic
/etc/dnsmasq.d/little-internet.conf:39:port=0
/etc/dnsmasq.d/little-internet.conf:62:dhcp-authoritative
/etc/dnsmasq.d/little-internet.conf:75:dhcp-option=3
/etc/dnsmasq.d/little-internet.conf:76:dhcp-option=6
/etc/dnsmasq.d/little-internet.conf:86:log-dhcp
/etc/dnsmasq.d/little-internet.conf:101:dhcp-range=10.10.0.1,10.10.0.50,12h
/etc/dnsmasq.d/little-internet.conf:115:dhcp-host=pi-foo-01,10.10.0.1
/etc/dnsmasq.d/little-internet.conf:116:dhcp-host=pi-foo-02,10.10.0.2
```

The directory listing contained little-internet.conf and README. The process
arguments included `-7 /etc/dnsmasq.d,.dpkg-dist,.dpkg-old,.dpkg-new` and no
lease-file override. The complete unit/helper text and directory listing are
omitted here; neither has been saved as a restoration backup.

## Corrected version, lease-file default, environment, and journal

Complete output from this command group, in order:

```bash
/usr/sbin/dnsmasq --version
/usr/sbin/dnsmasq --help | grep -E 'leasefile|lease file'
sudo -n grep -nEv '^[[:space:]]*(#|$)' /etc/default/dnsmasq
sudo -n journalctl -u dnsmasq -n 25 --no-pager
```

```text
Dnsmasq version 2.90  Copyright (c) 2000-2024 Simon Kelley
Compile time options: IPv6 GNU-getopt DBus no-UBus i18n IDN2 DHCP DHCPv6 no-Lua TFTP conntrack ipset nftset auth cryptohash DNSSEC loop-detect inotify dumpfile

This software comes with ABSOLUTELY NO WARRANTY.
Dnsmasq is free software, and you are welcome to redistribute it
under the terms of the GNU General Public License, version 2 or 3.
-l, --dhcp-leasefile=<path>                            Specify where to store DHCP leases (defaults to /var/lib/misc/dnsmasq.leases).
-9, --leasefile-ro                                     Do not use leasefile.
29:CONFIG_DIR=/etc/dnsmasq.d,.dpkg-dist,.dpkg-old,.dpkg-new
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 54 server-identifier  10.10.0.254
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 51 lease-time  12h
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 58 T1  6h
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 59 T2  10h30m
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option:  1 netmask  255.255.255.0
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 28 broadcast  10.10.0.255
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 available DHCP range: 10.10.0.1 -- 10.10.0.50
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 client provides name: pi-foo-02
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 DHCPREQUEST(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 tags: known, eth0
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 DHCPACK(eth0) 10.10.0.2 b8:27:eb:7d:e8:ee pi-foo-02
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 requested options: 1:netmask, 2:time-offset, 6:dns-server, 12:hostname,
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 requested options: 15:domain-name, 26:mtu, 28:broadcast, 121:classless-static-route,
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 requested options: 3:router, 33:static-route, 40:nis-domain,
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 requested options: 41:nis-server, 42:ntp-server, 119:domain-search,
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 requested options: 249, 252, 17:root-path
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 next server: 10.10.0.254
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  1 option: 53 message-type  5
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 54 server-identifier  10.10.0.254
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 51 lease-time  12h
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 58 T1  6h
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 59 T2  10h30m
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option:  1 netmask  255.255.255.0
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  4 option: 28 broadcast  10.10.0.255
Sep 09 13:12:14 pi-foo-dhcp dnsmasq-dhcp[11401]: 4280283188 sent size:  9 option: 12 hostname  pi-foo-02
```

## Lease-file contents

Complete output from
`sudo -n cat /var/lib/misc/dnsmasq.leases`:

```text
1789027934 b8:27:eb:7d:e8:ee 10.10.0.2 pi-foo-02 01:b8:27:eb:7d:e8:ee
1789027928 b8:27:eb:3a:e2:c8 10.10.0.1 pi-foo-01 01:b8:27:eb:3a:e2:c8
```

## Implication for the runbook

The server already has a corrected host address (.254/24) and two
hostname-based address assignments. Remove those assignments from the
preserved-and-reviewed experiment configuration before comparing allocation
without a preference against allocation with a client preference. Otherwise,
matching .1/.2 would also be explained by the server configuration.

A lease file still contains entries for both clients. This alone does not
prove whether Joel's release affected these leases, whether another client
reacquired, or whether either interface still has an address. Inspect the
clients before selecting mutation commands. Server lease reset has not run.

Technical reference: [dnsmasq manual, --dhcp-host](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html),
inspected 2026-09-09, supports interpreting the two hostname/address directives.

