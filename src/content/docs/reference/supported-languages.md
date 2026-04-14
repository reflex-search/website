---
title: Supported Languages
description: Languages supported by Reflex, with file extensions, symbol types, and dependency tracking.
---

Reflex supports 15 languages for full-text search and symbol extraction, with dependency tracking across all of them.

## Language matrix

| Language | Extensions | Symbol types | Dependency tracking |
|----------|-----------|--------------|-------------------|
| Rust | `.rs` | Function, Struct, Enum, Trait, Type, Constant, Method, Macro | Yes |
| TypeScript | `.ts`, `.tsx`, `.mts`, `.cts` | Function, Class, Interface, Type, Enum, Constant, Variable, Method | Yes |
| JavaScript | `.js`, `.jsx`, `.mjs`, `.cjs` | Function, Class, Constant, Variable, Method | Yes |
| Python | `.py` | Function, Class, Variable, Decorator | Yes |
| Go | `.go` | Function, Struct, Interface, Type, Constant, Variable, Method | Yes |
| Java | `.java` | Class, Interface, Enum, Method, Field, Annotation | Yes |
| C | `.c`, `.h` | Function, Struct, Enum, Type, Macro, Variable | Yes |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hh`, `.hxx` | Function, Class, Struct, Enum, Namespace, Method, Template | Yes |
| C# | `.cs` | Class, Struct, Interface, Enum, Method, Property, Field | Yes |
| PHP | `.php` | Function, Class, Interface, Trait, Method, Constant | Yes |
| Ruby | `.rb` | Class, Module, Method, Constant | Yes |
| Kotlin | `.kt`, `.kts` | Class, Interface, Function, Object, Property | Yes |
| Vue | `.vue` | Component, Function, Variable (from `<script>` blocks) | Yes |
| Svelte | `.svelte` | Component, Function, Variable (from `<script>` blocks) | Yes |
| Zig | `.zig` | Function, Struct, Enum, Union, Constant | Yes |

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
| PHP | `use Namespace\\Class`, `require 'file'`, `include 'file'` |
| Ruby | `require 'gem'`, `require_relative 'file'` |
| Vue/Svelte | `import` from `<script>` blocks |
| Zig | `@import("file")` |

## Dependency classification

Every detected dependency is classified as one of:

| Type | Description | Example |
|------|-------------|---------|
| **Internal** | Files within your project | `use crate::auth::handler` |
| **External** | Third-party packages | `import express from 'express'` |
| **Stdlib** | Standard library modules | `use std::collections::HashMap` |

## Special language features

### React (JSX/TSX)

JSX and TSX files are handled by the JavaScript and TypeScript parsers respectively. Component definitions are extracted as symbols.

### Vue and Svelte

Single-file components (`.vue`, `.svelte`) are parsed for:
- Component-level symbols
- Functions and variables declared in `<script>` blocks
- Import statements from `<script>` blocks for dependency tracking

## Adding language support

Reflex uses Tree-sitter grammars for parsing. Each language has a dedicated parser in the source. See [Contributing](/contributing/) for how to add support for new languages.

## Next steps

- [Symbol Search](/guides/symbol-search/) — searching by symbol type
- [Dependency Analysis](/guides/dependency-analysis/) — import tracking and analysis
- [Architecture](/reference/architecture/) — how parsing works internally
