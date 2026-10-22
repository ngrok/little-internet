# Lesson 02: who hands out IP addresses?

Connect three machines through a switch and find out who assigns their IPv4
addresses. This is the runnable version of
[build log 02](../../build-log/02_who-hands-out-addresses.md).

Start with unanswered requests, assign addresses by hand, then give a third
machine the job of handing them out. Capture each step of DHCP, the Dynamic
Host Configuration Protocol. Ask for specific addresses and reconnect the
network to see whether it starts working on its own.

## Three machines, one network

This lesson uses **three Debian VMs**, each with its own kernel. It follows the
[lesson 01 VM workflow](../01/scripts/virtual-vm/), with a learning Ethernet
switch in place of the direct cable. No network namespaces, veth pairs, host
bridges, or root access on the workstation are needed.

```text
            isolated lesson Ethernet network (eth0)
     pi-a  ──────────┬────────── pi-b
                     │
              learning switch
                     │
                  pi-dhcp
                10.10.0.254
            pool: 10.10.0.1–10, 12h

     Each VM also has its own mgmt NIC for SSH and package downloads.
     SSH: localhost:2221 (a), :2222 (b), :2223 (dhcp)
```

The switch learns which port each source MAC uses and forwards frames to the
right destination. It has no DHCP service or management IP. `dnsmasq` on
`pi-dhcp` is the only DHCP server on the lesson network. Management DHCP is
separate and does not reach `eth0`.

The VMs run DHCP clients and a dnsmasq server. A Python program supplies the
Ethernet switch; it doesn't reproduce the TP-Link management interface.
QEMU controls carrier events, so this lab has no physical link lights, speed
negotiation, or OLED displays. Frame padding can also differ from hardware.
The virtual interfaces use deliberately assigned Pi MAC prefixes.

## Start the lab

You need Git, Bash, Python 3, SSH, curl, QEMU, about **3 GB of free RAM** and
**6 GB of free disk space** (three thin guest disks can grow beyond that).
First boot needs internet and takes several minutes to install packages.

- macOS: `brew install qemu`; the scripts use HVF and the built-in `hdiutil`.
- Debian/Ubuntu: `sudo apt-get install qemu-system qemu-utils xorriso curl openssh-client python3`.
  QEMU uses KVM if `/dev/kvm` is writable; otherwise it uses slower emulation.
  ARM Linux may also need `qemu-efi-aarch64` for firmware.
- Windows: use WSL2 and the Linux instructions. Native Windows shells aren't supported.

From the repo root:

```bash
cd lessons/02
./scripts/check.sh --host
./scripts/virtual-vm/lab-up.sh
./scripts/run.sh
```

Setup installs NetworkManager with its dhclient backend, dnsmasq and its lease
utility, `tshark`, `tcpdump`, `ip`, `ping`, `arping`, and `ethtool`. It also
creates the lab SSH key, so you don't need to copy keys or enter passwords.

The clients start with an inactive `eth-dhcp` profile and no IPv4 address on
`eth0`. The DHCP service is stopped at first boot. Booting existing disks
preserves your progress; it doesn't reset a lesson you've already run.

Everything generated lives in `~/.little-internet/lab02-vm/`: guest disks, seed
ISOs, SSH key, serial logs, switch log, and exported captures. Set `LAB_HOME` to
an absolute path to use another directory; keep that value in every terminal.
Ports 2221–2223 and 10002 must be available. `WIRE_PORT` changes the switch port.

## Open shells on the machines

Open a terminal for each machine, from `lessons/02`:

```bash
./scripts/virtual-vm/ssh-a
./scripts/virtual-vm/ssh-b
./scripts/virtual-vm/ssh-dhcp
```

Each wrapper also accepts a command:

```bash
./scripts/virtual-vm/ssh-a 'ip -4 addr show eth0'
./scripts/virtual-vm/ssh-dhcp 'sudo journalctl -u dnsmasq -f'
```

Watch live frames in an extra client terminal while you run the lesson:

```bash
./scripts/virtual-vm/ssh-b 'sudo tshark -i eth0 -n -l'
```

Run the **lesson scripts on your workstation**, in a separate terminal. They
show the commands you are learning from, the raw evidence, and a short question
before explaining the result. Routine setup runs quietly; failures show the
command and its full output immediately. Open a step in your editor to inspect
its commands or type them into a guest shell yourself. The scripts use sudo
inside the dedicated VMs.

## Work through one question at a time

Use the paced runner for the normal walkthrough:

```bash
./scripts/run.sh
```

It checks the lab before phase 01. If an earlier run left addresses, profiles,
leases, address preferences, an enabled DHCP server, or disconnected links,
it explains what remains. Press Enter once to reset and continue, or Ctrl-C to
leave the lab as it is. Saved captures are preserved. A clean lab starts without
a reset prompt.

The runner then takes you through every phase. Press Enter at each
checkpoint to predict, inspect a small piece of evidence, and read the
explanation. Before each packet table, a short reading guide names the fields
or message types to follow. The question afterward returns to that same clue,
then the explanation connects the observed rows to the networking concept.
Each phase closes with a review question about what you just learned. Think
through your answer, press Enter to reveal a short explanation, then press
Enter again to advance. The explanation also sets up the next phase.
Magenta banners mark each new phase; a completion line closes the previous
one. Teal headings identify commands. Divider lines and phase numbers remain
visible without color, too.

Each checkpoint aims to fit on one terminal screen. Long packet tables pause
every eight rows and retain every decoded row. The runner advances between
phases for you, so there is no need to launch another script.

To repeat an interrupted phase and continue through the rest of the lesson:

```bash
./scripts/run.sh --from 04
```

This checks VM readiness and starts at phase 04 using the current lab state,
without resetting or repeating earlier phases. The preceding phases must have
completed successfully. Each phase is loaded into memory before it starts, so
edits made while it is paused take effect the next time that phase is launched.

The table below maps the phases. Use an individual script when you want to
repeat a phase or investigate it separately.

| Step | Run on the workstation | Look for |
| --- | --- | --- |
| Does the switch assign addresses? | `./scripts/01-switch.sh` | Link up, DHCP Discover received by other nodes, no Offer, no IPv4 identity. The activation timeout is expected here. |
| Can it carry a ping? | `./scripts/02-manual.sh` | Manual `.1`/`.2`, a connected route, ARP request/reply, then ICMP. |
| Who will answer DHCP? | `./scripts/03-server.sh` | Clients return to no IPv4; server gets `.254`, dnsmasq serves `.1–.10` for 12 hours. |
| How does a client get an identity? | `./scripts/04-dora.sh` | DORA grouped by transaction ID; leased addresses agree with `ip addr` and the lease file. |
| What does DHCP leave for ARP? | `./scripts/05-ping.sh` | Ping uses the actual peer lease; ARP resolves its MAC; the server does not relay client traffic. |
| Can I request `.1` and `.2`? | `./scripts/06-preference.sh` | Discover's Option 50, server Offer/ACK, and the resulting addresses. |
| Does it come together automatically? | `./scripts/07-reconnect.sh` | Carrier returns, clients obtain leases automatically, then ARP and ping work. |

The first two clients might receive addresses other than `.1` and `.2`.
Remembered leases can also affect later offers. Follow the addresses in **your**
output. A preference isn't a reservation: the server can offer another address.

The preference step follows the build log's conditional dhclient configuration:
it sends Option 50 only in Discover. It deactivates both clients, releases their
actual bindings with `dhcp_release`, and clears only their Ethernet lease files
before reconnecting. This lets the clients send fresh preferences while the
server keeps its other state. The final phase tests reconnection and lease
acquisition. It doesn't wait for a timed renewal or force an address conflict.

`ipv4.never-default yes` keeps the lab interface from replacing management's
default route. dnsmasq advertises neither a gateway nor DNS: those services are
not part of this network yet. Pings bind to `eth0` so the result tests the lab.

For an explicitly unattended demonstration or test:

```bash
NO_COLOR=1 ./scripts/run.sh --auto
```

Color has a consistent role: bright yellow questions and checkpoints, white
explanations, gray terminal output (including packet rows), teal commands,
and magenta phase banners. Color is enabled only when output is a terminal and
`NO_COLOR` is empty or unset. Captured/piped output is plain text.

Routine setup commands and their output go to a transcript under
`$LAB_HOME/transcripts/`. At the end of a run, the runner prints the path to an
index of its captures and transcripts. Phase transitions stay focused on the
lesson. Individual scripts still print their own paths and the next script
to run. To show setup inline while troubleshooting, use
either:

```bash
LESSON_VERBOSE=1 ./scripts/04-dora.sh
LESSON_VERBOSE=1 ./scripts/run.sh
```

Both runner modes require an already running lab. `--auto` also performs any
needed reset without prompting. Without `--auto`, a reset requires an interactive
terminal; piped input cannot silently approve it. The runner checks the starting
state again after resetting and stops if it could not restore it. Neither mode
shuts the VMs down at the end.

## Keep the packet evidence

Capture steps record all three nodes. Files are saved in `/home/pi/cap/` inside
each guest and copied to `$LAB_HOME/captures/` on the workstation. Filenames
include the beat, timestamp, run PID, and node; repeats don't overwrite evidence.
Set `CAPTURE_DIR` to change the workstation export directory.

The scripts print actual decoded `tshark` rows, focused on the current question.
Each table names its node and display filter. DORA follows one client's DHCP
conversation; ping beats compare the client with the server only after a pause.
The preference beat then looks inside that same client's packets at Option 50
and `yiaddr` (the offered or assigned address). Its aligned table shows message
names alongside their numeric types, such as `Discover (1)` and `ACK (5)`.
A dash means Option 50 is absent; `0.0.0.0` remains visible as the actual packet
value. The scripts save both the raw delimited fields and the aligned table.

The full captures include packets excluded by the display filters. The scripts
also save decoded views as plain `.txt` files beside the captures and record
the decoding commands in the setup transcript. Each view retains the original
frame numbers and timestamps. Gray styling applies only in the terminal.

To read an exported file on a workstation with Wireshark installed:

```bash
tshark -n -r /path/to/capture.pcap
```

Or read the guest copy with its already-installed `tshark`:

```bash
./scripts/virtual-vm/ssh-a 'ls ~/cap'
./scripts/virtual-vm/ssh-a 'tshark -n -r ~/cap/<filename>.pcap'
```

Frame numbers belong to each capture; match exchanges across nodes by
transaction ID and addresses, not by frame number. A server capture is not a
mirror of every switch port: learned unicast traffic between clients normally
won't reach it. Unknown unicast can be flooded.

Without VMs, use the [build log's recorded hardware captures](../../build-log/captures/02-dhcp/)
and its [capture manifest](../../build-log/captures/02-dhcp/manifest.json).
Those captures document the hardware experiments described in the build log.

## Reset, stop, and recover

```bash
./scripts/reset.sh                   # clear lesson state; preserve captures
./scripts/virtual-vm/lab-down.sh      # stop guests and switch; preserve disks
./scripts/virtual-vm/lab-up.sh        # resume those disks
./scripts/virtual-vm/lab-down.sh --wipe  # also delete this lesson's guest disks
```

Reset changes only these VMs' lesson profiles, address preferences, and leases.
Wiping also removes captures still inside the guests; exported captures and the
downloaded base image remain. Lesson 01's disks are separate.

If the lab fails or the output surprises you:

- For a boot or install failure, inspect `$LAB_HOME/pi-a-serial.log` (and `b` /
  `dhcp`), plus `switch.log`. Startup stops the processes it created on failure
  and keeps the disks and logs. After fixing package or internet access, stop
  with `--wipe` and retry a failed first-boot installation.
- If the lab is already running, inspect it with `check.sh`. Stop it before
  running `lab-up.sh` again, even if only some nodes are still running.
- If a port is occupied, stop the conflicting process. Use `WIRE_PORT` to choose
  another switch port; the three SSH ports are fixed for this lesson.
- If a capture is interrupted, the script stops its capture units on exit. If
  the controller is killed outright, captures expire after 180 seconds. Guest
  files remain in `/home/pi/cap/`. Stop a unit manually with
  `./scripts/virtual-vm/ssh-a 'sudo systemctl stop little-internet-02-capture'`
  (repeat for `b` and `dhcp`). Confirm no phase is running before removing a
  stale `$LAB_HOME/lesson.lock` directory with `rmdir`, then reset or retry.
- If you see no Offer, inspect the capture, the server's `.254` address, and
  `journalctl -u dnsmasq`. A live carrier doesn't prove the service is running.
- If a client gets an unexpected address, check the lease file and Option 50.
  The server can choose a different address from the client's preference.

## With a coding agent

Read the root [agent guide](../../AGENTS.md) and this lesson's
[manifest](manifest.json). Establish VM or read-only mode. Recommend the paced
runner for a terminal walkthrough. An agent driving an interactive terminal can
also use it, advancing only one checkpoint when the learner is ready.

Show exact commands and contiguous raw output before interpreting it, preserve
packet rows, and wait for the learner's prediction or explanation. An agent
should pause between evidence and the complete explanation. When tools cannot
keep an interactive terminal open, use individual scripts and supply that
pacing in the conversation: noninteractive shells skip Enter prompts.
`--auto` is for an explicitly unattended demonstration or development test.

## Developer checks

```bash
python3 -m unittest discover -s tests -v
./tests/smoke.sh   # running lesson 02 VMs required; resets their lesson state
```

The switch tests exercise broadcast, unknown and learned unicast, multicast,
stream framing, invalid frame lengths, aging, and disconnect cleanup.
Presentation tests use a fake transport and a real terminal to check color,
packet paging, quiet setup, and visible errors; they do not need running VMs.
The smoke test runs the real DHCP exchanges and verifies their packet fields
and final network state.

Validated on Apple Silicon macOS with QEMU 10.0.2 and Debian 12 guests on
2026-09-21: provisioning, all seven beats, complete DORA transactions, Discover
preferences, both echo replies, reset, and stop/resume with successful ping.
Linux/KVM and WSL2 still need validation on those platforms.
