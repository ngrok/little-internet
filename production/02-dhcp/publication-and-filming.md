# From the finished walkthrough to publication and filming

Joel completed the diary through B06. The raw draft, research, tools, image
source, and 17 captured packet files are preserved in commit `70a3f94`, pushed
to `origin/joelhans/production-02-dhcp`. This branch is the working archive.
The original MP4, camera footage, and Resolve project are outside this backup.

The diary can publish before the video. Its completed arc is: the switch
connects the devices, a Pi supplies DHCP, automatic assignment works, address
preferences improve the result, and a finished-network assembly proves it.
The remaining writing work is to make the explanation and commands match the
recorded evidence. Joel is revising the diary one editorial checkpoint at a time.

## B04 checkpoint complete

2026-09-10: Joel restored the server warning, the addition of 10.10.0.254/24,
the reason for choosing an address outside the client pool, and the client
retry leading to success. He also added the configuration restart before the
experiment; the log-follow and restart commands are labeled for two terminals.
The main causal gap is repaired. The more specific “eth0 which has no address”
diagnostic remains available in [the experiment record](evidence/2026-09-09-server-no-address-warning.md)
if useful during final polishing. The observed address configuration is
temporary, not a claim of persistence across reboot.

## Diary publication work

Assumed first destination: the repository's public `diaries/` collection,
matching diary 00. A blog adaptation can follow without blocking that release.
Prepare the following in order, one editorial checkpoint at a time:

1. **Use one consistent image baseline.** Joel chose to release a new image
   with the diary. Its source includes NetworkManager-managed dhclient and
   tsharkie. The diary no longer needs the historical two-client migration
   detour or manual tool installation. Keep the per-client address preferences
   and Ethernet-only lease resets inline; those are part of the experiment.
   Historical migration evidence remains in research and the capture archive.
2. **Give every packet excerpt its real source.** B07 now has client/server
   capture labels and tables generated with tsharkie's formatter. The three
   e2e excerpts link to their archived captures, and the opening mDNS timestamp
   is corrected. Keep these historical capture labels accurate when describing
   the revised walkthrough on the new image.
3. **Correct claims at the point they occur.** The review list below gives
   concrete locations and evidence boundaries. Finish this before polishing
   sentences so attractive phrasing does not cement unsupported explanations.
4. **Make a readable standalone article.** Remove production instructions and
   video-only comments, replace B labels with reader-facing headings, finish
   placeholders and code fences, fix typos, and keep Joel's reactions and
   useful detours. Reduce repeated full packet tables by focusing on one
   client plus a selective server view; link the rest. Include the prior
   episode link, a compact topology/address key, and the real payoff.
5. **Package a focused publication PR.** Start a separate branch from current
   main when the edited copy is ready. A candidate name is
   `diaries/01_who-hands-out-addresses.md`, because the public sequence currently
   ends at 00; production's 02 ID remains stable. Choose a durable public
   capture directory, such as `diaries/captures/01-dhcp/`, update links, include
   tsharkie and documented setup dependencies, and add the root README entry.
   The diary need not claim a runnable lesson or video exists. Bring only the
   reader-facing material and required tools into that PR; the production
   archive is not the publication diff.

**Image release decision, 2026-09-10:** publish a new image alongside the
standalone diary, without waiting for the video. Image source now includes
both the NM dhclient backend and tsharkie. Build the image, verify first boot,
management Wi-Fi, unprivileged live capture plus saved pcapng, and the diary's
DHCP/preference path on that artifact before release. Record its version and
checksum and point the diary at that release. No image has been built or
released for this change yet; source integration is not a downloadable image.

### Accuracy review list (original findings; many now corrected)

| Location | Required correction or boundary |
| --- | --- |
| B02/B03 switch introduction | Correct TG-SG108E to TL-SG108E. Describe this model's missing DHCP-server role without blaming price. It has a web management interface; lack of SSH is a separate limitation. |
| Connectivity and identity framing | Specify IPv4 identity where intended: the captures already contain IPv6 addresses. DHCP does not by itself provide public internet access or guarantee reachability to every host. |
| B07 ownership and preferences | Scope backend limitations to the tested version. Explain that NM manages interfaces and can launch dhclient. Two displayed addresses do not establish universal address precedence; the OLED reads the first IPv4 entry. A request does not “lock in” future leases. |
| E2E timing | On Pi 01: Discover→Offer about 5.839 s; Offer→ACK about 15 ms; ACK→first announcement about 56 ms. The draft's “a hundredth of a second” is inaccurate. Keep source clocks separate across captures. |
| Server “checks its work” aside | Post-ACK ARP rows establish neighbor queries, not that dnsmasq deliberately validates its leases. Distinguish this from the documented pre-offer conflict-check ping. Investigate the later ARP cause or describe only the observation. |
| Switch retries aside | These are Requests, not Discovers. Earlier pool was .1–.50, not .0–.50. That makes a prior .12 lease plausible; no .12 grant was found. Later .3 DORA is verified, but the exact reason it restarted acquisition is unknown. See [switch evidence](evidence/2026-09-09-switch-dhcp.md). |
| Scope and closing | The switch's IP is for management, not forwarding Ethernet frames. Describe the larger goal as interconnected networks/routing, since a single local ping already meets the introduction's current loose definition of “done.” Verify or remove the “300 feet” standards claim. |
| Presentation | Fix the `10.0.0.2` typo in the e2e outcome, missing fence around the ARP/ping excerpt, stale opening status, and remaining TK/NEED placeholders. The commented tshark `-td` examples use different timing semantics from tsharkie's relative-time column. |

Ready to publish means a complete standalone story, correct working commands,
identified evidence, working public links, and no unresolved claim presented
as fact. An honestly bounded unknown is acceptable; not every side question
needs another experiment. Preview the Markdown and check selected packet
references after editing. Retest hardware only where the corrected runnable
path still lacks evidence; do not rerun the whole lab merely to polish prose.

## Video preparation work

Use the corrected diary as source material. Do not read its entire transcript
or every capture table to camera. [beats.md](beats.md) remains the beat-ID map;
some candidate-only status text predates the successful walkthrough and needs
reconciliation before filming.

| Step | Concrete output | Ready when |
| --- | --- | --- |
| Shape the journey | Updated B01→B02→B03→B04→B05 first success→B07→B05 final assembly→B06 outline | Each beat has one question, a visible result, and a reason to continue. Keep switch retries and the two-client detour optional; don't reenact either as a first-time surprise. |
| Choose what viewers must see | Evidence/shot list covering bench topology, server config/address/logs, one complete DORA, option 50, client addresses, and Ethernet ping | Each claim names a capture point and supporting field. Use final e2e evidence for the payoff. |
| Decide the OLED requirements | Small display spec based on actual filming gaps | Determine whether stock address display plus readable packet rows is sufficient. If DORA stages need OLEDs, evaluate image-dhcp-role against that need; don't let its existing features set the episode scope. Label any replay or deliberately paced visualization. |
| Prepare short explainers | Entry, explanation, specific on-screen field, exit for switch vs DHCP, server identity, DORA, preferences, and payoff | Commands and claims are already settled. Backend selection is preparation so the filmed client remains NM-managed throughout. |
| Rehearse the filming state | Runbook for initial assignment and preference passes, captures, and reset between takes | Account for client leases, server leases, temporary server address, switch management state, capture startup, and actual OLED readability. One completed e2e assembly is evidence, not proof of every repeatable reset. |
| Review reusable footage, then film | Auditioned old-cut selects plus new bench/screen/pickup coverage | Start with C01 build close-ups, C02/C04 third-Pi reveal/build, and C05 success-to-preference story function. [Old-cut review](old-cut-review.md) still needs continuous playback/listening; no candidate is approved yet. |

Approximate runtime and the final teaser remain choices for the outline pass.
They need not delay diary publication. No new script, OLED implementation,
hardware reset, video render, or Resolve edit was performed in this planning
checkpoint.

## Next conversation

Finish the diary's accuracy/readability pass against the new-image baseline.
Replace manual backend/tool setup with a concise baseline note when the image
is ready. Build, boot-test, and release that image before diary publication.
Then expand the corrected journey into video scripts and display requirements.
