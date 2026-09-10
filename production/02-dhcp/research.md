# Research and explanation gaps

Status: research in progress, not a fact-checked script. Manufacturer, dnsmasq,
and DHCP documentation reviewed for selected questions. DHCP-filtered rows and
first requests decoded from both saved DHCP captures. The old export's entire
automated audio transcript and sampled picture have now been inspected;
listening and continuous playback remain pending. Historical interpretations
still need checking.

## Publication baseline decision — 2026-09-10

Joel will publish a new image alongside the standalone diary, with tsharkie
included. The image source now stages the existing tool from `tools/tsharkie`,
installs it on PATH, and explicitly includes mawk and less. NetworkManager's
dhclient backend was already added to the source. Address preferences remain
lesson configuration, introduced after the first automatic assignment.

This resolves the diary's setup gap without requiring a manual tool install or
an abrupt client migration in the story. Joel removed the two-address detour
from the revised diary; its original observations remain in this archive.
Source integration does not establish a working released image. Build, boot,
live-capture, and DHCP/preference checks on the actual artifact remain before
release and publication. See [the publication plan](publication-and-filming.md).

## Current direction — fresh repository image

Joel decided on 2026-09-09 to stop reconstructing the old setup and begin from
the latest repository image. Walk the beats, write the diary from actual
observations, and use that experience to inform OLED development while
finalizing the script and preparing for filming. image-dhcp-role is a candidate
implementation to reuse, not the starting baseline or a requirement to adopt
its feature set. Earlier diagnoses remain reference material.

GitHub's latest-release API reports v0.5.3, published 2026-08-07, with asset
`v0.5.3-little-internet.img.xz` ([release](https://github.com/ngrok/little-internet/releases/tag/v0.5.3)).
Checked 2026-09-09. Local tag resolves to
`48e2d21486cbb3fde0880e1d1e21a808c8d68ed9`; remote main verified with
`git ls-remote` is `b93b570e9053b8960b3ad08247672e1cb4f15abd`. A source diff
between those commits found no image/ or tools/ changes. The release source
includes status/ARP OLED tools and the NetworkManager eth-dhcp baseline; no
DHCP-specific OLED viewer. This is not verification of a downloaded or booted
artifact. Download checksum, flashing, and first boot remain pending.

Current work follows [runbook.md](runbook.md) and [diary.md](diary.md). The old
inventory/reset proposal is preserved in [prior-state-runbook.md](prior-state-runbook.md).

## Old-cut gap audit

### First-pass media findings — 2026-09-09

Joel reports all three Pis reflashed and is writing the new diary during the
build. He asked for old-cut selection work in parallel. The assistant left
diary.md and the hardware untouched. See [old-cut-review.md](old-cut-review.md)
for source hash, review method, windows, strengths, and limits; footage.csv
contains eleven candidate windows, all marked unclear pending playback.

The entire locally generated ASR transcript was read, actual picture sampled
throughout the export, and candidate sequences inspected at closer intervals.
This session does not support audio input, so the review does not establish
delivery, sound quality, or edit-ready boundaries. It is a selection shortlist,
not completed picture-and-sound coverage approval.

Evidence refines the earlier discussion:

- Around 06:38–07:06, the transcript already states a benefit of the third Pi:
  observing DHCP frames. Actual overhead footage shows gestures among the
  devices. The core observability motive is present; its extension to service,
  configuration, and lease evidence remains a task for the new journey.
- At 13:42 and 16:04, full-resolution frames show successful ping to .1. The
  latter is a cleaner terminal view. The old cut does demonstrate communication;
  avoid describing the payoff as absent. Reconnect it clearly to new evidence.
- At 16:32, the actual graphic highlights Request/Acknowledge and explicitly
  says only those appear. Retain this distinction between explanation and
  observed evidence while preparing the required full DORA demonstration.
- At 13:02–13:30, the transcript and sampled picture connect success to .4/.1
  numbering frustration. This is a useful existing motive for preferences after
  first success. It is footage of the old run, not a reaction to future captures.

Earlier recollections and unreviewed statuses below are retained as the history
of the gap discussion; use this section and old-cut-review.md for current status.

Fill this while reviewing `cut-for-ryan.mp4` with Joel. Use actual timecodes
when verified; label recollections separately from footage review.

### Discussion — 2026-09-09

- **Joel's recollection, B01:** The old cut explained the motivation for adding
  the switch: understand how a local network gets to the point where
  “someone” hands out addresses, instead of manually claiming one on each new
  device. Preserve that motivation as the starting point of the journey.
- **Editorial implication:** Do not classify the opening motivation as a gap
  based only on the proposed outline. Its delivery and placement in the old
  cut remain unreviewed.
- **Media located:** `cut-for-ryan.mp4` is now in this episode directory.
  Metadata inspection reports approximately 20:54, 1920×1080, 24 fps, with an
  audio stream. Picture and audio have not yet been reviewed.
- **First gap identified by Joel, G01 / B01:** More context about the previous
  video, supported by a few old-footage cut-ins; a reintroduction to the little
  internet; the project's overall destination; and this episode's specific
  destination. This is Joel's assessment, pending review of the opening.
- **Confirmed finish line:** Joel wants the Pis to receive addresses
  automatically and then communicate, demonstrating connectivity and identity
  together. This settles the payoff needed for G01's opening promise.
- **Second gap identified by Joel, G02 / B02:** He did not explain what the
  switch might do. He recalls introducing it approximately as “next time
  we're going to see what happens when we throw [a] switch into the mix.”
  This is a recollection, not a verified quote or a located passage; establish
  whether that teaser is in the preceding video or the old cut during review.
- **G02 history clarified by Joel:** At purchase he expected the switch to
  include a DHCP server and hand out addresses. He learned what it could and
  could not do just before shooting the previous video. The change in his
  understanding therefore preceded filming; it was not an on-camera discovery.
- **Tentative discovery recollection:** Joel thinks he was investigating the
  switch UI and whether he could SSH into it to monitor the DHCP server he
  assumed was present. He recalls learning that this inexpensive device lacked
  SSH access and a DHCP server. The exact sequence is uncertain; do not turn
  it into a precise incident or claim that he attempted a particular command.
- **Existing explanation to preserve, B03:** Joel says he explains that the
  third Pi will run dnsmasq and operate as the DHCP server. Do not classify
  the introduction of the Pi's role or software as missing. This establishes
  what Joel recalls covering; it does not verify the depth of the protocol
  explanation or the usability of the footage.
- **Third gap identified by Joel, G03 / B04:** The configuration section was
  mostly changing settings until an address appeared. He entered filming
  without knowing what to configure or what evidence to look for.
- **Workflow diagnosis from Joel:** Going in without prior knowledge made it
  hard to chart the journey or explain it concisely and accurately, creating
  avoidable re-recording work. Prepare the necessary understanding before
  recording; preserve the organic delivery and useful real troubleshooting.
- **G03 working explanation:** Joel believes assigning an IPv4 identity to
  the DHCP server made assignment work, but is not certain of the cause.
  Preserve that uncertainty. The historical diary records the same sequence;
  it is not independent proof that the address was the only relevant change.
- **Fourth gap identified, G04 / B05:** Joel explains the packets in voiceover
  recorded after the live session because he lacked the knowledge to explain
  them at the bench. He reports that lease state left him with Request/ACK,
  rather than the full four-message exchange he wanted. Preserve the existing
  voiceover as material to review; an explanation is present, but its fit to
  the footage has not been assessed.
- **G04 clarified by Joel:** He recalls saying there are four messages, but
  not explaining all four. The established gap is an incomplete account of
  the basic exchange; do not infer that the voiceover mislabels particular
  packets or claims all four are visible.
- **Existing ending to preserve, B06/B07:** Joel recalls acknowledging that
  pi-foo-01 still had .4 rather than his preferred matching number, leaving
  that for future work. He also concluded that the local network now behaved
  in the familiar way: devices could join, receive addresses, and communicate.
  He connected this to the home-network experience and suggested VLANs,
  spoofing, and other local-network explorations before expanding to multiple
  networks and eventually BGP. This is recollection, not footage review.
- **B07 scope settled by Joel:** Configure the clients to request .1 and .2
  from the start for visual consistency with pi-foo-01/02. Explain the reason
  for the preference and that the server decides the allocation. A future
  experiment could show two clients requesting the same address. The earlier
  proposal to leave preferences as a loose end is superseded.
- **Later refinement from Joel:** Make B03→B04 explain the benefit of hosting
  DHCP on a Pi: SSH access and ownership of the service allow investigation
  of configuration, operation, and packets. Back the observability promise
  with evidence in the content itself. Also reconsider when preferences enter:
  a first successful DHCP pass, followed by preferences as an improvement.
  Inclusion remains confirmed; the earlier from-the-start timing is reopened.
  Joel likes B07's transition into the demonstration.
- **Two-pass requirement from Joel:** The preference pass must also show the
  full DORA exchange, even though the same Pis already obtained leases in the
  first pass. Treat repeatable initial-state preparation as a prerequisite
  for this structure; a reconnect alone is not the plan.
- **Next useful work:** Verify the installed client/backend and implement a
  scoped rehearsal reset based on the design below, then demonstrate both
  exchanges before finalizing the recording sequence.

| Cut timecode | What the viewer is missing | Why it matters | Beat | Recording needed |
| --- | --- | --- | --- | --- |
| Unlocated; Joel's recollection | G01: Orientation—what the little internet is, what the previous video established, where the project is going, and what this episode will achieve | Viewers need a starting point and destination to understand why each bench action advances the project, even if they already hear the motivation for automatic addresses | B01 | New opening context and transitions; a few previous-video cut-ins, with actual selections still to locate and review |
| Unlocated; Joel's recollection | G02: What the switch contributes and what connecting it is meant to test | The new hardware is introduced, but viewers lack a model for interpreting what changes or how this step relates to automatic addresses | B02, leading into B03 | Before/after cable layout, a short explanation of the switch's role, an honest expectation, and an observation-led transition to the next job; footage unreviewed |
| Unlocated; Joel's assessment | G03: Why the DHCP settings are needed, what each change should accomplish, and what evidence establishes success | Changing settings until an address appears leaves the viewer without a causal explanation or a way to follow the troubleshooting | B04, leading into B05 | Prepared configuration walkthrough connecting each essential setting to its purpose, predicted result, and actual evidence; retain useful troubleshooting with explanation |
| Unlocated in cut; Joel's assessment plus saved-capture review below | G04: The four-message exchange is mentioned but not fully explained, and the saved demonstration shows returning clients | Viewers hear that four messages exist without learning each message's contribution; the shorter recorded exchange cannot illustrate the full introduction | B05 | Rehearse and capture initial acquisition; explain each message's sender, purpose, and relevant evidence; connect the exchange to the assigned address and communication test; returning clients optional and separate |

### G01 — Give the viewer a starting point and destination

**Diagnosis:** The motivation for automatic addresses and the context needed
to follow that motivation are separate coverage needs. Joel recalls explaining
the former, while identifying the latter as incomplete. Do not infer that the
entire opening failed or that any particular sentence was absent.

**Proposed journey repair:** Reintroduce the project and its larger destination,
recall the two-Pi result with a few brief footage cut-ins, then establish the
remaining manual work and this episode's intended result. Carry that question
into the new bench setup. This is an outline proposal, not camera copy.

**Context source:** The root [README](../../README.md), inspected 2026-09-09,
describes building a reproducible hardware internet through one network, two
networks, and eventually three networks exchanging reachability using BGP.
This establishes the project's stated ambition, not its current completion.
The [previous diary](../../diaries/00_two-pis-one-cable.md) documents the
two-Pi/manual-address starting point; footage selections remain unreviewed.

**Coverage to seek:** Earlier two-Pi/cable setup, manual address assignment,
and the successful ping. These are selection targets, not confirmed usable
shots. New bench footage should make the change in setup legible.

**Decision (Joel, 2026-09-09):** End with automatic address assignment followed
by successful communication between the Pis. Connect B01's promise to both
parts of B05's demonstration and recall them in B06. The intended meaning of
“identity” here is the clients' assigned IPv4 addresses on the lab network.

**Evidence requirement for the new recording:** Show assignment for both
clients, then a successful exchange using those assigned addresses over eth0.
A ping and its decoded request/reply rows are the proposed communication
demonstration. Record the interface/route evidence needed to establish the lab
Ethernet path. An OLED address alone does not complete the planned payoff.
This is required coverage to obtain, not an observation from the old cut.

### G02 — Give the switch experiment a question

**Diagnosis:** Joel reports no explanation of what the switch might do. A
promise to add hardware creates anticipation but leaves the viewer without a
clear expectation against which to interpret the result. This diagnosis comes
from the discussion; the actual delivery and placement remain unreviewed.

**History, from Joel:** He bought the switch believing it included the jobs
needed for automatic addressing, specifically a DHCP server. Just before
shooting, he realized its actual capabilities and limitations. He tentatively
recalls investigating UI/SSH access to monitor the presumed server. Preserve
the uncertainty around the sequence; no original documentation or terminal
session from that discovery has been identified.

**Editorial inference:** A key change in Joel's understanding happened before
the camera rolled. If the cut proceeds from adding the switch to providing
DHCP elsewhere without carrying viewers through that change, they miss the
reason for the next step. This is a working explanation of why the journey
felt incomplete, pending footage review.

**Proposed journey repair:** Recall the purchase expectation and explicitly
place the correction before the original filming. Explain the separate jobs
in this particular setup after verifying R01, show why the switch still
belongs in the build, then investigate the connected bench with viewers.
Use the observation to illustrate the distinction and motivate B03. The new
recording should share a discovery already made, with no reenacted surprise.

**Research dependency:** R01 must establish this device's role and configuration
before scripting claims about forwarding, address assignment, or routing.
R06 must establish what the chosen capture point can show. Do not treat an
unanswered request or an absent address as proof of all switch capabilities.

**Technical distinction to preserve:** Management access and DHCP serving are
separate capabilities. Lack of SSH access does not establish lack of a DHCP
server, and low price alone is not evidence of either. Preserve Joel's
discovery story while grounding device claims in the actual feature set.

**Initial documentation check, 2026-09-09:** BOM.md names the TP-Link TL-SG108E.
The manufacturer's current V6 product page describes web/utility management;
the V2 user guide, sections 3.1 and 4.2, documents browser login and a DHCP
client setting for the switch's own address. That client setting is not an
address pool for other devices. Sources and revision limits are below.
Installed hardware/firmware is still unconfirmed; R01 remains partially open.

**Scope still to settle:** How much switch explanation this DHCP journey
needs. Proposed minimum: separate connecting devices, managing the switch,
and assigning addresses, then return to the missing service. A detailed
switching lesson is not yet part of the agreed scope.

### G03 — Understand the setup before explaining it on camera

**Diagnosis, from Joel:** He mostly changed settings until addresses appeared
because he did not know what he needed to set up or observe before filming.
He identifies insufficient preparation as the broader cause of the incomplete
explanations and subsequent need to re-record. Footage remains unreviewed.

**Proposed journey repair:** Before changing configuration on camera, establish
what the server needs to do and the plan for making it do that. For each
essential setting, connect its purpose to an expected effect and then inspect
the actual result. End the beat with a concrete prediction for the client
experiment in B05. Technical choices depend on R05; do not reuse unverified
commands from the historical diary.

**Preparation before scripting and recording:** Research the essential jobs
and configuration, then rehearse the core experiment in an appropriate,
explicitly selected lab environment. Record the starting state, verified
settings and their purposes, expected observations, actual evidence, and how
to repeat the demonstration. Revise the journey from that rehearsal before
writing the concise explainers. No rehearsal has been run or hardware access
authorized in this discussion.

**Proposed readiness standard:** Joel can explain the purpose of each setting
shown, predict the next observable result, identify which evidence supports
the conclusion, and explain the reason for the next action. Unresolved
essentials need research; interesting optional questions can remain open.
This supports spontaneous delivery and investigation without relying on the
edit to supply missing understanding. It can reduce avoidable pickups, not
guarantee that none will be needed.

**Working explanation from Joel:** Giving the server its own IPv4 address
appeared to make the setup work. He is not fully certain that this was the
decisive change.

**Evidence checked, 2026-09-09:** The reference diary's “Giving dnsmasq a
range” and “Failure 2” sections record a configured range, then an nmcli
connection-add command assigning an address on eth0, followed by reported
client assignments. The command creates a connection profile as well as
specifying an address; exact activation, service state, and client retries
were not isolated. The diary also says live capture output was not enabled,
so silence in that terminal is not evidence that no DHCP packets were flowing.

**Technical support and limit:** The dnsmasq manual's --dhcp-range entry says
that on directly connected networks it derives an omitted netmask from the
interface configuration. The historical range omits that netmask. This makes
the server's eth0 IPv4 configuration a plausible missing prerequisite in this
setup; the manual cannot establish the cause of the old run's success.

**Verification needed during preparation:** Use a valid, reviewed address
plan, preserve server logs and decoded captures, and establish the server
interface, service, and client state. Compare otherwise equivalent client
attempts with and without the relevant server IPv4 configuration, recording
any profile activation or service restart as another change. Do this only in
the selected lab environment; no commands have been run. The historical
10.10.0.0/24 server address and overlapping pool are already flagged for
correction and must not become the new demonstration plan.

**Journey implication:** Establish the server's own lab address and the
client pool as separate setup decisions before expecting client assignment.
The explainer must account for why those decisions matter in this setup;
“the server needed an identity” is a useful question to investigate, not yet
a complete causal explanation to script.

### G04 — Match the DHCP demonstration to the explanation

**Existing explanation:** Joel reports adding packet analysis in later
voiceover. Its presence is established by his account, but wording, visual
alignment, and quality remain unreviewed. Voiceover itself is not a defect;
the preparation gap is needing it to supply understanding missing at filming.

**Clarified explanation gap:** Joel recalls naming the existence of four
messages without discussing all of them. The essential repair is a complete
basic account: who sends each message, what it contributes, and which visible
fields support that explanation. Detailed protocol edge cases are outside
this repair. Whether the old narration mislabels any shown packet remains
unknown until picture and audio are reviewed.

**Saved evidence, inspected 2026-09-09:** Complete DHCP-filtered summary output
from the two files follows. Non-DHCP frames are excluded by the display filter;
timestamps are relative to each file's own first packet.

```text
$ tshark -n -r production/02-dhcp/references/captures/dhcp_pi-foo-01.pcapng -Y dhcp
    1 0.000000000      0.0.0.0 → 255.255.255.255 DHCP 335 DHCP Request  - Transaction ID 0x468c6499
    2 0.007838680    10.10.0.0 → 10.10.0.4    DHCP 345 DHCP ACK      - Transaction ID 0x468c6499
    8 25.568267186      0.0.0.0 → 255.255.255.255 DHCP 335 DHCP Request  - Transaction ID 0x31f7ccff

$ tshark -n -r production/02-dhcp/references/captures/dhcp_pi-foo-02.pcapng -Y dhcp
    1 0.000000000      0.0.0.0 → 255.255.255.255 DHCP 335 DHCP Request  - Transaction ID 0x31f7ccff
    2 0.006310486    10.10.0.0 → 10.10.0.1    DHCP 345 DHCP ACK      - Transaction ID 0x31f7ccff
```

**Detailed observation:** Read frame 1 of each file with the same command,
replacing `-Y dhcp` with `-Y 'frame.number == 1' -V`. Both requests have
ciaddr 0.0.0.0, a broadcast destination, option 50 requesting the respective
address (10.10.0.4 or 10.10.0.1), and no option 54 server identifier. Each
file's first two rows share a transaction ID. No Discover or Offer appears
in either saved DHCP file. This does not establish what was sent before these
captures began or what appears in the edited video.

**Interpretation:** Those request fields match INIT-REBOOT under RFC 2131
sections 4.3.2 and 4.4.2: a client checks a previously known address and can
receive an ACK without a new Discover/Offer exchange. This supports the
returning-client explanation rather than assuming two packets were lost.
The packet pattern establishes protocol behavior; the actual stored lease
files and client process state at recording time remain unavailable here.

**Proposed journey repair:** Use initial acquisition as the main teaching
example, with Discover, Offer, Request, and ACK visible and explained. Before
recording, verify client ownership and starting lease state, rehearse a
repeatable setup, and ensure both saved packets and readable live output are
available. Do not assume a cable unplug/replug creates a fresh client. A
returning-client exchange can be a brief, separately labeled follow-up if
useful; it must not stand in for four packets that are not on screen.

**Coverage criterion for the new journey:** A viewer can follow one client's
complete initial exchange, connect the resulting address to that client's
interface/OLED, and understand why the subsequent communication test completes
the episode's promise. Keep the returning-client variation optional until the
main sequence is clear. Prepare concise explanation targets before camera copy.

**Later footage review:** Locate the old voiceover and compare its actual
claims with the frames shown. Preserve useful material; distinguish omitted
explanation from an incorrect explanation.

## Ending and scope — existing material, not a fifth diagnosed gap

Joel's account establishes that the old ending did return to the familiar
local-network outcome. Preserve that connection. The proposed repair is to
make the middle of the episode explain and demonstrate how that outcome was
reached, so the conclusion can point back to evidence the viewer understands.

**Proposed closing order:** Complete the automatic-address-and-communication
payoff, including what the server assigned in response to the clients'
preferences, then connect it to the familiar home-network experience. Keep the home
comparison focused on the demonstrated addressing and local communication;
the episode does not establish every part of Wi-Fi or home-router operation.
Choose a clear next question while leaving room for local-network side trips
before the larger multi-network build. This does not commit the next episode
to VLANs, spoofing, or BGP.

**Confirmed address-preference scope; timing reopened:** Joel wants
pi-foo-01/02 to request 10.10.0.1/.2 for visual consistency. He is now
considering first showing successful assignment and communication regardless
of the chosen addresses, then introducing the preference as an improvement.
Recommended order: B04 → B05 first success → B07 → B05 preference payoff.
This retains the B07→B05 transition he likes. It adds an exchange and requires
planning the lease-state transition between passes. Exact ordering remains
a proposal. Future address contention remains outside this episode.

**Observability transition, requested by Joel:** The switch did not supply the
DHCP job he expected; putting that job on a Pi benefits the learning project
because he can inspect and control its implementation. Connect this reason
for the third Pi in B03 to evidence shown in B04/B05. Describe the unmet
expectation without claiming that the switch malfunctioned.

**Coverage obligation:** Plan a readable server SSH session, selected
configuration, interface state, service status/logs, lease records, and decoded
packets from identified locations. Relate the same client and transaction
across views where supported. Check in rehearsal which log details are
available. Treat “everything is observable” as the ambition to make essential
steps inspectable; do not claim a capture sees all switch traffic or that logs
expose every internal decision. This is planned evidence, not reviewed footage.

**Protocol check for R07, 2026-09-09:** RFC 2131 section 3.1 permits an address
suggestion in DHCPDISCOVER. Section 4.3.1 describes server selection using
existing bindings, requested-address availability, and policy. A preference
can therefore accompany a full initial exchange; it does not inherently
require the returning-client shortcut seen in the old captures.

**Preparation still needed:** Verify how the actual client/version sends a
preferred address while beginning in INIT, with one process owning eth0.
Check both client remembered state and server bindings during rehearsal, and
show option 50 in Discover alongside the offered and acknowledged address.
Do not infer that the preference was sent merely because the final suffix
matches the hostname. The new server address plan must leave the desired
client addresses available. Do not guarantee the match or stage a rejection;
investigate any different result and keep the evidence.

### Two-pass rehearsal design — full DORA on the same hardware

Historical plan, now superseded by the fresh-image walkthrough. Server inspected
read-only; see [prior-state-runbook.md](prior-state-runbook.md) for inventory commands
and the checkpoint sequence. Joel reports commenting out the client preference
and running `sudo dhclient -r eth0`; affected nodes and resulting state await
confirmation. Server inspection now establishes .254/24, dnsmasq 2.90, a
.1–.50 pool, and active hostname-based assignments for .1/.2. Client inventory
and all mutations are still pending. Both passes must include full initial
acquisition; the same physical clients can be used with fresh protocol state.

**Two independent concerns:** Client lease memory determines whether it tries
to validate a known address instead of discovering. Separately, server binding
history can influence which address is offered. RFC 2131 section 4.3.1 places
current/previous bindings ahead of a requested address in its recommended
selection order; section 4.3.4 allows retained information after a release.
Full DORA alone therefore does not establish that a new preference will win.

**Candidate implementation:** A dedicated client configuration, lease file,
and PID file per run provide a controllable lifecycle. ISC dhclient documents
these controls via -cf, -lf, and -pf, plus release/stop via -r. Its configuration
supports sending option values. This is an implementation candidate, not a
decision to install or switch clients. Identify the actual installed software
first. The image's eth-dhcp profile uses NetworkManager; current NetworkManager
documentation defaults to its internal backend, so changing dhclient.conf
cannot be assumed to affect the active client. Never run two owners of eth0.

**Proposed sequence for the isolated lab:**

1. Identify each client/backend/version and preserve the lab configuration.
   Keep management Wi-Fi outside the experiment. Establish one owner of eth0
   and preserve the same MAC and explicit client identifier across both passes.
2. First pass: start from reviewed server/client configuration and empty lab
   lease state, with no manually specified address preference. Start capture
   before client activation. Save full DORA, server leases, client addresses,
   and the successful communication test.
3. Between passes: save the first run's state and evidence. Release the lab
   leases through their actual owners, stop those clients, and verify their
   old eth0 addresses are removed. A release is not the whole reset.
4. With the lab DHCP service stopped, prepare fresh, isolated server lease
   storage; restart it with the same reviewed address pool/options. dnsmasq
   supports an explicit --dhcp-leasefile path. Do not edit its live lease file
   while it is running. Check .1/.2 are available and no other lab client can
   claim them during preparation. Keep the server's own address unchanged.
5. Prepare fresh client lease storage and the .1/.2 preference settings while
   keeping client identifiers stable. Do not reuse a cached binding or create
   a reservation as a substitute for testing the client's request.
6. Start new captures, then activate the clients. Inspect Discover (including
   option 50), Offer, Request, and ACK for each transaction; connect the actual
   assignment to server leases, client addresses, and communication.

This resets remembered allocations between two controlled experiments. It
does not demonstrate that changing a preference on a live lease immediately
renumbers the client. A brief explanation of resetting the lab belongs in the
transition, even if the operational steps stay off camera.

**Readiness check:** Rehearse the two-pass sequence and repeat it from the
same documented starting state. Both runs must show full DORA for each client;
the preference run must show the requested option and the actual server
decision. Investigate any mismatch rather than rewriting the expected result.
If this cannot be made repeatable, revise the recording order before filming.
The server reset controls offer history; the client reset controls whether a
fresh exchange starts. Neither effect should be inferred solely from an OLED.

### Image/OLED work shares the rehearsal hardware — 2026-09-09

Joel identified the source of `little-internet.conf` as the sibling worktree
`/Users/joelhans/orca/workspaces/little-internet/image-dhcp-role`, where he is
developing OLED views of DHCP. Read-only inspection found a clean worktree on
`joelhans/image-dhcp-role`, commit `80f5bb5dfbeece5e4e20de223fe40179e82b532a`.
This explains the configuration's provenance; it does not establish that all
three Pis run that exact revision or that the lab is broken.

**Purposeful configuration:** The source
`image/stage-little-internet/00-net-tools/files/little-internet-dnsmasq.conf`
contains the same hostname assignments for .1/.2 seen on the live server.
Its range is commented in the image source and enabled on the serving Pi.
Stable server assignments are useful to the image setup, but obscure the
effect of client preferences in B07. Preserve the image source and runtime
backup; prepare a temporary server policy without those assignments for both
rehearsal passes, with explicit restoration afterward.

**Existing reset implementation:** `lessons/02/scripts/reset.sh` and `lib.sh`
already address remembered leases. They assume the `eth-dhcp` NetworkManager
profile and internal eth0 lease files. They do not account for an independent
dhclient process; deleting those files alone would not reset that client's
state. `--arm` leaves clients waiting for a trigger; ordinary reset reacquires
immediately; `--blank` tears down the server role too. The implementation
deletes rather than archives lease files, resets the server before clients,
and does not validate four captured messages. Reuse selected operations only
after runtime inventory, evidence preservation, and capture timing are settled.
No reset script was executed. Do not adopt source comments' absolute protocol
claims as evidence; retain the RFC and actual decoded exchange as authority.

**Concrete observability coverage:** `tools/dhcp-oled/dhcp_oled.py` reads live
tshark fields and latches the messages it sees. `tools/lease-oled/lease_oled.py`
reads the server lease file. Candidate filming arrangement: handshake views on
the clients and the lease ledger on the server, linked to terminal/capture
evidence for B04/B05. This supports Joel's B03 promise of inspectability.
An unfilled cell means that viewer did not record that message; investigate
capture readiness and packet evidence before saying the client skipped it.

The handshake tool's `--pace` reveals observed messages slowly and marks the
title with `~`; disclose the slowed display when filming. It does not save a
pcap. Save a separate capture, confirm viewers are ready without capture
errors, and identify the deployed versions before depending on the display.
If the experiment uses a different lease file, the ledger's `--leases` must
follow it. Both viewers use the shared panel-claim mechanism; plan one
foreground viewer per panel. Source inspection is not a hardware/OLED test.

**Client ownership checkpoint:** Subsequent read-only SSH inspection found
NetworkManager reporting `eth-dhcp` connected on both clients, with dynamic
.1/.2 addresses still present. Both report nmcli 1.42.4; neither exact process
search found dhclient or dhcpcd. See the [raw client inventory](evidence/2026-09-09-client-inventory.md).
This identifies the interface manager, but the DHCP backend and the effects of
the earlier release remain unverified. Confirm that backend and installed OLED
state before selecting reset commands. Editing dhclient.conf may have affected
a different client from the one the image expects; that remains a hypothesis.

## Essential questions

| ID | Question to resolve before scripting | Evidence/source to seek | Status |
| --- | --- | --- | --- |
| R01 | Which jobs belong to this switch, the DHCP service, and routing? | Device documentation and authoritative networking references; inspect actual configuration | Partial: model identified in BOM; manufacturer management/DHCP-client docs reviewed; installed revision/configuration and remaining claims unverified |
| R02 | How can a client ask for an IPv4 address before it has one? | DHCP specification and decoded packet fields from the actual capture | Unverified |
| R03 | What does a lease provide, and what does address assignment alone prove? | DHCP specification, lease file, interface state, and reachability check | Unverified |
| R04 | How will both planned passes show full initial acquisition on the same clients? | DHCP state-machine specification, packet options, and recorded client state | Old files match INIT-REBOOT; fresh-state design documented; implementation/rehearsal and old voiceover still unverified |
| R05 | What server address, pool, interface binding, and advertised options fit this isolated lab? | dnsmasq and NetworkManager docs, current image configuration | Partial: interface/netmask dependency documented; old failure cause and corrected setup still unverified |
| R06 | What can each capture point see through the switch? | Capture location, Ethernet destination fields, and matching captures | Unverified |
| R07 | How should preferred addresses be requested with one client owning each interface, including a possible transition from an initial unpreferred lease? | Actual client/version and configuration docs; option 50, offered/ACKed address, client/server state | Required; protocol support checked; placement, client configuration, and rehearsal unresolved |

For each resolved question, add the source title/URL or repo path, section or
frame numbers, date inspected, supported claim, and limits of the evidence.
Use primary technical sources. Keep the words intended for camera in beats.md.

## Previous-run details to investigate

- G04 confirms Request/ACK in both saved DHCP captures, with request fields
  matching INIT-REBOOT. Review the voiceover and prepare the intended client
  starting state before scripting the new demonstration.
- The draft uses `10.10.0.0/24` for the server and includes that address in the
  pool. Establish the intended address plan before reusing commands.
- Review the phrase “a switch plus this Pi is [a router]” and explain the jobs
  separately with wording that matches what the build actually does.
- The draft switches between NetworkManager and manual dhclient use. Determine
  current ownership of eth0 before planning a repeatable demonstration.
- A saved capture and visible terminal output are separate recording needs.
  The previous draft documents missing live output when `-P` was omitted.
- A capture on one client may not show every exchange. Document where the
  evidence comes from before narrating apparent absences.

These are review prompts, not completed diagnoses or instructions to modify Pis.

## Sources and findings

| Source | Location | Finding | Confidence / limitation |
| --- | --- | --- | --- |
| Previous working diary | [Reference snapshot](references/diary-02-working-copy.md) | Starting story and claimed observations | Historical draft; technical interpretations unverified |
| Previous working diary, server setup | [Reference snapshot](references/diary-02-working-copy.md), “Giving dnsmasq a range” and “Failure 2”; inspected 2026-09-09 | Records range setup, server eth0 address/profile creation, then reported client success | Supports chronology as recorded; does not isolate the cause or establish usable footage |
| Dnsmasq manual | [Upstream manual](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html), --dhcp-range; inspected 2026-09-09 | For directly connected networks, an omitted netmask is derived from interface configuration | Primary technical support for G03/R05; installed version and historical service state remain unknown |
| Two DHCP captures | [pi-foo-01](references/captures/dhcp_pi-foo-01.pcapng), frames 1, 2, 8; [pi-foo-02](references/captures/dhcp_pi-foo-02.pcapng), frames 1–2; inspected 2026-09-09 | Request/ACK pairs and first-request options documented in G04 | DHCP summaries and first-request details decoded; other frames and corresponding footage unreviewed |
| DHCP specification | [RFC 2131](https://www.rfc-editor.org/rfc/rfc2131.html), sections 4.3.2 and 4.4.2; inspected 2026-09-09 | Defines request fields and ACK path for initialization with a known address | Supports interpretation of captured behavior, not historical client lease-file contents |
| DHCP address preferences | [RFC 2131](https://www.rfc-editor.org/rfc/rfc2131.html), sections 3.1 and 4.3.1; inspected 2026-09-09 | Discover may suggest an address; allocation remains a server decision | Supports the intended B07/B05 protocol scenario; actual client support and configuration still to verify |
| DHCP state across passes | [RFC 2131](https://www.rfc-editor.org/rfc/rfc2131.html), sections 4.3.1, 4.3.4, 4.4.2; inspected 2026-09-09 | Client known-address behavior and server allocation history are separate reset concerns | Protocol guidance; exact dnsmasq/client behavior still to rehearse |
| ISC dhclient lifecycle | [ISC manual](https://kb.isc.org/docs/isc-dhcp-44-manual-pages-dhclient), Operation and Options; inspected 2026-09-09 | Reads remembered leases at startup; supports separate config/lease/PID files and explicit release/stop | Candidate implementation controls; installed client/version unknown |
| ISC client option configuration | [ISC dhclient.conf manual](https://kb.isc.org/docs/isc-dhcp-44-manual-pages-dhclientconf), “The send statement”; inspected 2026-09-09 | Client configuration can send specified option values | Actual preference packet and initial state still require rehearsal |
| NetworkManager client selection | [NetworkManager.conf](https://www.networkmanager.dev/docs/api/latest/NetworkManager.conf.html), main.dhcp; inspected 2026-09-09 | Backend selection is version/build dependent; current documentation defaults to internal | Combined with image eth-dhcp profile, establishes need to identify actual owner; not a report of Pi runtime state |
| Dnsmasq lease storage | [Upstream manual](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html), --dhcp-leasefile; inspected 2026-09-09 | Allows a dedicated lease file for the lab service | Storage control exists; no reset executed or tested |
| Live server inventory | [Actual output](evidence/2026-09-09-server-inventory.md), 2026-09-09 | .254/24; dnsmasq 2.90 active; .1–.50 pool; hostname-based .1/.2 assignments; both clients still listed in lease file | Read-only snapshot; client process/address state and reasons leases remain are unverified |
| Two switch link-up captures | [Reference inventory](references/README.md) | Available for evidence review | Still undecoded in this workflow |
| Project bill of materials | [BOM.md](../../BOM.md), Phase 1 switch row; inspected 2026-09-09 | Lists TP-Link TL-SG108E | Repository identification; installed hardware/firmware revision not established |
| TP-Link TL-SG108E V6 product page | [Manufacturer specifications](https://www.tp-link.com/us/business-networking/easy-smart-switch/tl-sg108e/), Management Made Easy and Specifications; inspected 2026-09-09 | Documents web UI and management utility, switching and monitoring features; no SSH or DHCP-server feature is listed | Primary documentation for V6; absence from a feature list alone is limited evidence; installed revision unknown |
| TP-Link TL-SG108E V2 user guide | [Manufacturer PDF](https://static.tp-link.com/res/down/doc/TL-SG108E_V2_UG.pdf), sections 3.1 and 4.2, printed pp. 9 and 11–12; inspected 2026-09-09 | Browser management; DHCP setting configures the switch as a client obtaining its own management address | Primary documentation for V2; establishes the setting's meaning, not this bench's current configuration or a universal claim about switches |

## Parking lot

Loop prevention, VLANs/port mirroring, DHCP server competition, and two clients
requesting the same address can become future questions. Client preferences
for .1/.2 are now included in this episode.
# Fresh diary review — 2026-09-09

**Completed-draft publication review:** Joel has finished through B06. The
next work is editorial: restore B04's missing server-address intervention,
repair B07's successful migration/reset steps and misplaced capture placeholder,
then correct timing/causal claims and prepare a standalone article. The
[publication and filming plan](publication-and-filming.md) records the specific
gaps and treats video production as a separate path. Raw diary preserved in
remote checkpoint `70a3f94`; no prose edits made in this review.

**Switch retry clarification:** The e2e recording's five-second DHCP Requests
come from TL-SG108E at .12, with ciaddr=.12 and no option 50/server identifier.
No ACK for it appears in that recording. A later server journal exchange at
21:58:49 grants the switch .3, also present in the current lease file. Keep
these events distinct; continued retries after the .3 ACK remain unverified.
See [packet interpretation and verbatim server evidence](evidence/2026-09-09-switch-dhcp.md).
For the diary, these are Requests, not Discovers; its management interface
needs an address for IP access, while switching Ethernet frames does not.
Follow-up found the pre-reflash server actually used a .1–.50 pool (active
config and journal preserved in the server inventory), so .12 was eligible
then. A retained lease from that setup is plausible; no .12 grant was found
in the available captures, saved inventory lease list, or current journal.

**Image baseline and Pi 01 follow-through:** Joel chose to codify NM-managed
dhclient in the image and requested the matching configuration on Pi 01.
Image source now explicitly installs isc-dhcp-client and the backend config;
it does not bake in .1/.2 requests. Stage syntax and temporary-root install
checks passed; no image build/release occurred. Pi 01 now sends option 50=.1
in full DORA and has a single .1/24 address, with NM parentage and Wi-Fi routing
verified. See [Pi 01 evidence](evidence/captures/2026-09-09-pi01-backend/README.md).
This completes the Pi 01 conversion left open below. Backend choice becomes
preparation, while B07 introduces the preference. Both clients currently have
preferences enabled; disable them and prepare lease state before rehearsing
the first assignment pass. Repeated full walkthroughs remain unproven.

**B07 managed-backend test completed:** With Joel's authorization, deactivated
Pi 02, removed the global .2 preference, preserved its DHCP client identifier,
archived eth0 lease state, restarted NetworkManager with dhclient, and reset
only Pi 02's server binding. Wi-Fi reconnected normally. An nmcli activation
produced full DORA with option 50=.2 and Offer/ACK=.2. Exactly one IPv4 address
remains, .2/24; dhclient is a child of NetworkManager. Autoconnect restored.
See [verified captures and procedure](evidence/captures/2026-09-09-nm-preference/README.md).
This supersedes the candidate-only status below for this one trial. Both-pass
repeatability, Pi 01 conversion, and final OLED filming remain future work.
Joel agrees to use the NM-managed client consistently for the video.

**B07 ownership and narrative revision:** Joel tried standalone dhclient with
`send dhcp-requested-address 10.10.0.2;` and reports success in the server and
capture. Read-only inspection of client 02 showed both 10.10.0.8/24 and
secondary 10.10.0.2/24 on eth0, an active NetworkManager eth-dhcp profile, and
standalone `dhclient eth0` PID 15849. The installed OLED reads `ip -json addr`
and displays the first IPv4 address, explaining the retained .8 display.
NetworkManager's journal records its .8 lease; the kernel route still selects
.8 for the lab subnet. An additional default route via .254 is present after
the standalone-client experiment. No ownership/address/route cleanup performed.

Joel questions changing network management tools mid-lesson. Better candidate:
keep NetworkManager as manager but configure its supported dhclient backend.
The version-specific 1.42.4 documentation supports `[main] dhcp=dhclient`.
Its `find_existing_config()` checks `/etc/NetworkManager/dhclient-eth0.conf`,
and its configuration merger retains a `send dhcp-requested-address` line.
This is source-supported, not yet rehearsed on these Pis. Backend selection is
global; a restart and Wi-Fi behavior must be accounted for. Move the current
global requested-address setting into an eth0-specific configuration so Wi-Fi
cannot inherit the lab preference. Stop/release the standalone client and
cleanly reset the NM connection before reacquiring, with client/server lease
history and option-61 identity accounted for when verifying DORA/option 50.

Recommended narrative: use the NM-managed backend consistently for both
filming passes, explaining once that NetworkManager manages the interface and
uses dhclient for DHCP. Alternatively, server reservations preserve the current
internal backend but answer a different question; do not substitute that
lesson without Joel choosing the scope change. Earlier standalone-handoff
recommendation is superseded by this candidate, pending validation.

Sources checked:
- https://www.networkmanager.dev/docs/api/1.42.4/NetworkManager.conf.html
- https://raw.githubusercontent.com/NetworkManager/NetworkManager/1.42.4/src/core/dhcp/nm-dhcp-dhclient.c
- https://raw.githubusercontent.com/NetworkManager/NetworkManager/1.42.4/src/core/dhcp/nm-dhcp-dhclient-utils.c

**B07 preparation checkpoint:** Read-only inspection of freshly walked-through
pi-foo-02 confirms NetworkManager 1.42.4, internal DHCP backend, and no exposed
requested-address property in `nmcli -f ipv4 connection show eth-dhcp`.
`isc-dhcp-client` 4.4.3-P1-2 is installed; its executable is
`/usr/sbin/dhclient` (ordinary SSH command lookup did not find it because of
PATH). A dedicated dhclient configuration/lease file is a candidate for the
explicit option-50 experiment, with a deliberate handoff of eth0 from
NetworkManager while Wi-Fi stays managed. No handoff or lease reset performed.
Do not imply editing dhclient.conf affects the active internal client.
Use Pi 02 first (.8 to requested .2); preserve current identity fields and
client/server lease records before comparing requests. A server reservation
would demonstrate different policy and is not a substitute for the requested
client-preference experiment. Full DORA must be observed after reset, not
assumed from reconnecting. ISC configuration reference:
https://kb.isc.org/docs/isc-dhcp-44-manual-pages-dhclientconf.

**B04/G03 experiment update:** New-run evidence now supports the missing server
IPv4 configuration explanation. dnsmasq received DHCP packets on unaddressed
eth0 and logged that specific problem. After Joel added 10.10.0.254/24 and
retried client acquisition, the same dnsmasq PID logged Discover/Offer/Request/
ACK and client 01 showed dynamic 10.10.0.1/24. Joel reports full DORA visible
in tshark. See [experiment evidence](evidence/2026-09-09-server-no-address-warning.md).
This supports the cause in this new setup, not retrospective proof of the old
run. Packet-file inspection, server address persistence, client 02 acquisition,
and client-to-client communication remain separate checkpoints.

Reviewed the current diary through B03; B04 is a heading awaiting the build.
The draft now connects questions, bench actions, packet excerpts, and next
decisions. Continue the walkthrough before polishing narration. Joel retains
ownership of diary.md; no diary edits made in this review.

Remaining documentation gaps and corrections:

- Label each packet excerpt with capture host/interface, retained filename,
  and whether it came from the initial run or a deliberate retake. Record
  intermediate actions such as profile activation and ARP-cache flushing when
  actually performed; do not infer missing commands from successful output.
  tsharkie now overwrites reused filenames, so preserve captures selected as
  diary evidence under distinct names.
- B02's “identity” must mean the IPv4 address needed for this experiment.
  Its displayed IPv6 source addresses already demonstrate IPv6 addressing.
  A failed ping alone does not establish absence of an IPv4 address or its
  route; pair it with interface/route evidence from the same run.
- Correct B03's DORA R from Reply to Request. DHCP configures hosts; a lease
  alone does not establish a path to the public internet. See RFC 2131,
  especially section 3.1: https://www.rfc-editor.org/rfc/rfc2131.html.
- Preserve the purchase expectation, but avoid attributing missing DHCP to
  price or describing the switch as wholly inaccessible. Existing R01/G02
  research distinguishes web management, SSH, and a DHCP server.
- Current command examples still give tsharkie a -w option it does not
  implement; use the positional capture filename. Its relative-time output
  is not equivalent to the commented tshark -td examples.
- For B04, write each change's purpose and predicted result before recording
  the actual result. In particular, record how clients leave their manual
  eth profiles and return to automatic DHCP before claiming lease acquisition.
  Keep unexpected outcomes and unresolved questions alongside the successful
  path so later scripting does not recreate the old unexplained settings hunt.
