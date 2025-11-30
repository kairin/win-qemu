---
name: 121-build
description: Execute Astro npm build.
model: haiku
tools: [Bash]
---

## Single Task

Execute `npm run build` in docs-astro/ directory to generate static site output.

## Execution

```bash
npm --prefix /home/kkk/Apps/win-qemu/docs-astro run build
```

## Pre-Conditions

- 121-precheck must pass first
- 121-config-check should pass first

## Expected Output

Build should:
1. Generate output in `docs/` directory (per astro.config.mjs outDir: '../docs')
2. Create `_astro/` folder with hashed CSS/JS
3. Create `index.html` at root
4. Create page directories (overview/, installation/, etc.)

## Output Format

```json
{
  "build_success": true,
  "output_dir": "docs/",
  "pages_generated": 6,
  "build_time_ms": 2500,
  "status": "pass"
}
```

## Failure Conditions

- TypeScript errors → Report error location
- Missing dependencies → Run npm install
- Config errors → Check astro.config.mjs

## Auto-Fix: No
## Parallel-Safe: No (writes to filesystem)
## Parent: 012-astro
