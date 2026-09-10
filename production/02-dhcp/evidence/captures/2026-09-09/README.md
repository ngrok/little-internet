# Fresh walkthrough captures — 2026-09-09

Read alongside the [walkthrough diary](../../../diary.md), which links each
packet excerpt to its recording host and frame numbers. Eight of its nine
packet excerpts match the archived rows and rounded relative times. The opening
mDNS excerpt's frame 19 matches the packet contents, but its diary time is
10.825 s and the archive time is 3.253 s; that discrepancy is flagged in place.

Copied from `/home/pi/cap/` on the three Pis. Original filenames and source
files are preserved. Each local SHA-256 matches its remote source both before
and after transfer. No tshark processes were running when the sources were
inventoried. All 11 captures decode successfully with tshark.

Client files are listed in Joel's diary order: switch connection, manual
addressing, DHCP acquisition, and ping after DHCP. The server has separate
captures for the first client's acquisition, the second client's acquisition,
and the subsequent ping. These are different observation points; a server
capture is not expected to contain every client-to-client frame.

| Capture host | Diary stage | File | Packets |
| --- | --- | --- | ---: |
| pi-foo-01 | 1. Switch connection | [lesson-02_link-switch_pi-foo-01.pcapng](pi-foo-01/lesson-02_link-switch_pi-foo-01.pcapng) | 54 |
| pi-foo-01 | 2. Manual addressing and ping | [lesson-02_link-switch-manual_pi-foo-01.pcapng](pi-foo-01/lesson-02_link-switch-manual_pi-foo-01.pcapng) | 6 |
| pi-foo-01 | 3. DHCP acquisition | [lesson-02_dhcp_pi-foo-01.pcapng](pi-foo-01/lesson-02_dhcp_pi-foo-01.pcapng) | 64 |
| pi-foo-01 | 4. Ping after DHCP | [lesson-02_dhcp-ping_pi-foo-01.pcapng](pi-foo-01/lesson-02_dhcp-ping_pi-foo-01.pcapng) | 6 |
| pi-foo-02 | 1. Switch connection | [lesson-02_link-switch_pi-foo-02.pcapng](pi-foo-02/lesson-02_link-switch_pi-foo-02.pcapng) | 59 |
| pi-foo-02 | 2. Manual addressing and ping | [lesson-02_link-switch-manual_pi-foo-02.pcapng](pi-foo-02/lesson-02_link-switch-manual_pi-foo-02.pcapng) | 6 |
| pi-foo-02 | 3. DHCP acquisition | [lesson-02_dhcp_pi-foo-02.pcapng](pi-foo-02/lesson-02_dhcp_pi-foo-02.pcapng) | 15 |
| pi-foo-02 | 4. Ping after DHCP | [lesson-02_dhcp-ping_pi-foo-02.pcapng](pi-foo-02/lesson-02_dhcp-ping_pi-foo-02.pcapng) | 6 |
| pi-foo-dhcp | 3a. First client acquisition | [lesson-02_dhcp_pi-foo-dhcp.pcapng](pi-foo-dhcp/lesson-02_dhcp_pi-foo-dhcp.pcapng) | 66 |
| pi-foo-dhcp | 3b. Second client acquisition | [lesson-02_dhcp-02_pi-foo-dhcp.pcapng](pi-foo-dhcp/lesson-02_dhcp-02_pi-foo-dhcp.pcapng) | 15 |
| pi-foo-dhcp | 4. Ping after DHCP | [lesson-02_dhcp-ping_pi-foo-dhcp.pcapng](pi-foo-dhcp/lesson-02_dhcp-ping_pi-foo-dhcp.pcapng) | 1 |

[manifest.json](manifest.json) records source paths, sizes, packet counts, and
hashes. [SHA256SUMS](SHA256SUMS) can verify the archived bytes. From this folder:

```bash
shasum -a 256 -c SHA256SUMS
```

These are workspace copies on the Mac, not a completed remote backup. They are
eligible for Git tracking; this transfer did not commit or push the branch.
Keep this set intact when recording later preference experiments.
