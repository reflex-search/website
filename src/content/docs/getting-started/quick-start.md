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

Reflex walks your source tree, extracts trigrams for every file, and builds a memory-mapped index. On a typical project (1,000–5,000 files), this takes 1–3 seconds.

```
Indexed 1,247 files (8 languages) in 1.8s
```

The index is **incremental** — subsequent runs only reprocess changed files using blake3 content hashing.

## 2. Search for text

```bash
rfx query "handleRequest"
```

This performs a full-text search across every indexed file. Results include file path, line number, and a snippet of matching context:

```
src/server/handler.rs:42    pub fn handleRequest(req: Request) -> Response {
src/tests/server_test.rs:18 let response = handleRequest(mock_request());
2 results in 3ms
```

## 3. Filter by symbols

Add `--symbols` (or `-s`) to restrict results to symbol definitions — functions, classes, structs, types:

```bash
rfx query "handleRequest" --symbols
```

```
src/server/handler.rs:42  [Function] pub fn handleRequest(req: Request) -> Response {
1 result in 4ms
```

Use `--kind` to narrow further:

```bash
rfx query "Config" --symbols --kind struct
```

## 4. Filter by language

```bash
rfx query "import" --lang typescript
```

## 5. Get JSON output

For scripts and AI pipelines, use `--json`:

```bash
rfx query "authenticate" --symbols --json
```

```json
{
  "metadata": {
    "status": "fresh",
    "total_results": 1,
    "query_time_ms": 3
  },
  "results": [
    {
      "file": "src/auth/mod.rs",
      "line": 42,
      "column": 8,
      "match": "pub fn authenticate(credentials: &Credentials) -> Result<Session>",
      "symbol": "authenticate",
      "kind": "Function",
      "language": "rust"
    }
  ]
}
```

## 6. Interactive mode

Launch the TUI for live, interactive search:

```bash
rfx query
```

Type to search, use arrow keys to navigate results, and press `Enter` to open a file in your editor. See the [Interactive Mode](/guides/interactive-mode/) guide for keybindings and editor integration.

## Next steps

- [Configuration](/getting-started/configuration/) — customize index settings, file limits, and performance tuning
- [Full-Text Search](/guides/full-text-search/) — understand trigram search in depth
- [Symbol Search](/guides/symbol-search/) — filter by functions, classes, and more
- [AI Integration](/guides/ai-integration/) — connect Reflex to AI coding assistants via MCP
