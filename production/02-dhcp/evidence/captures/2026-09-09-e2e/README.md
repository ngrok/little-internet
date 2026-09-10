# Finished-network assembly captures — 2026-09-09

Joel reports that the assembled network came up as expected after resetting
DHCP state, with client address preferences retained. These three captures
were copied from the Pis at his request while he continues writing
[the diary](../../../diary.md). The diary was not edited during archiving.

| Capture host | File | Packets | DHCP packets |
| --- | --- | ---: | ---: |
| Pi 01 | [lesson-02_dhcp-e2e_pi-foo-01.pcapng](lesson-02_dhcp-e2e_pi-foo-01.pcapng) | 28 | 13 |
| Pi 02 | [lesson-02_dhcp-e2e_pi-foo-02.pcapng](lesson-02_dhcp-e2e_pi-foo-02.pcapng) | 27 | 12 |
| Server | [lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng](lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng) | 34 | 21 |

## Verified DHCP evidence

Frame numbers below are local to each capture, in Discover/Offer/Request/ACK
order. Relative times differ between capture start points.

| Client | Transaction ID | Client capture frames | Server capture frames | Requested and assigned address |
| --- | --- | --- | --- | --- |
| Pi 01 | `0x3449fa25` | 2, 6, 7, 8 | 10, 15, 16, 18 | 10.10.0.1 |
| Pi 02 | `0x0329ce6b` | 1, 5, 6, 8 | 8, 12, 14, 17 | 10.10.0.2 |

Both client exchanges contain all four messages. Option 50 contains the
preferred address in Discover and Request; Offer and ACK contain that address
in yiaddr. This confirms the on-wire exchanges; the report that the complete
assembly worked comes from Joel, not a new remote interface or OLED check.

Actual decoded DHCP tables and extracted fields:

- Pi 01: [packet table](pi-foo-01-dhcp-summary.txt), [fields](pi-foo-01-dhcp-fields.tsv).
- Pi 02: [packet table](pi-foo-02-dhcp-summary.txt), [fields](pi-foo-02-dhcp-fields.tsv).
- Server: [packet table](pi-foo-dhcp-dhcp-summary.txt), [fields](pi-foo-dhcp-dhcp-fields.tsv).

Tables include other DHCP traffic as captured. Use transaction ID and client
MAC to distinguish the two acquisitions from other messages. DHCP option 53
values 1, 2, 3, 5 mean Discover, Offer, Request, ACK.

## Provenance and storage

Sources are `/home/pi/cap/` on pi-foo-01.local, pi-foo-02.local, and
pi-foo-dhcp.local, with original filenames retained. No tshark or dumpcap
processes were running during discovery. Original files remain on the Pis.

[manifest.json](manifest.json) records source paths, file sizes, packet counts,
and SHA-256 hashes. Remote hashes before and after transfer match each local
file. All three captures decode successfully with tshark.
[SHA256SUMS](SHA256SUMS) supports later integrity checks.

This is a local workspace archive. No commit, push, or off-machine backup was
performed during this copy. Earlier captures remain separate and unchanged.
