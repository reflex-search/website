#!/usr/bin/env bash
# Records public/casts/rfx-query-demo.cast (94x30)
source "$(dirname "$0")/lib.sh"

title "rfx — Fast, local code search for AI agents" "Trigram-indexed full-text search across any codebase"

# 0. Indexing
comment "Index the codebase — code, docs, and config files"
type_cmd 'rfx index' 5

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
type_cmd 'rfx deps src/query/mod.rs' 5

printf '\n\033[1;33m  ✓ All queries ran against the Reflex codebase (~300 files)\033[0m\n'
printf '\033[0;37m  Install: cargo install reflex-search\033[0m\n\n'
sleep 4
