---
name: 121-validate
description: Validate Astro build output.
model: haiku
tools: [Bash, Glob, Read]
---

## Single Task

Verify the docs/ build output contains all expected files and pages.

## Execution

1. Check `docs/index.html` exists
2. Check `docs/_astro/` directory exists
3. Check `docs/_astro/*.css` files exist
4. Check expected page directories:
   - docs/overview/index.html
   - docs/installation/index.html
   - docs/performance/index.html
   - docs/security/index.html
   - docs/changelog/index.html
5. Verify no broken asset references in HTML

## Output Format

```json
{
  "index_html": true,
  "astro_dir": true,
  "css_files": ["changelog.BttMfxTJ.css"],
  "pages": {
    "overview": true,
    "installation": true,
    "performance": true,
    "security": true,
    "changelog": true
  },
  "total_pages": 6,
  "status": "pass"
}
```

## Failure Conditions

- Missing index.html → Build failed
- Missing _astro/ → Build incomplete
- Missing pages → Check src/pages/ source

## Auto-Fix: No (rebuild required)
## Parallel-Safe: Yes
## Parent: 012-astro
