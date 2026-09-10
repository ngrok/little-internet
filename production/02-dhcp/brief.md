# Brief: who hands out the addresses?

Status: starter proposal, 2026-09-09. Research and recording plan still to develop.

## Why re-record

Joel reached `cut-for-ryan.mp4` and found explanatory gaps too substantial to
repair naturally with voiceover and cut-ins. Preserve the organic vlog style
while planning enough of the learning journey to capture a complete story.
The old cut now has a first-pass selection review: full automated transcript
and sampled picture, with listening still pending. See old-cut-review.md.

Joel's diagnosis (2026-09-09): filming without enough prior knowledge left him
changing settings until addresses appeared, without a clear course or concise
explanations. Prepare the essential understanding and rehearse the experiment
before the new recording so the journey can connect decisions to evidence.

## Audience and promise

Working audience: curious developers who use networks but want the machinery
to become tangible. Assume only a short recap of the previous two-Pi experiment.

Working promise: follow the build from plugging Pis into a switch to watching
them receive IPv4 addresses automatically and communicate using those
addresses, and understand which part of the setup did what.

Confirmed payoff (Joel, 2026-09-09): the Pis have connectivity and IPv4
identities and can “chat.” Show automatic assignment and then a successful
exchange between the clients over the lab Ethernet network.

Proposed central question: what has to exist on this little network before
plugging in a device gives it an address automatically?

## Creative approach

- Start from the latest repository image and write a diary through a fresh
  walkthrough. Let the baseline and observations inform the OLEDs. Build/reuse
  display tools while finalizing the script and preparing to film;
  image-dhcp-role may provide the implementation if it fits.
- Keep the bench, cables, OLEDs, and actual packets central to the story.
- Make observability a reason for running the service on a Pi: show SSH access,
  configuration, service inspection, leases, and named packet captures as the
  journey unfolds. The viewer should be able to inspect the evidence behind
  each essential conclusion. Match the promise to the views actually shown.
- Plan questions and evidence; leave room for reactions and investigation.
- Separate exploratory learning from the main recording. Use research and a
  rehearsal to establish the core path before writing explainers; keep the
  delivery conversational and acknowledge discoveries already made.
- Interlace short, prepared explanations at the moment the viewer needs them.
- Acknowledge prior discoveries when revisiting them. Unexpected results belong
  in the story when they help answer the question.
- Record entry and exit sentences for explainers during the bench session.

## Proposed scope

Essential: the switch's role, the missing address-assignment service, setting up
the third Pi, preparing the clients to request .1 and .2 for visual consistency,
witnessing assignment, explaining the captured exchange and the server's
decision, and demonstrating communication between the addressed clients.

Optional: new cases, switch management traffic, and the switch obtaining a
lease. Retain when they strengthen the
journey; their presence in the diary does not commit us to covering them all.

Defer unless essential: proprietary loop-detection dissection, comprehensive
DHCP state-machine coverage, and a full investigation of competing DHCP clients.
Two clients asking for the same address is a future experiment, not part of
this recording.

Ending material to preserve (Joel's recollection): the build now reproduces
the familiar experience of automatic addresses and local communication; a
personal wish for address numbers to match the Pi names remains open. Future
local-network explorations such as VLANs or spoofing can come before expanding
to multiple networks. No specific next episode is committed yet.

Confirmed inclusion: teach client address preferences. Joel wants pi-foo-01/02
and .1/.2 to align visually, and the
request provides a concrete way to explain the server's authority to allocate
an address. Prepare and verify the client behavior before filming; the desired
numbers are requests, not guaranteed results. Resolve this in the main
exchange, rather than retaining the old .4 mismatch as an unfinished ending.

Placement now under discussion: Joel is reconsidering preferences from the
start. The recommended revision is to establish DHCP and communication first,
then introduce preferences as an improvement to the working network. This
adds a second exchange and some setup/recording time, but gives the preference
a concrete purpose after a complete first success. Rehearse both passes and
their lease-state transition; no ordering decision or rehearsal is complete.

## Decisions to make together

- Which missing explanations in the old cut actually prompted the re-recording?
- How much of the first episode should viewers need to remember?
- Which single future question should the ending point toward? Two clients
  asking for the same address is now a candidate.
- What is the desired approximate runtime? Unset; no timing budget yet.
- Which existing moments should survive, even if most of the episode is new?

## Success

The viewer can explain the result using what appeared on screen. Each essential
beat has usable narration, readable evidence, and a natural next step. The
recording still feels like spending time at the bench with Joel.
