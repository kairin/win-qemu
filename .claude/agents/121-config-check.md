---
name: 121-config-check
description: Verify astro.config.mjs compliance.
model: haiku
tools: [Read, Grep]
---

## Single Task

Validate `docs-astro/astro.config.mjs` has correct configuration for GitHub Pages deployment.

## Required Configuration

```javascript
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/win-qemu/',           // MUST match repo name
  outDir: '../docs',            // MUST output to docs/
  // ...
});
```

## Execution

1. Read `docs-astro/astro.config.mjs`
2. Verify `base` is `/win-qemu/`
3. Verify `outDir` is `../docs`
4. Verify `site` is correct
5. Check Tailwind CSS v4 vite plugin configured

## Output Format

```json
{
  "base_path": "/win-qemu/",
  "base_correct": true,
  "out_dir": "../docs",
  "out_dir_correct": true,
  "site_url": "https://kairin.github.io",
  "tailwind_configured": true,
  "status": "pass"
}
```

## Failure Conditions

- Wrong base path → Assets won't load on GitHub Pages
- Wrong outDir → Build goes to wrong location
- Missing Tailwind → Styles won't compile

## Auto-Fix: No (config requires review)
## Parallel-Safe: Yes
## Parent: 012-astro
