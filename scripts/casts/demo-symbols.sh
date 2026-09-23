#!/usr/bin/env bash
# Records public/casts/demo-symbols.cast (94x30)
source "$(dirname "$0")/lib.sh"

title "rfx — Symbol Search" "Find definitions: functions, structs, enums, traits, and more"

comment "Find symbol definitions — only where symbols are declared"
type_cmd 'rfx query "Config" --symbols' 5

comment "Filter by symbol kind — find only functions"
type_cmd 'rfx query "parse" --symbols --kind function --limit 10' 5

comment "Find struct definitions whose name contains \"Result\""
type_cmd 'rfx query "Result" --symbols --kind struct --contains' 5

comment "Find enum definitions"
type_cmd 'rfx query "SymbolKind" --symbols --kind enum' 5

comment "Find trait definitions"
type_cmd 'rfx query "trait" --symbols --kind trait' 5

comment "--kind implies --symbols"
type_cmd 'rfx query "Config" --kind struct' 5

comment "Combine symbol search with language filter"
type_cmd 'rfx query "new" --symbols --kind function --lang rust --limit 10' 5

comment "Symbol search with JSON output — includes kind and line info"
type_cmd 'rfx query "extract" --symbols --json --limit 5' 6

footer "Symbol search: served from a symbol cache built in the background"
