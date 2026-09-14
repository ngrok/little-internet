# DHCP build log captures

These are the original captures linked from [Build log 02](../../02_who-hands-out-addresses.md), copied without modification. Original `lesson-02` filenames are retained so saved commands, frame numbers, and evidence remain consistent. Every capture here was recorded on `eth0`.

Open a `.pcapng` file in Wireshark, or read it with `tshark -r FILE.pcapng`. Frame numbers refer to that file; relative times are seconds from its first packet. The TSV contains decoded DHCP fields for the preference transition. [Server log excerpts](server-log.md) preserve the address-assignment diagnostic and subsequent DORA exchange.

The September 9 captures retain historical switch DHCP traffic. The build log’s setup instructions reflect the later correction to use a static management address outside the client pool. The preference-transition captures are from the September 11 verification of the final conditional configuration.

| File | Recorded |
| --- | --- |
| [lesson-02_link-switch_pi-foo-01.pcapng](lesson-02_link-switch_pi-foo-01.pcapng) | September 9, 2026 |
| [lesson-02_link-switch_pi-foo-02.pcapng](lesson-02_link-switch_pi-foo-02.pcapng) | September 9, 2026 |
| [lesson-02_link-switch-manual_pi-foo-01.pcapng](lesson-02_link-switch-manual_pi-foo-01.pcapng) | September 9, 2026 |
| [lesson-02_link-switch-manual_pi-foo-02.pcapng](lesson-02_link-switch-manual_pi-foo-02.pcapng) | September 9, 2026 |
| [lesson-02_dhcp_pi-foo-01.pcapng](lesson-02_dhcp_pi-foo-01.pcapng) | September 9, 2026 |
| [lesson-02_dhcp_pi-foo-dhcp.pcapng](lesson-02_dhcp_pi-foo-dhcp.pcapng) | September 9, 2026 |
| [lesson-02_dhcp_pi-foo-02.pcapng](lesson-02_dhcp_pi-foo-02.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-02_pi-foo-dhcp.pcapng](lesson-02_dhcp-02_pi-foo-dhcp.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-ping_pi-foo-01.pcapng](lesson-02_dhcp-ping_pi-foo-01.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-ping_pi-foo-02.pcapng](lesson-02_dhcp-ping_pi-foo-02.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-ping_pi-foo-dhcp.pcapng](lesson-02_dhcp-ping_pi-foo-dhcp.pcapng) | September 9, 2026 |
| [lesson-02-preference-release-to-two_pi-foo-02.pcapng](lesson-02-preference-release-to-two_pi-foo-02.pcapng) | September 11, 2026 |
| [lesson-02-preference-release-to-two_pi-foo-dhcp.pcapng](lesson-02-preference-release-to-two_pi-foo-dhcp.pcapng) | September 11, 2026 |
| [lesson-02-preference-release-to-two_pi-foo-02.tsv](lesson-02-preference-release-to-two_pi-foo-02.tsv) | September 11, 2026 |
| [lesson-02_dhcp-e2e_pi-foo-01.pcapng](lesson-02_dhcp-e2e_pi-foo-01.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-e2e_pi-foo-02.pcapng](lesson-02_dhcp-e2e_pi-foo-02.pcapng) | September 9, 2026 |
| [lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng](lesson-02_dhcp-e2e_pi-foo-dhcp.pcapng) | September 9, 2026 |

[manifest.json](manifest.json) records the archive source and SHA-256 for each capture and TSV. Verify the copies from this directory with `shasum -a 256 -c SHA256SUMS`.
