---
title: Installation
description: Install Reflex and get your project set up for code search.
---

Reflex is a local-first code search engine that combines trigram indexing for full-text search with Tree-sitter parsing for symbol extraction and static analysis for dependency tracking. Unlike symbol-only tools, Reflex finds **every occurrence** of a pattern with deterministic, repeatable results.

## Install

Choose your preferred installer:

```bash
# npm (recommended — includes prebuilt binaries)
npm install -g reflex-search

# Shell installer (Linux, macOS)
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/reflex-search/reflex/releases/latest/download/reflex-search-installer.sh | sh

# PowerShell installer (Windows)
powershell -ExecutionPolicy Bypass -c "irm https://github.com/reflex-search/reflex/releases/latest/download/reflex-search-installer.ps1 | iex"

# cargo (builds from source, requires Rust toolchain)
cargo install reflex-search
```

The npm package and the shell/PowerShell installers download a prebuilt binary for Linux and macOS (x86_64 and arm64) or Windows (x86_64). The installers place `rfx` in `$CARGO_HOME/bin` (usually `~/.cargo/bin`).

## Verify the installation

```bash
rfx --version
```

You should see output like `rfx 2.0.0`.

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

:::caution[Upgrading from 1.x]
Reflex 2.0 changes the on-disk index formats (`trigrams.bin` V4, `content.bin` V2), so every existing `.reflex/` index needs a one-time full rebuild. Run this once in each indexed project after upgrading:

```bash
rfx index --force
```

An index written by Reflex 1.7.2 or later records the version that wrote it, and a plain `rfx index` from 2.0 refuses to update it (`this .reflex/ was written by reflex 1.7.2 …`). `--force` clears `.reflex/` and rebuilds from scratch. Because it clears the whole directory, `.reflex/config.toml` is recreated with defaults — copy it somewhere first if you customized it.
:::

## What's inside `.reflex/`

| File | Purpose |
|------|---------|
| `meta.db` | SQLite metadata: file list with per-file fingerprints (size, mtime, blake3 hash), symbol cache, dependency graph, stats |
| `meta.db-wal`, `meta.db-shm` | SQLite write-ahead log files, present while `meta.db` is open (it runs in WAL mode) |
| `trigrams.bin` | Trigram inverted index for fast full-text search (memory-mapped) |
| `content.bin` | Full file contents for result display (memory-mapped) |
| `config.toml` | Project-level configuration |
| `index.lock` | Workspace lock file, locked while an index write is in progress |
| `indexing.lock`, `indexing.status` | Lock and progress file for the background symbol pass (`rfx index status` reads the status) |
| `trigram_temp/` | Transient: partial trigram batches during a large rebuild, removed when indexing finishes |

## System requirements

- **Node.js 14+** (for npm install) or **Rust 1.89+** (for cargo install)
- Works on Linux, macOS, and Windows
- No external services or network access required

## Next steps

Head to the [Quick Start](/getting-started/quick-start/) to index your first project and run queries, or see [Configuration](/getting-started/configuration/) to customize Reflex for your workflow.
