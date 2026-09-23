# Reflex Documentation Website

Marketing landing page and documentation site for [Reflex](https://github.com/reflex-search/reflex), a local-first code search engine.

## Stack

- **Astro Starlight** — documentation framework
- **Custom landing page** at `/` (`src/pages/index.astro`)
- **Docs** served at root (e.g., `/getting-started/`, `/guides/`, `/reference/`)
- Dark-only theme (no toggle)
- JetBrains Mono for all headings

## Project structure

```
src/
├── pages/index.astro          # Landing page (not Starlight)
├── content/docs/              # All documentation pages (Markdown)
│   ├── getting-started/       # Installation, quick start, config
│   ├── guides/                # Feature guides (search, deps, AI, etc.)
│   └── reference/             # CLI, API, MCP, languages, architecture
├── components/                # Starlight overrides (dark theme)
├── styles/custom.css          # Theme colors, fonts, spacing
└── assets/logo.svg            # Header logo
public/favicon.svg             # Favicon
public/casts/                  # asciinema recordings embedded in pages
scripts/casts/                 # Scripts that record the casts
repos/reflex/                  # Source repo (git submodule, read-only)
```

## Development

```bash
npm run dev        # Start dev server
npm run build      # Production build
npm run preview    # Preview production build
```

## Adding/editing docs

- All docs are static Markdown in `src/content/docs/`
- Sidebar is explicitly configured in `astro.config.mjs`
- When adding a new page, add its sidebar entry in `astro.config.mjs`
- Content is adapted from source docs in `repos/reflex/` but not dynamically imported
- Verify facts against the rfx source code, `rfx --help`, and real output — the upstream `docs/` folder is partly stale

## Recording casts

Casts are recorded against an indexed checkout of the reflex repo (`REFLEX_DIR`), with asciinema (`nix shell nixpkgs#asciinema`):

```bash
# Scripted demos (94x30), one per guide
REFLEX_DIR=... asciinema rec --headless --window-size 94x30 -f asciicast-v2 --overwrite \
  -c "bash scripts/casts/demo-fulltext.sh" public/casts/demo-fulltext.cast
REFLEX_DIR=... scripts/casts/record-live.sh sanitize public/casts/demo-fulltext.cast  # after recording ends

# Live demos driven through tmux: query-interactive | ask-interactive | hero
REFLEX_DIR=... scripts/casts/record-live.sh hero
```

The `hero` cast needs `.mcp.json` (rfx mcp) and `.claude/settings.local.json` (allow `mcp__reflex`) in `REFLEX_DIR`. Keep the `rows`/`cols` of each `<AsciinemaPlayer>` equal to the cast size.

## Theme

- Colors derived from the Reflex logo: dark navy bg (#1a2530), orange accent (#e8722a), cream text (#e8dcc8)
- Dark mode enforced via `src/components/ForceDarkTheme.astro`
- Theme toggle hidden via `src/components/EmptyComponent.astro`

## Deployment

GitHub Pages via `.github/workflows/deploy.yml`. Push to `main` triggers build and deploy.
