---
title: MCP Tools
description: Complete reference for all 17 MCP tools exposed by Reflex's MCP server.
---

Reflex's MCP server (`rfx mcp`) exposes 17 tools through the Model Context Protocol. These tools let AI assistants search code, analyze dependencies, and understand your codebase.

The server speaks MCP protocol version `2025-11-25` over stdio and uses its working directory as the project root. On `initialize` it also returns an `instructions` string telling the agent to prefer Reflex tools over grep and listing the exact argument names.

## Setup

### Claude Code

```bash
# Current project only (default "local" scope)
claude mcp add reflex -- rfx mcp

# Share with your team via a checked-in .mcp.json
claude mcp add --scope project reflex -- rfx mcp
```

Or add it to `.mcp.json` in your project root yourself:

```json
{
  "mcpServers": {
    "reflex": {
      "type": "stdio",
      "command": "rfx",
      "args": ["mcp"]
    }
  }
}
```

Other MCP clients use the same `command` / `args`. Launch the server from your project directory (the one containing `.reflex/`).

### Hiding the structural tools

Five whole-graph analysis tools (`find_circular`, `find_islands`, `find_unused`, `analyze_summary`, `get_transitive_deps`) can be removed from the tool list to save context. Add this to `~/.reflex/config.toml`:

```toml
[mcp]
enable_structural_tools = false   # default: true
```

## Argument handling

- The search argument is always `pattern`, the language filter is `lang`, and the result cap is `limit`.
- Common wrong names are accepted and mapped, with a `warnings` entry in the response: `query`, `symbol`, `text`, `search` → `pattern`; `max_results` → `limit`; `path` → `file` (only on tools that have no real `path` parameter).
- Any other unknown argument is rejected with a JSON-RPC `-32602` error that lists the valid names.
- Numeric strings (`"40"`) are accepted for integer parameters.

## Freshness

Every search response carries `status` (`"fresh"` or `"stale"`) and `can_trust_results`. A stale response still contains real matches, but it may be incomplete. It includes a `warning` with the changed paths (`files_modified`, `files_added`, `files_deleted`) and `action_required: "index_project"`. Freshness is judged by file content, not by commit, so an uncommitted edit makes the index stale and committing already-indexed content does not.

## Search tools

### Common filters

All search tools accept these filters. `search_ast` and `find_references` take only some of them, as noted below.

| Parameter | Type | Description |
|-----------|------|-------------|
| `lang` | string | `rust`, `typescript`, `javascript`, `go`, `java`, `php`, `kotlin`, `python`, `c`, `cpp`, `csharp`, `ruby`, `vue`, `svelte`, `zig`, or `text` / `lock` / `generated` for the non-code tiers |
| `file` | string | Filter by file path substring |
| `glob` | string[] | Include files matching patterns (gitignore rules: a pattern containing `/` is anchored at the index root, a bare name matches at any depth, `*` does not cross `/`) |
| `exclude` | string[] | Exclude files matching patterns (same rules) |
| `force` | bool | Bypass broad-query detection |
| `dependencies` | bool | Include static imports in results |
| `ignore_case` | bool | Match regardless of case, like `rg -i` |
| `include_locks` | bool | Also search lock files (`Cargo.lock`, `package-lock.json`, `*.lock`, `go.sum`) |
| `include_generated` | bool | Also search generated files (`*.pb.go`, `*.min.js`, `*.min.css`, `*.map`, `*_generated.*`) |

Coverage matches ripgrep's defaults: every non-binary file that isn't gitignored and isn't under a dot-directory. Lock and generated files are indexed, but left out unless you ask for them. A zero-result response carries `excluded_reason` (`hidden`, `not_indexed`, `lock_or_generated`, or `whole_identifier`) and a `hint` naming the cause.

### `search_code`

Full-text search. Matches **whole identifiers** by default (`verify_csrf` does not match `verify_csrf_form_field`). Pass `contains: true` for substring matching. A pattern containing brackets (`()`, `[]`, `<>`) is escaped and run as a regex, with a note in `warnings`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Text to find |
| `contains` | bool | no | Substring matching, like `grep -F` |
| `symbols` | bool | no | Symbol definitions only |
| `kind` | string | no | Symbol kind filter (`function`, `class`, `struct`, …) |
| `exact` | bool | no | Case-sensitive exact-identifier match |
| `expand` | bool | no | Show full symbol body |
| `mode` | `list` \| `count` | no | `count` returns only `{count, pattern}` |
| `limit` | int | no | Results per page (default: 200, max: 500) |
| `offset` | int | no | Pagination offset |
| `paths` | bool | no | Return only unique file paths |
| `preview_length` | int | no | Max characters per preview line (default: 180) |

Plus the [common filters](#common-filters).

Results are **columnar**: each row lines up with `columns`.

```json
{
  "status": "fresh",
  "can_trust_results": true,
  "columns": ["path", "language", "start_line", "end_line", "preview", "kind", "symbol"],
  "rows": [
    ["src/cli/ask.rs", "rust", 9, 426, "pub(super) fn handle_ask(\n    question: Option<String>,\n   …", "Function", "handle_ask"]
  ],
  "pagination": { "count": 1, "has_more": false, "limit": 2, "offset": 0, "total": 1, "total_is_exact": true },
  "returned_count": 1,
  "total_count": 1,
  "total_is_exact": true,
  "has_more": false,
  "ai_instruction": "Found 1 precise result. Respond concisely: '[symbol] at [path]:[line]'."
}
```

With `paths: true` the response is `{status, can_trust_results, paths, total_files}` instead. Set the environment variable `REFLEX_MCP_COLUMNAR=0` to get the file-grouped `results[]` shape used by `rfx query --json`, or `REFLEX_MCP_TIMING=1` to add per-phase `timings`.

A list-mode search stops verifying once the page is full, so `total` is a number only when `total_is_exact` is true. Otherwise it's `null` and `approx_total` holds an estimate. Use `mode: "count"` for an exact number.

### `search_regex`

Regular-expression search with the same coverage as `search_code`. Regexes with a literal of 3+ characters (including `(?i)` patterns) still use the trigram index.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Regex pattern |
| `mode` | `list` \| `count` | no | `count` returns only `{count, pattern}` |
| `limit` | int | no | Results per page (default: 200, max: 500) |
| `offset` | int | no | Pagination offset |
| `paths` | bool | no | Return only unique file paths |

Plus the [common filters](#common-filters). `ignore_case: true` prepends `(?i)`.

### `search_ast`

Structure-aware search with Tree-sitter S-expression patterns. It's slow, because it bypasses the trigram index and parses every candidate file, so pass `glob` to limit scope.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Tree-sitter S-expression, e.g. `(function_item) @fn` |
| `lang` | string | yes | `rust`, `typescript`, `javascript`, `python`, `go`, `java`, `c`, `cpp`, `csharp`, `php`, `ruby`, `kotlin`, `zig` |
| `glob` | string[] | no | Include patterns (strongly recommended) |
| `exclude` | string[] | no | Exclude patterns |
| `file` | string | no | File path substring |
| `limit` | int | no | Max results |
| `offset` | int | no | Pagination offset |
| `paths` | bool | no | Return only unique file paths |
| `force` | bool | no | Bypass broad-query detection |
| `dependencies` | bool | no | Include static imports |

### `find_references`

A symbol's definition plus every usage, in one call. By default it skips matches inside string literals and comments, and it only searches code files (not docs or config).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Symbol name, e.g. `CacheManager` |
| `contains` | bool | no | Substring matching |
| `ignore_case` | bool | no | Case-insensitive matching |
| `include_strings` | bool | no | Include matches in strings and comments (default: false) |
| `kind` | string | no | Filter the definition lookup by kind |
| `lang` | string | no | Filter by language |
| `glob` | string[] | no | Include patterns |
| `exclude` | string[] | no | Exclude patterns |
| `mode` | `list` \| `count` | no | `count` returns only `{count, pattern}` |
| `limit` | int | no | References per page (default: 200, max: 500) |
| `offset` | int | no | Pagination offset |
| `force` | bool | no | Bypass broad-query detection |

```json
{
  "status": "fresh",
  "definition": {
    "kind": "Function", "path": "src/cli/ask.rs", "symbol": "handle_ask",
    "span": { "start_line": 9, "end_line": 426 },
    "preview": "pub(super) fn handle_ask(\n    question: Option<String>,\n   …"
  },
  "references": [
    { "line": 9, "path": "src/cli/ask.rs", "preview": "pub(super) fn handle_ask(" },
    { "line": 1258, "path": "src/cli/mod.rs", "preview": "            }) => ask::handle_ask(" }
  ],
  "total_references": 2,
  "returned_count": 2,
  "filtered_out": 0,
  "pagination": { "count": 2, "has_more": false, "limit": 3, "offset": 0, "total": 2, "total_is_exact": true }
}
```

`total_references` and `pagination.total` are raw totals before string/comment filtering. `filtered_out` is how many of them were dropped.

### `list_locations`

Every place a pattern occurs, as `{path, line}` pairs with no previews and no limit. It's the cheapest way to enumerate hits.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Text to find |
| `contains` | bool | no | Substring matching |

Plus the [common filters](#common-filters).

```json
{"locations":[{"line":9,"path":"src/cli/ask.rs"},{"line":1258,"path":"src/cli/mod.rs"}],"status":"fresh","total_locations":2}
```

### `count_occurrences`

Total occurrences and file count, without loading content.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Text to find |
| `contains` | bool | no | Substring matching |
| `symbols` | bool | no | Count definitions only |
| `kind` | string | no | Symbol kind filter |

Plus the [common filters](#common-filters).

```json
{"files":2,"pattern":"handle_ask","status":"fresh","total":2}
```

## Index tools

### `index_project`

Build or update the index. Incremental by default. Returns index statistics (`total_files`, `files_by_language`, `lines_by_language`, `index_size_bytes`, `corpus_bytes`, `trigram_index_bytes`, `last_updated`, plus changed-file counts).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `force` | bool | no | Force a full rebuild |
| `languages` | string[] | no | Languages to include (empty = all) |

:::caution
`force: true` deletes **everything** in `.reflex/` before rebuilding, including the project `config.toml` and any Pulse snapshots. The rebuilt index uses default settings. The default incremental run already applies config changes, so use `force` only when the index is corrupted.
:::

### `check_index_status`

Check whether the index is fresh, stale, or missing, without running a search. Call it at session start, after git operations, and after editing files. No parameters.

```json
{
  "status": "fresh",
  "can_trust_results": true,
  "details": {
    "checked_by": "git",
    "current_branch": "HEAD",
    "current_commit": "436f836…",
    "indexed_branch": "HEAD",
    "indexed_commit": "436f836…",
    "indexed_at": 1790189114
  }
}
```

When stale, the response adds `reason`, `action_required` (`"index_project"`), `files_modified`, `files_added`, `files_deleted` (capped at 100 each, with `truncated` set if cut short), and `changed_count`.

## Dependency tools

Path matching is fuzzy: exact paths, fragments, or bare filenames all work. Only static imports are considered.

### `get_dependencies`

Every import of a single file.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | yes | File path |

```json
[{"line":1,"path":"src/cache.rs"},{"line":2,"path":"anyhow","symbols":["Context","Result"]}]
```

### `get_dependents`

Every file that imports the given file. Returns an array of paths.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | yes | File path |

### `get_transitive_deps`

Walk the dependency tree of a file. Returns `[{path, depth}]`. *Structural tool.*

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | yes | File path |
| `depth` | int | no | Max traversal depth (default: 3) |

## Analysis tools

Paginated analysis tools return `{pagination, results}` with a default page size of 200.

### `find_hotspots`

Files ranked by how many other files import them. Returns `[{path, import_count}]`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `min_dependents` | int | no | Minimum dependents to include (default: 2) |
| `sort` | `asc` \| `desc` | no | Sort order (default: `desc`) |
| `limit` | int | no | Page size (default: 200) |
| `offset` | int | no | Pagination offset |

### `find_circular`

Circular dependency chains. Returns `[{paths: ["a.rs", "b.rs", "a.rs"]}]`, longest first by default. *Structural tool.*

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sort` | `asc` \| `desc` | no | Sort by cycle length (default: `desc`) |
| `limit` | int | no | Page size (default: 200) |
| `offset` | int | no | Pagination offset |

### `find_unused`

Files that no other file imports. Entry points such as `main.rs` show up here by design. *Structural tool.*

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | int | no | Page size (default: 200) |
| `offset` | int | no | Pagination offset |

### `find_islands`

Disconnected components of the import graph. Returns `[{island_id, size, paths}]`, largest first by default. *Structural tool.*

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `min_island_size` | int | no | Minimum files per island (default: 2) |
| `max_island_size` | int | no | Maximum files per island (default: 500 or 50% of files) |
| `sort` | `asc` \| `desc` | no | Sort by size (default: `desc`) |
| `limit` | int | no | Page size (default: 200) |
| `offset` | int | no | Pagination offset |

### `analyze_summary`

Aggregate counts, to decide which analysis to drill into. *Structural tool.*

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `min_dependents` | int | no | Hotspot threshold (default: 2) |

```json
{"circular_dependencies":1,"hotspots":68,"islands":187,"min_dependents":2,"unused_files":24}
```

## Context tools

### `gather_context`

Collect codebase orientation: project structure, frameworks, entry points, and file statistics. With no parameters, all context types are gathered. Returns prose, not JSON.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `structure` | bool | no | Show directory structure |
| `file_types` | bool | no | Show file type distribution |
| `project_type` | bool | no | Detect project type (CLI, library, webapp, monorepo) |
| `framework` | bool | no | Detect frameworks and conventions |
| `entry_points` | bool | no | Show entry point files |
| `test_layout` | bool | no | Show test organization pattern |
| `config_files` | bool | no | List important configuration files |
| `depth` | int | no | Tree depth for structure (default: 2) |
| `path` | string | no | Focus on a specific directory path |

## Next steps

- [AI Integration](/guides/ai-integration/) — integration patterns and best practices
- [Dependency Analysis](/guides/dependency-analysis/) — understanding the dependency graph
- [CLI Commands](/reference/cli-commands/) — `rfx mcp` reference
