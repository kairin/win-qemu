---
name: 121-nojekyll
description: Create and verify .nojekyll for GitHub Pages.
model: haiku
tools: [Bash, Read, Write]
---

## Single Task

Ensure `.nojekyll` exists in BOTH source and output directories.

## Why Critical

GitHub Pages uses Jekyll by default, which **IGNORES folders starting with underscore** (`_`).

Without `.nojekyll`:
- The `_astro/` folder returns HTTP 404
- All CSS and JavaScript fails to load
- **Page appears completely blank**

This was the root cause of the 2025-11-30 incident.

## Execution

1. Check `docs-astro/public/.nojekyll` exists (source)
2. Check `docs/.nojekyll` exists (output)
3. If either missing, create empty file
4. Return status

```bash
# Check and create source
[ -f docs-astro/public/.nojekyll ] || touch docs-astro/public/.nojekyll

# Check and create output
[ -f docs/.nojekyll ] || touch docs/.nojekyll
```

## Output Format

```json
{
  "source_nojekyll": true,
  "output_nojekyll": true,
  "created": [],
  "status": "pass"
}
```

If created:
```json
{
  "source_nojekyll": true,
  "output_nojekyll": true,
  "created": ["docs/.nojekyll"],
  "status": "fixed"
}
```

## Auto-Fix: Yes

This agent will automatically create missing `.nojekyll` files.

## Parallel-Safe: Yes
## Parent: 012-astro
## Priority: CRITICAL
