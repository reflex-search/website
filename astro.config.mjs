// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://reflex-search.github.io',
	integrations: [
		starlight({
			title: 'Reflex',
			customCss: [
				'@fontsource-variable/jetbrains-mono',
				'./src/styles/custom.css',
			],
			components: {
				ThemeProvider: './src/components/ForceDarkTheme.astro',
				ThemeSelect: './src/components/EmptyComponent.astro',
			},
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/reflex-search/reflex',
				},
			],
			logo: {
				src: './src/assets/logo.svg',
				replacesTitle: true,
			},
			favicon: '/favicon.svg',
			sidebar: [
				{
					label: 'Getting Started',
					items: [
						{ label: 'Installation', slug: 'getting-started' },
						{ label: 'Quick Start', slug: 'getting-started/quick-start' },
						{ label: 'Configuration', slug: 'getting-started/configuration' },
					],
				},
				{
					label: 'Guides',
					items: [
						{ label: 'Full-Text Search', slug: 'guides/full-text-search' },
						{ label: 'Symbol Search', slug: 'guides/symbol-search' },
						{ label: 'Regex & AST Patterns', slug: 'guides/regex-ast' },
						{ label: 'Dependency Analysis', slug: 'guides/dependency-analysis' },
						{ label: 'AI Integration', slug: 'guides/ai-integration' },
						{ label: 'AI Query Assistant', slug: 'guides/ai-query-assistant' },
						{ label: 'Interactive Mode', slug: 'guides/interactive-mode' },
						{
							label: 'Pulse',
							slug: 'guides/pulse',
							badge: { text: 'Preview', variant: 'caution' },
						},
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'CLI Commands', slug: 'reference/cli-commands' },
						{ label: 'HTTP API', slug: 'reference/http-api' },
						{ label: 'MCP Tools', slug: 'reference/mcp-tools' },
						{ label: 'Supported Languages', slug: 'reference/supported-languages' },
						{ label: 'Architecture', slug: 'reference/architecture' },
					],
				},
				{ label: 'Contributing', slug: 'contributing' },
				{ label: 'Changelog', slug: 'changelog' },
			],
		}),
	],
});
