---
name: 122-asset-check
description: Verify _astro/ assets are accessible on GitHub Pages.
model: haiku
tools: [Bash]
---

## Single Task

Verify the `_astro/` directory assets (CSS/JS) return HTTP 200 on the live site.

## Why Critical

If `.nojekyll` is missing, GitHub Pages' Jekyll processor ignores `_astro/` and returns 404 for all assets.

## Execution

1. Find CSS filename from local docs/_astro/
2. Test that file returns HTTP 200 on live site

```bash
# Get CSS filename
CSS_FILE=$(ls docs/_astro/*.css | head -1 | xargs basename)

# Test live URL
curl -sI "https://kairin.github.io/win-qemu/_astro/${CSS_FILE}" | head -1
```

## Output Format

```json
{
  "css_file": "changelog.BttMfxTJ.css",
  "css_url": "https://kairin.github.io/win-qemu/_astro/changelog.BttMfxTJ.css",
  "css_status": 200,
  "nojekyll_working": true,
  "status": "pass"
}
```

## Failure Conditions

- HTTP 404 on CSS → `.nojekyll` missing or not deployed
- HTTP 403 → Permission issue
- HTTP 500 → Server error

## Auto-Fix: No (requires 121-nojekyll + redeploy)
## Parallel-Safe: Yes
## Parent: 012-astro
## Related: 121-nojekyll
