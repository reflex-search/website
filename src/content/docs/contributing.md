---
title: Contributing
description: Development setup, code style, testing, and how to add language support.
---

Reflex is written in Rust. This guide covers everything you need to contribute.

## Prerequisites

- **Rust 1.75+** (edition 2024)
- Git

## Development setup

```bash
git clone https://github.com/reflex-search/reflex.git
cd reflex
cargo build --release
cargo test
```

### Running with debug output

```bash
RUST_LOG=debug cargo run -- query "pattern"

# Module-specific logging
RUST_LOG=reflex::query=debug cargo run -- query "pattern"
```

### Generate documentation

```bash
cargo doc --open
```

## Project structure

```
src/
├── main.rs              # CLI entry point
├── cache.rs             # Cache manager (.reflex/ directory)
├── indexer.rs           # Trigram indexer
├── trigram.rs            # Trigram extraction and index
├── content_store.rs     # Binary content storage
├── query.rs             # Query engine
├── models.rs            # Language enum, shared types
├── parsers/
│   ├── mod.rs           # Parser factory
│   ├── rust.rs          # Rust parser
│   ├── typescript.rs    # TypeScript parser
│   ├── javascript.rs    # JavaScript parser
│   ├── python.rs        # Python parser
│   ├── go.rs            # Go parser
│   ├── java.rs          # Java parser
│   ├── c.rs             # C parser
│   ├── cpp.rs           # C++ parser
│   ├── csharp.rs        # C# parser
│   ├── php.rs           # PHP parser
│   ├── ruby.rs          # Ruby parser
│   ├── kotlin.rs        # Kotlin parser
│   ├── vue.rs           # Vue parser
│   └── svelte.rs        # Svelte parser
└── ...
tests/
├── integration_test.rs  # End-to-end tests
└── performance_test.rs  # Latency benchmarks
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
cargo clippy -- -D warnings
```

## Testing

### Unit tests

Embedded in source files as `#[cfg(test)]` modules:

```bash
cargo test --lib
```

### Integration tests

End-to-end workflows in `tests/`:

```bash
cargo test --test integration_test
```

### Performance tests

Latency benchmarks (run in release mode):

```bash
cargo test --test performance_test --release
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

Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`

Breaking changes use a `BREAKING CHANGE:` footer or `!` after the type.

## Pull request checklist

- [ ] Tests pass (`cargo test`)
- [ ] Code formatted (`cargo fmt --check`)
- [ ] No clippy warnings (`cargo clippy -- -D warnings`)
- [ ] Documentation updated if public API changed
- [ ] Commit messages follow conventional format
- [ ] PR description explains the change

## Adding a new language

1. **Add the Tree-sitter grammar** to `Cargo.toml`
2. **Update the `Language` enum** in `src/models.rs` with the new variant
3. **Create a parser** at `src/parsers/your_language.rs` implementing symbol extraction
4. **Register the parser** in the factory at `src/parsers/mod.rs`
5. **Add file extensions** in `src/indexer.rs`
6. **Write tests** — 8–15 tests covering all symbol types
7. **Update documentation** — README, this website, and API docs

## Debugging tips

### Inspect the index

```bash
# Check database schema
sqlite3 .reflex/meta.db ".schema"

# View file list
sqlite3 .reflex/meta.db "SELECT * FROM files LIMIT 10;"

# Check index statistics
sqlite3 .reflex/meta.db "SELECT * FROM statistics;"
```

### Inspect binary files

```bash
hexdump -C .reflex/trigrams.bin | head
hexdump -C .reflex/content.bin | head
```

## Release process

Releases are automated via `release-plz`. Pushing to `main` triggers a version bump, CHANGELOG update, and release PR.

## Philosophy

Three guiding values:
1. **Speed** — sub-100ms queries are non-negotiable
2. **Accuracy** — deterministic, complete results
3. **Simplicity** — do fewer things well

## Next steps

- [Architecture](/reference/architecture/) — deep dive into the internals
- [Supported Languages](/reference/supported-languages/) — existing parser details
- [Changelog](/changelog/) — version history
