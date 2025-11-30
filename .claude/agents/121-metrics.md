---
name: 121-metrics
description: Calculate Astro build metrics.
model: haiku
tools: [Bash]
---

## Single Task

Calculate build size and page count metrics for the docs/ output.

## Execution

```bash
# Total size
du -sh docs/

# File counts
find docs/ -name "*.html" | wc -l
find docs/_astro/ -name "*.css" | wc -l
find docs/_astro/ -name "*.js" | wc -l

# Largest files
du -h docs/_astro/* | sort -hr | head -5
```

## Output Format

```json
{
  "total_size_kb": 450,
  "html_files": 6,
  "css_files": 1,
  "js_files": 0,
  "largest_files": [
    {"file": "_astro/changelog.BttMfxTJ.css", "size_kb": 89}
  ],
  "assets": {
    "og_image": true,
    "favicon": true,
    "fonts": true
  },
  "status": "pass"
}
```

## Thresholds (Advisory)

| Metric | Warning | Error |
|--------|---------|-------|
| Total size | > 5MB | > 20MB |
| CSS size | > 500KB | > 2MB |
| HTML files | < expected | 0 |

## Auto-Fix: No
## Parallel-Safe: Yes
## Parent: 012-astro
