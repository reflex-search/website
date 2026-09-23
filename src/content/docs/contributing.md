---
title: Contributing
description: Development setup, code style, testing, and how to add language support.
---

Reflex is written in Rust. This guide covers everything you need to contribute.

## Prerequisites

- **Rust 1.89+** (edition 2024). `Cargo.toml` sets no `rust-version`; 1.89 is the oldest toolchain that compiles Reflex, because the index lock uses `File::try_lock`, stabilized in Rust 1.89. The code also uses let-chains, which need 1.88. CI builds with the latest stable.
- Git
- Optional: [lefthook](https://github.com/evilmartians/lefthook) for the pre-commit hook

## Development setup

```bash
git clone https://github.com/reflex-search/reflex.git
cd reflex
cargo build --release
cargo test
```

The `Makefile` wraps the common tasks. Run `make` (or `make help`) to list every target:

| Target | Runs |
|--------|------|
| `make build` / `make release` | Debug / optimized build (`target/release/rfx`) |
| `make check` | Fast type-check, no codegen |
| `make install` | `cargo install --path .` |
| `make fmt` / `make fmt-check` | Format / verify formatting |
| `make clippy` | Clippy with warnings as errors |
| `make test` | Unit and integration tests |
| `make pre-commit` | `fmt` + `clippy` + `test` |
| `make ci` | `fmt-check` + `clippy` + `test` |
| `make index` / `make serve` / `make mcp` | Run `rfx index`, `rfx serve`, or `rfx mcp` on the repo itself |
| `make doc` / `make doc-open` | API docs (`cargo doc --no-deps`) |
| `make clean-all` | Remove `target/` and the `.reflex/` cache |

### Pre-commit hook

The repo ships a `lefthook.yml` that runs `cargo fmt --all` on staged `.rs` files and re-stages the result:

```bash
lefthook install
```

### Running with debug output

```bash
RUST_LOG=debug cargo run -- query "pattern"

# Module-specific logging
RUST_LOG=reflex::query=debug cargo run -- query "pattern"

# Per-phase indexing timings
RUST_LOG=info cargo run --release -- index

# Per-phase query timings
cargo run --release -- query "pattern" --timing
```

### Generate documentation

```bash
cargo doc --no-deps --open
```

## Project structure

```
src/
├── main.rs              # CLI entry point
├── lib.rs               # Library root
├── cli/                 # Argument parsing and one handler module per command
├── models.rs            # Language enum, symbol kinds, config, shared types
├── cache.rs             # Cache manager (.reflex/ directory, meta.db schema)
├── indexer.rs           # Indexing engine (walk, read, hash, extract)
├── trigram.rs           # Trigram index format and posting-list intersection
├── trigram_build.rs     # Parallel construction of trigrams.bin
├── content_store.rs     # Memory-mapped content.bin
├── atomic_write.rs      # Crash-safe file replacement and the index lock
├── background_indexer.rs # Detached background symbol pass
├── symbol_cache.rs      # Symbol cache in meta.db
├── query/               # Query engine
│   ├── mod.rs           # Search pipeline
│   ├── open_index.rs    # Shared, reusable handle on the open index
│   ├── filter.rs        # Query filter types and filtering helpers
│   ├── result.rs        # Result assembly and file-id resolution
│   └── zero_hint.rs     # Why a search returned nothing
├── regex_trigrams.rs    # Literal extraction from regexes for trigram lookup
├── line_filter.rs       # Comment and string-literal detection
├── ast_query.rs         # Tree-sitter AST queries (--ast)
├── dependency.rs        # Dependency tracking and graph analysis
├── git.rs               # Git utilities for branch tracking and freshness
├── watcher.rs           # File watcher (rfx watch)
├── mcp.rs               # MCP server
├── formatter.rs         # Terminal formatting for query results
├── output.rs            # User-facing terminal messages
├── errors.rs            # Error types
├── context/             # rfx context (structure and project detection)
├── interactive/         # Interactive TUI (rfx query with no pattern)
├── semantic/            # rfx ask: LLM providers, agentic mode, chat
├── pulse/               # rfx pulse and rfx snapshot
└── parsers/
    ├── mod.rs           # Parser factory, grammars, combined per-language queries
    ├── rust.rs          # Rust parser
    ├── typescript.rs    # TypeScript and JavaScript parser
    ├── python.rs        # Python parser
    ├── go.rs            # Go parser
    ├── java.rs          # Java parser
    ├── c.rs             # C parser
    ├── cpp.rs           # C++ parser
    ├── csharp.rs        # C# parser
    ├── php.rs           # PHP parser
    ├── ruby.rs          # Ruby parser
    ├── kotlin.rs        # Kotlin parser
    ├── zig.rs           # Zig parser
    ├── vue.rs           # Vue parser (line-based)
    ├── svelte.rs        # Svelte parser (line-based)
    ├── swift.rs         # Swift parser (currently disabled)
    ├── preview.rs       # Bounded preview extraction shared by every parser
    └── tsconfig.rs      # tsconfig.json path-alias parsing
tests/                   # ~30 integration test files, plus corpus/ fixtures and insta snapshots/
benches/
├── trigram_bench.rs     # Criterion benchmarks
└── efficacy/            # Agent A/B efficacy benchmark harness
```

## Code style

- Standard Rust conventions: `rustfmt` + `clippy`
- Modules: `snake_case`
- Structs/enums: `PascalCase`
- Functions: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Error handling: `anyhow::Result`, `anyhow::bail!()`, `.context()`
- Public APIs must have rustdoc documentation

### Check formatting and lints

```bash
cargo fmt --check
cargo clippy --all-targets -- -D warnings
```

## Testing

### Unit tests

Embedded in source files as `#[cfg(test)]` modules:

```bash
cargo test --lib
```

### Integration tests

About 30 test files in `tests/`, each run as its own crate. A few examples:

| File | Covers |
|------|--------|
| `integration_test.rs` | End-to-end workflows |
| `symbol_equivalence.rs` | Symbol output snapshots (insta) |
| `tracked_mode.rs` | Tracked-files coverage and ripgrep parity |
| `glob_anchoring.rs` | Gitignore-style glob rules |
| `mcp_freshness.rs` | Freshness after edit, add, delete, revert, commit |
| `regex_candidate_lines.rs` | Regex literal extraction against the regex crate |

```bash
cargo test --test integration_test
```

### Performance tests

Latency tests are `#[ignore]`d by default; run them in release mode as CI does:

```bash
cargo test --release --test performance_test -- --ignored

# Latency harness over a synthetic 30 MB corpus, enforcing per-query budgets
REFLEX_LATENCY_BUDGET=1 cargo test --release --test latency_budget -- --ignored --nocapture --test-threads=1
```

### Benchmarks

```bash
cargo bench --bench trigram_bench
```

### Coverage goals

- New features must include tests
- Language parsers need 8–15 tests each
- Target >80% coverage on critical paths

## Commit messages

Reflex uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `chore`, `style`, `ci`, `build`

Breaking changes use a `BREAKING CHANGE:` footer or `!` after the type.

## Pull request checklist

- [ ] Tests pass (`cargo test`)
- [ ] Code formatted (`cargo fmt --check`)
- [ ] No clippy warnings (`cargo clippy --all-targets -- -D warnings`)
- [ ] Documentation updated if public API changed
- [ ] Commit messages follow conventional format
- [ ] PR description explains the change

`make ci` runs the first three in one go.

## Adding a new language

1. **Add the Tree-sitter grammar** to `Cargo.toml`
2. **Update the `Language` enum** in `src/models.rs` with the new variant, and mark it supported in `Language::is_supported`
3. **Map file extensions** in `Language::from_extension` in `src/models.rs` (`Language::from_path` is the one classifier the indexer, watcher, and query engine share)
4. **Create a parser** at `src/parsers/your_language.rs` implementing symbol extraction (and a `DependencyExtractor` for imports)
5. **Register the parser** in `src/parsers/mod.rs`: the grammar in `get_language_grammar`, and the `parse` dispatch
6. **Write tests** — 8–15 tests covering all symbol types
7. **Update documentation** — README, this website, and API docs

## Debugging tips

### Inspect the index

```bash
# Check database schema
sqlite3 .reflex/meta.db ".schema"

# View file list
sqlite3 .reflex/meta.db "SELECT path, language, line_count FROM files LIMIT 10;"

# Check index statistics
sqlite3 .reflex/meta.db "SELECT * FROM statistics;"

# Background symbol pass progress
rfx index status
```

### Inspect binary files

```bash
hexdump -C .reflex/trigrams.bin | head
hexdump -C .reflex/content.bin | head
```

## Release process

Releases are manual, using `cargo-release` and `cargo-dist`:

```bash
cargo install cargo-release   # one-time setup
cargo release patch           # or minor / major
```

`cargo-release` bumps the version in `Cargo.toml`, regenerates `CHANGELOG.md` with `git-cliff`, commits `chore: bump version to X.Y.Z`, and pushes the `vX.Y.Z` tag. The same can be started from GitHub under **Actions → Bump & Release**. Pushing the tag triggers the release workflow, which builds binaries for Linux, macOS, and Windows with `cargo-dist` and publishes a GitHub Release with the binaries and shell/PowerShell installers.

## Philosophy

Three guiding values:
1. **Speed** — sub-100ms queries are non-negotiable
2. **Accuracy** — deterministic, complete results
3. **Simplicity** — do fewer things well

## Next steps

- [Architecture](/reference/architecture/) — deep dive into the internals
- [Supported Languages](/reference/supported-languages/) — existing parser details
- [Changelog](https://github.com/reflex-search/reflex/releases) — version history
