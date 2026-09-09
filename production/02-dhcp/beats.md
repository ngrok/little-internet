# Recording journey

Status: proposed order. Script slots are intentionally unfinished until the
research and Joel's missing-explainer list are developed. No lab commands in
this document have been prepared or authorized for a recording run.

Keep these IDs when moving beats. Footage and edit decisions refer to them.

| Beat | Question | Essential? | Research |
| --- | --- | --- | --- |
| B01 | Why am I adding a switch? | Yes | R01 |
| B02 | What changed when I plugged the Pis in? | Yes | R01, R02, R06 |
| B03 | Who should answer the request for an address? | Yes | R01, R02, R03 |
| B04 | What does the third Pi need to do that job? | Yes | R05 |
| B05 | Can we watch a device receive its address? | Yes | R02, R03, R04, R06 |
| B06 | What have we built, and what remains to build? | Yes | R01, R03 |
| B07 | Can the addresses match the Pi names? | Optional | R07 |

## B01 — A reason to change the bench

- **Question:** Why add a switch after making two Pis talk over one cable?
- **Action:** Show the earlier arrangement and the new bench setup.
- **Evidence:** A clear view of the nodes, their labels, and cable paths.
- **Explanation slot:** Brief recap of the previous result and today's goal.
- **Handoff prompt:** What would I expect to happen when I plug these in?
- **Room for the vlog:** Cases, OLEDs, and what makes this setup nicer to use.

## B02 — Plugging in is an experiment

- **Question:** What did connecting the Pis actually change?
- **Action:** Start recording the evidence, connect the devices, and inspect.
- **Evidence:** Readable interface/OLED state and decoded chatter from a named
  capture point. Preserve capture files and actual terminal output.
- **Explanation slot:** Explain only the fields and terms needed to interpret
  what appeared. Research must establish the limits of the conclusion.
- **Handoff prompt:** What part of the result still falls short of the goal?
- **If the result differs:** Inspect existing profiles, leases, and services
  with Joel before deciding whether to reset or incorporate the surprise.

## B03 — Put a name to the missing job

- **Question:** Who should answer a device asking for an address?
- **Action:** Point to the devices and describe the service to add.
- **Evidence:** Use the preceding capture as the reason for this explanation.
- **Explanation slot:** Short DHCP explainer: roles, the request, and the meaning
  of a lease, tied to this physical setup and familiar home networking.
- **Handoff prompt:** Why run that service on this third Pi?

## B04 — Give the third Pi a job

- **Question:** What configuration lets this Pi serve the lab?
- **Action:** Work through a verified configuration plan once R05 is resolved.
- **Evidence:** Selected config lines, interface state, and service output.
- **Explanation slot:** Explain the purpose of the server's address, pool, and
  interface choice. Do not copy the old address plan without review.
- **Handoff prompt:** What should the next client connection let us observe?
- **Room for the vlog:** Actual troubleshooting, with a short explanation of
  what each correction changes. Do not reproduce past mistakes for drama.

## B05 — Watch the promise become visible

- **Question:** How did this Pi acquire the address now shown on its OLED?
- **Action:** Record the chosen client scenario and inspect the exchange.
- **Evidence:** Cable action, OLED change, decoded packet rows, lease entry,
  interface address, and a separate reachability check where relevant.
- **Explanation slot:** Trace the actual packets. If explaining a different
  DHCP scenario, label it and supply its own evidence or an explicit diagram.
- **Handoff prompt:** What can I now do without manually assigning each client?
- **Before recording:** Document client lease state and capture locations so
  the expected exchange is a prediction grounded in the setup.

## B06 — Name the result

- **Question:** Which parts of the network now do which jobs?
- **Action:** Return to a wide view and point to the components involved.
- **Evidence:** Recall the specific successful observations from B02–B05.
- **Explanation slot:** Restate the outcome, what it proves, and the remaining
  question that makes the next episode worth doing.
- **Handoff prompt:** Joel to choose the next question after the scope settles.

## B07 — Optional address preferences

- **Question:** Can I make the numbers match the names on the cases?
- **Action/evidence:** Plan only if included and after R07 is resolved.
- **Explanation slot:** What is being requested, what decides the outcome,
  and what evidence shows that the request was made?
- **Placement:** Before B06 if it earns its place; otherwise keep for later.

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
| B05 | [ ] | [ ] | [ ] | |
| B06 | [ ] | [ ] | [ ] | |

Say the beat ID and take number aloud when useful. Leave breathing room before
and after explainers, and record clean views of the evidence at readable size.
