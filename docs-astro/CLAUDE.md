# QEMU/KVM Documentation Website - Development Rules

> Astro.build + TailwindCSS v4.1+ + DaisyUI v5 documentation site

## TailwindCSS v4 Rules (MANDATORY)

These rules MUST be followed for all CSS and component development:

### Spacing & Layout
- Use `gap` instead of `space-x-*` or `space-y-*`
- Use `min-h-dvh` instead of `min-h-screen`
- Use `size-*` for equal width/height elements

### Colors & Opacity
- Use opacity modifiers: `bg-red-500/60` not `bg-opacity-60`
- Use `bg-linear-*` not `bg-gradient-*`

### Typography
- Use line-height modifiers: `text-base/7` not separate `leading-*`
- Use `text-wrap-balance` for headings

### Shadows & Borders
- `shadow-xs` (was `shadow-sm`)
- `shadow-sm` (was `shadow`)
- `rounded-sm` (was `rounded`)

### Prohibited
- NEVER use `@apply` - use utility classes directly
- NEVER use `space-x-*` or `space-y-*`
- NEVER use `bg-gradient-*`
- NEVER use `min-h-screen`

### DaisyUI Components
- Use DaisyUI semantic colors: `primary`, `secondary`, `accent`, `neutral`
- Use DaisyUI components: `btn`, `card`, `badge`, `alert`, `modal`
- Theme classes: `data-theme="nightowl"` (dark) or `data-theme="sunrise"` (light)

## Project Structure

```
docs-astro/
├── src/
│   ├── components/     # Reusable Astro components
│   │   ├── CodeBlock.astro
│   │   ├── ProgressTracker.astro
│   │   └── SearchModal.astro
│   ├── layouts/        # Page layouts
│   │   └── BaseLayout.astro
│   ├── pages/          # Route pages
│   │   └── index.astro
│   └── styles/         # Global CSS
│       └── app.css     # TailwindCSS + DaisyUI themes
├── public/             # Static assets
├── astro.config.mjs    # Astro configuration
└── package.json
```

## Themes

### Nightowl (Dark - Default)
- Primary: Vibrant purple `oklch(0.75 0.18 280)`
- Secondary: Teal blue `oklch(0.70 0.15 200)`
- Accent: Pink/magenta `oklch(0.80 0.20 320)`
- Base: Deep purple-black

### Sunrise (Light)
- Primary: Warm orange `oklch(0.60 0.20 30)`
- Secondary: Fresh green `oklch(0.55 0.15 150)`
- Accent: Golden yellow `oklch(0.70 0.18 45)`
- Base: Cream white

## Component Guidelines

### CodeBlock
- Include copy-to-clipboard functionality
- Support syntax highlighting
- Use `relative group` for hover states

### ProgressTracker
- Display project completion percentage
- Use DaisyUI `stats` component
- Include progress bars for sub-sections

### SearchModal
- Use Pagefind for full-text search
- Keyboard shortcut: Cmd/Ctrl + K
- Use DaisyUI `modal` component

## Build Commands

```bash
npm run dev      # Development server
npm run build    # Production build
npm run preview  # Preview production build
```

## Deployment

- Output directory: `../docs-site/`
- GitHub Pages via self-hosted runner
- Branch: `gh-pages`
