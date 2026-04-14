---
title: Pulse
description: Generate a browsable intelligence site for your codebase — digests, wiki pages, and architecture maps.
---

:::caution
Pulse is a **preview feature**. Commands and output formats may change between releases.
:::

Pulse turns Reflex from a query tool into one that **proactively surfaces information** about your codebase. It generates a self-contained static site with three browsable surfaces grounded in index data.

## Quick start

```bash
# Generate the Pulse site
rfx pulse generate --output ./pulse-site

# Serve it locally
rfx pulse serve
```

That's it — open your browser and explore your codebase's structure, history, and architecture.

## What gets generated

The generated site includes three surfaces:

### Digest

A periodic summary of structural changes — not a git log, but an analysis of how your code's architecture is evolving. The digest reports on:

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

### Architecture map

A dependency graph at varying zoom levels, rendered as interactive diagrams.

## Generation options

```bash
rfx pulse generate \
  --output ./pulse-site \
  --title "My Project" \
  --theme dark \
  --no-llm           # Structural data only, no LLM narration
```

## Snapshots

Pulse is built on **snapshots** — point-in-time captures of your codebase's structural state. Comparing snapshots produces the diffs that power the digest.

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
