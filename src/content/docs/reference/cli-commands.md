---
title: CLI Commands
description: Complete reference for every rfx command, subcommand, and flag.
---

## Global options

These work with every command.

| Flag | Short | Description |
|------|-------|-------------|
| `--verbose` | `-v` | Enable verbose logging. Repeat for more detail (`-vv`, `-vvv`) |
| `--help` | `-h` | Print help (`-h` for a summary, `--help` for the full text) |
| `--version` | `-V` | Print version |

---

## `rfx index`

Build or update the local code index.

```bash
rfx index [OPTIONS] [PATH] [COMMAND]
```

| Argument | Description |
|----------|-------------|
| `[PATH]` | Directory to index (default: `.`) |

| Flag | Short | Description |
|------|-------|-------------|
| `--force` | `-f` | Force a full rebuild. Deletes `.reflex/` first, including `config.toml` |
| `--languages <LANGS>` | `-l` | Languages to include, comma-separated (empty = all) |
| `--quiet` | `-q` | Suppress all output (no progress bar, no summary) |

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `status` | Show background symbol indexing status |
| `compact` | Compact the cache by removing deleted files |

`rfx index compact` removes files that no longer exist on disk from the cache and reclaims space with SQLite `VACUUM`. It also runs automatically in the background every 24 hours. It accepts `--json` and `--pretty`.

```bash
# Index the current directory
rfx index

# Full rebuild, Rust and Python only
rfx index --force --languages rust,python

# Is the background symbol pass finished?
rfx index status

# Reclaim space from deleted files
rfx index compact --json
```

Indexing is **incremental** by default: unchanged files are skipped, and only new or modified files are reprocessed. After indexing, `rfx index` starts a background pass that parses every file once and caches its symbols; `rfx index status` reports its progress:

```
Background Symbol Indexing Status
==================================
State:           Completed
Total files:     298
Processed:       298
Cached:          0
Parsed:          230
Failed:          0
```

Plain `rfx index` picks up changes to `.reflex/config.toml`; you don't need `--force` for that. Use `--force` when troubleshooting or when upgrading.

:::caution
`--force` deletes the whole `.reflex/` directory before rebuilding, **including `.reflex/config.toml`**, which comes back with default settings. Back up your config first if you have customized it.
:::

**Upgrading to 2.0:** an index written by rfx 1.7.2 or later is refused with a "written by a different version" error. Run `rfx index --force` once to rebuild it (or set `REFLEX_ALLOW_SCHEMA_REBUILD=1`). Indexes from before 1.7.2 are adopted and rebuilt in full by a plain `rfx index`.

---

## `rfx query`

Search the codebase. With no pattern, launches interactive TUI mode.

```bash
rfx query [OPTIONS] [PATTERN]
```

By default a plain pattern matches **whole identifiers**: `Error` finds `Error` but not `NetworkError`. Use `--contains` for substring matching, `--regex` for regular expressions, or `-i` to ignore case.

### Pattern and match mode

| Flag | Short | Description |
|------|-------|-------------|
| `--pattern <PATTERN>` | | The search pattern as a named flag, for patterns that start with `-` (e.g. `--pattern '-> Result<'`). Conflicts with the positional pattern |
| `--symbols` | `-s` | Search symbol definitions only (functions, classes, etc.) |
| `--kind <KIND>` | `-k` | Filter by symbol kind (implies `--symbols`) |
| `--regex` | `-r` | Use regex pattern matching. Cannot be combined with `--contains` |
| `--ast` | | Treat the pattern as a Tree-sitter S-expression query. Slow (scans all files); needs `--glob` or `--force` |
| `--contains` | | Substring matching for both text and symbols. Cannot be combined with `--regex` or `--exact` |
| `--exact` | | Exact symbol name match (symbol searches only) |
| `--ignore-case` | `-i` | Match letters regardless of case (like `rg -i`). Works with the default search, `--contains`, and `--regex` |

Supported `--kind` values: `function`, `class`, `struct`, `enum`, `interface`, `trait`, `constant`, `variable`, `method`, `module`, `namespace`, `type`, `macro`, `property`, `event`, `import`, `export`, `attribute`.

### Filters

| Flag | Short | Description |
|------|-------|-------------|
| `--lang <LANG>` | `-l` | Filter by language (see below) |
| `--file <FILE>` | `-f` | Filter by file path substring (e.g. `--file math.rs`, `--file helpers/`) |
| `--glob <GLOB>` | `-g` | Include files matching a glob. Repeatable |
| `--exclude <GLOB>` | `-x` | Exclude files matching a glob. Repeatable |
| `--include-locks` | | Also search lock files (`Cargo.lock`, `package-lock.json`, `*.lock`, `go.sum`) |
| `--include-generated` | | Also search generated files (`*.pb.go`, `*.min.js`, `*.map`, `*_generated.*`) |

`--lang` accepts `rust` (`rs`), `python` (`py`), `javascript` (`js`), `typescript` (`ts`), `vue`, `svelte`, `go`, `java`, `php`, `c`, `cpp` (`c++`), `csharp` (`cs`, `c#`), `ruby` (`rb`), `kotlin` (`kt`), `zig`, plus the non-code tiers `text` (`txt`), `lock`, and `generated` (`gen`). Markdown, YAML, and other docs and config files are searched with `--lang text`. Lock and generated files are indexed but left out of every search unless you pass `--include-locks` / `--include-generated`, or select them alone with `--lang lock` / `--lang generated`.

Globs follow **gitignore rules**, like `rg -g`:
- A pattern containing `/` is anchored at the index root: `src/**/*.rs` matches only under the top-level `src/`
- A bare name (`*.rs`, `Makefile`) matches at any depth
- `**` matches across directories; `*` never crosses `/`, so `src/*.rs` means files directly in `src/`
- Use `**/src/**/*.rs` to match any `src/` directory

### Output

| Flag | Short | Description |
|------|-------|-------------|
| `--json` | | Output as JSON |
| `--pretty` | | Pretty-print JSON (only with `--json`; minified by default) |
| `--ai` | | AI-optimized JSON with an `ai_instruction` field. Implies `--json` |
| `--plain` | | Plain text output (no colors or syntax highlighting) |
| `--count` | `-c` | Only show the count and timing, not the results |
| `--paths` | `-p` | Return only unique file paths (no line numbers or content). With `--json`, outputs `["path1", "path2", ...]` |
| `--expand` | | Show the full symbol definition (symbol searches only) |
| `--context <N>` | `-C` | Show N lines before and after each match (max 10) |
| `--no-truncate` | | Show full lines instead of previews truncated to ~100 characters |
| `--timing` | | Print per-phase timings (open, candidates, verify, status, group) to stderr; with `--json`, adds a `timings` object |

### Pagination and limits

| Flag | Short | Description |
|------|-------|-------------|
| `--limit <N>` | `-n` | Maximum number of results (default: 100). `--limit 0` is rejected; use `--all` |
| `--offset <N>` | `-o` | Skip the first N results (use with `--limit` to paginate) |
| `--all` | `-a` | Return all results (no limit) |
| `--timeout <SECS>` | `-t` | Query timeout in seconds (default: 30, `0` = no timeout) |
| `--force` | | Run queries the broad-query guard would block: patterns under 3 characters, symbol/AST queries over more than 5,000 candidate files, AST queries without `--glob` |
| `--dependencies` | | Include import information in results (Rust files only) |

`--count` and `--paths` (without an explicit `--limit`) are never limited. When a limited search stops early, the footer shows an estimate, e.g. `Found 10 results (~1234 total, estimated)`; use `--count` for the exact total.

### Examples

```bash
# Whole-identifier search
rfx query "handleRequest"

# Substring and case-insensitive
rfx query "Error" --contains
rfx query "realmid" -i

# Symbol definitions only (--kind implies --symbols)
rfx query "Config" --kind struct

# Regex search
rfx query "fn (get|set)_\w+" --regex

# Patterns that start with a dash
rfx query --pattern '-> Result<'

# Rust files under src/ only
rfx query "unwrap" --lang rust --glob "src/**/*.rs"

# Search Markdown and other docs
rfx query "install" --lang text

# Which files mention it?
rfx query "open_index" --paths

# Exact count with per-phase timings
rfx query "trigram" --count --timing

# JSON output, page 2
rfx query "authenticate" --json --limit 20 --offset 20

# AST query (Tree-sitter S-expression)
rfx query "(function_item) @fn" --ast --lang rust --glob "src/**/*.rs"

# Interactive mode
rfx query
```

A symbol search groups results by file and tags each line with its kind:

```
  src/parsers/c.rs (1 match)
     152 [fn] extract_symbols
```

---

## `rfx deps`

Analyze dependencies for a single file. For graph-wide analysis, use [`rfx analyze`](#rfx-analyze).

```bash
rfx deps [OPTIONS] <FILE>
```

| Flag | Short | Description |
|------|-------|-------------|
| `--reverse` | `-r` | Show files that depend on this file |
| `--depth <N>` | `-d` | Traversal depth for transitive dependencies (default: 1) |
| `--format <FMT>` | `-f` | Output format: `tree` (default), `table`, or `json` |
| `--json` | | Output as JSON (same as `--format json`) |
| `--pretty` | | Pretty-print JSON output |

:::note
The built-in help also lists `dot` as a format, but rfx 2.0.0 does not implement it and exits with `Unknown format 'dot'`.
:::

### Examples

```bash
# Direct dependencies
rfx deps src/main.rs

# Reverse dependencies (who imports this file?)
rfx deps src/cache.rs --reverse

# Transitive dependencies
rfx deps src/main.rs --depth 3

# Table or JSON output
rfx deps src/main.rs --format table
rfx deps src/main.rs --json --pretty
```

```
Dependencies of src/main.rs:
  └─ clap::Parser [external] (line 3)
  └─ reflex::cli::Cli [external] (line 5)
  └─ reflex::output [external] (line 6)

Found 3 dependencies
```

---

## `rfx analyze`

Codebase-wide dependency analysis. With no flags, prints a summary report with counts.

```bash
rfx analyze [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--circular` | | Show circular dependencies |
| `--hotspots` | | Show the most-imported files |
| `--min-dependents <N>` | | Minimum dependents for a hotspot (default: 2) |
| `--unused` | | Show unused/orphaned files |
| `--islands` | | Show disconnected components |
| `--min-island-size <N>` | | Minimum island size (default: 2) |
| `--max-island-size <N>` | | Maximum island size (default: 500 or 50% of total files) |
| `--format <FMT>` | `-f` | Output format: `tree` (default), `table`, or `json` |
| `--json` | | Output as JSON |
| `--pretty` | | Pretty-print JSON output |
| `--count` | `-c` | Only show the count and timing, not the results |
| `--plain` | | Plain text output (no colors) |
| `--glob <GLOB>` | `-g` | Include files matching a glob. Repeatable |
| `--exclude <GLOB>` | `-x` | Exclude files matching a glob. Repeatable |
| `--limit <N>` | `-n` | Maximum number of results |
| `--offset <N>` | `-o` | Pagination offset |
| `--all` | `-a` | Return all results (no limit) |
| `--sort <ORDER>` | | `asc` or `desc` (default: `desc`). Sorts hotspots by import count, islands by size, cycles by length |
| `--force` | | Bypass broad-query detection |

### Examples

```bash
# Summary report
rfx analyze

# Find circular dependencies under src/
rfx analyze --circular --glob "src/**"

# Top 10 hotspots with at least 5 dependents
rfx analyze --hotspots --min-dependents 5 --limit 10

# Just the number of unused files
rfx analyze --unused --count

# All islands as JSON
rfx analyze --islands --all --json
```

```
Dependency Analysis Summary

Circular Dependencies: 1 cycle(s)
Hotspots: 68 file(s) with 2+ dependents
Unused Files: 24 file(s)
Islands: 187 disconnected component(s) (2 clusters of 2+ files, 185 isolated files)
```

---

## `rfx mcp`

Start the MCP (Model Context Protocol) server for AI assistant integration, using stdio transport.

```bash
rfx mcp
```

No flags. MCP clients such as Claude Code start this command themselves; you don't need to run it by hand. The server exposes 17 tools and uses its working directory as the project root. See [MCP Tools](/reference/mcp-tools/) for the complete tool reference.

---

## `rfx ask`

Ask a natural-language question. An LLM turns it into `rfx query` commands, which are then run against the index.

```bash
rfx ask [OPTIONS] [QUESTION]
```

With no question, launches interactive chat mode.

| Flag | Short | Description |
|------|-------|-------------|
| `--provider <PROVIDER>` | `-p` | Override the configured provider: `openai`, `anthropic`, `openrouter`, `openai-compatible` |
| `--answer` | | Generate a conversational answer from the search results (off by default) |
| `--execute` | `-e` | Show the generated queries and ask `[y/N]` before running them (see note) |
| `--agentic` | | Multi-step reasoning with context gathering |
| `--max-iterations <N>` | | Maximum query-refinement iterations in agentic mode (default: 2) |
| `--no-eval` | | Skip result evaluation in agentic mode |
| `--show-reasoning` | | Show LLM reasoning blocks at each phase (agentic mode only) |
| `--verbose` | | Show tool results and details (agentic mode only) |
| `--quiet` | | Suppress progress output (agentic mode only) |
| `--additional-context <TEXT>` | | Extra context to inject into the prompt (e.g. from `rfx context`) |
| `--json` | | Output as JSON |
| `--pretty` | | Pretty-print JSON output (only with `--json`) |
| `--interactive` | `-i` | Launch interactive chat mode (TUI) with conversation history |
| `--configure` | | Launch the provider setup wizard (deprecated; use `rfx llm config`) |
| `--debug` | | Output full LLM prompts and retain terminal history |

:::note
The built-in help describes `--execute` as "Execute queries immediately without confirmation", but in rfx 2.0.0 it does the opposite: a plain `rfx ask "..."` runs the generated queries immediately, while `--execute` prints them and waits for `y` before running. The prompt is skipped with `--json` and in `--agentic` mode.
:::

Requires an API key, set with `rfx llm config` or the `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `OPENROUTER_API_KEY` environment variables.

### Examples

```bash
# Interactive chat
rfx ask

# One-shot question
rfx ask "How does error handling work?"

# Answer in prose, not just results
rfx ask "Where is the config file parsed?" --answer

# Agentic mode for complex questions
rfx ask "How would I add WebSocket support?" --agentic --show-reasoning

# Feed project context into the prompt
rfx ask "find auth" --additional-context "$(rfx context --framework)"
```

---

## `rfx context`

Generate codebase context for AI prompts. With no flags, shows every context type.

```bash
rfx context [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--structure` | | Show directory structure (on by default) |
| `--file-types` | | Show file type distribution (on by default) |
| `--project-type` | | Detect project type (CLI/library/webapp/monorepo) |
| `--framework` | | Detect frameworks and conventions |
| `--entry-points` | | Show entry point files |
| `--test-layout` | | Show test organization pattern |
| `--config-files` | | List important configuration files |
| `--path <PATH>` | `-p` | Focus on a specific directory |
| `--depth <N>` | | Tree depth for `--structure` (default: 1) |
| `--json` | | Output as JSON |

```bash
# Full context
rfx context

# Monorepo subdirectory
rfx context --path services/backend

# Specific context types only
rfx context --framework --entry-points

# Deeper directory tree
rfx context --structure --depth 5
```

---

## `rfx serve`

Start the local HTTP API server.

```bash
rfx serve [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--port <PORT>` | `-p` | Port to listen on (default: 7878) |
| `--host <HOST>` | | Host to bind to (default: 127.0.0.1) |

See [HTTP API](/reference/http-api/) for endpoint documentation.

---

## `rfx llm`

Manage LLM provider configuration, shared by `rfx ask` and `rfx pulse`.

```bash
# Interactive configuration wizard (provider and API key)
rfx llm config

# Show current configuration
rfx llm status
```

---

## `rfx pulse`

Turn structural facts from the index into browsable documentation.

```bash
rfx pulse <COMMAND> [OPTIONS]
```

| Subcommand | Description | Options |
|------------|-------------|---------|
| `changelog` | Product-level changelog from recent commits | `--count <N>` (default: 20), `--no-llm`, `--json`, `--pretty` |
| `wiki` | Living wiki pages | `--no-llm`, `-o, --output <DIR>`, `--json` |
| `map` | Architecture map | `-f, --format <FMT>` (`mermaid` default, `d2`), `-o, --output <FILE>` (stdout if unset), `-z, --zoom <ZOOM>` (`repo` default, or a module path) |
| `generate` | Complete static site (Zola project + HTML build) | See below |
| `serve` | Serve the generated site locally with live reload | `-o, --output <DIR>` (default: `pulse-site`), `-p, --port <PORT>` (default: 1111), `--open` |
| `onboard` | Developer onboarding guide | `--no-llm`, `--json` |
| `timeline` | Development timeline from git history | `--json` |
| `glossary` | Cross-cutting symbol glossary | `--json` |

LLM narration runs whenever a provider is configured; pass `--no-llm` for structural content only.

### `rfx pulse generate`

| Flag | Short | Description |
|------|-------|-------------|
| `--output <DIR>` | `-o` | Output directory for the Zola project (default: `pulse-site`) |
| `--base-url <URL>` | | Base URL for the site, mapped to Zola's `base_url` (default: `/`) |
| `--title <TITLE>` | | Site title |
| `--include <LIST>` | | Surfaces to include, comma-separated: `wiki`, `changelog`, `map`, `onboard`, `timeline`, `glossary`, `explorer` |
| `--no-llm` | | Skip LLM narration |
| `--clean` | | Clean the output directory before generating |
| `--force-renarrate` | | Ignore the LLM cache and narrate again |
| `--concurrency <N>` | | Maximum concurrent LLM requests (default: 0 = unlimited) |
| `--depth <N>` | | Maximum directory depth for module discovery (default: 2) |
| `--min-files <N>` | | Minimum file count for a module to be included (default: 1) |

```bash
rfx pulse changelog --no-llm
rfx pulse map --format d2 --output architecture.d2
rfx pulse generate --no-llm
rfx pulse serve --open
```

See [Pulse guide](/guides/pulse/) for details.

---

## `rfx snapshot`

Take and manage snapshots of the index's structural state (files, dependencies, metrics) for diffing and historical analysis.

```bash
rfx snapshot [COMMAND]
```

| Subcommand | Description | Options |
|------------|-------------|---------|
| (none) | Take a new snapshot | |
| `diff` | Compare two snapshots (default: latest vs previous) | `--baseline <ID>` (default: second-most-recent), `--current <ID>` (default: most recent), `--json`, `--pretty` |
| `list` | List available snapshots | `--json`, `--pretty` |
| `gc` | Run snapshot garbage collection (retention policy) | `--json` |

---

## Utility commands

### `rfx stats`

Show index statistics: branch, file count, index size, trigram count, and a per-language breakdown.

```bash
rfx stats [--json] [--pretty]
```

### `rfx clear`

Remove the local cache (`.reflex/` directory).

```bash
rfx clear [-y | --yes]
```

`-y` / `--yes` skips the confirmation prompt.

### `rfx list-files`

List all indexed files.

```bash
rfx list-files [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--lang <LANG>` | `-l` | Filter by language (e.g. `rust`, `python`, `lock`) |
| `--glob <GLOB>` | `-g` | Include files matching a glob. Repeatable |
| `--json` | | Output as JSON |
| `--pretty` | | Pretty-print JSON output (only with `--json`) |

### `rfx watch`

Watch for file changes and reindex automatically.

```bash
rfx watch [OPTIONS] [PATH]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--debounce <MS>` | `-d` | Milliseconds to wait after the last change before reindexing (default: 15000; valid range 5000–30000) |
| `--quiet` | `-q` | Suppress output (only log errors) |

`[PATH]` defaults to the current directory. The debounce timer resets on every change, so a burst of edits (a multi-file refactor, format-on-save) triggers a single reindex.
