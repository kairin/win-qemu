---
name: 121-precheck
description: Verify Astro project structure before build.
model: haiku
tools: [Bash, Read, Glob]
---

## Single Task

Verify the docs-astro/ Astro project has all required files and dependencies before build.

## Execution

1. Check `docs-astro/package.json` exists
2. Check `docs-astro/astro.config.mjs` exists
3. Check `docs-astro/src/` directory exists
4. Check `docs-astro/node_modules/` exists (npm install ran)
5. Verify key dependencies in package.json:
   - astro
   - @astrojs/tailwind or tailwindcss
   - daisyui

## Output Format

```json
{
  "package_json": true,
  "astro_config": true,
  "src_directory": true,
  "node_modules": true,
  "dependencies": {
    "astro": "5.16.3",
    "tailwindcss": "4.1.17",
    "daisyui": "5.5.5"
  },
  "status": "pass"
}
```

## Failure Conditions

- Missing package.json → "Run npm init in docs-astro/"
- Missing node_modules → "Run npm install in docs-astro/"
- Missing astro.config.mjs → "Astro not configured"

## Auto-Fix: No (requires user action)
## Parallel-Safe: Yes
## Parent: 012-astro
