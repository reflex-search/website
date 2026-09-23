#!/usr/bin/env bash
# Records public/casts/demo-regex-ast.cast (94x30)
source "$(dirname "$0")/lib.sh"

title "rfx — Regex & AST Search" "Pattern matching from simple regex to tree-sitter AST queries"

comment "Regex search — find patterns with wildcards"
type_cmd 'rfx query "fn (get|set)_\w+" --regex --lang rust --limit 8' 5

comment "Find all pub fn declarations with regex"
type_cmd 'rfx query "pub fn \w+\(" --regex --lang rust --limit 8' 5

comment "Find format! and write! macro invocations"
type_cmd 'rfx query "(format|write)!\(" --regex --lang rust --limit 8' 5

comment "Find all .expect() calls — potential panic points"
type_cmd 'rfx query "\.expect\(" --regex --lang rust --limit 8' 5

comment "Count how many .unwrap() vs .expect() calls exist"
type_cmd 'rfx query "\.unwrap\(\)" --regex --lang rust --count' 2
type_cmd 'rfx query "\.expect\(" --regex --lang rust --count' 4

comment "Case-insensitive regex still uses the index (new in 2.0)"
type_cmd 'rfx query "(?i)symbolkind" --regex --lang rust --count' 4

comment "AST search — structural code matching with tree-sitter"
type_cmd 'rfx query "(function_item) @fn" --ast --lang rust --glob "src/main.rs" --limit 5' 5

comment "AST: Find all struct definitions"
type_cmd 'rfx query "(struct_item) @s" --ast --lang rust --glob "src/query/mod.rs"' 6

footer "Regex extracts trigrams for speed; AST uses tree-sitter for structure"
