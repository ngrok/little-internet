# B04: dnsmasq warning with unaddressed eth0

Joel reported this startup warning:

```text
Sep 09 17:14:48 pi-foo-dhcp dnsmasq[13798]: warning: interface eth0 does not currently exist
```

Read-only SSH checks after the report; no configuration or service changes:

`ip addr show dev eth0` returned:

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b8:27:eb:ba:c7:ba brd ff:ff:ff:ff:ff:ff
```

`nmcli -f GENERAL.STATE,GENERAL.CONNECTION,WIRED-PROPERTIES.CARRIER device show eth0`:

```text
GENERAL.STATE:                          30 (disconnected)
GENERAL.CONNECTION:                     --
WIRED-PROPERTIES.CARRIER:               on
```

`systemctl is-active dnsmasq` returned `active`. Journal excerpt:

```text
Sep 09 17:14:48 pi-foo-dhcp dnsmasq[13798]: warning: interface eth0 does not currently exist
Sep 09 17:14:48 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP, IP range 10.10.0.1 -- 10.10.0.10, lease time 12h
```

The assumed `/etc/dnsmasq.d/little-internet.conf` did not exist (cat reported
No such file or directory). Inspection located these active settings instead
in `/etc/dnsmasq.conf`, with no other non-comment lines in that file:

```ini
interface=eth0
dhcp-range=10.10.0.1,10.10.0.10,12h
```

`log-dhcp` is not enabled in this file. Current link exists and has carrier,
but has neither an IPv4 nor an IPv6 address. dnsmasq remains running.

Source check: dnsmasq v2.90 src/dnsmasq.c warns for configured interface names
not marked INAME_USED; src/network.c enumerates IPv4/IPv6 addresses and marks
matching interface names. Lack of any IP address is consistent with this
warning even though the kernel device exists. Sources:
https://raw.githubusercontent.com/imp/dnsmasq/v2.90/src/dnsmasq.c
https://raw.githubusercontent.com/imp/dnsmasq/v2.90/src/network.c

This supports investigating address configuration but does not establish a
received Discover, a failed allocation, or the cause of historical success.
Next conceptual checkpoint: inspect Joel's server eth0 capture for a client
Discover while retaining this state, and compare with the service log.

## Client retry timing

Joel reported no Discover in the server capture and no client address. A
read-only check of pi-foo-01 returned:

```text
GENERAL.STATE:                          30 (disconnected)
GENERAL.CONNECTION:                     --
GENERAL.AUTOCONNECT:                    yes
WIRED-PROPERTIES.CARRIER:               on
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.dhcp-timeout:                      10
```

`ip -4 addr show dev eth0` emitted nothing. The client journal records link-up
and DHCP activation at 17:13:10, repeated failures, and this final failure:

```text
Sep 09 17:13:56 pi-foo-01 NetworkManager[663]: <info>  [1788999236.1251] device (eth0): state change: ip-config -> failed (reason 'ip-config-unavailable', sys-iface-state: 'managed')
Sep 09 17:13:56 pi-foo-01 NetworkManager[663]: <warn>  [1788999236.1268] device (eth0): Activation: failed for connection 'eth-dhcp'
Sep 09 17:13:56 pi-foo-01 NetworkManager[663]: <info>  [1788999236.1276] device (eth0): state change: failed -> disconnected (reason 'none', sys-iface-state: 'managed')
```

The logged failures precede the server's 17:14:48 startup. Current disconnected
state supports that client acquisition attempts have stopped. This does not
establish which packets reached the server earlier. Next: leave captures and
server configuration in place and explicitly activate eth-dhcp on client 01
to observe a new attempt. The retry has not been run by the agent.

## Request reaches the unaddressed server

Joel reports that explicitly activating eth-dhcp on client 01 triggered a
Discover visible in his capture. He supplied this server output:

```text
Sep 09 17:17:23 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
Sep 09 17:17:25 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
Sep 09 17:17:29 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
```

This is user-supplied evidence of DHCP receipt by dnsmasq and an explicit
missing-interface-address diagnostic. The current service can receive DHCP
packets despite the earlier startup warning. This does not yet establish that
adding an address is sufficient for successful assignment.

Proposed next comparison: add 10.10.0.254/24 to server eth0 temporarily with
`sudo ip addr add 10.10.0.254/24 dev eth0`, outside the configured .1–.10 pool,
then explicitly activate client eth-dhcp again while keeping captures, cables,
and dnsmasq process/configuration unchanged. This temporary kernel configuration
isolates the address/prefix addition from creating or activating a new
NetworkManager profile; make the successful server setup persistent afterward.
No address addition or successful lease observed at this checkpoint.

## Successful acquisition after the address change

Joel reports adding the server address and obtaining full DORA in tshark,
with client 01 receiving the intended IP. Read-only verification afterward:

Client `ip -4 addr show dev eth0`:

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.1/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 43099sec preferred_lft 43099sec
```

Server `ip -4 addr show dev eth0` and `systemctl show dnsmasq -p MainPID`:

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.254/24 scope global eth0
       valid_lft forever preferred_lft forever
MainPID=13798
```

Contiguous final six lines of `journalctl -u dnsmasq -n 15 --no-pager`
(the preceding nine lines repeat the earlier no-address diagnostic):

```text
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPREQUEST(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPACK(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8 pi-foo-01
```

The service PID matches the earlier failed attempts. This supports that adding
the server address/prefix enabled assignment on the subsequent client attempt
without restarting dnsmasq in this setup. It does not establish the cause of
the historical cut, client address preference behavior, or two-client
communication. Full packet capture is reported by Joel, not yet independently
decoded here; preserve its filename before overwriting. Server addressing is
currently temporary and still needs a persistent NetworkManager configuration.
