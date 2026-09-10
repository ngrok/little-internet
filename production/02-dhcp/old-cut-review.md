# Old cut: material worth carrying forward

First-pass selection review, 2026-09-09. The strongest material is the pleasure
of building the physical network, the third-Pi reveal, and the contrast between
automatic assignment working and the numbers not matching Joel's preferences.
Preserve those story functions as the fresh diary develops.

## Review basis and limits

Source: `cut-for-ryan.mp4`, relative to this episode directory. This is an
already edited export, not the camera-original footage. Duration 1254.314667s;
1920×1080, 24fps, AAC audio. SHA-256:
`6edc89863d54861cac87eb61286595dff54745bec8baaf124e215302a96ef8eb`.

The full source audio was transcribed locally with whisper.cpp large-v3-turbo
(173 segments through 20:53.980). All transcript segments were read. Actual
picture was inspected through five overview sheets spanning the cut, nine
closer sequence sheets, and full-resolution frames at selected evidence points.
Overview samples are navigation aids; closer sheets select frames at 2–4-second
intervals. This was not continuous playback. The session cannot accept audio
input, so no human-style listening assessment of delivery, music, noise,
sync, or clean edit boundaries has been performed.

All entries in footage.csv are therefore **unclear** pending playback. That
status means promising but not approved for assembly. Times below are elapsed
MM:SS from the export's beginning; CSV ranges use elapsed seconds, inclusive in
and exclusive out. They are review windows with context, not frame-final trims.
Words in quotation marks below are automated transcript excerpts, not
ear-verified quotations. Technical claims remain subject to the fresh evidence.

## Highest-priority candidates

| Candidate | Review window | What is actually there | Why retain it / proposed use | Remaining check |
| --- | --- | --- | --- | --- |
| C01 — Delight in the build | 00:50–01:23 | Overhead bench view cuts to close-ups of green cases, OLED towers, wiring, and GPIO. Transcript ends with “I find it all utterly delightful.” | B01: a short tactile introduction gives the project personality. Strong candidate for using existing close-ups, especially about 00:55–01:14. | Match case/display design to the new bench; screens show “no IPv4.” Check movement and audio before choosing exact cuts. |
| C02 — Another Raspberry Pi | 06:10–06:38 | Joel brings the third board and accessories into the overhead frame and explains its DHCP role. Transcript includes “in typical little internet fashion.” | B03: a characteristic way of turning the missing service into a physical addition. Preserve the reveal, possibly with the existing narration if playback supports it. | Check sentence boundaries and continuity; the reveal cannot look like a new discovery if the opening already shows all three nodes. |
| C03 — Why the Pi helps us see | 06:38–07:06 | Overhead gestures connect the server, switch, and clients. Transcript explicitly says the benefit is observing DHCP frames. | B03→B04: preserve the core reason for building it this way. The old cut already contains part of the observability promise. Extend it with service/configuration/lease evidence in the new version. | Rework the comparison with a “much more expensive switch” and scope claims about seeing “all” frames to actual capture coverage. Exact original wording need not survive. |
| C04 — Build and wake the third node | 07:12–07:58 | Assembly sequence includes mounting the board, a pink drill, display wiring, the OLED lighting, and adding Ethernet. At 07:42 the sampled display is dark; at 07:46 it is lit. | B04: strong visual material for a short construction transition. Save the OLED waking as the end of that transition. | Review continuous motion and sound; sampled frames do not establish exact wake timing. Its display waking is not proof that DHCP is serving. Avoid giving it that meaning. |
| C05 — It worked; I dislike the numbers | 13:02–13:30 | Joel points to the addressed clients. Close-ups at 13:17/13:20 show .4 and .1. Transcript says “I did not create these on my own,” then describes how the numbering “irks me to no end.” | B05→B07: the clearest existing seed for the proposed success-then-preferences journey. Preserve the satisfaction followed by a personal reason to improve a working network. | It documents the old run. Use as an acknowledged callback or recreate the explanatory function from new results; do not attach this reaction to a different transaction. Avoid retaining “solve at some other point” if this episode now solves it. |

## Additional material to save

| Candidate | Review window | Value | Reuse constraint |
| --- | --- | --- | --- |
| C06 — The switch needs an address too | 03:07–03:44; callback 18:07–18:57 | Earlier passage shows Discover rows and a switch close-up while explaining its management address. Later passage returns to the switch and highlights an ARP row with sender .3. A useful setup/payoff inside the bigger story. | Preserve the observation as a candidate; verify device attribution and assignment in the fresh run. The later ARP row shows address use, not the switch's DHCP exchange by itself. Keep this compact if it earns its place. |
| C07 — Ten Pis is too many | 10:35–10:54 | During pool configuration, the transcript jokes that more than ten Pis on one local network would mean going “fully off the deep end.” Picture shows Joel gesturing in a terminal inset. | A small human aside worth retaining if the new pool explanation gives it a natural home. Existing terminal background contains old configuration; favor carrying the idea into new delivery over recycling the whole screen. Comic timing needs listening. |
| C08 — Clean communication proof | 16:02–16:07 | Full-resolution frame at 16:04 shows `ping -c1 10.10.0.1`, a reply, and 0% packet loss in a mostly uncluttered terminal. | B05: preserve the presentation pattern and hold long enough to read. It is evidence from the old addresses/run; capture the new payoff afresh. |
| C09 — What automatic assignment buys us | 18:57–19:17 | Overhead view and client close-ups accompany the claim that another device can get an address, announce itself, and communicate without manually typing its configuration. | B06: a useful plain-language destination. Re-explain using new evidence and avoid carrying the following switch-plus-Pi/router claim into it. The close-ups still show the old .4/.1 allocation. |

## What this changes in our diagnosis

The old cut contains more of the intended journey than recollection alone
established:

- **Motivation:** the opening transcript at 00:26–00:44 connects DHCP to the
  familiar experience of plugging into a home network. Keep that destination;
  G01 still calls for a clearer previous-video recap and project orientation.
- **Observability:** C03 already promises packet visibility; the callback at
  18:42–18:57 returns to transparency. The new work should strengthen the
  explanation and show the service/configuration/lease views, rather than
  treat the core motivation as wholly absent.
- **Actual communication:** successful ping output is visible at 13:42 and
  16:04. The first includes earlier failures to the old .2 target above the
  eventual .1 success. The second is cleaner. The payoff exists; it needs a
  clearer connection to the preceding configuration and acquisition evidence.
- **DORA honesty:** the graphic at 16:32 explicitly highlights Request and
  Acknowledge with “visible in this capture.” That is useful honesty to retain,
  even though the new initial-acquisition demonstration needs all four messages.

Editorial inference: the old version spends roughly six minutes before the
third-Pi reveal, first shows assigned addresses around thirteen minutes, then
repeats acquisition after the capture-display problem. A tighter cause-and-effect
sequence can preserve the personality while making each result easier to explain.
This structural assessment is based on transcript timing and sampled picture;
it is not a judgment of the audible pace or performance.

## Material to rewrite or leave aside

- 02:34–02:58 and 05:51–06:10 frame the switch as doing nothing/an expensive
  middleman. Explain the specific missing DHCP role in the new version.
- 03:44–04:56 is the Realtek/loop-detection detour. Park it unless the fresh
  journey gives it a necessary job; its detailed claims were not verified here.
- 11:20–12:24 contains the .0 server address and a correction; the surrounding
  configuration hunt through about 15:23 is preparation history, not a template
  for the new server setup.
- 16:17–17:08 explains the shorter returning-client exchange. Keep only if
  returning behavior becomes a useful aside after full DORA; do not use it as
  footage of a fresh initial exchange.
- 17:30–18:02 gives a purpose to the server's ARP activity. The packet ordering
  alone does not establish that purpose; verify before using the interpretation.
- 19:17–20:00 moves from the working LAN into a router/gateway model without
  showing routing between networks. Rebuild that transition from the project's
  actual scope and leave a single clear next question.

## Playback handoff

First audition C01, C02/C04, and C05. Decide whether each contributes original
footage, a line, or only a story function. Then check C03's wording against the
fresh diary. Preserve useful moments without forcing the new build to reproduce
an old allocation or an old mistake. No old clip is mandatory merely because it
has been shortlisted.

Local review artifacts are under `exports/old-cut-review/` (ignored): transcript
JSON/SRT, transcription log, extracted audio, five overview sheets, candidate
contact sheets, and full-resolution evidence stills. Candidate sheets are named
`cases`, `third-pi`, `assembly`, `first-payoff`, `switch-client`, `switch-callback`,
`ten-pis-joke`, `reconnect`, and `ending`. Full-resolution still filenames use
elapsed seconds, e.g. `frame-964.png` for 16:04. They can be regenerated from
the unchanged export. This file and footage.csv retain the findings if the
local cache is absent. Original-camera filenames and source offsets remain unknown.
