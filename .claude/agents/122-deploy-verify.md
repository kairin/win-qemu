---
name: 122-deploy-verify
description: Verify GitHub Pages deployment is live.
model: haiku
tools: [Bash, WebFetch]
---

## Single Task

Verify the GitHub Pages deployment at https://kairin.github.io/win-qemu/ is live and serving content.

## Execution

1. Wait 30 seconds for GitHub Pages rebuild
2. Fetch the site URL
3. Check HTTP status is 200
4. Verify HTML content is returned (not error page)

```bash
sleep 30
curl -sI https://kairin.github.io/win-qemu/ | head -1
curl -s https://kairin.github.io/win-qemu/ | grep -c "<html"
```

## Output Format

```json
{
  "url": "https://kairin.github.io/win-qemu/",
  "http_status": 200,
  "has_html": true,
  "deployment_time_seconds": 30,
  "status": "pass"
}
```

## Failure Conditions

- HTTP 404 → Check GitHub Pages settings
- HTTP 500 → GitHub Pages error
- No HTML → Build output incorrect

## Auto-Fix: No
## Parallel-Safe: Yes
## Parent: 012-astro
