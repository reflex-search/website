#!/usr/bin/env bash
# Records public/casts/demo-deps.cast (94x30)
source "$(dirname "$0")/lib.sh"

title "rfx — Dependency Analysis" "Understand how files in your codebase are connected"

comment "Show what a file imports (forward dependencies)"
type_cmd 'rfx deps src/indexer.rs' 5

comment "Show what a specific module depends on"
type_cmd 'rfx deps src/query/mod.rs' 5

comment "Same data as a table — with the import type of each line"
type_cmd 'rfx deps src/query/mod.rs --format table' 5

comment "Reverse dependencies — what files import this models module?"
type_cmd 'rfx deps src/models.rs --reverse' 5

comment "Transitive dependencies — follow the chain 2 levels deep"
type_cmd 'rfx deps src/query/mod.rs --depth 2' 5

comment "Find circular dependencies in the codebase"
type_cmd 'rfx analyze --circular' 5

comment "Find the most-imported files (dependency hotspots)"
type_cmd 'rfx analyze --hotspots' 5

comment "Find orphaned files that nothing imports"
type_cmd 'rfx analyze --unused' 5

comment "Full dependency analysis summary"
type_cmd 'rfx analyze' 6

footer "Dependency analysis: understand your codebase structure at a glance"
