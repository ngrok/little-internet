# Research and explanation gaps

Status: research queue, not a fact-checked script. No external technical sources
or original video have been reviewed for this scaffold. The reference diary
records prior work and includes interpretations that need checking.

## Old-cut gap audit

Fill this while reviewing `cut-for-ryan.mp4` with Joel. Use actual timecodes.

| Cut timecode | What the viewer is missing | Why it matters | Beat | Recording needed |
| --- | --- | --- | --- | --- |
| TBD | Joel to identify first gap | TBD | TBD | TBD |

## Essential questions

| ID | Question to resolve before scripting | Evidence/source to seek | Status |
| --- | --- | --- | --- |
| R01 | Which jobs belong to this switch, the DHCP service, and routing? | Device documentation and authoritative networking references; inspect actual configuration | Unverified |
| R02 | How can a client ask for an IPv4 address before it has one? | DHCP specification and decoded packet fields from the actual capture | Unverified |
| R03 | What does a lease provide, and what does address assignment alone prove? | DHCP specification, lease file, interface state, and reachability check | Unverified |
| R04 | Which exchange will this take show: initial acquisition or a returning client? | DHCP state-machine specification, packet options, and recorded client state | Unverified |
| R05 | What server address, pool, interface binding, and advertised options fit this isolated lab? | dnsmasq and NetworkManager docs, current image configuration | Unverified |
| R06 | What can each capture point see through the switch? | Capture location, Ethernet destination fields, and matching captures | Unverified |
| R07 | If included, how should preferred addresses be requested with one client owning each interface? | Actual client/version and configuration docs; packet options | Optional, unverified |

For each resolved question, add the source title/URL or repo path, section or
frame numbers, date inspected, supported claim, and limits of the evidence.
Use primary technical sources. Keep the words intended for camera in beats.md.

## Previous-run details to investigate

- The draft describes a four-message introduction, but its displayed DHCP
  sequence begins with Request/ACK. Inspect the actual options and client state
  before labeling the exchange or choosing what to demonstrate on camera.
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
| Four previous packet captures | [Reference inventory](references/README.md) | Available for evidence review | Copied intact; not decoded during scaffolding |

## Parking lot

Loop prevention, VLANs/port mirroring, DHCP server competition, and lease
preferences can become future questions if they distract from this episode.
