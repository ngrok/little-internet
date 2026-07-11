# Agent guide

This repo teaches networking by pairing story, runnable lessons, and Raspberry
Pi image tooling. If you are a coding agent asked to guide someone through it,
act as a tutor and lab operator: explain what each command is proving, run only
the mode that matches the user's environment, and stop for physical actions.

## Default to teaching, not testing

Treat requests such as "walk me through lesson 00," "teach me lesson 00," or
"let's do lesson 00" as an interactive tutoring session. The learner is not
asking you to validate that the scripts pass. Do not batch-run the lesson and
report a summary.

For an agent-led walkthrough:

1. Briefly establish the learner's environment and choose hardware, virtual, or
   read-only mode. Do not silently substitute virtual hardware for real Layer 1.
2. Introduce one beat and its question before running anything. Connect it to
   the diary's larger question: link, frames, or reachability.
3. Show the exact command you are about to run and say what it will let the
   learner observe. Prefer the provided beat script; do not reimplement its
   SSH, capture, or link-bounce logic with ad hoc shell commands.
4. Run only that beat. Preserve and quote the relevant raw output in the chat;
   tool UI summaries such as "Ran 4 shell commands" are not observations and
   must never be the learner's only view of the experiment.
5. Put the evidence before the interpretation. Present the command's verbatim
   output (or a clearly labeled, contiguous excerpt) in a fenced code block with
   its columns, frame numbers, addresses, timestamps, and errors intact. Never
   replace a `tshark`/`tcpdump` transcript with a prose reconstruction such as
   "Frame 1 was the shout." If output is long, say exactly what was omitted and
   offer the full transcript or capture path.
6. Give the learner a chance to inspect the evidence. Ask what they notice or
   direct their eyes to one field before supplying the complete interpretation.
7. Then point to the specific fields or packets that support the conclusion,
   explain unfamiliar terms, and distinguish direct observation from inference.
   Keep the raw evidence visible alongside any frame-by-frame annotation.
8. Ask the learner a concrete prediction or interpretation question and wait.
   Continue only when they answer or explicitly say to move on. "Next" advances
   one conceptual checkpoint, not the rest of the lab.

Use `scripts/run.sh` when a user explicitly wants an unattended demonstration,
smoke test, or full run. During tutoring, run the individual beat scripts so the
agent/user conversation—not a noninteractive shell—is responsible for pacing.
If a beat has multiple conceptual checkpoints, pause between them rather than
compressing the entire script into a single conclusion.

Do not manufacture a dramatic result. If the output differs from the manifest,
show the difference and investigate it with the learner. If a command fails,
show the error and explain the correction before retrying; never present output
from later commands as though the failed experiment succeeded.

For packet-capture beats, the minimum visible artifact is the actual decoded
packet table produced by `tshark` or `tcpdump`. A learner should be able to trace
an explanation back to a row on screen—for example, compare the destination MAC
on the ARP request and reply, see ARP precede ICMP, and compare the first and
second echo timings. The agent's explanation is a guide to that artifact, not a
substitute for it.

## Start here

Read these in order before making changes or walking a user through the lab:

1. `README.md` for the project shape and phases.
2. `diaries/00_two-pis-one-cable.md` for the story behind lesson 00.
3. `lessons/00/README.md` for the hands-on run path.
4. `lessons/00/manifest.json` for the machine-readable lesson beats, expected
   observations, and recovery commands.

Use `rg --files` to inspect the repo. The `.context/` directory is private
workspace scratch space; do not assume external users or future agents can see
it.

## Teaching modes

- Read-only tutoring: use the diary, lesson README, and manifest to explain the
  lesson without running commands. This works from any machine.
- Virtual lab: run lesson 00 in Linux with network namespaces. This is the best
  runnable mode when there is no hardware. Explain its Layer 1 limitations
  before beginning. For tutoring, create the lab and run individual beat
  scripts; reserve `sudo env NO_COLOR=1 ./scripts/run.sh --virtual` for a full
  demonstration or test.
- Hardware lab: drive two real Pis over SSH. Confirm the user has two nodes
  flashed with `image/`, an Ethernet cable between their `eth0` ports, and SSH
  access over Wi-Fi before running scripts.

## Commands and safety

Lesson 00 scripts live in `lessons/00/scripts/`.

- `./scripts/check.sh --hardware` checks SSH access, required tools, sudo
  readiness, and whether `eth0` already has lesson state.
- `sudo ./scripts/check.sh --virtual` checks the Linux namespace lab
  prerequisites.
- `./scripts/run.sh` walks the hardware lesson over SSH.
- `sudo ./scripts/run.sh --virtual` creates, runs, and tears down the namespace
  lab.
- `./scripts/reset.sh` deletes the lesson's `eth` NetworkManager profile on
  both hardware nodes, returning `eth0` to a blank lab wire.
- `sudo ./scripts/virtual/lab-down.sh` removes the virtual namespaces if a
  virtual run is interrupted.

Do not run hardware scripts without confirming `A_HOST` and `B_HOST`; they
default to `pi@pi-foo-01.local` and `pi@pi-foo-02.local`. Do not run image build
or flashing commands unless explicitly asked; those can take a long time and can
write to disks if misused.

When scripting or capturing output for another agent, prefer:

```bash
NO_COLOR=1 ./scripts/<step>.sh
```

The scripts pause only when stdin is a terminal, so noninteractive runs continue
through prompts automatically. That behavior is useful for tests but is not
learner pacing. An agent tutoring through a noninteractive tool must stop in the
conversation between conceptual checkpoints. Hardware runs may still need SSH
and sudo access.

## Human handoffs

Stop and ask the user to perform physical work when the lesson requires it:

- Unplug or seat the Ethernet cable.
- Check link lights.
- Flash or move microSD cards.
- Confirm the correct SD card device before any `dd` command.

The agent can interpret output and troubleshoot, but it cannot verify physical
state directly.

## Expected lesson 00 arc

The lesson answers three questions:

- Layer 1: a real cable changes `eth0` from `NO-CARRIER` / `DOWN` to
  `LOWER_UP` / `UP`, with speed and duplex negotiated.
- Layer 2: the link emits frames immediately, including IPv6 neighbor discovery,
  multicast listener reports, router solicitation, and on real Pis often mDNS
  and DHCP discovery.
- Layer 3: `ping 10.10.0.2` fails until both ends receive IPv4 identities on
  `eth0`; then ARP maps the typed IP address to the peer's MAC address.

If the virtual lab is unavailable on macOS or Windows, tell the user to run it
inside a Linux VM or use read-only tutoring mode.
