---
title: HTTP API
description: REST API endpoints for programmatic integration with Reflex.
---

Reflex includes an HTTP server for programmatic access. Run it from your project directory (the one containing `.reflex/`):

```bash
rfx serve                  # 127.0.0.1:7878
rfx serve --port 8080      # custom port
rfx serve --host 0.0.0.0   # all interfaces (use with caution)
```

## Endpoints

### `GET /query`

Search the codebase. Like the CLI, plain queries match **whole identifiers** by default: `handle_as` does not match `handle_ask` unless you pass `contains=true`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | yes | Search pattern |
| `symbols` | bool | no | Only return symbol definitions |
| `kind` | string | no | Filter by symbol kind (case-insensitive; implies `symbols=true`) |
| `regex` | bool | no | Treat `q` as a regular expression |
| `contains` | bool | no | Substring matching instead of whole identifiers |
| `ignore_case` | bool | no | Case-insensitive matching |
| `exact` | bool | no | Exact identifier match |
| `expand` | bool | no | Show full symbol bodies |
| `lang` | string | no | Filter by language (see [Language identifiers](#language-identifiers)) |
| `file` | string | no | Filter by file path substring |
| `limit` | int | no | Max results (default: 100) |
| `offset` | int | no | Pagination offset |
| `dependencies` | bool | no | Include each file's static imports (Rust only) |
| `force` | bool | no | Bypass broad-query detection |
| `timeout` | int | no | Timeout in seconds (default: 30) |

**Response:** the same JSON that `rfx query --json` returns.

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
      "path": "src/cli/ask.rs",
      "language": "rust",
      "matches": [
        {
          "kind": "Function",
          "symbol": "handle_ask",
          "span": { "start_line": 9, "end_line": 426 },
          "preview": "pub(super) fn handle_ask(\n    question: Option<String>,\n    auto_execute: bool,\n    …"
        }
      ]
    }
  ]
}
```

`kind` and `symbol` appear only on symbol matches. When a search fills its page before verifying every candidate, `pagination.total` is `null`, `total_is_exact` is `false`, and `approx_total` holds an estimate:

```json
"pagination": { "total": null, "count": 2, "offset": 0, "limit": 2, "has_more": true, "total_is_exact": false, "approx_total": 1745 }
```

A whole-identifier search that finds nothing tells you why:

```json
{
  "status": "fresh",
  "can_trust_results": true,
  "pagination": { "total": 0, "count": 0, "offset": 0, "limit": 100, "has_more": false, "total_is_exact": true },
  "results": [],
  "substring_hint_count": 2,
  "hint": "0 whole-identifier matches; 2 substring matches — pass contains:true (--contains on the CLI) to see them. Reflex matches whole identifiers by default, so \"handle_as\" does not match longer names that merely contain it.",
  "excluded_reason": "whole_identifier"
}
```

**Status values:**

| `status` | `can_trust_results` | Meaning |
|----------|---------------------|---------|
| `fresh` | `true` | Index matches the files on disk |
| `stale` | `false` | Files were edited, added, or deleted since indexing. A `warning` object lists them (`files_modified`, `files_added`, `files_deleted`) |

When `can_trust_results` is `false`, trigger a reindex with `POST /index`. If no index exists, the request fails with an error instead of returning a status.

**Examples:**

```bash
curl "http://localhost:7878/query?q=handle_ask&kind=function"
curl "http://localhost:7878/query?q=HANDLE_ASK&ignore_case=true"
curl "http://localhost:7878/query?q=fn%20handle_&regex=true&lang=rust&limit=20"
```

---

### `GET /stats`

Index statistics.

**Response:**

```json
{
  "total_files": 298,
  "index_size_bytes": 12389570,
  "last_updated": "2026-09-23T18:51:32+00:00",
  "files_by_language": {
    "Rust": 179,
    "Text": 67,
    "Python": 18,
    "TypeScript": 11,
    "Lock": 1
  },
  "lines_by_language": {
    "Rust": 100331,
    "Text": 25661,
    "Python": 4810,
    "TypeScript": 834,
    "Lock": 1
  },
  "corpus_bytes": 4631790,
  "trigram_index_bytes": 6224375
}
```

Returns `404` with `{"error":{"kind":"IndexNotFound",...}}` if no index exists.

---

### `POST /index`

Trigger reindexing. This is synchronous: the response comes back after indexing completes. Indexing is incremental unless you pass `force`.

**Request body** (optional; send it with a `Content-Type` header):

```json
{
  "force": false,
  "languages": ["rust", "typescript"]
}
```

Both fields are optional. When `force` is `true`, the existing cache is cleared and the index is rebuilt from scratch.

:::caution
`force: true` deletes **everything** in `.reflex/`, including your project `config.toml` and any Pulse snapshots. The rebuilt index uses default settings. Back up `.reflex/config.toml` first, or leave `force` off: a normal incremental reindex already applies config changes.
:::

`languages` limits indexing to the named languages. This endpoint accepts `rust`/`rs`, `python`/`py`, `javascript`/`js`, `typescript`/`ts`, `vue`, `svelte`, `go`, `java`, `php`, `c`, and `cpp`/`c++`, and ignores other names.

**Response:** index statistics, in the same schema as `GET /stats`, plus change counts (`new_files`, `modified_files`, `unchanged_files`, `deleted_files`) when they're non-zero.

An unparseable body returns `400`:

```json
{"error":{"kind":"ParseError","message":"Invalid JSON body: key must be a string at line 1 column 2"}}
```

---

### `GET /health`

Health check endpoint.

**Response:**

```json
{"service":"reflex","status":"ok"}
```

---

## Errors

Errors are JSON objects with a `kind` and a `message`:

```json
{"error":{"kind":"QuerySyntaxError","message":"Query parameter 'q' cannot be empty"}}
```

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Invalid request: empty `q`, unknown `lang`, query syntax error, or invalid JSON body (`QuerySyntaxError`, `ParseError`) |
| 404 | No index found (`IndexNotFound`), or unknown endpoint (`NotFound`) |
| 500 | Internal error |

## Language identifiers

Use these values for the `lang` parameter of `GET /query` (case-insensitive):

| Language | Identifiers |
|----------|------------|
| Rust | `rust`, `rs` |
| TypeScript | `typescript`, `ts` |
| JavaScript | `javascript`, `js` |
| Python | `python`, `py` |
| Go | `go` |
| Java | `java` |
| C | `c` |
| C++ | `cpp`, `c++` |
| C# | `csharp`, `cs`, `c#` |
| Ruby | `ruby`, `rb` |
| PHP | `php` |
| Kotlin | `kotlin`, `kt` |
| Vue | `vue` |
| Svelte | `svelte` |
| Zig | `zig` |
| Plain text (docs, config, templates, extensionless files) | `text`, `txt`, `plaintext`, `plain` |
| Lock files | `lock`, `lockfile`, `lockfiles` |
| Generated files (`*.pb.go`, `*.min.js`, `*.map`, `*_generated.*`) | `generated`, `gen` |

Lock and generated files are indexed but left out of searches unless you select them with `lang=lock` or `lang=generated`.

## Security considerations

The HTTP server is designed for **local use only**:
- Binds to `127.0.0.1` by default
- No authentication mechanism
- CORS enabled for all origins (for local tool integration)

If you bind to a non-loopback address such as `0.0.0.0`, the server is accessible on your network and prints a warning at startup: `WARNING: Reflex server exposed on 0.0.0.0:7878 — NO authentication.` Use it only on trusted networks.

## Next steps

- [CLI Commands](/reference/cli-commands/) — `rfx serve` options
- [MCP Tools](/reference/mcp-tools/) — alternative integration via MCP protocol
- [AI Integration](/guides/ai-integration/) — patterns for agent integration
