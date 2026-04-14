---
title: Full-Text Search
description: Understand how Reflex's trigram-based search engine finds every occurrence in your codebase.
---

Reflex's core search mode uses **trigram indexing** — the same technique behind Google Code Search and Zoekt. Every query finds every matching occurrence, not just definitions or references.

## How trigram search works

A trigram is a sequence of three consecutive characters. When Reflex indexes your code, it extracts every trigram from every file and builds an inverted index mapping each trigram to the files that contain it.

For a query like `handleRequest`:
1. Reflex extracts trigrams: `han`, `and`, `ndl`, `dle`, `leR`, `eRe`, `Req`, `equ`, `que`, `ues`, `est`
2. Looks up each trigram in the inverted index to get candidate files
3. Intersects the candidate lists (AND operation) — only files containing *all* trigrams survive
4. Scans the candidates to verify actual matches and extract line numbers

This narrows the search space by **100–1000x** before any file scanning, which is why queries run in single-digit milliseconds on most codebases.

## Basic queries

```bash
# Simple text search
rfx query "handleRequest"

# Case-sensitive by default
rfx query "HandleRequest"   # different from above

# Phrases with spaces
rfx query "function validate"
```

## Filtering results

### By language

```bash
rfx query "import" --lang typescript
rfx query "use " --lang rust
```

### By file path

```bash
rfx query "TODO" --paths "src/api/"
```

### Limit results

```bash
rfx query "error" --limit 20
```

### Timeout

Long-running queries can be capped:

```bash
rfx query "a]" --timeout 5
```

The default timeout is 30 seconds.

## Understanding results

A typical result looks like:

```
src/auth/handler.rs:42  pub fn authenticate(creds: &Credentials) -> Result<Session> {
```

Format: `file:line  matching_line_content`

Results are sorted by file path, then line number.

## Performance characteristics

| Codebase size | Typical query time |
|---|---|
| Small (< 1,000 files) | 2–3ms |
| Medium (1,000–10,000 files) | 10–50ms |
| Large (60,000+ files, e.g. Linux kernel) | 100–250ms |

Performance comes from three techniques:
- **Trigram indexing** — eliminates most files before scanning
- **Memory-mapped I/O** — OS-level caching of index and content files
- **Incremental indexing** — blake3 hashing detects changes instantly

## When to use full-text vs. other modes

| Use case | Mode |
|---|---|
| Find all occurrences of a string | Full-text search (this page) |
| Find only definitions (functions, classes) | [Symbol search](/guides/symbol-search/) |
| Pattern matching with wildcards | [Regex search](/guides/regex-ast/) |
| Structural code patterns | [AST patterns](/guides/regex-ast/#ast-pattern-matching) |

## Next steps

- [Symbol Search](/guides/symbol-search/) — filter results to symbol definitions
- [Regex & AST Patterns](/guides/regex-ast/) — pattern matching and structural queries
- [CLI Commands](/reference/cli-commands/) — full `rfx query` reference
