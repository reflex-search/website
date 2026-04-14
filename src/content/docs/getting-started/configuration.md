---
title: Configuration
description: Configure Reflex with project settings, user preferences, and project context files.
---

Reflex uses three configuration layers, from most specific to most general:

## Project config — `.reflex/config.toml`

Created automatically when you first run `rfx index`. Controls indexing and search behavior for a single project.

```toml
[index]
# Languages to index (empty = all supported languages)
languages = []
# Maximum file size in bytes (default: 10MB)
max_file_size = 10485760
# Follow symbolic links during indexing
follow_symlinks = false

[search]
# Default result limit for queries
default_limit = 100

[performance]
# Number of parallel indexing threads (0 = auto, uses 80% of CPU cores)
parallel_threads = 0
```

### Common adjustments

**Index only specific languages:**

```toml
[index]
languages = ["rust", "typescript", "python"]
```

**Increase file size limit** for projects with large generated files:

```toml
[index]
max_file_size = 52428800  # 50MB
```

## User config — `~/.reflex/config.toml`

Stores personal settings that apply across all projects — primarily AI provider configuration for `rfx ask`.

```toml
[semantic]
provider = "anthropic"  # or "openai", "openrouter"

[credentials]
anthropic_api_key = "sk-ant-..."
anthropic_model = "claude-sonnet-4-20250514"

# Alternative: OpenAI
# openai_api_key = "sk-..."
# openai_model = "gpt-4o-mini"

# Alternative: OpenRouter
# openrouter_api_key = "sk-or-..."
# openrouter_model = "anthropic/claude-sonnet-4-20250514"
```

Use the interactive wizard to set this up:

```bash
rfx llm config
```

Check current configuration:

```bash
rfx llm status
```

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

## Forcing a full reindex

If you change configuration, rebuild the index:

```bash
rfx index --force
```

## Index-specific languages on demand

```bash
rfx index --languages rust,typescript
```

## Next steps

- [Full-Text Search](/guides/full-text-search/) — learn how trigram search works
- [AI Query Assistant](/guides/ai-query-assistant/) — use `rfx ask` with your configured provider
- [CLI Commands](/reference/cli-commands/) — complete command reference
