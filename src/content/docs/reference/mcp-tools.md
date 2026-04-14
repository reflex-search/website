---
title: MCP Tools
description: Complete reference for all 15 MCP tools exposed by Reflex's MCP server.
---

Reflex's MCP server (`rfx mcp`) exposes 15 tools through the Model Context Protocol. These tools let AI assistants search code, analyze dependencies, and understand your codebase.

## Search tools

### `search_code`

Full-text search across the codebase.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | yes | Search text |
| `language` | string | no | Filter by language |
| `limit` | int | no | Max results |

### `search_regex`

Search with regular expressions.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Regex pattern |
| `language` | string | no | Filter by language |
| `limit` | int | no | Max results |

### `search_ast`

Search using Tree-sitter AST patterns.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | yes | Tree-sitter S-expression |
| `language` | string | yes | Target language |
| `limit` | int | no | Max results |

### `list_locations`

Find all locations of a symbol or text pattern.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | yes | Search text |
| `symbols_only` | bool | no | Restrict to symbol definitions |
| `kind` | string | no | Symbol kind filter |

### `count_occurrences`

Count how many times a pattern appears without returning full results.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | yes | Search text |
| `language` | string | no | Filter by language |

## Index tools

### `index_project`

Trigger reindexing of the project.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `force` | bool | no | Force full rebuild |

## Dependency tools

### `get_dependencies`

Get direct dependencies of a file.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | yes | File path |

### `get_dependents`

Get files that depend on (import) a given file.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | yes | File path |

### `get_transitive_deps`

Get the full transitive dependency tree of a file.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | yes | File path |
| `depth` | int | no | Max traversal depth |

## Analysis tools

### `find_hotspots`

Find files with the highest fan-in (most depended upon).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | int | no | Number of results |

### `find_circular`

Detect circular dependency chains.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | int | no | Max cycles to return |

### `find_unused`

Find files that are never imported by other files.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | int | no | Number of results |

### `find_islands`

Find disconnected clusters of files with no dependency relationships to the rest of the codebase.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | int | no | Number of results |

### `analyze_summary`

Get a high-level summary of the codebase's dependency structure.

No parameters.

## Context tools

### `gather_context`

Collect comprehensive codebase information — project structure, frameworks, entry points, and file statistics. With no parameters, all context types are gathered.

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

## Setup

Add Reflex to your MCP client configuration:

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

## Next steps

- [AI Integration](/guides/ai-integration/) — integration patterns and best practices
- [Dependency Analysis](/guides/dependency-analysis/) — understanding the dependency graph
- [CLI Commands](/reference/cli-commands/) — `rfx mcp` reference
