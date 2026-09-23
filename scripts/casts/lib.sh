#!/usr/bin/env bash
# Shared helpers for the scripted asciinema demos.
# Each demo script sources this file, then runs inside $REFLEX_DIR
# (a checkout of the reflex repo that has already been indexed).

set -e

: "${REFLEX_DIR:?Set REFLEX_DIR to an indexed checkout of the reflex repo}"
cd "$REFLEX_DIR"

# Typing simulation with realistic pacing
type_cmd() {
  local cmd="$1"
  local pause="${2:-4}"  # seconds to pause after output (default 4)
  printf '\n$ '
  for ((i=0; i<${#cmd}; i++)); do
    printf '%s' "${cmd:$i:1}"
    sleep 0.04
  done
  sleep 0.5
  printf '\n'
  eval "$cmd" || true
  sleep "$pause"
}

comment() {
  printf '\n\033[1;36m# %s\033[0m\n' "$1"
  sleep 2
}

title() {
  clear
  printf '\033[1;33m  %s\033[0m\n' "$1"
  printf '\033[0;37m  %s\033[0m\n' "$2"
  sleep 3
}

footer() {
  printf '\n\033[1;33m  %s\033[0m\n\n' "$1"
  sleep 4
}
