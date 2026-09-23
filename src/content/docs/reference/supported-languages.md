---
title: Supported Languages
description: Languages supported by Reflex, with file extensions, symbol types, and dependency tracking.
---

Reflex parses 15 languages for symbol extraction and dependency tracking. Full-text and regex search go further: they cover every non-binary file in your project, using the same rules as ripgrep.

## Language matrix

| Language | Extensions | Symbol types | Dependency tracking |
|----------|-----------|--------------|-------------------|
| Rust | `.rs` | Function, Struct, Enum, Trait, Type, Constant, Variable, Method, Module, Macro, Attribute | Yes |
| TypeScript | `.ts`, `.tsx`, `.mts`, `.cts` | Function, Class, Interface, Type, Enum, Constant, Variable, Method | Yes |
| JavaScript | `.js`, `.jsx`, `.mjs`, `.cjs` | Function, Class, Constant, Variable, Method | Yes |
| Python | `.py` | Function, Class, Method, Constant, Variable | Yes |
| Go | `.go` | Function, Struct, Interface, Method, Constant, Variable | Yes |
| Java | `.java` | Class, Interface, Enum, Method, Variable, Attribute | Yes |
| C | `.c`, `.h` | Function, Struct, Enum, Type, Macro, Variable | Yes |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx`, `.C`, `.H` | Function, Class, Struct, Enum, Namespace, Method, Type, Variable | Yes |
| C# | `.cs` | Class, Struct, Interface, Enum, Method, Property, Variable, Namespace, Type, Event, Attribute | Yes |
| PHP | `.php` | Function, Class, Interface, Trait, Method, Constant, Variable, Namespace, Enum, Attribute | Yes |
| Ruby | `.rb`, `.rake`, `.gemspec` | Class, Module, Method, Constant, Property, Variable | Yes |
| Kotlin | `.kt`, `.kts` | Class, Interface, Method, Variable, Constant, Attribute | Yes |
| Vue | `.vue` | Function, Constant, Variable (from `<script>` blocks) | Yes |
| Svelte | `.svelte` | Function, Constant, Variable (from `<script>` blocks) | Yes |
| Zig | `.zig` | Function, Struct, Enum, Constant, Variable | Yes |

Reflex uses Tree-sitter 0.26. The grammars are the 0.23 releases, except `tree-sitter-kotlin-ng` 1.1.0 and `tree-sitter-zig` 1.1.2. JavaScript shares the TypeScript parser, and Vue and Svelte `<script>` blocks are extracted with regex-based parsers.

Symbols aren't extracted during `rfx index` itself. A background pass right after indexing parses each file once and caches its symbols, so symbol queries don't have to re-parse. `rfx index status` shows its progress.

### Swift

`.swift` files are recognized and indexed for full-text and regex search, but the Swift parser is currently disabled (its queries are out of date with the current grammar). Symbol search, AST queries and dependency analysis skip Swift files.

## Beyond code: text, lock and generated files

By default (`[index] mode = "tracked"`), Reflex indexes every file that isn't gitignored, isn't under a dot-directory, and isn't binary (a NUL byte marks a file as binary). Files that aren't in a parsed language fall into one of three tiers:

| Tier | `--lang` value | What's in it | Searched by default |
|------|----------------|--------------|---------------------|
| Text | `text` | Docs, config, templates, and extensionless files (`README`, `Makefile`, `Dockerfile`, `.md`, `.yaml`, `.toml`, `.json`, `.sql`, …) | Yes |
| Lock | `lock` | `Cargo.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Gemfile.lock`, `go.sum`, and any `*.lock` or `*-lock.json` | No: pass `--include-locks` or `--lang lock` |
| Generated | `generated` | `*.pb.go`, `*.min.js`, `*.min.css`, `*.map`, `*_generated.*`, `*.generated.*` | No: pass `--include-generated` or `--lang generated` |

These tiers get full-text and regex search only. They're never parsed for symbols or dependencies.

To go back to the pre-2.0 behavior (code plus a fixed list of docs and config extensions, with no lock or generated files), set `mode = "allowlist"` in the `[index]` section of `.reflex/config.toml`.

## Dependency import syntax

Each language's import statements are parsed for dependency tracking:

| Language | Import syntax |
|----------|--------------|
| Rust | `use crate::path`, `mod name`, `extern crate` |
| TypeScript/JavaScript | `import x from 'y'`, `require('y')` |
| Python | `import x`, `from x import y` |
| Go | `import "path"` |
| Java | `import com.example.Class` |
| Kotlin | `import com.example.Class` |
| C/C++ | `#include <header>`, `#include "header"` |
| C# | `using Namespace` |
| PHP | `use Namespace\\Class`, `require`/`require_once`, `include`/`include_once` |
| Ruby | `require 'gem'`, `require_relative 'file'` |
| Vue/Svelte | `import` from `<script>` blocks |
| Zig | `@import("file")` |

Only static imports (string literals) are tracked. Dynamic imports are filtered out.

## Dependency classification

Every detected dependency is classified as one of:

| Type | Description | Example |
|------|-------------|---------|
| **Internal** | Files within your project | `use crate::auth::handler` |
| **External** | Third-party packages | `import express from 'express'` |
| **Stdlib** | Standard library modules | `use std::collections::HashMap` |

Rust `mod name;` declarations are recorded as a fourth type, `mod_decl`. They describe parent-to-child module ownership, not usage.

## Special language features

### React (JSX/TSX)

JSX and TSX files are handled by the JavaScript and TypeScript parsers respectively. Component definitions are extracted as symbols.

### Vue and Svelte

Single-file components (`.vue`, `.svelte`) are parsed for:
- Functions, constants and variables declared in `<script>` blocks
- Import statements from `<script>` blocks for dependency tracking

## Adding language support

Reflex uses Tree-sitter grammars for parsing. Each language has a dedicated parser in `src/parsers/`, and file extensions are mapped in `src/models.rs`. See [Contributing](/contributing/) for how to add support for new languages.

## Next steps

- [Symbol Search](/guides/symbol-search/) — searching by symbol type
- [Dependency Analysis](/guides/dependency-analysis/) — import tracking and analysis
- [Architecture](/reference/architecture/) — how parsing works internally
