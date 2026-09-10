# Prior-state DHCP rehearsal plan — retained reference

Superseded on 2026-09-09 by Joel's decision to begin with the latest repository
image and write the diary through a fresh walkthrough. This is retained history,
not the next task. Use [runbook.md](runbook.md) for the current workflow.
Existing inventories describe the pre-reflash Pis.

Status: draft in progress. Server and initial client inventories completed;
client DHCP backend still unverified. Only the
read-only inventory commands below are ready for review/execution on confirmed
nodes; configuration, reset, and capture commands still need the inventory.
This is an interactive rehearsal, with a pause at each checkpoint.

## Purpose and success criteria

Prove the proposed B04 → B05 first success → B07 → B05 preference payoff
sequence before recording it. Both passes must show Discover, Offer, Request,
and ACK for each client, with matching transaction IDs within each exchange.
The second pass must show the clients' .1/.2 preferences and the server's
actual response. Show interface addresses, server leases, and successful
client-to-client communication over eth0. Repeat the entire sequence from its
documented starting state before calling the reset reliable.

Keep the same MAC/client identities across passes. Store each pass's evidence
separately. Read and show actual packet rows before explaining them; never
substitute expected output for a missing or different result.

## Current handoff

Joel reports commenting out the preference line in `/etc/dhcp/dhclient.conf`
and running `sudo dhclient -r eth0`. Which clients this was done on and the
resulting output are not yet recorded. Do not repeat those steps by assumption.
This does not establish that NetworkManager stopped managing eth0, that all
client lease memory is empty, or that dnsmasq has forgotten prior allocations.

| Item | Confirmed value |
| --- | --- |
| Client A SSH destination | pi@pi-foo-01.local; login succeeded |
| Client B SSH destination | pi@pi-foo-02.local; login succeeded |
| Server SSH destination | pi@pi-foo-dhcp.local; hostname confirmed, login succeeded |
| Management path | Confirm Wi-Fi SSH access on all three nodes |
| Physical topology | Confirm all three eth0 ports connect to the isolated lab switch |
| Nodes on which Joel released leases | Pending |
| Actual client owner/backend/version | NetworkManager reports eth-dhcp active on both; nmcli 1.42.4; no dhclient/dhcpcd processes found; DHCP backend pending |
| Server eth0 address and prefix | 10.10.0.254/24; link UP/LOWER_UP |
| dnsmasq service, configuration inputs, lease-file path | dnsmasq 2.90; active dnsmasq.service; /etc/dnsmasq.conf includes /etc/dnsmasq.d/little-internet.conf; default /var/lib/misc/dnsmasq.leases |
| Persistent backup and rehearsal evidence paths | Pending |

Confirm SSH destinations before any remote commands, per the root AGENTS.md.
The commands below run inside the named node's SSH session; do not run them on
the workstation. Read-only server and client SSH inspection has been performed; no
hardware reset has run. Stop for physical cable actions; the agent cannot
verify them directly.

## Shared image and OLED work

Joel identified `image-dhcp-role` as the source of the deployed drop-in. Its
branch is `joelhans/image-dhcp-role`; source inspected at commit
`80f5bb5dfbeece5e4e20de223fe40179e82b532a` on 2026-09-09. The local worktree is
`/Users/joelhans/orca/workspaces/little-internet/image-dhcp-role`.
Source inspection does not establish which OLED version is deployed.

The image deliberately supplies hostname assignments for .1/.2. Keep that
source configuration intact. For the preference experiment, prepare a backed-up,
temporary server configuration without those assignments, and document how to
restore the image/OLED setup afterward. Both rehearsal passes use the same
temporary server policy. Do not run `promote.sh` as an inventory or reset step:
it deploys configuration and changes node roles/profiles.

Reuse the existing lesson 02 reset machinery where the runtime matches its
assumptions, after reviewing the selected operation with the learner:

- `lessons/02/scripts/lib.sh` targets the `eth-dhcp` profile and
  NetworkManager's internal eth0 lease files. It does not stop a separately
  launched dhclient. Confirm the owner/backend before choosing this path.
- `reset.sh --arm` is the candidate for preparing clients before capture. The
  ordinary reset immediately reacquires addresses; `--server` alone does not
  clear client memory. `--blank` also demotes the server and is inappropriate
  for the between-pass reset. None has been run here.
- The current reset removes lease files without archiving them and resets the
  server before clients. Our rehearsal must preserve evidence first and keep
  clients quiescent while clearing server state. Resolve these differences
  before adopting exact commands; do not assume the script proves full DORA.

Proposed display coverage: handshake OLED on each client, lease-ledger OLED on
the server. Inventory deployed scripts, active display processes, and panel
ownership alongside client state before launching viewers. Use one foreground
viewer per panel. Start viewers and saved packet capture before acquisition,
and check readiness/errors. The handshake viewer reads tshark fields but does
not save a pcap; its cells supplement the decoded packet evidence.

If filming with `--pace 0.6`, explain that observed messages are revealed slowly
for readability; this is not elapsed wire time. If a dedicated server lease
file is selected, point `lease_oled.py --leases` at that same file. Verify the
display against the actual packet rows and lease entries during rehearsal.

## Checkpoint 1 — What state is the server actually in?

Question: what address, configuration, and process are currently serving DHCP?
These read-only commands identify the node, its Ethernet address, and the
service's launch configuration. The final command shows active lines in the
default config; it is not proof that this is the complete effective config.

On the confirmed server, run this checkpoint only:

```bash
hostname
ip -4 addr show dev eth0
/usr/sbin/dnsmasq --version
systemctl show dnsmasq -p ActiveState -p SubState -p MainPID -p ExecStart -p FragmentPath -p DropInPaths
systemctl cat dnsmasq
sudo grep -nEv '^[[:space:]]*(#|$)' /etc/dnsmasq.conf
```

Pause and preserve the actual output. Follow any service arguments, environment
files, `conf-file`, or `conf-dir` references with targeted reads before
declaring the effective configuration known. Identify the live lease file from
those settings, process arguments, and packaged defaults; do not assume its
path. Then read that exact file and the relevant dnsmasq journal entries.

Resolve these questions from the output:

- Is the server's eth0 host address valid and outside the intended client pool?
- What pool, reservations, interface limits, and advertised options are active?
- Which instance owns DHCP, and where does it persist its leases?
- Can the switch or another client consume .1/.2? Document its management
  address/lease behavior and account for it before the preference test.

Do not remove the server's Ethernet identity as part of a lease reset. If it
still uses the historical `10.10.0.0/24`, prepare a corrected address plan
before treating it as the rehearsal baseline.

**Observed checkpoint result:** See [server inventory](evidence/2026-09-09-server-inventory.md)
for actual output. The server is already .254/24 with pool .1–.50 and 12-hour
leases. Two active hostname-based assignments fix pi-foo-01 to .1 and pi-foo-02
to .2. These assignments come from the image work and are intentional. Omit
them only in the planned temporary experiment configuration; matching addresses
under the existing policy cannot demonstrate the effect of client preferences.
Its lease file still lists both clients.
The original `dnsmasq --version` failed in the SSH shell; using the discovered
absolute executable path succeeded. No server state was changed.

## Checkpoint 2 — Who owns each client interface?

Question: did the reported release leave the intended client stopped, or can
another process acquire an address? Run separately on each confirmed client:

```bash
hostname
ip -4 addr show dev eth0
ip route show dev eth0
nmcli --version
nmcli -f GENERAL.STATE,GENERAL.CONNECTION device show eth0
nmcli -f NAME,UUID,TYPE,DEVICE connection show --active
pgrep -a -x dhclient
pgrep -a -x dhcpcd
sudo grep -nEv '^[[:space:]]*(#|$)' /etc/dhcp/dhclient.conf
```

An empty pgrep result means that process name was not found; it does not mean
there is no DHCP client. NetworkManager may use its internal client. Record
the active Ethernet profile/backend and the installed client version through
targeted follow-up reads. Inspect only the relevant Ethernet profile and lease
storage; keep management Wi-Fi configuration out of the reset.

Pause before selecting one owner of eth0 for the rehearsal. The historical
NetworkManager/manual-dhclient mixture must not become the operating procedure.
Record existing profiles, service state, and restoration steps before changes.

**Initial result:** [Client inventory](evidence/2026-09-09-client-inventory.md)
shows NetworkManager's `eth-dhcp` active on both clients, with dynamic .1/.2
addresses still present. Neither exact process-name search found dhclient or
dhcpcd. Confirm the NetworkManager DHCP backend next; do not infer the earlier
release's effect or choose lease files solely from this snapshot.

## Checkpoint 3 — Define and preserve the baseline

Turn the inventory into exact configuration and commands before proceeding:

- Choose a valid server address/prefix, a pool including available .1/.2,
  intended advertised options, and lab-only interface binding.
- Preserve the existing server/client configs, lease records, and service and
  profile state. Assign unique evidence paths for each rehearsal and pass.
- Establish one client owner, stable identifiers, and a way to start without
  remembered leases. A dedicated client configuration/lease/PID file is a
  candidate if supported by the installed client.
- Prepare a dedicated dnsmasq lease-file path and a controlled service
  stop/start. Preserve the reviewed address/pool/options across both passes.
- Prepare DHCP/ARP captures before client activation, with readable live
  output and saved files. Prepare a separate ICMP-inclusive view for ping.
  Document capture location and coverage limits.

The live .254/24 address and .1–.50 pool are the starting candidates. Client
ownership, preference controls, backups, and exact reset commands remain open.
Do not copy the historical .0 server address.

## Checkpoint 4 — First success

Start from the documented baseline with fresh lab lease state and no manual
address preference. Start captures, then activate one client at a time. Show
each complete exchange, assigned address, and server lease record. Pause to
interpret the evidence before the communication test. Use the actual assigned
addresses and verify the route/interface is eth0. Save outputs and captures.

Any different result is a finding to investigate, not a reason to skip to the
next pass. The first addresses may already match .1/.2; do not force a mismatch.

## Checkpoint 5 — Reset remembered allocations between passes

This is the reset design; replace it with exact commands after inventory.
It resets the isolated experiment's allocation history while preserving the
server address and reviewed DHCP configuration.

1. Save the first pass's captures, client/server lease records, and output.
2. Release both lab leases through their actual owners, stop those clients,
   and verify they cannot auto-reacquire. Remove remaining experiment addresses
   through that owner's controlled lifecycle. Account for other lab clients.
3. Stop the identified lab dnsmasq instance. Archive its lease file; prepare
   fresh storage with the ownership/access needed by that instance. Do not
   edit the live lease file while the daemon is running.
4. Prepare fresh client lease storage and the .1/.2 preference settings,
   keeping client identifiers unchanged. Retain the first pass's files.
5. Start dnsmasq with the same reviewed server configuration and fresh lab
   lease state. Verify service readiness, then start new captures before any
   client activation.

A restart alone is not our reset procedure. Nor does release alone prove that
both sides forgot allocation history. Explain briefly in the video that the
experiment is reset before testing preferences; this is not instant renumbering
of a live lease. Source rationale is in research.md's two-pass rehearsal design.

## Checkpoint 6 — Preference payoff and repeatability

Activate one client at a time. Preserve full DORA and point to the preferred
address in Discover, what the server offers, what the client requests, and
what the server acknowledges. Confirm interface/OLED and server lease state,
then communication. If the preference is not honored, inspect the evidence
and state; do not replace the request with a reservation to force the result.

Repeat the entire two-pass sequence from the documented baseline. Record
whether reset restored the expected starting state and both exchanges repeated.
Keep the repeated captures as proof; do not mark this runbook tested until
that has happened. Record final running state and exact restoration commands.

## Rehearsal record

| Checkpoint | Result | Evidence |
| --- | --- | --- |
| Joel's initial preference removal/release | Reported; nodes/output unconfirmed | Conversation |
| Server inventory | Completed read-only; .254/24, two server-side address assignments, two lease entries | evidence/2026-09-09-server-inventory.md |
| Image/OLED source inspection | Existing reservations, reset functions, handshake and ledger viewers reviewed; deployment unverified | image-dhcp-role commit 80f5bb5; research.md |
| Client inventories | Initial ownership check completed; NetworkManager eth-dhcp on both, dynamic .1/.2; backend still pending | evidence/2026-09-09-client-inventory.md |
| Baseline and restoration commands | Not prepared | |
| First DORA and communication | Not run | |
| Reset and preference DORA | Not run | |
| Full sequence repeated | Not run | |
| Final state / restoration | Not recorded | |

## Sources

- [Dnsmasq manual](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html):
  configuration/interface controls and `--dhcp-leasefile`.
- [ISC dhclient manual](https://kb.isc.org/docs/isc-dhcp-44-manual-pages-dhclient):
  release/stop and configuration, lease, and PID file controls; applicable only
  if this is the selected client.
- [NetworkManager nmcli manual](https://networkmanager.dev/docs/api/latest/nmcli.html):
  device/connection inspection. Identify the installed version/backend before
  preparing its mutation commands.
- [Research notes](research.md): RFC evidence, captured returning-client
  exchange, and limits of the historical server-fix explanation.
