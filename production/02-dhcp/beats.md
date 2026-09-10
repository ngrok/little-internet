# Recording journey

Status: proposed order. Script slots are intentionally unfinished until the
research and Joel's missing-explainer list are developed. No lab commands in
this document have been prepared or authorized for a recording run.

Keep these IDs when moving beats. Footage and edit decisions refer to them.

Workflow decision, 2026-09-09: develop these questions through a fresh walkthrough
from the latest repository image, writing observations in diary.md. Derive OLED
requirements from that experience and build the tools alongside script
finalization and filming preparation. Existing DHCP display code is reusable
material to evaluate, not a prerequisite or fixed visual plan.

| Beat | Question | Essential? | Research |
| --- | --- | --- | --- |
| B01 | Where are we starting, and what will this build let us do? | Yes | G01, R01 |
| B02 | What should the switch change, and what actually changes? | Yes | G02, R01, R02, R06 |
| B03 | Who should answer the request for an address? | Yes | R01, R02, R03 |
| B04 | What does the third Pi need to do that job? | Yes | G03, R05 |
| B05 — first pass | Can we explain automatic assignment and prove communication? | Yes | G04, R02, R03, R04, R06 |
| B07 | Can the clients ask for addresses that match their names? | Yes | R07 |
| B05 — preference payoff | What does the server assign when the clients ask for .1/.2? | Yes | R04, R07 |
| B06 | What have we built, and what remains to build? | Yes | R01, R03 |

The table now shows a two-pass proposal under discussion, following Joel's
reconsideration of preferences from the start. B05 appears twice as two
checkpoints of the same beat; its ID remains stable. First establish working
DHCP with whatever valid addresses are assigned, then use B07 to motivate
preferences and return to B05 for their payoff. This ordering is recommended,
not yet settled. Rehearse both states before filming; do not invent a mismatch.

## B01 — Orient the viewer, then change the bench

- **Question:** What is the little internet, where did we leave it, and what
  will this episode add?
- **Proposed progression (G01; outline only):** Reintroduce the project as
  learning networking by building it on real hardware, with the eventual goal
  of interconnected networks. Recall two Pis talking over one cable after
  manual IPv4 assignment. Establish today's goal: have someone on the network
  hand out addresses so each new device does not need manual assignment, then
  demonstrate the Pis communicating using those addresses.
  Introduce the switch and new bench arrangement as the next experiment.
- **Action:** Connect the larger ambition to a few previous-video cut-ins,
  then return to the current bench and its immediate question.
- **Evidence / proposed coverage:** Locate and review earlier footage of the
  two-Pi cable setup, manual address assignment, and successful ping. Record a
  clear view of the new nodes, labels, and cable paths. No source selections
  have been verified yet.
- **Explanation slot:** Project context, prior result, and the episode's
  concrete destination. Exact wording waits until the gap audit and scope
  discussion are ready for scripting.
- **Confirmed payoff:** Automatic IPv4 assignment followed by successful
  communication between the clients over lab Ethernet. B05 must show both;
  B06 returns to connectivity and identity as the result.
- **Handoff prompt:** What would I expect to happen when I plug these in,
  and what would show that the address-assignment goal has been met?
- **Room for the vlog:** Cases, OLEDs, and what makes this setup nicer to use.

## B02 — Plugging in is an experiment

- **Question:** What do we expect adding the switch to change, and what does
  connecting the Pis actually reveal?
- **Before connecting (G02; proposed):** Show the old direct cable arrangement
  alongside the new cable paths. Explain the practical reason for the switch
  and its role at the depth needed for this experiment, after R01 is verified.
  Recall Joel's purchase expectation that the switch included a DHCP server,
  then place his realization about its limitations just before the original
  filming. Explain why the switch still belongs in the build and which job
  remains to be supplied. This progression shares prior learning; it does not
  stage a fresh discovery. Joel tentatively recalls investigating UI/SSH access
  to monitor the presumed DHCP server; the exact sequence is uncertain and
  should stay general in the retelling.
- **Action:** Start recording the evidence, connect the devices, and inspect.
- **Evidence:** Readable interface/OLED state and decoded chatter from a named
  capture point. Preserve capture files and actual terminal output.
- **Explanation slot:** Explain only the fields and terms needed to interpret
  what appeared, and connect them back to the switch's role. Research must
  establish the limits of the conclusion. The depth of switching mechanics
  remains a scope decision.
- **G02 explanation boundary:** Distinguish connecting devices, accessing the
  switch's management controls, and providing DHCP service. Do not explain
  lack of a DHCP server as a consequence of no SSH or low price. Manufacturer
  documentation findings and revision limits are in research.md.
- **Handoff prompt:** What did adding the switch accomplish, and what work
  remains before devices receive addresses automatically?
- **If the result differs:** Inspect existing profiles, leases, and services
  with Joel before deciding whether to reset or incorporate the surprise.

## B03 — Put a name to the missing job

- **Question:** Who should answer a device asking for an address?
- **Action:** Point to the devices and describe the service to add.
- **Existing material to preserve:** Joel recalls explaining that the third
  Pi will run dnsmasq as the DHCP server. Locate and review that passage;
  build the transition from G02 into this established explanation.
- **Connection to G02:** Return to the address-assignment job Joel originally
  expected to come with the switch. Make the reason for providing that job
  elsewhere explicit before introducing the third Pi's configuration.
- **Why the Pi is a benefit (Joel's requested transition):** The switch did
  not include the address-assignment job Joel expected. Providing it on a Pi
  puts the service in a machine he can SSH into, configure, and investigate.
  Connect this directly to the project's purpose: important networking steps
  can be inspected and explained by the learner.
- **Evidence:** Use the preceding capture to motivate the missing service;
  open a real SSH session to the server Pi and carry that same session into
  B04. The planned configuration, service output, leases, and packet views
  must substantiate the observability promise across B04/B05.
- **Explanation slot:** Short DHCP explainer: roles, the request, and the meaning
  of a lease, tied to this physical setup and familiar home networking.
- **Handoff prompt:** With the service on a machine we control, what can we
  inspect and configure to make it hand out addresses?

## B04 — Give the third Pi a job

- **Question:** What configuration lets this Pi serve the lab?
- **Preparation (G03):** Resolve R05 and rehearse the core setup before
  scripting this beat. Prepare the starting state, essential settings, a
  plain-language reason for each, expected observations, and a repeatable
  demonstration plan. This preparation has not yet been performed.
- **Action:** Establish the setup plan before editing settings. For each
  essential change, explain its purpose, predict its effect, then inspect the
  result. Use the verified plan and evidence from preparation.
- **Evidence:** In the server SSH session, show selected config lines,
  interface state, and service status/log output. In B05, return to this
  server view for lease records and a named capture point. Prepare readable
  evidence and demonstrate what each view establishes; commands and log
  detail remain to be verified.
- **Explanation slot:** Explain the purpose of the server's address, pool, and
  interface choice. Do not copy the old address plan without review.
- **G03 causal question:** Joel believes giving the server an IPv4 identity
  unlocked client assignment. Treat that as a hypothesis to verify in
  preparation. Establish the server's own lab address and the client pool as
  separate decisions; support the explanation with logs and packet evidence.
  Do not reenact the old failure or claim its exact cause is already proven.
- **Handoff prompt:** What should the next client connection let us observe
  at the client and inside the server?
- **Room for the vlog:** Actual troubleshooting, with a short explanation of
  what each correction changes and the evidence that prompted it. If an
  unexpected result cannot yet be explained, investigate and return with the
  explanation. Do not reproduce past mistakes for drama.

## B07 — Ask for addresses that match the labels

- **Question:** Can the clients ask for .1 and .2 to match pi-foo-01 and
  pi-foo-02, and who decides whether they get them?
- **Confirmed purpose:** Joel wants visual consistency across names, OLEDs,
  and packet evidence. This is a client preference to explain within DHCP.
- **Placement under discussion:** After the first successful B05 pass, ask
  whether the already-working network can also give the clients the preferred
  numbers. Joel likes the transition from this question into B05's payoff.
- **Preparation:** Resolve R07 and rehearse both passes before filming, with
  one process owning eth0. Plan how to move from the first pass's client leases
  and server bindings to a repeatable preference test. Both passes must show
  full DORA; the researched reset design is in research.md. Exact commands
  depend on the installed client/backend and remain unimplemented.
- **Action:** Recall the first pass's success, explain the visual-consistency
  preference, then show the relevant client setting. Leave assignment to the
  server in the next checkpoint. If the numbers already match, explain the
  desire to request them explicitly; do not manufacture an unwanted address.
- **Evidence:** In B05, connect the desired value in configuration to option
  50 in Discover, the server's offered address, the client's selection, the
  ACK, and the resulting interface/OLED address. Matching numbers alone do not
  establish that a preference was sent or honored because of the request.
- **Explanation slot:** Why Joel wants consistent numbering; what the client
  can suggest; what the server controls. Exact client behavior needs research.
- **Handoff prompt:** Does the server offer the address this client asked for?
- **Transition context:** Explain that the lab's remembered allocations are
  reset so the same Pis start a fresh exchange with their new preferences.
  Do not imply changing a preference instantly alters an existing lease.
- **Scope boundary:** Two devices asking for the same address is a future
  experiment. Do not add a conflict demonstration to this recording.

## B05 — Watch the promise become visible

- **Question:** How did the Pis acquire their addresses, and can they now
  communicate using them?
- **G04 scenario proposal:** Make initial acquisition the main example and
  obtain a visible Discover/Offer/Request/ACK exchange through a rehearsed
  client starting state. The old saved captures show Request/ACK consistent
  with returning clients; retain that as an optional, separately explained
  comparison. Exact state preparation is unresolved and has not been run.
- **First-pass proposal:** Show full initial acquisition without manually
  configuring .1/.2 preferences. Explain all four messages, inspect the server
  lease record alongside the client's address, and prove communication with
  the addresses actually assigned. That is a complete first success.
- **Preference-payoff proposal, after B07:** Run the rehearsed preference test
  and inspect the requested, offered, and acknowledged addresses. Focus on
  the new evidence rather than repeating the entire protocol explanation.
  Capture full DORA even if only changed fields get screen time. Rehearse the
  client/server reset and verify both full exchanges before filming. Finish
  with communication using the resulting addresses.
- **Existing explanation to review:** Joel recorded packet-analysis voiceover
  after the old session. He recalls mentioning four messages without explaining
  them all. Inspect its wording against the packets actually shown before
  deciding what can be reused. Prepare the new explanation and entry/exit
  transitions before recording; voiceover remains a valid format.
- **Action, first checkpoint:** Record the chosen client scenario and inspect
  the address-assignment exchange. Establish automatic assignment for both
  clients.
- **Action, second checkpoint:** Use the assigned addresses to demonstrate a
  successful exchange between the clients. A ping with decoded request/reply
  rows is the proposed test; exact commands remain to be prepared.
- **Evidence:** Cable action, OLED changes, decoded DHCP rows, lease entries,
  and interface addresses for both clients; then readable ping output and
  packet rows from a named Ethernet capture point. Include interface/route
  evidence to establish that the exchange used the lab wire.
- **Pay off B03's observability promise:** Revisit the server SSH session to
  connect its configuration and lease record to the client identity and
  transaction in the packet evidence. Identify every capture location and
  prepare only the service-log claims the actual output can support. A server
  capture is not a promise that every frame elsewhere on the switch is visible.
- **Explanation slot (G04; learning targets, not camera copy):** Trace one
  complete initial exchange. For Discover, Offer, Request, and ACK, identify
  the sender, purpose, and the relevant field or fields in the actual packet.
  Explain why each step follows the preceding one. Connect the assigned
  address to the client on the bench, then move to the communication test.
  Verify the technical account through R02–R04 before scripting. Label any
  returning-client comparison separately and use its own evidence.
- **Handoff prompt:** What can I now do without manually assigning each client?
- **Before recording:** Document client lease state and capture locations so
  the expected exchange is a prediction grounded in the setup. Verify which
  process owns the client interface and check the repeatable scenario during
  rehearsal. Check readable live output as well as saved capture files.

## B06 — Name the result

- **Question:** Which parts of the network now do which jobs?
- **Existing ending to preserve:** Joel recalls concluding that the network
  now behaves like the familiar experience of joining a home network and
  communicating. He also left pi-foo-01's .4 address as future work and
  suggested local-network side trips before adding more networks. Actual
  wording and pacing remain unreviewed.
- **Action:** Return to a wide view and point to the components involved.
- **Evidence:** Recall the specific successful observations from B02–B05.
- **Explanation slot:** Restate the outcome, what it proves, and the remaining
  question that makes the next episode worth doing.
- **Confirmed ending:** Return to the two results from B05: the clients
  received IPv4 identities automatically and successfully communicated over
  their Ethernet connection. Connect this to the previous episode's manually
  assigned addresses. Keep the conclusion tied to the demonstrated local
  exchange.
- **Proposed closing progression:** Land that result, recall what the clients
  requested and what the server assigned, then connect it to familiar
  automatic addressing at home. The old .4 frustration is historical context;
  the new plan incorporates preferences in the main exchange. Scope of the
  home analogy is addressing/local communication.
- **Handoff prompt:** Choose one next question after scope settles. VLANs,
  spoofing, and other local-network explorations can precede adding networks;
  BGP remains the larger destination, not an immediate episode commitment.
- **New teaser candidate:** What happens when two clients ask for the same
  address? Joel wants to leave room for this future visualization.

## Script card — duplicate inside any beat that needs one

- Entry sentence: TBD
- Exact explainer: TBD
- On-screen evidence and field to point at: TBD
- Exit sentence / reason for the next action: TBD
- Research IDs and verified sources: TBD

## Before packing up

For each essential beat, play back the crucial take and record its filename or
slate. An unchecked box means coverage is still unknown.

| Beat | Usable explanation | Readable evidence | Transition recorded | Take / pickup notes |
| --- | --- | --- | --- | --- |
| B01 | [ ] | [ ] | [ ] | |
| B02 | [ ] | [ ] | [ ] | |
| B03 | [ ] | [ ] | [ ] | |
| B04 | [ ] | [ ] | [ ] | |
| B07 | [ ] | [ ] | [ ] | |
| B05 | [ ] | [ ] | [ ] | |
| B06 | [ ] | [ ] | [ ] | |

Say the beat ID and take number aloud when useful. Leave breathing room before
and after explainers, and record clean views of the evidence at readable size.
