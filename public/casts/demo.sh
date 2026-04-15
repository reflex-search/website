#!/usr/bin/env bash
# Demo script for rfx query — recorded with asciinema
set -e

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
  eval "$cmd"
  sleep "$pause"
}

comment() {
  printf '\n\033[1;36m# %s\033[0m\n' "$1"
  sleep 2
}

clear
printf '\033[1;33m  rfx — Fast, local code search for AI agents\033[0m\n'
printf '\033[0;37m  Trigram-indexed full-text search across any codebase\033[0m\n'
sleep 3

# 1. Basic full-text search
comment "Full-text search — find every occurrence of a pattern"
type_cmd 'rfx query "trigram" --limit 5' 5

# 2. Symbol definitions only
comment "Symbol search — find only definitions, not usages"
type_cmd 'rfx query "extract_symbols" --symbols --limit 5' 5

# 3. Language filtering
comment "Filter by language"
type_cmd 'rfx query "unwrap" --lang rust --limit 5' 5

# 4. Glob filtering
comment "Filter by file path with glob patterns"
type_cmd 'rfx query "fn parse" --glob "src/parsers/*.rs" --limit 5' 5

# 5. Kind filtering
comment "Filter by symbol kind (function, struct, enum, etc.)"
type_cmd 'rfx query "Config" --symbols --kind struct' 5

# 6. Count occurrences
comment "Count occurrences without showing results"
type_cmd 'rfx query "Result" --lang rust --count' 4

# 7. JSON output for AI agents
comment "JSON output — designed for AI agent consumption"
type_cmd 'rfx query "SymbolKind" --symbols --json --limit 3' 5

# 8. Dependency analysis
comment "Dependency analysis — what does a file import?"
type_cmd 'rfx deps src/query.rs' 5

printf '\n\033[1;33m  ✓ All queries ran against the Reflex codebase (~70 source files)\033[0m\n'
printf '\033[0;37m  Install: cargo install reflex-cli\033[0m\n\n'
sleep 4
