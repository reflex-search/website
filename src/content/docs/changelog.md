---
title: Changelog
description: Version history for Reflex.
---

All notable changes to Reflex are documented here. This project follows [Semantic Versioning](https://semver.org/).

## v1.1.1

Current release.

## v0.2.3 — 2025-11-04

### Changed
- Cargo.toml dependency updates

## v0.1.3 — 2025-11-03

### Fixed
- CI release status logging improvements

## v0.1.2 — 2025-11-03

### Fixed
- CI fixes for GitHub token configuration
- release-plz configuration updates

## v0.1.1 — 2025-11-03

### Added
- Query timeout support (`--timeout` flag, default 30s)
- HTTP API timeout handling
- MCP server timeout support

### Fixed
- CI pipeline fixes

## v1.0.0 — 2025-11-03

Initial release.

### Core
- Trigram-based full-text indexing with inverted index
- Runtime symbol detection via Tree-sitter (no parsing during indexing)
- Deterministic, repeatable search results
- Memory-mapped I/O for instant index loading
- Incremental indexing with blake3 content hashing
- Regular expression search with trigram optimization
- AST pattern matching via Tree-sitter S-expressions

### Languages
- Initial support: Rust, TypeScript, JavaScript, Vue, Svelte, PHP
- Symbol extraction for each language (functions, classes, structs, etc.)

### CLI
- `rfx index` — build/update search index (with `--force`, `--languages`)
- `rfx query` — search in 4 modes (full-text, symbol, regex, AST)
- `rfx stats` — index statistics
- `rfx clear` — remove index cache
- `rfx list-files` — list indexed files
- `rfx watch` — file watcher with auto-reindex
- `rfx serve` — HTTP API server
- `rfx mcp` — MCP server for AI assistants

### HTTP API
- `GET /query` — search with full parameter support
- `GET /stats` — index statistics
- `POST /index` — trigger reindexing
- `GET /health` — health check
- CORS enabled for local tool integration

### MCP Server
- `search_code`, `search_regex`, `search_ast`, `index_project`
- Standard MCP protocol compliance

### Performance
- Sub-100ms queries on 10,000+ file codebases
- 2–3ms typical queries on small codebases
- 124ms full-text search on Linux kernel (62,000 files)
- 224ms symbol search on Linux kernel

### Testing
- 221 tests: 194 unit, 17 integration, 10 performance
