---
name: 122-url-test
description: Test all page URLs return HTTP 200.
model: haiku
tools: [Bash]
---

## Single Task

Test that all documentation pages return HTTP 200 on the live site.

## Pages to Test

1. https://kairin.github.io/win-qemu/ (index)
2. https://kairin.github.io/win-qemu/overview/
3. https://kairin.github.io/win-qemu/installation/
4. https://kairin.github.io/win-qemu/performance/
5. https://kairin.github.io/win-qemu/security/
6. https://kairin.github.io/win-qemu/changelog/

## Execution

```bash
BASE="https://kairin.github.io/win-qemu"
for page in "" "/overview/" "/installation/" "/performance/" "/security/" "/changelog/"; do
  STATUS=$(curl -sI "${BASE}${page}" | head -1 | awk '{print $2}')
  echo "${page:-/}: $STATUS"
done
```

## Output Format

```json
{
  "pages_tested": 6,
  "pages_passed": 6,
  "results": {
    "/": 200,
    "/overview/": 200,
    "/installation/": 200,
    "/performance/": 200,
    "/security/": 200,
    "/changelog/": 200
  },
  "status": "pass"
}
```

## Failure Conditions

- Any page 404 → Page not built or path wrong
- Any page 500 → Server error
- Mixed results → Partial deployment

## Auto-Fix: No
## Parallel-Safe: Yes
## Parent: 012-astro
