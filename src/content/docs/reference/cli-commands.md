---
title: CLI Commands
description: Complete reference for every rfx command, subcommand, and flag.
---

## `rfx index`

Build or update the search index.

```bash
rfx index [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--force` | Rebuild the entire index, ignoring cached hashes |
| `--languages <LANGS>` | Comma-separated list of languages to index |

### Subcommands

```bash
# Show index status
rfx index status

# Compact the index (reclaim space from deleted files)
rfx index compact
```

Indexing is **incremental** by default — only files whose blake3 hash has changed are reprocessed. Use `--force` after configuration changes or when troubleshooting.

---

## `rfx query`

Search the codebase. With no pattern, launches interactive TUI mode.

```bash
rfx query [PATTERN] [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--symbols` | `-s` | Only return symbol definitions |
| `--regex` | `-r` | Treat pattern as a regular expression |
| `--lang <LANG>` | | Filter by language |
| `--kind <KIND>` | | Filter by symbol kind (requires `--symbols`) |
| `--paths <PATTERN>` | `-p` | Filter by file path prefix |
| `--dependencies` | | Include dependency context in results |
| `--json` | | Output results as JSON |
| `--limit <N>` | | Maximum number of results (default: 100) |
| `--timeout <SECS>` | | Query timeout in seconds (default: 30) |

### Examples

```bash
# Full-text search
rfx query "handleRequest"

# Symbol definitions only
rfx query "Config" --symbols --kind struct

# Regex search
rfx query "TODO\(\w+\)" --regex

# JSON output
rfx query "authenticate" --symbols --json

# Language filter
rfx query "import" --lang typescript

# Interactive mode
rfx query
```

---

## `rfx deps`

Per-file dependency analysis.

```bash
rfx deps <FILE> [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--reverse` | Show files that depend on this file |
| `--depth <N>` | Traversal depth (default: 1) |
| `--format <FMT>` | Output format: `tree` (default), `table`, `json` |
| `--json` | Shorthand for `--format json` |
| `--pretty` | Pretty-print JSON output |

### Examples

```bash
# Direct dependencies
rfx deps src/main.rs

# Reverse dependencies (who imports this file?)
rfx deps src/auth/handler.rs --reverse

# Transitive dependencies
rfx deps src/main.rs --depth 3

# JSON output
rfx deps src/main.rs --json --pretty
```

---

## `rfx analyze`

Codebase-wide dependency analysis.

```bash
rfx analyze [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--circular` | Find circular dependencies |
| `--hotspots` | Find most-depended-upon files |
| `--unused` | Find files that nothing imports |
| `--islands` | Find disconnected file clusters |
| `--limit <N>` | Results per page |
| `--offset <N>` | Skip first N results |
| `--all` | Return all results (no pagination) |
| `--json` | JSON output |

### Examples

```bash
# Find circular dependencies
rfx analyze --circular

# Top 10 hotspots
rfx analyze --hotspots --limit 10

# All unused files as JSON
rfx analyze --unused --all --json
```

---

## `rfx mcp`

Start the MCP (Model Context Protocol) server for AI assistant integration.

```bash
rfx mcp
```

No flags — the MCP server exposes 14 tools through the standard MCP protocol. See [MCP Tools](/reference/mcp-tools/) for the complete tool reference.

---

## `rfx ask`

AI-powered code question answering.

```bash
rfx ask [QUESTION] [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--provider <PROVIDER>` | Override LLM provider (`anthropic`, `openai`, `openrouter`) |
| `--agentic` | Enable multi-step reasoning |
| `--answer` | Direct answer mode (default) |
| `--execute` | Run query without LLM interpretation |

With no question, enters interactive conversation mode.

### Examples

```bash
# Interactive mode
rfx ask

# One-shot question
rfx ask "How does error handling work?"

# Agentic mode for complex questions
rfx ask "How would I add WebSocket support?" --agentic
```

---

## `rfx context`

Generate codebase context for AI prompts.

```bash
rfx context [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--structure` | Include directory structure |
| `--file-types` | Include file type breakdown |
| `--project-type` | Detect and include project type |
| `--framework` | Detect and include framework |
| `--entry-points` | Include entry point files |
| `--test-layout` | Include test file organization |
| `--config-files` | Include configuration files |
| `--path <PATH>` | Scope to a subdirectory |
| `--depth <N>` | Directory tree depth |

---

## `rfx serve`

Start the HTTP API server.

```bash
rfx serve [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--port <PORT>` | Port number (default: 7878) |
| `--host <HOST>` | Bind address (default: 127.0.0.1) |

See [HTTP API](/reference/http-api/) for endpoint documentation.

---

## `rfx llm`

Manage LLM provider configuration.

```bash
# Interactive configuration wizard
rfx llm config

# Show current configuration
rfx llm status
```

---

## `rfx pulse`

Codebase intelligence surfaces (preview feature).

```bash
rfx pulse <SUBCOMMAND> [OPTIONS]
```

| Subcommand | Description |
|------------|-------------|
| `digest` | Generate periodic change report |
| `wiki` | Generate per-module documentation |
| `map` | Generate architecture diagram |
| `generate` | Generate complete static site |
| `serve` | Serve generated site |
| `watch` | Watch and auto-regenerate |

See [Pulse guide](/guides/pulse/) for details.

---

## `rfx snapshot`

Manage Pulse snapshots.

```bash
rfx snapshot [SUBCOMMAND]
```

| Subcommand | Description |
|------------|-------------|
| (none) | Take a new snapshot |
| `diff` | Compare two snapshots |
| `list` | List saved snapshots |
| `gc` | Garbage-collect old snapshots |

---

## Utility commands

### `rfx stats`

Show index statistics — file counts, language breakdown, index size.

```bash
rfx stats
```

### `rfx clear`

Remove the index cache (`.reflex/` directory).

```bash
rfx clear
```

### `rfx list-files`

List all indexed files.

```bash
rfx list-files
```

### `rfx watch`

Watch for file changes and auto-reindex.

```bash
rfx watch
```
