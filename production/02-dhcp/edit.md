# Edit state and next session

Stage: preproduction scaffold. No footage reviewed, selected, or edited here.

## Next useful task

Review the gaps Joel identified in `cut-for-ryan.mp4`, populate the gap audit in
research.md, and refine B01–B03 with him. Resolve the episode scope before
writing all the explainers. Start with brief.md and beats.md.

## Confirmed decisions

- Preserve the organic vlog style and plan the learning journey before filming.
- Interlace scripted explainers, including natural entry and exit sentences.
- Check essential coverage at the bench and again before editing for polish.
- Track production notes on this branch. Keep the original worktree intact.
- Use stable beat IDs to connect plans, source footage, and edit decisions.

## Media and Resolve state

| Item | Current value |
| --- | --- |
| Stable original-media root | TBD |
| Separate media backup location | TBD |
| Old cut | `cut-for-ryan.mp4` in the original worktree; unreviewed here |
| Resolve project/library | Uninspected; record exact identity before editing |
| Current working timeline | Unset |
| Last recoverable timeline version | None created by this workflow |
| Last Resolve project export and backup | None created by this workflow |
| Last successful production-branch push | None during scaffolding; local only |

The original worktree is at:
`/Users/joelhans/orca/workspaces/little-internet/oled-lesson-01-beyond`.
This local path locates the existing cut; it is not a portable media archive.

## Indexing footage

Add one selection per row in footage.csv. `source_file` is relative to the
stable media root. Use either source timecode (`HH:MM:SS:FF`, with the actual
frame rate and drop/non-drop basis) or elapsed seconds from file start, and
name that basis explicitly. `source_in` is inclusive; `source_out` is exclusive.
Do not substitute edited-timeline timecodes for source positions.

Roles: journey, explainer, evidence, transition, b-roll, audio.
Review status: unreviewed, usable, unclear, rejected.
Leave unknown fields empty; do not create dummy selections to fill the table.

## Coverage audit before assembly

| Beat | Coverage | Missing / weak material | Best source selection |
| --- | --- | --- | --- |
| B01 | Unknown | Await footage review | |
| B02 | Unknown | Await footage review | |
| B03 | Unknown | Await footage review | |
| B04 | Unknown | Await footage review | |
| B05 | Unknown | Await footage review | |
| B06 | Unknown | Await footage review | |

Use covered, unclear, missing, or intentionally omitted after inspecting the
picture and audio. A plan or transcript does not establish usable coverage.

## Editing loop

1. Inspect and record the current Resolve project and timeline.
2. Preserve a recoverable timeline version before making an edit pass.
3. Work from actual selections and the current beat order.
4. Review the changed sequence for sound, readability, and explanatory continuity.
5. Record decisions, the resulting timeline/version, and the next task here.

| Date / pass | Beat | Decision and reason | Source or timeline reference |
| --- | --- | --- | --- |

## Handoff checklist

- Current stage and next task updated.
- Essential gaps named; unresolved claims remain in research.md.
- Media root, source selections, and actual Resolve identity recorded when known.
- Important reactions or detours to preserve listed in the decision log.
- Notes committed; remote backup status stated accurately.
