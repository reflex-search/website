---
title: Pulse
description: Auto-generated codebase intelligence — digests, wiki pages, and architecture maps.
---

:::caution
Pulse is a **preview feature**. Commands and output formats may change between releases.
:::

Pulse turns Reflex from a query tool into one that **proactively surfaces information** about your codebase. It generates three browsable surfaces grounded in index data:

## Surfaces

### Digest

A periodic summary of structural changes in your codebase — not a git log, but an analysis of how your code's architecture is evolving.

```bash
rfx pulse digest
```

The digest reports on:
- Module activity and growth
- New symbols and removed symbols
- Dependency changes
- Hotspot movements
- Convention drift

### Wiki

One auto-generated documentation page per module. Each page includes:
- What the module does
- Its dependencies and dependents
- Key symbols
- Recent structural activity

```bash
rfx pulse wiki
```

### Architecture map

A generated dependency graph at varying zoom levels, output as Mermaid or D2 diagrams.

```bash
rfx pulse map
```

## Static site generation

Generate a complete, self-contained static HTML site with all three surfaces:

```bash
rfx pulse generate --output ./pulse-site
```

Options:

```bash
rfx pulse generate \
  --output ./pulse-site \
  --title "My Project" \
  --theme dark \
  --no-llm           # Structural data only, no LLM narration
```

Serve the generated site:

```bash
rfx pulse serve
```

Watch for changes and auto-regenerate:

```bash
rfx pulse watch
```

## Snapshots

Pulse is built on **snapshots** — point-in-time captures of your codebase's structural state. Comparing snapshots produces diffs that power the digest.

```bash
# Take a snapshot
rfx snapshot

# Compare snapshots
rfx snapshot diff

# List snapshots
rfx snapshot list

# Clean old snapshots
rfx snapshot gc
```

### Retention policy

By default, Pulse keeps 7 daily, 4 weekly, and 12 monthly snapshots (~23 total). Configure retention in your project config:

```toml
[pulse.retention]
daily = 7
weekly = 4
monthly = 12
```

## LLM narration

By default, Pulse uses structural data only (`--no-llm` equivalent). When an LLM provider is configured (via `rfx llm config`), Pulse can add narrative explanations grounded in the structural data.

Every narrative claim is backed by structural evidence — the LLM adds readability, not speculation.

## Design philosophy

Pulse follows a "structure first, prose only when grounded" principle:
- Structural claims come from the index (zero LLM)
- Narrative claims require grounding evidence
- Every assertion is traceable to index data

## Next steps

- [Configuration](/getting-started/configuration/) — LLM provider setup for narration
- [Dependency Analysis](/guides/dependency-analysis/) — the dependency graph that powers Pulse
- [Architecture](/reference/architecture/) — how the snapshot system works
