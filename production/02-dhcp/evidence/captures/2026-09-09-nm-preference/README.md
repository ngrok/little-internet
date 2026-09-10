# NetworkManager-managed address preference — 2026-09-09

One completed acquisition test on pi-foo-02. NetworkManager 1.42.4 launches
ISC dhclient 4.4.3-P1-2, imports the eth0-only requested address, and applies
the lease. All four DHCP messages use transaction ID `0x7289b37f`.

| Capture | Acquisition frames | Result |
| --- | --- | --- |
| [Pi 02](lesson-02_nm-request_pi-foo-02.pcapng) | 1, 3, 4, 5 | Discover requests .2; Offer and ACK assign .2 |
| [Server](lesson-02_nm-request_pi-foo-dhcp.pcapng) | 1, 3, 4, 5 | Same exchange observed on server eth0 |

Exact fields are in [client TSV](pi-foo-02-dhcp-fields.tsv) and
[server TSV](pi-foo-dhcp-dhcp-fields.tsv). DHCP option 53 values 1/2/3/5 mean
Discover/Offer/Request/ACK. Option 50 is .2 in Discover and Request. The offered
and acknowledged `yiaddr` is .2. Captures include ARP and ICMP traffic too.
Each capture has 10 packets. Both were recorded with tsharkie on eth0, using
its default filter and `--no-pager`, under an 18-second `timeout --signal=INT`.
Exit 124 was the intentional time limit; both captures decode successfully.

For the diary, the saved exchange is also available in tsharkie's table format:
[client excerpt](pi-foo-02-tsharkie-dora.txt) and
[server excerpt](pi-foo-dhcp-tsharkie-dora.txt). Generated on 2026-09-10 by
decoding each original with `tshark -n -r FILE -Y 'dhcp.id == 0x7289b37f'`,
extracting the same six fields as tools/tsharkie/tsharkie, and running that
script's unchanged awk formatter with `pager=yes` for compact rows. These
are saved-capture excerpts, not a new live run. Original frame numbers and
relative times are retained; times are rounded to milliseconds for display.
Only the four DHCP packets are shown; the six other packets in each file
remain in the original capture. The source capture bytes were not changed.

[manifest.json](manifest.json) and [SHA256SUMS](SHA256SUMS) preserve origins
and hashes. Remote hashes before/after transfer match the local files.
These files are local workspace copies, not a completed remote backup.

## Setup performed

Joel had released standalone dhclient and prepared the backend and eth0
configuration files. Inspection found no standalone dhclient, no eth0 IPv4
address, and an NM eth-dhcp profile still marked active. The .2 preference
also remained in global `/etc/dhcp/dhclient.conf`.

On Pi 02:

1. Backed up the three config files, standalone lease file, and NM profile
   settings to `/var/tmp/little-internet-b07-EISfuX` (root-only).
2. Removed only the global `send dhcp-requested-address 10.10.0.2;` line,
   retaining it in `/etc/NetworkManager/dhclient-eth0.conf`.
3. Ran `nmcli connection modify eth-dhcp connection.autoconnect no`, then
   `nmcli connection down eth-dhcp`. IPv4 address and route checks were empty.
4. Explicitly preserved the baseline DHCP client identifier with
   `nmcli connection modify eth-dhcp ipv4.dhcp-client-id 01:b8:27:eb:7d:e8:ee`.
5. Moved matching eth0 lease files out of /var/lib/NetworkManager and
   /var/lib/dhcp into the backup directory. Existing internal eth0 lease
   remembered .8; no NM dhclient eth0 lease existed before this first test.
6. Scheduled NetworkManager restart with systemd-run and a 120-second fallback
   to the internal backend. Restart loaded `[main] dhcp=dhclient`; Wi-Fi
   reconnected at 192.168.1.4 using NM-managed dhclient. Canceled fallback after
   reconnecting. The preference was absent from Wi-Fi's global source config.

On the server, stopped dnsmasq, backed up its lease file to
`/var/tmp/little-internet-b07-server-FcR5eh/dnsmasq.leases`, removed the single
binding for Pi 02's MAC, and restarted dnsmasq. Pi 01's .1 binding was retained.
The server's address stayed 10.10.0.254/24, with the existing .1–.10 pool.

Started both captures before running, on Pi 02:

```bash
sudo nmcli --wait 15 connection up eth-dhcp
```

Actual client capture decoded with `tshark -n -r FILE -Y dhcp`:

```text
    1 0.000000000      0.0.0.0 → 255.255.255.255 DHCP 342 DHCP Discover - Transaction ID 0x7289b37f
    3 3.004971917  10.10.0.254 → 10.10.0.2    DHCP 342 DHCP Offer    - Transaction ID 0x7289b37f
    4 3.005587290      0.0.0.0 → 255.255.255.255 DHCP 342 DHCP Request  - Transaction ID 0x7289b37f
    5 3.013355984  10.10.0.254 → 10.10.0.2    DHCP 345 DHCP ACK      - Transaction ID 0x7289b37f
```

## Result and final state

NetworkManager PID 16630 is the parent of eth0 dhclient PID 16835. Its generated
`/var/lib/NetworkManager/dhclient-eth0.conf` contains the requested address,
preserved client identifier, and hostname pi-foo-02. NM's helper receives the
lease; this is not an independent dhclient competing with NetworkManager.

`ip -4 addr show dev eth0` after activation:

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.2/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 43200sec preferred_lft 43200sec
```

`ip route show dev eth0`:

```text
10.10.0.0/24 proto kernel scope link src 10.10.0.2 metric 100
```

Restored `connection.autoconnect yes` on eth-dhcp after successful acquisition.
Wi-Fi retains management/default routing. Pi 01 was not switched to dhclient.
Server addressing remains temporary. No client-to-client ping was performed
in this test; the earlier first-pass ping is archived separately. Joel confirmed
the physical OLED now displays .2 after this test. This establishes one managed
preference acquisition; repeated resets have not yet been rehearsed.
