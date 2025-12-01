---
name: 122-rollback
description: Rollback docs/ to previous state if deployment fails.
model: haiku
tools: [Bash]
---

## Single Task

Revert the docs/ directory to the previous git state if deployment verification fails.

## Execution

```bash
# Revert docs/ to last committed state
git -C /home/kkk/Apps/win-qemu checkout HEAD -- docs/

# Or revert to specific commit
git -C /home/kkk/Apps/win-qemu checkout <commit-sha> -- docs/
```

## When to Invoke

- 122-deploy-verify fails (site not live)
- 122-asset-check fails (CSS 404)
- 122-url-test fails (pages missing)

## Output Format

```json
{
  "rollback_performed": true,
  "previous_commit": "abc123",
  "files_reverted": 15,
  "reason": "CSS assets returning 404",
  "status": "rolled_back"
}
```

## Post-Rollback Actions

1. Alert user with failure reason
2. Suggest running 121-nojekyll
3. Suggest rebuilding with 121-build

## Auto-Fix: Yes (automatic revert)
## Parallel-Safe: No (modifies filesystem)
## Parent: 012-astro
## Severity: Recovery action
