#!/usr/bin/env bash
# Records the live demos (TUIs, rfx ask, Claude Code + MCP) by driving a
# tmux pane that runs `asciinema rec`. Keystrokes are sent with tmux, so the
# recording shows a real session.
#
# Usage: REFLEX_DIR=/path/to/indexed/reflex scripts/casts/record-live.sh <cast>
#   <cast> = query-interactive | ask-interactive | hero
#
# Needs: tmux, asciinema, rfx, an LLM provider in ~/.reflex/config.toml
# (ask-interactive, hero), and the `claude` CLI (hero).

set -euo pipefail

: "${REFLEX_DIR:?Set REFLEX_DIR to a checkout of the reflex repo}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cd "$HERE/../../public/casts" && pwd)"
ASCIINEMA="${ASCIINEMA:-asciinema}"
SOCK=rfxcast

tm() { tmux -L "$SOCK" "$@"; }

start() { # <cast-file> <cols> <rows>
  tm kill-server 2>/dev/null || true
  tm new-session -d -s rec -x "$2" -y "$3" -c "$REFLEX_DIR" \
    "TERM=xterm-256color $ASCIINEMA rec -q -f asciicast-v2 --overwrite -c 'bash --rcfile $HERE/demo-bashrc -i' '$OUT/$1'"
  sleep 1.5
}

screen() { tm capture-pane -p -t rec 2>/dev/null || true; }

# Wait until the visible screen matches an extended regex
wait_for() { # <regex> [timeout-seconds]
  local deadline=$((SECONDS + ${2:-60}))
  until screen | grep -qE "$1"; do
    ((SECONDS < deadline)) || { echo "timeout waiting for: $1" >&2; return 1; }
    sleep 0.3
  done
}

# Wait until no running process matches a pattern
wait_gone() { # <pgrep-pattern> [timeout-seconds]
  local deadline=$((SECONDS + ${2:-120}))
  while pgrep -f "$1" >/dev/null; do
    ((SECONDS < deadline)) || { echo "timeout waiting for exit: $1" >&2; return 1; }
    sleep 0.3
  done
}

type_text() { # <text> [delay-per-char]
  local s="$1" d="${2:-0.05}"
  for ((i = 0; i < ${#s}; i++)); do
    tm send-keys -t rec -l "${s:$i:1}"
    sleep "$d"
  done
}

key() { tm send-keys -t rec "$@"; }

run_cmd() { # <command> — type at the shell prompt and press Enter
  type_text "$1"
  sleep 0.4
  key Enter
}

finish() {
  sleep 1
  type_text "exit"
  key Enter
  while tm has-session -t rec 2>/dev/null; do sleep 0.3; done
  sanitize "$OUT/$CAST"
  echo "wrote $OUT/$CAST"
}

# Drop local details from the cast header (command path, login shell)
# and the exit-status event, so the file matches the scripted casts.
sanitize() { # <cast-file>
  python3 - "$1" "$REFLEX_DIR" <<'PY'
import json, os, re, sys
path, reflex_dir = sys.argv[1], os.path.realpath(sys.argv[2])
lines = open(path).read().splitlines()
header = json.loads(lines[0])
header.pop("command", None)
header["env"] = {"SHELL": "/bin/bash", "TERM": "xterm-256color"}

# Show the checkout as ~/code/reflex (matches the prompt). Claude Code may
# abbreviate the path as "/…/<tail>", so match both forms. Pad with spaces
# to keep the TUI layout intact.
shown = "~/code/reflex"
tail = re.escape(os.path.basename(reflex_dir))
pattern = re.compile(re.escape(reflex_dir) + "|/…/[^\\s\x1b]*" + tail + "(?![\\w/])")
def fix(m):
    s = m.group(0)
    return shown + " " * (len(s) - len(shown)) if len(s) > len(shown) else shown

# Cap idle gaps at 3 s so waits for the LLM don't bloat the timeline
MAX_GAP = 3.0
events, prev, shift = [], 0.0, 0.0
for line in lines[1:]:
    e = json.loads(line)
    if e[1] == "x":
        continue
    shift += max(0.0, e[0] - prev - MAX_GAP)
    prev = e[0]
    e[0] = round(e[0] - shift, 6)
    e[2] = pattern.sub(fix, e[2])
    events.append(json.dumps(e, ensure_ascii=False))
open(path, "w").write("\n".join([json.dumps(header)] + events) + "\n")
PY
}

query_interactive() {
  CAST=rfx-query-interactive.cast
  start "$CAST" 94 33
  run_cmd "rfx query"
  wait_for "Start typing to search"
  sleep 1
  type_text "index" 0.12
  sleep 0.4
  key Enter
  wait_for "Results \([0-9]+\)"
  sleep 2
  key s
  wait_for "\[(Module|Function)\] index"
  sleep 1.5
  for _ in 1 2 3; do key Down; sleep 0.5; done
  sleep 0.5
  key Enter
  sleep 1.5
  for _ in $(seq 8); do key Down; sleep 0.3; done
  for _ in $(seq 4); do key Up; sleep 0.3; done
  sleep 1
  key Escape
  sleep 1.2
  key q
  wait_gone "rfx query$" 10
  finish
}

ask_interactive() {
  CAST=rfx-ask-interactive.cast
  start "$CAST" 104 35
  run_cmd "rfx ask"
  wait_for "Type your question here"
  sleep 1
  type_text "What database does this project use?" 0.06
  sleep 0.5
  key Enter
  sleep 3
  wait_for "Ready" 180
  sleep 6
  key C-c
  wait_gone "rfx ask$" 10
  finish
}

hero() {
  CAST=demo.cast
  # Off camera: start from an empty index so `rfx index` does a full build
  (cd "$REFLEX_DIR" && rfx clear -y >/dev/null)
  start "$CAST" 104 49
  run_cmd "rfx index"
  wait_gone "rfx index$" 120
  sleep 3
  run_cmd 'rfx query --kind function "index"'
  wait_gone "rfx query --kind function" 30
  sleep 3
  run_cmd 'rfx query --kind struct --contains "Cache"'
  wait_gone "rfx query --kind struct" 30
  sleep 3
  run_cmd 'rfx ask "Which files deal with trigram indexing?"'
  wait_gone "rfx ask Which" 180
  sleep 3
  run_cmd "claude"
  wait_for "❯" 60
  sleep 2
  type_text "Give me an architectural overview of this codebase. What are the hottest files, are there any circular dependencies, and how is the project structured?" 0.01
  sleep 0.5
  key Enter
  sleep 5
  # Claude is done when the screen stops changing for 6 s (the spinner
  # animates the whole time it works)
  local quiet=0 last="" now deadline=$((SECONDS + 600))
  while ((quiet < 12 && SECONDS < deadline)); do
    now=$(screen | md5sum)
    if [[ $now == "$last" ]]; then quiet=$((quiet + 1)); else quiet=0; last=$now; fi
    sleep 0.5
  done
  sleep 6
  key C-c
  sleep 0.3
  key C-c
  wait_for "user@name:~/code/reflex\]\\$ *$" 20
  finish
}

case "${1:-}" in
  query-interactive) query_interactive ;;
  ask-interactive) ask_interactive ;;
  hero) hero ;;
  sanitize) sanitize "$2" ;;
  *) echo "usage: $0 query-interactive|ask-interactive|hero|sanitize <cast>" >&2; exit 2 ;;
esac
