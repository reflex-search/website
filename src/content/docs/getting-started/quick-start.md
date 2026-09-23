---
title: Quick Start
description: Index your project and run your first search queries in under a minute.
---

This walkthrough takes you from zero to searching your codebase in under a minute.

## 1. Index your project

From your project root:

```bash
rfx index
```

Reflex walks your source tree, extracts trigrams for every file, and builds a memory-mapped index. It covers the same files ripgrep searches by default: every non-binary file that is not gitignored and not under a dot-directory. On the Reflex repository itself (298 files), a full index takes about half a second; a 27,448-file Kubernetes checkout indexes in 7.7 seconds on a 16-core machine.

```
Indexing complete!
  Files indexed: 298
  Cache size: 10.68 MB
  Index/corpus ratio: 1.3x (trigrams.bin 5.94 MB, content.bin 4.42 MB)
  Last updated: 2026-09-23T18:48:45+00:00
  Breakdown:     298 new, 0 modified, 0 unchanged
  Text: 67 files, Lock: 1, Generated: 0 (lock and generated are excluded from searches unless asked for)
  Coverage: ripgrep defaults — not gitignored, not binary, not under a dot-directory ([index] hidden = true to include them)

Files by language:
  Language    Files  Lines
  ----------  -----  -------
  Rust          179   100331
  Text           67    25661
  Python         18     4810
  TypeScript     11      834
  ...

Starting background symbol indexing...
  Symbols will be cached for faster queries
  Check status with: rfx index status
```

Files without a symbol parser — docs, config, and anything else that isn't code — are indexed as `Text` and are fully searchable. Lock files and generated files are indexed too, but left out of results unless you ask for them.

The index is **incremental** — subsequent runs only reprocess changed files, detected by file content (size, modification time, and blake3 hash):

```
  Breakdown:     0 new, 1 modified, 297 unchanged
```

After indexing, a background pass parses every file once and caches its symbols, so `--symbols` queries are fast. Symbol queries still work before it finishes; check its progress with `rfx index status`.

## 2. Search for text

```bash
rfx query "resolve_thread_count"
```

This performs a full-text search across every indexed file. Results are grouped by file, with the line number and matching line:

```
  📁 src/indexer.rs (1 match)
     504
                let num_threads = crate::models::resolve_thread_count(self.config.parallel_threads, 32);

  📁 src/models.rs (1 match)
     635
        pub fn resolve_thread_count(configured: usize, auto_cap: usize) -> usize {

  📁 src/query/open_index.rs (1 match)
     161
                    crate::models::resolve_thread_count(config.parallel_threads, QUERY_AUTO_THREAD_CAP);

Found 3 results in 9ms
```

By default a pattern matches **whole identifiers**: `thread_coun` does not match `resolve_thread_count`. When a search comes back empty, Reflex tells you if a substring search would have found something:

```
Hint: 0 whole-identifier matches; 6 substring matches — pass contains:true (--contains on the CLI) to see them. Reflex matches whole identifiers by default, so "thread_coun" does not match longer names that merely contain it.
No results found (searched in 7ms).
```

A few flags change how matching works:

- `--contains` — match substrings (`Error` also matches `NetworkError`)
- `-i` / `--ignore-case` — match regardless of case, like `rg -i`
- `--include-locks` / `--include-generated` — also search lock files (`Cargo.lock`, `package-lock.json`) and generated files (`*.pb.go`, `*.min.js`)

By default a query returns the first 100 results (change it with `--limit`, page with `--offset`). When there are more, the footer shows the total — or an estimate when counting every match would slow the search down:

```
Found 100 results (~1476 total, estimated) in 8ms
Use --limit/--offset to paginate, or --count for the exact total
```

## 3. Filter by symbols

Add `--symbols` (or `-s`) to restrict results to symbol definitions — functions, classes, structs, types:

```bash
rfx query "resolve_thread_count" --symbols
```

```
  📁 src/models.rs (1 match)
     635 [fn] resolve_thread_count
        pub fn resolve_thread_count(configured: usize, auto_cap: usize) -> usize {
    if configured != 0 {…

Found 1 result in 7ms
```

Use `--kind` to narrow further (it implies `--symbols`):

```bash
rfx query "IndexConfig" --kind struct
```

## 4. Filter by language

```bash
rfx query "import" --lang typescript
```

Use `--lang text` to search only non-code files (docs, config), or `--lang lock` / `--lang generated` to search only lock or generated files.

## 5. Get JSON output

For scripts and AI pipelines, use `--json`:

```bash
rfx query "resolve_thread_count" --symbols --json --pretty
```

```json
{
  "status": "fresh",
  "can_trust_results": true,
  "pagination": {
    "total": 1,
    "count": 1,
    "offset": 0,
    "limit": 100,
    "has_more": false,
    "total_is_exact": true
  },
  "results": [
    {
      "path": "src/models.rs",
      "language": "rust",
      "matches": [
        {
          "kind": "Function",
          "symbol": "resolve_thread_count",
          "span": {
            "start_line": 635,
            "end_line": 643
          },
          "preview": "pub fn resolve_thread_count(configured: usize, auto_cap: usize) -> usize {\n    if configured != 0 {…"
        }
      ]
    }
  ]
}
```

Every response reports whether the index matches your working tree: `status` is `"fresh"` or `"stale"`. When it is stale, `can_trust_results` is `false` and a `warning` object explains why and lists the changed files — re-run `rfx index` to refresh:

```json
{
  "status": "stale",
  "can_trust_results": false,
  "warning": {
    "reason": "Files changed since the index was built (1 modified) — these results may not reflect them",
    "action_required": "index_project",
    "files_modified": [
      "src/lib.rs"
    ],
    "changed_count": 1,
    ...
  },
  ...
}
```

When the total is estimated, `pagination.total` is `null`, `total_is_exact` is `false`, and `approx_total` holds the estimate.

## 6. Interactive mode

Launch the TUI for interactive search:

```bash
rfx query
```

Type a pattern and press `Enter` to search, move through results with `↑`/`↓`, press `Enter` on a result to preview the file, and press `o` to open it in your editor. See the [Interactive Mode](/guides/interactive-mode/) guide for keybindings and editor integration.

## Next steps

- [Configuration](/getting-started/configuration/) — customize index settings, file limits, and performance tuning
- [Full-Text Search](/guides/full-text-search/) — understand trigram search in depth
- [Symbol Search](/guides/symbol-search/) — filter by functions, classes, and more
- [AI Integration](/guides/ai-integration/) — connect Reflex to AI coding assistants via MCP
