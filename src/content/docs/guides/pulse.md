---
title: Pulse
description: Generate a browsable intelligence site for your codebase — wiki pages, changelog, architecture maps, onboarding guide, timeline, glossary, and explorer.
---

Pulse turns Reflex from a query tool into one that **proactively surfaces information** about your codebase. It projects the structural facts the index already extracts — symbols, dependencies, hotspots, file churn — into a static documentation site and a set of standalone commands.

## Quick start

```bash
# Index first (Pulse reads from .reflex/)
rfx index

# Generate the Pulse site into ./pulse-site
rfx pulse generate

# Serve it locally at http://127.0.0.1:1111
rfx pulse serve --open
```

`rfx pulse generate` writes a [Zola](https://www.getzola.org/) project and builds it into static HTML in `pulse-site/public/`. You don't need to install Zola yourself: Reflex downloads a pinned release (v0.19.2, SHA-256 verified) to `~/.reflex/bin/zola` the first time it's needed. It fetches [Pagefind](https://pagefind.app/) the same way to build the site's search index. On a platform with no prebuilt Zola, install Zola yourself and run `zola build` inside the output directory.

## What gets generated

By default the site includes seven surfaces. Use `--include` to pick a subset:

```bash
rfx pulse generate --include wiki,map,onboard
```

| Surface | `--include` name | What it shows |
|---------|------------------|---------------|
| Wiki | `wiki` | One page per detected module (directory): dependencies, dependents, key symbols, metrics, and an optional LLM summary |
| Changelog | `changelog` | A product-level changelog built from recent git commits |
| Architecture map | `map` | Module-level dependency graph |
| Onboarding guide | `onboard` | Entry points (main files, CLI handlers, API routes) and a suggested reading order based on the dependency graph |
| Timeline | `timeline` | Development timeline from git history: contributors, file churn, weekly summaries |
| Glossary | `glossary` | Cross-cutting symbol glossary |
| Explorer | `explorer` | Interactive treemap of the whole codebase, sized by line count and colored by language (no LLM needed) |

## Generation options

```bash
rfx pulse generate \
  --output ./pulse-site \
  --title "My Project" \
  --base-url / \
  --no-llm
```

| Flag | Default | Description |
|------|---------|-------------|
| `-o, --output <DIR>` | `pulse-site` | Output directory for the Zola project |
| `--base-url <URL>` | `/` | Base URL for the site (maps to Zola's `base_url`) |
| `--title <TITLE>` | `<Directory> Documentation` | Site title |
| `--include <LIST>` | all surfaces | Comma-separated: `wiki,changelog,map,onboard,timeline,glossary,explorer` |
| `--no-llm` | — | Skip LLM narration |
| `--clean` | — | Clean the output directory before generating |
| `--force-renarrate` | — | Ignore the LLM cache and re-narrate everything |
| `--concurrency <N>` | `0` | Maximum concurrent LLM requests (`0` = unlimited) |
| `--depth <N>` | `2` | Maximum directory depth for module discovery (`1` = top-level only) |
| `--min-files <N>` | `1` | Minimum file count for a module to be included |

### Serving the site

```bash
rfx pulse serve                      # http://127.0.0.1:1111
rfx pulse serve --port 8080 --open   # custom port, open browser
rfx pulse serve --output ./docs-site # different project directory
```

`rfx pulse serve` runs Zola's built-in server with live reload. It expects a project that `rfx pulse generate` already created.

## Standalone commands

Each surface can also be generated on its own and printed to the terminal as Markdown:

```bash
# Changelog from the last 20 commits (default); --count to change
rfx pulse changelog --no-llm
rfx pulse changelog --count 50 --json --pretty

# Wiki pages (printed, or written as .md files with --output)
rfx pulse wiki --no-llm --output ./wiki

# Architecture map (mermaid by default, or d2)
rfx pulse map
rfx pulse map --format d2 --output architecture.d2
rfx pulse map --zoom src/query     # Zoom into one module

# Onboarding guide, timeline, glossary
rfx pulse onboard --no-llm
rfx pulse timeline
rfx pulse glossary --json
```

Example `rfx pulse map` output (Mermaid; each edge is labeled with its dependency count):

```
graph LR
  m_src["src/ (110 files)"]
  m_src_cli["src/cli/ (11 files)"]
  m_src_parsers["src/parsers/ (18 files)"]
  m_src_query["src/query/ (5 files)"]

  m_src_parsers -->|28| m_src
  m_src_query -->|24| m_src
  m_src_cli -->|22| m_src
```

## Snapshots

Pulse is built on **snapshots**: point-in-time captures of your codebase's structural state (file metadata, dependency edges, aggregate metrics). Each one is a standalone SQLite database in `.reflex/snapshots/`. A forced rebuild (`rfx index --force`) deletes everything in `.reflex/`, including your snapshots and the LLM cache. `rfx pulse generate` and `rfx pulse wiki` take a snapshot automatically if the index has changed since the last one.

Comparing two snapshots gives you a structural diff: files added, removed or modified, dependency edges added or removed, hotspot shifts, cycle changes, and threshold alerts.

```bash
# Take a snapshot
rfx snapshot

# Compare latest vs previous
rfx snapshot diff

# Compare specific snapshots
rfx snapshot diff --baseline <ID> --current <ID> --json --pretty

# List snapshots
rfx snapshot list

# Apply the retention policy
rfx snapshot gc
```

### Retention and thresholds

By default, Pulse keeps 7 daily, 4 weekly, and 12 monthly snapshots (~23 total). You can change this, and the alert thresholds used in diffs, in `.reflex/config.toml`:

```toml
[pulse.retention]
daily = 7
weekly = 4
monthly = 12

[pulse.thresholds]
fan_in_warning = 10       # Fan-in warning threshold
fan_in_critical = 25      # Fan-in critical threshold
cycle_length = 3          # Minimum cycle length to flag
module_file_count = 50    # Module file count warning
line_count_growth = 2.0   # Line count growth multiplier warning
```

## LLM narration

Narration is **on by default**. When an API key is available, the wiki, changelog, onboarding guide and glossary get LLM-written prose on top of the structural data. Pulse shares its provider configuration with [`rfx ask`](/guides/ai-query-assistant/): set it up with `rfx llm config` and check it with `rfx llm status`. If the configured provider has no API key, it falls back to the first of OpenRouter, Anthropic or OpenAI that has one.

If no provider is available, Pulse prints `LLM unavailable: ...` and continues with structural content only. Pass `--no-llm` to skip narration entirely. At the end of a run, `rfx pulse generate` reports its narration mode: `narrated`, `structural` (no LLM output), or `disabled` (`--no-llm`).

Narrated responses are cached in `.reflex/pulse/llm-cache/`, keyed by snapshot and structural context, so re-running `generate` with the same inputs doesn't call the LLM again (whatever the provider or model). Use `--force-renarrate` to bypass the cache.

## Design philosophy

Pulse follows a "structure first, prose only when grounded" principle:
- Structural claims come from the index (zero LLM)
- Narrative claims require grounding evidence
- Every assertion is traceable to index data

## Next steps

- [AI Query Assistant](/guides/ai-query-assistant/) — LLM provider setup for narration
- [Dependency Analysis](/guides/dependency-analysis/) — the dependency graph that powers Pulse
- [Architecture](/reference/architecture/) — how the index is stored
