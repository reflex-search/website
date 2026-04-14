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

## Theme

- Colors derived from the Reflex logo: dark navy bg (#1a2530), orange accent (#e8722a), cream text (#e8dcc8)
- Dark mode enforced via `src/components/ForceDarkTheme.astro`
- Theme toggle hidden via `src/components/EmptyComponent.astro`

## Deployment

GitHub Pages via `.github/workflows/deploy.yml`. Push to `main` triggers build and deploy.
