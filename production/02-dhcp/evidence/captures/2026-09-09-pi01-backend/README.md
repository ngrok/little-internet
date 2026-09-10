# Pi 01 managed DHCP preference — 2026-09-09

At Joel's request, installed the image source's NetworkManager dhclient backend
configuration on Pi 01 and set its eth0-only request to 10.10.0.1. NetworkManager
1.42.4 remains the interface manager; ISC dhclient is its child process.

[Verified capture](lesson-02_nm-request-verified_pi-foo-01.pcapng),
[decoded packet table](dhcp-summary.txt), and [DHCP fields](dhcp-fields.tsv)
show Discover, Offer, Request, ACK in frames 1–4, transaction `0x7d1abb3a`.
Option 50 is 10.10.0.1 in Discover and Request; Offer and ACK assign .1.
The server already held Pi 01's .1 binding, so this proves the preference was
sent and accepted, not that the preference alone changed its allocation.

## Procedure and evidence limits

- Backed up prior configuration/profile settings and eth0 lease state under
  `/var/tmp/little-internet-pi01-backend-mFIC58` on Pi 01.
- Installed `/etc/NetworkManager/conf.d/20-little-internet-dhcp-client.conf`
  from the image source, with `[main] dhcp=dhclient`.
- Installed `/etc/NetworkManager/dhclient-eth0.conf` containing
  `send dhcp-requested-address 10.10.0.1;`. The global dhclient config had no
  requested-address directive.
- Disabled eth-dhcp autoconnect, preserved client ID `01:b8:27:eb:3a:e2:c8`,
  deactivated eth-dhcp, and moved its saved lease state into the backup.
- Restarted NetworkManager with a scheduled fallback to the internal backend.
  Wi-Fi reconnected at 192.168.1.5; canceled fallback after checking access.
- First acquisition succeeded, but its capture started too late and contains
  only ARP. A second timed capture expired before activation. Both remain on
  Pi 01 as `lesson-02_nm-request_pi-foo-01.pcapng` and
  `lesson-02_nm-request-confirmed_pi-foo-01.pcapng`; neither is DORA evidence.
- Deactivated eth-dhcp and moved the newly created NM dhclient eth0 lease into
  the backup. Started the verified capture with
  `timeout --signal=INT 30s tsharkie lesson-02_nm-request-verified_pi-foo-01.pcapng --no-pager`,
  waited five seconds for capture startup, then ran
  `sudo nmcli --wait 15 connection up eth-dhcp`. Restored autoconnect afterward.
  Exit 124 was the intentional capture time limit; saved packets decode.

Final interface and route output:

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 10.10.0.1/24 brd 10.10.0.255 scope global dynamic noprefixroute eth0
       valid_lft 43200sec preferred_lft 43200sec
default via 192.168.1.1 dev wlan0 proto dhcp src 192.168.1.5 metric 600
10.10.0.0/24 dev eth0 proto kernel scope link src 10.10.0.1 metric 100
192.168.1.0/24 dev wlan0 proto kernel scope link src 192.168.1.5 metric 600
```

NetworkManager PID 21506 owns eth0 dhclient PID 21978 and wlan0 dhclient PID
21532. The generated `/var/lib/NetworkManager/dhclient-eth0.conf` imports the
eth0 preference and includes the preserved client identifier. One eth0 IPv4
address remains; default routing stays on Wi-Fi. Autoconnect is restored.
No server configuration/bindings or Pi 02 settings changed in this test.
No new ping or physical Pi 01 OLED check was performed.

[Manifest](manifest.json) and [SHA256SUMS](SHA256SUMS) record provenance.
Remote hashes before/after transfer match the local file. This is a local
workspace archive; no commit/push or off-machine backup was performed.

The image source now installs isc-dhcp-client and the backend configuration.
The stage script passed syntax and temporary-root installation checks,
including installed file contents/modes. No image build, boot test, or release
was performed. Shared images do not contain per-client address preferences.
