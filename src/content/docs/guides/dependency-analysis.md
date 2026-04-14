---
title: Dependency Analysis
description: Track imports, find reverse dependencies, and analyze your codebase's dependency graph.
---

Reflex tracks file-level dependencies by extracting import/require/use statements from your code. This powers reverse lookups, circular dependency detection, hotspot analysis, and more.

## Per-file dependencies with `rfx deps`

See what a specific file imports:

```bash
rfx deps src/auth/handler.rs
```

```
src/auth/handler.rs
├── src/auth/credentials.rs (internal)
├── src/auth/session.rs (internal)
├── src/models/user.rs (internal)
├── anyhow (external)
└── std::collections::HashMap (stdlib)
```

### Reverse dependencies

Find every file that imports a given file:

```bash
rfx deps src/auth/handler.rs --reverse
```

This answers "what breaks if I change this file?" — essential for safe refactoring.

### Deeper traversal

Explore transitive dependencies:

```bash
rfx deps src/main.rs --depth 3
```

### Output formats

```bash
# Tree view (default)
rfx deps src/main.rs --format tree

# Table view
rfx deps src/main.rs --format table

# JSON for scripting
rfx deps src/main.rs --json
```

## Codebase analysis with `rfx analyze`

Analyze your entire dependency graph:

### Circular dependencies

```bash
rfx analyze --circular
```

Finds dependency cycles (A → B → C → A) that can cause build issues and architectural problems.

### Hotspots

```bash
rfx analyze --hotspots
```

Identifies files with the highest fan-in (most depended upon). These are your highest-impact files — changes here affect the most code.

### Unused files

```bash
rfx analyze --unused
```

Finds files that nothing imports — potential dead code candidates.

### Isolated subgraphs

```bash
rfx analyze --islands
```

Detects disconnected clusters of files that have no dependency relationship with the rest of your codebase.

### Pagination

For large results, use `--limit` and `--offset`:

```bash
rfx analyze --hotspots --limit 20 --offset 0
rfx analyze --hotspots --limit 20 --offset 20
```

Or get everything at once:

```bash
rfx analyze --hotspots --all --json
```

## Dependency types

Reflex classifies every dependency into one of three types:

| Type | Description | Example |
|------|-------------|---------|
| `internal` | Files within your project | `use crate::auth::handler` |
| `external` | Third-party packages | `use anyhow::Result` |
| `stdlib` | Standard library | `use std::collections::HashMap` |

## Supported languages

Dependency extraction works across 12 languages. See [Supported Languages](/reference/supported-languages/) for the full matrix of what import syntax each language supports.

| Language | Import syntax |
|----------|--------------|
| Rust | `use`, `mod`, `extern crate` |
| TypeScript/JavaScript | `import`, `require()` |
| Python | `import`, `from...import` |
| Go | `import` |
| Java/Kotlin | `import` |
| C/C++ | `#include` |
| C# | `using` |
| PHP | `use`, `require`, `include` |
| Ruby | `require`, `require_relative` |
| Vue/Svelte | imports from `<script>` blocks |

## Adding dependency context to searches

Add `--dependencies` to a regular query to see import context alongside search results:

```bash
rfx query "handleRequest" --dependencies
```

This enriches each result with the file's direct dependencies, useful for understanding the context around a match.

## Next steps

- [AI Integration](/guides/ai-integration/) — dependency data is available through MCP tools
- [CLI Commands](/reference/cli-commands/) — full `rfx deps` and `rfx analyze` reference
- [Architecture](/reference/architecture/) — how the dependency index works internally
