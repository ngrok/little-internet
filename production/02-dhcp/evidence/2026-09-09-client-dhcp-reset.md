# Client reset before DHCP acquisition

Joel confirmed client Ethernet was disconnected. Ran the repository helper
from the worktree root over management Wi-Fi:

```bash
MODE=ssh NO_COLOR=1 \
A_HOST=pi@pi-foo-01.local \
B_HOST=pi@pi-foo-02.local \
./lessons/00/scripts/reset.sh
```

The helper exited 0 and reported for each client:

```text
eth0 back to the DHCP baseline (eth-dhcp): no address, ready to chatter
```

Follow-up commands on each client:

```bash
hostname
nmcli -f NAME,TYPE,DEVICE connection show
nmcli -f connection.autoconnect,ipv4.method,ipv4.addresses connection show eth-dhcp
nmcli -f GENERAL.AUTOCONNECT,GENERAL.STATE,WIRED-PROPERTIES.CARRIER device show eth0
ip -4 addr show dev eth0
```

Actual output, with trailing whitespace removed:

```text
pi-foo-01
NAME           TYPE      DEVICE
preconfigured  wifi      wlan0
lo             loopback  lo
eth-dhcp       ethernet  --
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.addresses:                         --
GENERAL.AUTOCONNECT:                    yes
GENERAL.STATE:                          20 (unavailable)
WIRED-PROPERTIES.CARRIER:               off
```

```text
pi-foo-02
NAME           TYPE      DEVICE
preconfigured  wifi      wlan0
lo             loopback  lo
eth-dhcp       ethernet  --
connection.autoconnect:                 yes
ipv4.method:                            auto
ipv4.addresses:                         --
GENERAL.AUTOCONNECT:                    yes
GENERAL.STATE:                          20 (unavailable)
WIRED-PROPERTIES.CARRIER:               off
```

Both IPv4 address checks emitted no output. The manual eth profiles are gone;
eth-dhcp and device autoconnect are enabled. Clients are prepared to request
DHCP configuration when connected. This reset did not inspect or change the
server, clear lease history, or establish successful acquisition/full DORA.
Next checkpoint: start captures on both clients before reconnecting Ethernet.
