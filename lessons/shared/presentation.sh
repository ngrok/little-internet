#!/usr/bin/env bash
# Both lessons use the same visual roles and checkpoint behavior.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _B=$'\033[1m'; _C=$'\033[36m'; _M=$'\033[35m'; _Y=$'\033[93m'
  _W=$'\033[38;2;255;255;255m'; _G=$'\033[90m'; _X=$'\033[0m'
else
  _B=; _C=; _M=; _Y=; _W=; _G=; _X=
fi

say() { printf '\n%s%s%s\n' "$_W" "$*" "$_X"; }
h() { printf '\n%s%s▸ %s%s\n' "$_B" "$_C" "$*" "$_X"; }
# Accept either a quoted argument or a heredoc, for both lessons' prose.
note() { if [ "$#" -gt 0 ]; then say "$*"; else say "$(cat)"; fi; }
eye() {
  local explanation
  if [ "$#" -gt 0 ]; then explanation="$*"; else explanation=$(cat); fi
  printf '\n%swhat just happened%s\n%s%s%s\n' "$_B$_W" "$_X" "$_W" "$explanation" "$_X"
}
phase_banner() {
  local rule='================================================================'
  printf '\n\n%s%s%s\n  %s\n%s%s\n' "$_B" "$_M" "$rule" "$*" "$rule" "$_X"
}
pause() {
  printf '\n%s%s%s\n' "$_B$_Y" "$*" "$_X"
  if [ -t 0 ] && [ "${LESSON_AUTO:-0}" != 1 ]; then
    read -r -p '[press Enter] ' _
  fi
}
review() {
  pause "$1"$'\nThink it through, then press Enter to reveal the answer.'
  note "$2"
  pause 'Ready to leave this phase?'
  printf '\n%s%sPhase %s complete.%s\n' "$_B" "$_M" "${PHASE_TITLE%% — *}" "$_X"
}
terminal_output() {
  local status
  printf '%s' "$_G"
  if "$@"; then status=0; else status=$?; fi
  printf '%s' "$_X"
  return "$status"
}
# Load a phase before it pauses, so edits cannot shift Bash's read offset.
run_script() {
  local script="$1" body
  shift
  body=$(cat "$script") || return $?
  bash -c "$body" "$script" "$@"
}
# Preserve every decoded row. An optional header function repeats on each page.
page_rows() {
  local file="$1" header="${2:-}" total first=1 last
  total=$(awk 'END {print NR}' "$file")
  if [ "$total" -eq 0 ]; then
    note '(No packets matched this filter.)'
    return
  fi
  while [ "$first" -le "$total" ]; do
    last=$((first + 7))
    [ "$last" -le "$total" ] || last="$total"
    if [ -n "$header" ]; then terminal_output "$header"; fi
    terminal_output sed -n "${first},${last}p" "$file"
    if [ "$last" -lt "$total" ]; then
      pause "Rows ${first}–${last} of $total. Inspect these before the next page."
    fi
    first=$((last + 1))
  done
}
