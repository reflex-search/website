#!/usr/bin/env bash
# Records public/casts/demo-fulltext.cast (94x30)
source "$(dirname "$0")/lib.sh"

title "rfx — Full-Text Trigram Search" "Find every occurrence of a pattern across your codebase"

comment "Simple text search — finds all occurrences, not just definitions"
type_cmd 'rfx query "trigram"' 4

comment "Substring search — find partial matches with --contains"
type_cmd 'rfx query "trigram" --contains --limit 5' 5

comment "Case-insensitive search with -i"
type_cmd 'rfx query "TRIGRAM" -i --lang rust --count' 4

comment "Filter by language — only search Rust files"
type_cmd 'rfx query "unwrap()" --lang rust --limit 8' 5

comment "Filter by file path with glob patterns"
type_cmd 'rfx query "fn new" --glob "src/*.rs" --limit 8' 5

comment "Exclude test files from results"
type_cmd 'rfx query "assert" --lang rust --exclude "tests/**" --limit 5' 5

comment "Docs and config are indexed too — search them with --lang text"
type_cmd 'rfx query "trigram" --lang text --limit 3' 5

comment "Count total occurrences across the codebase"
type_cmd 'rfx query "Result" --lang rust --count' 3

comment "Count occurrences of error handling patterns"
type_cmd 'rfx query "unwrap()" --lang rust --count' 4

comment "See where the time goes with --timing"
type_cmd 'rfx query "extract_trigrams" --timing --limit 1' 5

comment "JSON output — structured results for AI agents & scripts"
type_cmd 'rfx query "extract_trigrams" --json --limit 3' 6

footer "Trigram search: answers straight from the index, in milliseconds"
