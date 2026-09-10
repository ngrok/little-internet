# Fresh-image readiness check — 2026-09-09

## Follow-up after unplugging

Joel confirmed both client Ethernet cables were unplugged and the DHCP Pi was
fully disconnected. Restored pi-foo-01's device autoconnect over management SSH:

```bash
sudo -n nmcli device set eth0 autoconnect yes
```

The command exited successfully with no output. Then ran hostname, the device
check below, and `ip -4 addr show dev eth0` on each client:

```bash
nmcli -f GENERAL.AUTOCONNECT,GENERAL.STATE,WIRED-PROPERTIES.CARRIER device show eth0
```

Actual output (IPv4 address checks printed nothing):

```text
pi-foo-01
GENERAL.AUTOCONNECT:                    yes
GENERAL.STATE:                          20 (unavailable)
WIRED-PROPERTIES.CARRIER:               off
```

```text
pi-foo-02
GENERAL.AUTOCONNECT:                    yes
GENERAL.STATE:                          20 (unavailable)
WIRED-PROPERTIES.CARRIER:               off
```

Both clients now permit automatic activation and report no carrier and no IPv4
address on eth0. Next: Joel starts unfiltered tsharkie captures in his client
terminals before reconnecting Ethernet. Reconnect behavior remains unobserved.

## Initial inspection

Read-only SSH inspection of all three confirmed hosts, after Joel reflashed.
No interface settings, profiles, leases, or services were changed. diary.md was
read to match the starting beat and was not edited.

## Findings

All three have only the expected Wi-Fi, loopback, and eth-dhcp profiles. eth-dhcp
is bound to eth0, with profile autoconnect yes, IPv4 auto, no configured static
IPv4 address, never-default yes, and IPv6 auto. No IPv4 address or route on eth0
was printed. dnsmasq reported inactive and no exact dhclient/dhcpcd process
matches were returned. No lease files matched the inspected NetworkManager
eth0 or dhclient lease paths; this is limited to those paths.

pi-foo-01 has a device-level autoconnect block (GENERAL.AUTOCONNECT no), with
reason 39: disconnected by user or client. pi-foo-02 has device autoconnect yes.
Both client Ethernet links currently report carrier on. pi-foo-dhcp reports
autoconnect yes and carrier off. The switch topology itself has not been
physically verified.

Next physical checkpoint: Joel disconnects both client Ethernet cables while
keeping management Wi-Fi connected. Then restore pi-foo-01's device autoconnect
and verify the state before starting captures and asking him to plug in.
Do not reflash or delete eth-dhcp. Capture actual reconnect behavior before
claiming the baseline is fully rehearsed.

The current diary's tsharkie line needs positional filename syntax and an empty
capture filter for B02's IPv6/mDNS/Realtek observations:

```bash
tsharkie "lesson-02_link-switch_$(hostname).pcapng" -f ''
```

No -w option is implemented by the wrapper. Default filtering would exclude
some of the traffic the diary intends to discuss. The helper currently formats
relative time rounded to milliseconds; the diary's existing raw tshark example
uses delta time. Record new actual output rather than treating the formats as
identical.

## Commands

Initial inventory:

```bash
hostname
nmcli -f NAME,UUID,TYPE,DEVICE connection show
nmcli -f GENERAL.STATE,GENERAL.CONNECTION device show eth0
ip -4 addr show dev eth0
ip route show dev eth0
nmcli -f connection.id,connection.interface-name,connection.autoconnect,ipv4.method,ipv4.addresses,ipv4.never-default,ipv6.method connection show eth-dhcp
systemctl is-active dnsmasq
pgrep -a -x dhclient
pgrep -a -x dhcpcd
true
```

Follow-up:

```bash
hostname
nmcli -f GENERAL,WIRED-PROPERTIES device show eth0
ip link show dev eth0
sudo -n sh -c 'for f in /var/lib/NetworkManager/*eth0*.lease /var/lib/dhcp/dhclient*.leases; do if [ -f "$f" ]; then printf "\nLease file: %s\n" "$f"; cat "$f"; fi; done'
```

## Actual output

Trailing padding in tables is omitted below; no output rows omitted. All six
SSH calls completed successfully and emitted no stderr. The initial command
ends in true so empty process searches do not set the SSH exit code.

### pi-foo-01.local

Initial inventory:

```text
pi-foo-01
NAME           UUID                                  TYPE      DEVICE
preconfigured  e957098c-d08c-381d-847d-99547ad86773  wifi      wlan0
lo             6bafc31b-312c-4aa8-be1b-09ba8ee80051  loopback  lo
eth-dhcp       ea4302a7-a8e0-43f3-8aae-d9bb45eed4db  ethernet  --
GENERAL.STATE:                          30 (disconnected)
GENERAL.CONNECTION:                     --
connection.id:                          eth-dhcp
connection.interface-name:              eth0
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.addresses:                         --
ipv4.never-default:                     yes
ipv6.method:                            auto
inactive
```

Follow-up:

```text
pi-foo-01
GENERAL.DEVICE:                         eth0
GENERAL.TYPE:                           ethernet
GENERAL.NM-TYPE:                        NMDeviceEthernet
GENERAL.DBUS-PATH:                      /org/freedesktop/NetworkManager/Devices/2
GENERAL.VENDOR:                         Microchip Technology, Inc. (formerly SMSC)
GENERAL.PRODUCT:                        SMSC9512/9514 Fast Ethernet Adapter
GENERAL.DRIVER:                         smsc95xx
GENERAL.DRIVER-VERSION:                 6.12.96+rpt-rpi-v8
GENERAL.FIRMWARE-VERSION:               smsc95xx USB 2.0 Ethernet
GENERAL.HWADDR:                         B8:27:EB:3A:E2:C8
GENERAL.MTU:                            1500
GENERAL.STATE:                          30 (disconnected)
GENERAL.REASON:                         39 (Device disconnected by user or client)
GENERAL.IP4-CONNECTIVITY:               1 (none)
GENERAL.IP6-CONNECTIVITY:               1 (none)
GENERAL.UDI:                            /sys/devices/platform/soc/3f980000.usb/usb1/1-1/1-1.1/1-1.1:1.0/net/eth0
GENERAL.PATH:                           platform-3f980000.usb-usb-0:1.1:1.0
GENERAL.IP-IFACE:                       --
GENERAL.IS-SOFTWARE:                    no
GENERAL.NM-MANAGED:                     yes
GENERAL.AUTOCONNECT:                    no
GENERAL.FIRMWARE-MISSING:               no
GENERAL.NM-PLUGIN-MISSING:              no
GENERAL.PHYS-PORT-ID:                   --
GENERAL.CONNECTION:                     --
GENERAL.CON-UUID:                       --
GENERAL.CON-PATH:                       --
GENERAL.METERED:                        unknown
WIRED-PROPERTIES.CARRIER:               on
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether b8:27:eb:3a:e2:c8 brd ff:ff:ff:ff:ff:ff
```

### pi-foo-02.local

Initial inventory:

```text
pi-foo-02
NAME           UUID                                  TYPE      DEVICE
preconfigured  e957098c-d08c-381d-847d-99547ad86773  wifi      wlan0
lo             910ce616-28b1-4806-a057-f8214ae9b3f4  loopback  lo
eth-dhcp       ea4302a7-a8e0-43f3-8aae-d9bb45eed4db  ethernet  --
GENERAL.STATE:                          30 (disconnected)
GENERAL.CONNECTION:                     --
connection.id:                          eth-dhcp
connection.interface-name:              eth0
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.addresses:                         --
ipv4.never-default:                     yes
ipv6.method:                            auto
inactive
```

Follow-up:

```text
pi-foo-02
GENERAL.DEVICE:                         eth0
GENERAL.TYPE:                           ethernet
GENERAL.NM-TYPE:                        NMDeviceEthernet
GENERAL.DBUS-PATH:                      /org/freedesktop/NetworkManager/Devices/2
GENERAL.VENDOR:                         Microchip Technology, Inc. (formerly SMSC)
GENERAL.PRODUCT:                        SMSC9512/9514 Fast Ethernet Adapter
GENERAL.DRIVER:                         smsc95xx
GENERAL.DRIVER-VERSION:                 6.12.96+rpt-rpi-v8
GENERAL.FIRMWARE-VERSION:               smsc95xx USB 2.0 Ethernet
GENERAL.HWADDR:                         B8:27:EB:7D:E8:EE
GENERAL.MTU:                            1500
GENERAL.STATE:                          30 (disconnected)
GENERAL.REASON:                         0 (No reason given)
GENERAL.IP4-CONNECTIVITY:               1 (none)
GENERAL.IP6-CONNECTIVITY:               1 (none)
GENERAL.UDI:                            /sys/devices/platform/soc/3f980000.usb/usb1/1-1/1-1.1/1-1.1:1.0/net/eth0
GENERAL.PATH:                           platform-3f980000.usb-usb-0:1.1:1.0
GENERAL.IP-IFACE:                       --
GENERAL.IS-SOFTWARE:                    no
GENERAL.NM-MANAGED:                     yes
GENERAL.AUTOCONNECT:                    yes
GENERAL.FIRMWARE-MISSING:               no
GENERAL.NM-PLUGIN-MISSING:              no
GENERAL.PHYS-PORT-ID:                   --
GENERAL.CONNECTION:                     --
GENERAL.CON-UUID:                       --
GENERAL.CON-PATH:                       --
GENERAL.METERED:                        unknown
WIRED-PROPERTIES.CARRIER:               on
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether b8:27:eb:7d:e8:ee brd ff:ff:ff:ff:ff:ff
```

### pi-foo-dhcp.local

Initial inventory:

```text
pi-foo-dhcp
NAME           UUID                                  TYPE      DEVICE
preconfigured  e957098c-d08c-381d-847d-99547ad86773  wifi      wlan0
lo             c212f548-d854-4915-a25d-57184735c467  loopback  lo
eth-dhcp       ea4302a7-a8e0-43f3-8aae-d9bb45eed4db  ethernet  --
GENERAL.STATE:                          20 (unavailable)
GENERAL.CONNECTION:                     --
connection.id:                          eth-dhcp
connection.interface-name:              eth0
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.addresses:                         --
ipv4.never-default:                     yes
ipv6.method:                            auto
inactive
```

Follow-up:

```text
pi-foo-dhcp
GENERAL.DEVICE:                         eth0
GENERAL.TYPE:                           ethernet
GENERAL.NM-TYPE:                        NMDeviceEthernet
GENERAL.DBUS-PATH:                      /org/freedesktop/NetworkManager/Devices/2
GENERAL.VENDOR:                         Microchip Technology, Inc. (formerly SMSC)
GENERAL.PRODUCT:                        SMSC9512/9514 Fast Ethernet Adapter
GENERAL.DRIVER:                         smsc95xx
GENERAL.DRIVER-VERSION:                 6.12.96+rpt-rpi-v8
GENERAL.FIRMWARE-VERSION:               smsc95xx USB 2.0 Ethernet
GENERAL.HWADDR:                         B8:27:EB:BA:C7:BA
GENERAL.MTU:                            1500
GENERAL.STATE:                          20 (unavailable)
GENERAL.REASON:                         40 (Carrier/link changed)
GENERAL.IP4-CONNECTIVITY:               1 (none)
GENERAL.IP6-CONNECTIVITY:               1 (none)
GENERAL.UDI:                            /sys/devices/platform/soc/3f980000.usb/usb1/1-1/1-1.1/1-1.1:1.0/net/eth0
GENERAL.PATH:                           platform-3f980000.usb-usb-0:1.1:1.0
GENERAL.IP-IFACE:                       --
GENERAL.IS-SOFTWARE:                    no
GENERAL.NM-MANAGED:                     yes
GENERAL.AUTOCONNECT:                    yes
GENERAL.FIRMWARE-MISSING:               no
GENERAL.NM-PLUGIN-MISSING:              no
GENERAL.PHYS-PORT-ID:                   --
GENERAL.CONNECTION:                     --
GENERAL.CON-UUID:                       --
GENERAL.CON-PATH:                       --
GENERAL.METERED:                        unknown
WIRED-PROPERTIES.CARRIER:               off
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN mode DEFAULT group default qlen 1000
    link/ether b8:27:eb:ba:c7:ba brd ff:ff:ff:ff:ff:ff
```

