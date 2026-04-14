---
title: Symbol Search
description: Filter search results to symbol definitions using Tree-sitter parsing.
---

Symbol search combines Reflex's full-text trigram search with runtime Tree-sitter parsing to filter results down to **symbol definitions** — functions, classes, structs, interfaces, and more.

## How it works

Reflex uses a two-phase approach:

1. **Trigram search** finds all files containing the query text (fast, milliseconds)
2. **Tree-sitter parsing** runs on each candidate file to identify symbol definitions (lazy, on-demand)

This "runtime symbol detection" architecture means indexing is instant (no parsing during `rfx index`) while symbol searches are still fast because trigrams narrow the search space first.

## Basic symbol search

Add `--symbols` (or `-s`) to any query:

```bash
rfx query "authenticate" --symbols
```

```
src/auth/mod.rs:42  [Function] pub fn authenticate(creds: &Credentials) -> Result<Session>
1 result in 4ms
```

Without `--symbols`, this query would also find calls, comments, and string literals containing "authenticate". With it, only definitions appear.

## Filter by symbol kind

Use `--kind` to restrict to a specific symbol type:

```bash
# Only functions
rfx query "handle" --symbols --kind function

# Only structs
rfx query "Config" --symbols --kind struct

# Only interfaces (TypeScript, Go)
rfx query "Repository" --symbols --kind interface
```

### Available symbol kinds

| Kind | Description |
|------|-------------|
| `function` | Functions, methods |
| `class` | Classes |
| `struct` | Structs (Rust, Go, C) |
| `enum` | Enums |
| `trait` | Traits (Rust) |
| `interface` | Interfaces (TypeScript, Go, Java) |
| `type` | Type aliases |
| `constant` | Constants |
| `variable` | Variables, let bindings |
| `method` | Methods (when distinguishable from functions) |

Symbol kinds vary by language — see [Supported Languages](/reference/supported-languages/) for what each language extracts.

## Combine with other filters

Symbol search composes with all other query filters:

```bash
# Symbols in a specific language
rfx query "parse" --symbols --lang rust

# Symbols matching a path pattern
rfx query "Handler" --symbols --paths "src/api/"

# JSON output for tooling
rfx query "Config" --symbols --kind struct --json
```

## Performance

Symbol search adds Tree-sitter parsing to the query pipeline, but this only runs on files that pass the trigram filter. Typical overhead is 1–5ms on top of the base query time.

On large codebases, symbol search is often *faster* in practice because it returns fewer results, reducing output formatting time.

## Next steps

- [Regex & AST Patterns](/guides/regex-ast/) — structural code pattern matching
- [Supported Languages](/reference/supported-languages/) — symbol types by language
- [CLI Commands](/reference/cli-commands/) — full `rfx query` reference
