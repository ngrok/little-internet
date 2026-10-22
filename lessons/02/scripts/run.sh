#!/usr/bin/env bash
# Recommended terminal walkthrough; --auto skips learner pacing.
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
START_PHASE=01
while [ "$#" -gt 0 ]; do
  case "$1" in
    --auto) export LESSON_AUTO=1; shift;;
    --from)
      case "${2:-}" in
        [1-7]|0[1-7]) printf -v START_PHASE '%02d' "$2"; shift 2;;
        *) echo 'usage: run.sh [--auto] [--from 01..07]' >&2; exit 2;;
      esac;;
    *) echo 'usage: run.sh [--auto] [--from 01..07] (start the VM lab first)' >&2; exit 2;;
  esac
done
"$SCRIPTS/check.sh"
source "$SCRIPTS/lib.sh"
export LESSON_RUNNER=1
export LESSON_RUN_INDEX="$LAB_HOME/transcripts/run-$RUN_ID.txt"
mkdir -p "$LAB_HOME/transcripts"
printf 'Lesson 02 evidence from this run\n' > "$LESSON_RUN_INDEX"
trap 'note "Captures and setup transcripts for this run: $LESSON_RUN_INDEX"' EXIT
if [ "$START_PHASE" = 01 ]; then
  prepare_start
else
  note "Resuming at phase $START_PHASE with the current lab state."
fi
for step in 01-switch 02-manual 03-server 04-dora 05-ping 06-preference 07-reconnect; do
  [ "${step%%-*}" -ge "$START_PHASE" ] || continue
  run_script "$SCRIPTS/$step.sh"
done
