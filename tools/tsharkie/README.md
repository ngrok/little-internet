# tsharkie

A small live tshark wrapper: save a pcapng and display aligned packet rows.
Uses `mawk -W interactive` on the Pis so low-volume traffic appears immediately.
With an interactive terminal, `less -S +F` follows new packets without wrapping.

```bash
tsharkie first-dora.pcapng -f 'arp or (udp port 67 or udp port 68)'
tsharkie ping-proof.pcapng -f 'arp or icmp'
tsharkie all-traffic.pcapng -f ''
```

Bare filenames are saved in `~/cap/`. A path containing `/` is used as given;
quote paths containing spaces. Reusing a filename overwrites the existing capture
with the new session; packets are not appended. `-i` changes the
interface from `eth0`; `--no-pager` prints directly. Redirected/piped output also
skips the pager automatically. Ctrl+C then `q` exits the interactive view.
Without the pager, a blank line separates packets so long, visually wrapped
rows are easier to distinguish. This spacing also appears in piped or redirected
output; continuation lines belonging to the same packet stay together.

`-f` is a **capture filter**: it controls both saved and displayed traffic.
The default captures DHCP (UDP 67/68), ARP, and IPv4 ICMP. An empty filter captures
everything. This viewer does not change interface configuration or start a
DHCP client. Capture visibility is still limited to the selected interface.

Times are rounded to milliseconds for display; the pcapng retains captured
timestamps. Addresses and Info text are not truncated. Both address columns
reserve 26 characters, enough for this lab's MAC, IPv4, and compressed IPv6
addresses (such as `fe80::ba27:ebff:fe3a:e2c8`). The protocol column reserves 8
characters, so DHCP, ICMPv6, and Realtek rows align. Visible `|` separators stay
in the same positions on every line. Longer values wrap onto continuation lines
within their column, preserving the full text without shifting later columns.
These widths leave more room for Info; they do not reserve space for the longest
possible IPv6 representation. Info stays on one line; in the pager, `>` marks
text beyond the screen edge, which you can view by scrolling horizontally
after pressing Ctrl+C to pause following.
Protocol coloring is not retained by this field-based formatter.

TShark's startup messages and live packet counter are suppressed with `-Q` and
`--log-level warning`, while `-P` keeps packet rows visible. Warnings and errors
remain on stderr; the wrapper prints the capture path once before the table.

## Install on a Pi

Copy `tsharkie` to the Pi, then:

```bash
sudo install -m 755 tsharkie /usr/local/bin/tsharkie
tsharkie --help
```

Dependencies: Bash, tshark, awk (mawk on the image), and less for interactive
viewing. Use the image's normal `pi` capture permissions; sudo is needed for
the installation above, not routine capture. This tool is separate from the
released image and has not been added to the image build.
