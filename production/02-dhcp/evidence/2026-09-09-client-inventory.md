# Client ownership inventory — 2026-09-09

Read-only SSH as `pi` to the confirmed client hostnames. Both logins succeeded.
No network configuration, service, address, or lease state was changed.

Commands inside each SSH session:

```bash
hostname
ip -4 addr show dev eth0
nmcli --version
nmcli -f GENERAL.STATE,GENERAL.CONNECTION device show eth0
nmcli -f NAME,UUID,TYPE,DEVICE connection show --active
pgrep -a -x dhclient
pgrep -a -x dhcpcd
true
```

The trailing `true` keeps an empty process search from making the overall SSH
command report failure. Neither process search printed a match on either node.

## pi-foo-01.local — complete stdout

```text
pi-foo-01
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.1/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 42438sec preferred_lft 42438sec
nmcli tool, version 1.42.4
GENERAL.STATE:                          100 (connected)
GENERAL.CONNECTION:                     eth-dhcp
NAME           UUID                                  TYPE      DEVICE
preconfigured  e957098c-d08c-381d-847d-99547ad86773  wifi      wlan0
eth-dhcp       ea4302a7-a8e0-43f3-8aae-d9bb45eed4db  ethernet  eth0
lo             c142f93e-d020-4445-af19-880c80e56812  loopback  lo
```

## pi-foo-02.local — complete stdout

```text
pi-foo-02
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.2/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 42445sec preferred_lft 42445sec
nmcli tool, version 1.42.4
GENERAL.STATE:                          100 (connected)
GENERAL.CONNECTION:                     eth-dhcp
NAME           UUID                                  TYPE      DEVICE
preconfigured  e957098c-d08c-381d-847d-99547ad86773  wifi      wlan0
eth-dhcp       52a876a2-2ccb-4312-a07c-a6a6ae171035  ethernet  eth0
lo             73864f4e-b2dd-4f91-a74e-65675913a4dc  loopback  lo
```

Trailing table padding omitted; no output rows omitted. No stderr was emitted.

## Supported conclusion and limits

NetworkManager reports both Ethernet interfaces connected under `eth-dhcp`.
Both retain dynamic IPv4 addresses (.1/.2) at inspection time; neither is in
the intended blank starting state. `nmcli` reports version 1.42.4 on both.
No process named exactly dhclient or dhcpcd was found. This supports using
NetworkManager to control the interfaces, but does not by itself prove the
DHCP backend or the history of Joel's earlier release commands.

Next checkpoint: inspect NetworkManager's DHCP backend via effective
configuration/service logs and the relevant Ethernet profile. Do not select
lease-file mutation commands until that is established. Active Wi-Fi profiles
are visible; the route carrying SSH has not been separately verified.
