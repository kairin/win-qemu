---
name: 122-git-sync
description: Sync docs/ directory with git staging.
model: haiku
tools: [Bash]
---

## Single Task

Stage all changes in docs/ directory for git commit.

## Execution

```bash
git -C /home/kkk/Apps/win-qemu add docs/
git -C /home/kkk/Apps/win-qemu status --porcelain docs/
```

## Pre-Conditions

- 121-validate must pass
- 121-nojekyll must pass

## Output Format

```json
{
  "files_staged": 15,
  "additions": 10,
  "modifications": 3,
  "deletions": 2,
  "status": "pass"
}
```

## Notes

- This agent only stages files
- Actual commit is delegated to 009-git for constitutional compliance
- Never commits directly (preserves branch workflow)

## Auto-Fix: No
## Parallel-Safe: Yes (read-only git status)
## Parent: 012-astro
