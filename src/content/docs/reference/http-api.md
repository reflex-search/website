---
title: HTTP API
description: REST API endpoints for programmatic integration with Reflex.
---

Reflex includes an HTTP server for programmatic access. Start it with:

```bash
rfx serve                  # localhost:7878
rfx serve --port 8080      # custom port
rfx serve --host 0.0.0.0   # all interfaces (use with caution)
```

## Endpoints

### `GET /query`

Search the codebase.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | yes | Search query |
| `symbols` | bool | no | Only return symbol definitions |
| `regex` | bool | no | Treat query as regex |
| `exact` | bool | no | Exact match only |
| `lang` | string | no | Filter by language |
| `kind` | string | no | Filter by symbol kind |
| `file` | string | no | Filter by file path |
| `limit` | int | no | Max results (default: 100) |
| `expand` | bool | no | Include context lines |
| `timeout` | int | no | Timeout in seconds (default: 30) |

**Response:**

```json
{
  "status": "Fresh",
  "can_trust_results": true,
  "results": [
    {
      "file": "src/auth/handler.rs",
      "line": 42,
      "column": 8,
      "match": "pub fn authenticate(creds: &Credentials) -> Result<Session>",
      "symbol": "authenticate",
      "kind": "Function",
      "language": "rust",
      "context_before": ["/// Authenticate a user with credentials"],
      "context_after": ["    let user = lookup_user(&creds.username)?;"]
    }
  ]
}
```

**Status values:**

| Status | Meaning |
|--------|---------|
| `Fresh` | Index is up to date |
| `Stale` | Index may be outdated |
| `Missing` | No index found |

When `can_trust_results` is `false`, consider triggering a reindex via `POST /index`.

**Example:**

```bash
curl "http://localhost:7878/query?q=authenticate&symbols=true&kind=Function"
```

---

### `GET /stats`

Index statistics.

**Response:**

```json
{
  "total_files": 1247,
  "index_size_bytes": 4521984,
  "last_updated": "2025-11-04T10:30:00Z",
  "files_by_language": {
    "rust": 342,
    "typescript": 518,
    "python": 187
  },
  "lines_by_language": {
    "rust": 45200,
    "typescript": 62800,
    "python": 18400
  }
}
```

Returns `404` if no index exists.

---

### `POST /index`

Trigger reindexing. This is synchronous — the response returns after indexing completes.

**Request body:**

```json
{
  "force": false,
  "languages": ["rust", "typescript"]
}
```

Both fields are optional. When `force` is `true`, the entire index is rebuilt. When `languages` is provided, only those languages are indexed.

**Response:** Same schema as `GET /stats`.

---

### `GET /health`

Health check endpoint.

**Response:** `Reflex is running` (text/plain)

---

## Status codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Invalid query parameters |
| 404 | No index found (for `/stats`) |
| 500 | Internal error |

## Language identifiers

Use these values for the `lang` parameter:

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

## Security considerations

The HTTP server is designed for **local use only**:
- Binds to `127.0.0.1` by default
- No authentication mechanism
- CORS enabled for all origins (for local tool integration)

If you bind to `0.0.0.0`, the server is accessible on your network. Use only on trusted networks.

## Next steps

- [CLI Commands](/reference/cli-commands/) — `rfx serve` options
- [MCP Tools](/reference/mcp-tools/) — alternative integration via MCP protocol
- [AI Integration](/guides/ai-integration/) — patterns for agent integration
