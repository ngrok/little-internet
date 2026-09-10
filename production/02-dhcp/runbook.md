# Fresh-image DHCP walkthrough

Status: Joel reports all three Pis reflashed and back to a basic state. He is
undertaking the fresh build and adding to diary.md; leave his diary edits to
him during concurrent old-cut review. The exact flashed-artifact checksum and
fresh runtime state have not been independently verified here.
[Prior-state investigation](prior-state-runbook.md) remains reference only.

## Starting image

Repository checked on 2026-09-09:

- Latest published image: [v0.5.3](https://github.com/ngrok/little-internet/releases/tag/v0.5.3),
  asset `v0.5.3-little-internet.img.xz`, published 2026-08-07.
- Local release tag resolves to `48e2d21486cbb3fde0880e1d1e21a808c8d68ed9`.
- Remote main is `b93b570e9053b8960b3ad08247672e1cb4f15abd`. Comparing the tag
  with this commit found no differences under `image/` or `tools/`.
- Source provides NetworkManager's `eth-dhcp` autoconnect profile, boot status
  OLED, OLED test tools, and ARP viewer. DHCP-specific viewers from
  image-dhcp-role are not prerequisites. These are source findings; booted
  release behavior still needs observation.

Record the actual downloaded image's checksum and use the same artifact for
all three Pis. Provision pi-foo-01, pi-foo-02, and pi-foo-dhcp plus management
Wi-Fi using the release's image instructions. Flashing/moving cards are physical
handoffs; preserve wanted recordings and custom work before replacing cards.
Old SSH inventories do not describe the freshly booted state.

## Walk the questions, write the diary

Use [beats.md](beats.md) as working questions and [diary.md](diary.md) as the
new observation record. Advance one checkpoint at a time:

1. Verify the fresh image's behavior, Wi-Fi management access, and Ethernet
   topology. Connect the episode's starting state to the previous video;
   record deliberate setup changes before the first beat.
2. Observe what connecting through the switch changes and what remains missing
   before a DHCP service exists. Save actual decoded packet evidence.
3. Give the third Pi the server role step by step, explaining and recording
   each required address, service, and configuration choice.
4. Observe automatic assignment, capture full DORA, and prove client-to-client
   Ethernet communication using the addresses actually received.
5. Investigate .1/.2 preferences as the next experiment. Establish a repeatable
   reset from this documented setup; verify the preferred-address option,
   full exchange, resulting assignment, and communication.

At each checkpoint: state the question and prediction, show the exact command,
perform one action, preserve raw evidence, and pause for interpretation. Write
what happened and what it supports before continuing. Prepare missing commands
from the chosen baseline; reuse existing operations when their assumptions fit.

## Develop the OLEDs alongside the script

Added during the fresh-build workflow: [tsharkie](../../tools/tsharkie/README.md),
installed at `/usr/local/bin/tsharkie` on all three Pis. It wraps the working
live capture/formatter/pager command and accepts a filename plus `-f` capture
filter. This is an explicit addition after flashing, not part of v0.5.3.
Live streaming and saved-packet readback were checked using only pi-foo-01's
loopback interface; see [validation](evidence/2026-09-09-tsharkie.md).

As the diary develops, record what viewers need to see and whether stock
displays and terminal evidence make it readable. Turn demonstrated gaps into
OLED requirements while finalizing the script and preparing to film. Evaluate
image-dhcp-role for reuse then; it may already fit or need changes. Its feature
set does not determine the journey.

Test chosen displays against packet and lease evidence. Record additions so
the filming setup can be recreated from the base image. Explain paced message
reveals if used. Repeat required exchanges and communication with the final
tools before filming. Review the old cut for retained material once the new
journey is grounded in the walkthrough. Final screen order remains open.

## Next checkpoint

### B07 verified: retain NetworkManager ownership

Both Pi 01 and Pi 02 now use NetworkManager-managed dhclient, with full DORA,
the requested-address option, a single eth0 IPv4 address, and NM process
ownership verified. Wi-Fi management remains available and eth-dhcp
autoconnect is restored. See [Pi 02 evidence](evidence/captures/2026-09-09-nm-preference/README.md)
and [Pi 01 evidence](evidence/captures/2026-09-09-pi01-backend/README.md) for
commands, backup locations, captures, and limits. Joel confirmed Pi 02's OLED.

The image source now explicitly installs isc-dhcp-client and installs this
configuration at `/etc/NetworkManager/conf.d/20-little-internet-dhcp-client.conf`:

```ini
[main]
dhcp=dhclient
```

This applies to Wi-Fi as well as Ethernet. NetworkManager remains the manager;
activate the connection with nmcli, without launching a standalone dhclient.
Source installation checks passed; no new image has been built or released.
The published v0.5.3 baseline described above predates this source change.

The per-client preference is separate lesson configuration, absent from the
shared image. Both live clients currently have it enabled in
`/etc/NetworkManager/dhclient-eth0.conf`:

```conf
# Pi 01
send dhcp-requested-address 10.10.0.1;
```

Pi 02 has the corresponding line requesting 10.10.0.2. Keep these directives
out of global `/etc/dhcp/dhclient.conf`, which can also affect Wi-Fi.

### Next rehearsal: first assignment, then preferences

Keep the backend consistent throughout filming; its selection is preparation.
Before rebuilding the first assignment pass, remove/comment the eth0 preference
on both clients, deactivate their Ethernet profiles, and prepare their lease
state deliberately. Saved leases can still request a previous address even
without an explicit preference. Preserve client identifiers and distinguish
client memory from server bindings; inspect the actual capture.

Introduce the preference files in B07, then perform the prepared reset and
capture a new DORA exchange. The verified Pi 01 test retained its existing
server .1 binding, while Pi 02's earlier preference test cleared its server
binding. Those are documented individual tests, not yet one repeatable reset
procedure for both passes. Do not promise that a reconnect alone produces DORA
or that a client request obliges the server to grant it.

Current server .254/24 addressing is temporary; account for it before any
reboot. Rehearse the remaining build and final Ethernet ping one checkpoint
at a time with Joel. No physical reconnection or complete reset was performed
during the Pi 01 migration.

### B04 proposal: test the server's IPv4 configuration last

Joel wants to isolate whether giving the server an IPv4 address enables
assignments. Proposed experimental order, not yet executed:

1. Prepare and syntax-check dnsmasq's lab configuration while the service is
   stopped. Limit DHCP to eth0, choose a valid pool, and enable DHCP logging.
   Installing/starting the package alone does not configure an address pool.
2. Prepare the server's eth0 to remain up without an IPv4 address or its own
   DHCP client. Establish this state before the comparison; do not let the
   server obtain an address during the test. Keep Wi-Fi management available.
3. Start named captures and the service-log view, connect the lab, and verify
   carrier and no server eth0 IPv4 address. Initially test with client 01;
   bring 02 into the successful result afterward to keep the first trace clear.
4. Start the configured service and observe a deliberate client DHCP attempt.
   Preserve Discover arriving at the server, any response, and service logs.
   A lack of Offer is not sufficient by itself to diagnose the cause.
5. Add the chosen server address/prefix, outside the client pool, while keeping
   dnsmasq configuration and cabling fixed. Ensure another client attempt is
   actually observed; NetworkManager retries can time out. Do not quietly mix
   in other changes or assume that a request was sent.
6. If service startup failed without the address, or a restart is necessary,
   record it and use the same start/restart procedure in both comparison cases.
   Successful acquisition after an address change plus restart does not isolate
   the address change alone. Verify DHCP exchange, client address, server lease,
   and ultimately client-to-client Ethernet ping.

This investigates the new configuration, not the unproven cause of the old
cut's success. Exact commands and runtime state still need checking at each
checkpoint. The server address/prefix supplies local subnet information as
well as an address; avoid reducing the explanation to the server needing a
name. See dnsmasq --dhcp-range and research.md G03.

Record the fresh starting state and continue one build checkpoint at a time
with Joel. Reflashing is reported complete; do not instruct him to repeat it.
The assistant is reviewing old-cut candidates while Joel writes the diary.
Further diagnosis of the pre-reflash clients is not a prerequisite.
