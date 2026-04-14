---
title: Installation
description: Install Reflex and get your project set up for code search.
---

Reflex is a local-first code search engine that combines trigram indexing for full-text search with Tree-sitter parsing for symbol extraction and static analysis for dependency tracking. Unlike symbol-only tools, Reflex finds **every occurrence** of a pattern with deterministic, repeatable results.

## Install

Choose your preferred package manager:

```bash
# npm (recommended — includes prebuilt binaries)
npm install -g reflex-search

# cargo (builds from source, requires Rust toolchain)
cargo install reflex-search
```

## Verify the installation

```bash
rfx --version
```

You should see output like `reflex-search 1.1.1`.

## Project setup

Navigate to your project root and run:

```bash
rfx index
```

This creates a `.reflex/` directory containing the search index. Add it to your `.gitignore`:

```bash
echo '.reflex/' >> .gitignore
```

That's it — Reflex is ready. The index is fully local; no data leaves your machine.

## What's inside `.reflex/`

| File | Purpose |
|------|---------|
| `meta.db` | SQLite metadata (file list, stats, config) |
| `trigrams.bin` | Trigram inverted index for fast full-text search |
| `content.bin` | Memory-mapped file contents for result display |
| `config.toml` | Project-level configuration |

## System requirements

- **Node.js 18+** (for npm install) or **Rust 1.75+** (for cargo install)
- Works on Linux, macOS, and Windows
- No external services or network access required

## Next steps

Head to the [Quick Start](/getting-started/quick-start/) to index your first project and run queries, or see [Configuration](/getting-started/configuration/) to customize Reflex for your workflow.
