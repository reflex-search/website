---
title: AI Integration
description: Connect Reflex to AI coding assistants via MCP and JSON output.
---

Reflex is designed for AI coding workflows. It provides an MCP server with 17 tools, structured JSON output for agent pipelines, and a freshness check on every response so agents know when results may be incomplete.

## MCP server

The Model Context Protocol (MCP) lets AI assistants like Claude use Reflex as a tool. The server runs over stdio:

```bash
rfx mcp
```

You don't normally run this yourself: your MCP client launches it. The server uses its working directory as the project root, so the client should start it from your project directory.

### Claude Code configuration

Add Reflex with the `claude` CLI:

```bash
# This project only
claude mcp add reflex -- rfx mcp

# Shared with your team (writes .mcp.json in the project root)
claude mcp add --scope project reflex -- rfx mcp
```

Or create `.mcp.json` in your project root yourself:

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

Once configured, Claude can search your codebase, find references, analyze dependencies, and check index freshness through 17 MCP tools. On connect, the server also sends instructions telling the agent to prefer Reflex over grep and which argument names to use. See [MCP Tools Reference](/reference/mcp-tools/) for the complete tool list.

## JSON output for agent pipelines

`rfx query`, `deps`, `analyze`, `ask`, `context`, `stats`, `list-files`, `snapshot`, and most `pulse` subcommands support `--json` (add `--pretty` to format it):

```bash
rfx query "handle_ask" --symbols --json --pretty
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
      "path": "src/cli/ask.rs",
      "language": "rust",
      "matches": [
        {
          "kind": "Function",
          "symbol": "handle_ask",
          "span": {
            "start_line": 9,
            "end_line": 426
          },
          "preview": "pub(super) fn handle_ask(\n    question: Option<String>,\n    auto_execute: bool,\n   …"
        }
      ]
    }
  ]
}
```

Results are grouped by file. `kind` and `symbol` appear only on symbol matches. `context_before` / `context_after` appear with `-C`, and a file-level `dependencies` array appears with `--dependencies`.

`pagination.total` is exact only when `total_is_exact` is `true`. A search that stops once the page is full reports `total: null` and an `approx_total` estimate instead.

### Freshness status

Every query response carries `status` and `can_trust_results`:

| `status` | `can_trust_results` | Meaning |
|----------|---------------------|---------|
| `fresh` | `true` | Every indexed file matches what's on disk |
| `stale` | `false` | Files were edited, added, or deleted since the last index |

Freshness is judged by **file content** (size, modification time, and hash), not by commit or branch. Editing a file makes the index stale whether or not you commit. Committing already-indexed content, or switching to a branch with the same files, doesn't.

A stale response is still made of real matches, but it may be incomplete, and a deleted file can still produce hits at its old lines. It includes a `warning` object:

```json
{
  "status": "stale",
  "can_trust_results": false,
  "warning": {
    "reason": "Files changed since the index was built (2 modified, 1 added) — these results may not reflect them",
    "action_required": "index_project",
    "files_modified": ["src/storage/mod.rs", "src/lib.rs"],
    "files_added": ["src/storage/zz_probe.rs"],
    "changed_count": 3
  }
}
```

The file lists name the actual changed paths, and `truncated: true` means they were cut short. `action_required` names the MCP tool to call. From the CLI, run `rfx index`.

### Auto-reindexing pattern

The recommended pattern for AI agents:

```python
import subprocess
import json

def search(query, *flags):
    cmd = ["rfx", "query", query, "--json", *flags]
    data = json.loads(subprocess.run(cmd, capture_output=True, text=True).stdout)

    # Reindex and retry if the index is stale
    if data["status"] != "fresh":
        subprocess.run(["rfx", "index"])
        data = json.loads(subprocess.run(cmd, capture_output=True, text=True).stdout)

    return data["results"]
```

## Codebase context for prompts

Generate structured context about your project:

```bash
rfx context
```

With no flags, this shows every context type:
- Project structure and file types
- Project type (CLI, library, webapp, monorepo)
- Framework detection
- Entry points
- Test layout
- Configuration files

Useful for seeding AI prompts with project understanding.

```bash
# Include specific context types
rfx context --framework --entry-points

# Deeper tree for a monorepo subdirectory
rfx context --path services/backend --structure --depth 3

# Feed it to rfx ask
rfx ask "find auth" --additional-context "$(rfx context --framework)"
```

## Best practices for AI integration

1. **Use `--json`** (or MCP) for programmatic access, because the text output format may change
2. **Check `status`** (or `can_trust_results`) before relying on a result for find-all tasks like rename planning or impact analysis
3. **Reindex on stale**, since incremental reindexing only reprocesses changed files
4. **Use symbol search** (`--symbols`) or `find_references` to cut noise for agents
5. **Remember whole-identifier matching**: `verify_csrf` doesn't match `verify_csrf_form_field` unless you pass `--contains` (`contains: true` over MCP)
6. **Set timeouts**: `--timeout 10` (`-t 10`) caps a query at 10 seconds (default: 30, `0` = no timeout)

## Next steps

- [MCP Tools Reference](/reference/mcp-tools/) — all 17 MCP tools with parameters
- [AI Query Assistant](/guides/ai-query-assistant/) — `rfx ask` for conversational code queries
- [CLI Commands](/reference/cli-commands/) — full JSON output reference
