---
title: Configuration
description: Configure Reflex with project settings, user preferences, and project context files.
---

Reflex uses three configuration layers, from most specific to most general:

## Project config — `.reflex/config.toml`

Created automatically when you first run `rfx index`. Controls indexing behavior for a single project.

```toml
[index]
# Languages to index (empty = all supported languages)
languages = []
# Also index docs, config and every other non-binary file as plain text
text_tier = true
# "tracked" (default): every non-binary file that is not gitignored and not
#   under a dot-directory — ripgrep's defaults
# "allowlist": code plus a fixed docs/config extension list
mode = "tracked"
# Also walk dot-directories and dotfiles (.githooks/, .env.example);
# .git/ and .reflex/ are never indexed
hidden = false
# Maximum file size in bytes (default: 10MB)
max_file_size = 10485760
# Follow symbolic links during indexing
follow_symlinks = false

[index.include]
# Only index files matching these patterns (empty = everything)
patterns = []

[index.exclude]
# Skip files matching these patterns
patterns = []

[performance]
# Indexing and query threads (0 = auto: 80% of CPU cores, at most 32)
parallel_threads = 0
# Background symbol pass threads (0 = auto: 50% of CPU cores, at most 32)
symbol_threads = 0
```

The generated file also contains `[search] default_limit` and `fuzzy_threshold`, `[performance] compression_level`, and a `[semantic]` section. Reflex does not read these from the project config — the query result limit comes from `--limit` (default 100), and AI provider settings live in your [user config](#user-config--reflexconfigtoml).

### Coverage tiers

In the default `tracked` mode, every file is indexed in one of these tiers:

- **Code** — the 15 languages with a Tree-sitter parser. Full-text, symbol, and dependency search.
- **Text** — docs, config, and any other non-binary file (including Swift, whose parser is currently disabled). Full-text search only; `--lang text` selects it.
- **Lock** and **Generated** — lock files (`Cargo.lock`, `package-lock.json`, `*.lock`, `go.sum`) and generated files (`*.pb.go`, `*.min.js`, `*.map`, `*_generated.*`). Indexed, but excluded from search results unless you pass `--include-locks` / `--include-generated` or select them with `--lang lock` / `--lang generated`.

Set `text_tier = false` to skip the text tier — useful for a repository with large generated JSON or vendored documentation, where index growth isn't worth it.

### Common adjustments

**Index only specific languages:**

```toml
[index]
languages = ["rust", "typescript", "python"]
```

**Exclude directories or files** — patterns follow `.gitignore` rules. A pattern containing `/` is anchored at the project root, a bare name (`*.rs`, `Makefile`) matches at any depth, a trailing `/` names a directory anywhere, and `*` does not cross `/`:

```toml
[index.exclude]
patterns = ["vendor/", "testdata/", "*.snap"]
```

**Increase file size limit** for projects with large generated files:

```toml
[index]
max_file_size = 52428800  # 50MB
```

## User config — `~/.reflex/config.toml`

Stores personal settings that apply across all projects — AI provider configuration for `rfx ask` and `rfx pulse`, and MCP server options.

```toml
[semantic]
provider = "anthropic"  # or "openai", "openrouter", "openai-compatible"
# model = "claude-3-5-haiku-20241022"  # Optional: overrides [credentials] <provider>_model

[credentials]
anthropic_api_key = "sk-ant-..."
anthropic_model = "claude-3-5-haiku-20241022"

# Alternative: OpenAI
# openai_api_key = "sk-..."
# openai_model = "gpt-4o-mini"

# Alternative: OpenRouter
# openrouter_api_key = "sk-or-..."
# openrouter_model = "anthropic/claude-sonnet-4"
# openrouter_sort = "price"  # or "throughput", "latency"

# Alternative: any OpenAI-compatible endpoint (e.g. a local server)
# openai_compatible_base_url = "http://localhost:11434/v1"
# openai_compatible_model = "your-model-name"
# openai_compatible_api_key = "..."  # Optional for keyless local servers

[mcp]
# Set to false to hide the structural analysis tools (find_circular, find_islands,
# find_unused, analyze_summary, get_transitive_deps) from MCP clients
enable_structural_tools = true
```

If no provider is set, Reflex uses `openai`. If no model is configured, each provider falls back to its default:

| Provider | Default model |
|----------|---------------|
| `openai` | `gpt-4o-mini` |
| `anthropic` | `claude-3-5-haiku-20241022` |
| `openrouter` | `anthropic/claude-sonnet-4` |
| `openai-compatible` | none — you must set a model |

Use the interactive wizard to set this up:

```bash
rfx llm config
```

Check current configuration:

```bash
rfx llm status
```

### Environment variables

Environment variables override or supplement the config files:

| Variable | Effect |
|----------|--------|
| `REFLEX_PROVIDER` | Overrides `[semantic] provider` |
| `REFLEX_MODEL` | Overrides `[semantic] model` |
| `REFLEX_AI_API_KEY` | API key for whichever provider is active (checked after `[credentials]`) |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `OPENAI_COMPATIBLE_API_KEY` | Provider-specific API keys (checked last) |
| `OPENAI_COMPATIBLE_BASE_URL`, `OPENAI_COMPATIBLE_MODEL` | Base URL and model for `openai-compatible` when not set in `[credentials]` |
| `REFLEX_LLM_TIMEOUT_SECONDS` | LLM request timeout in seconds (default 30) |
| `REFLEX_HOME` | Directory used in place of your home directory when locating `~/.reflex/config.toml` |
| `REFLEX_SYMBOL_THREADS` | Overrides `[performance] symbol_threads` |
| `REFLEX_INDEX_BATCH_FILES`, `REFLEX_INDEX_BATCH_BYTES` | Indexing batch size limits (defaults 5000 files, 48 MiB) |
| `REFLEX_FRESHNESS_TTL_MS` | How long `rfx mcp` / `rfx serve` reuse a freshness check before re-checking the working tree (default 1000 ms) |
| `REFLEX_MCP_COLUMNAR` | Set to `0` to return the file-grouped `results` array from MCP search tools instead of the columnar format |
| `REFLEX_MCP_TIMING` | Set to `1` to add per-phase `timings` to MCP `search_code` / `search_regex` responses |
| `REFLEX_SQLITE_JOURNAL` | SQLite journal mode for `meta.db` (default `WAL`) |
| `REFLEX_ALLOW_SCHEMA_REBUILD` | Allow `rfx index` to rebuild an index written by a different Reflex version without `--force` |

## Project context — `REFLEX.md`

An optional markdown file in your project root that gives Reflex (and its AI query assistant) context about your project. When present, `rfx ask` includes this context to provide better answers.

```markdown
# My Project

## Overview
A REST API service for managing user authentication.

## Architecture
- `src/auth/` — authentication logic
- `src/middleware/` — Express middleware
- `src/models/` — database models

## Conventions
- All API endpoints return JSON
- Error responses use the `ApiError` type
- Tests live alongside source files as `*.test.ts`
```

## Applying configuration changes

After editing `.reflex/config.toml`, run `rfx index` again. The next run applies the new settings — for example, files matching a new `[index.exclude]` pattern are dropped from the index.

To rebuild the index from scratch:

```bash
rfx index --force
```

:::caution
`--force` deletes everything in `.reflex/`, including `config.toml`, which is recreated with defaults. Back up your config before forcing a rebuild.
:::

## Index-specific languages on demand

```bash
rfx index --languages rust,typescript
```

## Next steps

- [Full-Text Search](/guides/full-text-search/) — learn how trigram search works
- [AI Query Assistant](/guides/ai-query-assistant/) — use `rfx ask` with your configured provider
- [CLI Commands](/reference/cli-commands/) — complete command reference
