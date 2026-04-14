---
title: AI Integration
description: Connect Reflex to AI coding assistants via MCP and JSON output.
---

Reflex is designed for AI coding workflows. It provides an MCP server with 14 tools, structured JSON output for agent pipelines, and automatic freshness detection so agents always work with up-to-date results.

## MCP server

The Model Context Protocol (MCP) lets AI assistants like Claude use Reflex as a tool. Start the MCP server:

```bash
rfx mcp
```

### Claude Desktop / Claude Code configuration

Add Reflex to your Claude MCP config:

```json
{
  "mcpServers": {
    "reflex": {
      "command": "rfx",
      "args": ["mcp"],
      "cwd": "/path/to/your/project"
    }
  }
}
```

Once configured, Claude can search your codebase, analyze dependencies, and understand your code structure through 14 MCP tools. See [MCP Tools Reference](/reference/mcp-tools/) for the complete tool list.

## JSON output for agent pipelines

Every `rfx` command supports `--json` for structured output:

```bash
rfx query "authenticate" --symbols --json
```

```json
{
  "metadata": {
    "status": "fresh",
    "total_results": 1,
    "query_time_ms": 3,
    "current_branch": "main",
    "indexed_branch": "main"
  },
  "results": [
    {
      "file": "src/auth/mod.rs",
      "line": 42,
      "column": 8,
      "match": "pub fn authenticate(creds: &Credentials) -> Result<Session>",
      "symbol": "authenticate",
      "kind": "Function",
      "language": "rust"
    }
  ]
}
```

### Freshness status

The `metadata.status` field tells agents whether results are trustworthy:

| Status | Meaning | Action |
|--------|---------|--------|
| `fresh` | Index is up to date | Trust results |
| `branch_not_indexed` | Different branch than indexed | Run `rfx index` |
| `commit_changed` | New commits since indexing | Run `rfx index` |
| `files_modified` | Files changed on disk | Run `rfx index` |

When status isn't `fresh`, `metadata.action_required` contains the command to fix it (typically `rfx index`).

### Auto-reindexing pattern

The recommended pattern for AI agents:

```python
import subprocess
import json

def search(query, **kwargs):
    result = subprocess.run(
        ["rfx", "query", query, "--json", *[f"--{k}" for k in kwargs]],
        capture_output=True, text=True
    )
    data = json.loads(result.stdout)

    # Auto-reindex if stale
    if data["metadata"]["status"] != "fresh":
        subprocess.run(["rfx", "index"])
        result = subprocess.run(
            ["rfx", "query", query, "--json", *[f"--{k}" for k in kwargs]],
            capture_output=True, text=True
        )
        data = json.loads(result.stdout)

    return data["results"]
```

## Codebase context for prompts

Generate structured context about your project:

```bash
rfx context
```

This produces a summary including:
- Project structure and file types
- Framework detection
- Entry points
- Test layout
- Configuration files

Useful for seeding AI prompts with project understanding.

```bash
# Include specific context types
rfx context --structure --file-types --entry-points
```

## Best practices for AI integration

1. **Always use `--json`** for programmatic access — text output format may change
2. **Check `metadata.status`** before trusting results
3. **Auto-reindex on stale** — the overhead is typically ~200ms for incremental reindex
4. **Use symbol search** (`--symbols`) to reduce result noise for agents
5. **Set timeouts** — `--timeout 10` prevents runaway queries
6. **Branch awareness** — reindex after branch switches

## Next steps

- [MCP Tools Reference](/reference/mcp-tools/) — all 14 MCP tools with parameters
- [AI Query Assistant](/guides/ai-query-assistant/) — `rfx ask` for conversational code queries
- [CLI Commands](/reference/cli-commands/) — full JSON output reference
