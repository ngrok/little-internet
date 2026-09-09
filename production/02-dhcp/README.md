# Episode 02: DHCP production workspace

Start with [brief.md](brief.md), then shape [beats.md](beats.md). This is a
working production archive for a re-recording and a trial of a repeatable video
workflow. The outline is a proposal; the research and scripts are unfinished.

## Files

| File | Purpose |
| --- | --- |
| [brief.md](brief.md) | Audience, promise, scope, and creative decisions |
| [research.md](research.md) | Questions, sources, claims, and unresolved gaps |
| [beats.md](beats.md) | Recording journey, explainer slots, and coverage checks |
| [footage.csv](footage.csv) | Actual source selections connected to beat IDs |
| [edit.md](edit.md) | Edit decisions, missing coverage, Resolve state, and handoff |
| [references/README.md](references/README.md) | Provenance of the previous diary and captures |
| exports/ | Ignored local review renders and Resolve project exports |

## Working loop

1. Use the old cut to name the missing explanations and transitions. Record
   those gaps in research.md; do not assume the diary identifies all of them.
2. Research the essential questions, then write short explainers inside their
   beats, including the sentences entering and leaving them.
3. Record the journey with room for detours. Before leaving the bench, play
   back the crucial takes and check explanation, evidence, and transition.
4. Index actual footage in footage.csv and audit coverage before polishing.
5. Edit in Resolve, carrying decisions and current project/timeline identity
   forward in edit.md so another session can resume.

## Versioning and storage

Track these notes and small evidence files on `joelhans/production-02-dhcp`.
Commit useful checkpoints and push the branch regularly for remote backup.
A local commit alone is not an off-machine backup. This scaffold has not been
pushed. Record a remote backup checkpoint in edit.md after one succeeds.

Keep original video/audio in stable, separately backed-up storage. Record the
media root in edit.md; paths in footage.csv are relative to that root. Local
media, proxies, transcripts, caches, renders, and Resolve exports are ignored
here. Put durable transcript excerpts and editorial decisions in the notes.
Git does not save Resolve's live project database: export project checkpoints
and back those up separately. A worktree does not isolate Resolve state.

The original `oled-lesson-01-beyond` worktree remains the archive of the existing
edit and a possible source for the eventual public PR. This production branch
starts independently at `origin/main` (`b93b570`). Bring only the intended
public content to a publication branch when ready; keep this production branch.

Numbering differs: this base uses `diaries/00_two-pis-one-cable.md` and
`lessons/00/`; the source worktree uses `01` for that lesson and `02` for DHCP.
`02-dhcp` is the requested production ID, not a repository renumbering.

## Agent handoff prompt

> Read production/02-dhcp/README.md, brief.md, research.md, beats.md, and edit.md.
> Help me develop the DHCP re-recording one beat at a time. Keep my delivery
> organic, write precise explainers where needed, and connect each essential
> claim to evidence we can show. Begin with the next task recorded in edit.md.
