---
name: 095-sync-remote
description: Sync with remote repository.
model: haiku
---

## Single Task
Synchronize local repository with remote.

## Execution
```bash
# Fetch all branches
git fetch --all --prune

# Check current status
git status

# Pull with rebase (if clean)
git pull --rebase origin $(git branch --show-current)

# Or merge if preferred
git pull origin $(git branch --show-current)

# Push local commits
git push origin $(git branch --show-current)
```

## Safety Checks
- Verify working tree is clean before pull
- Use `--rebase` only if no local merge commits
- Never force push to main

## Output
```json
{
  "status": "pass | fail",
  "branch": "main",
  "ahead": 0,
  "behind": 0,
  "synced": true
}
```

## Parallel-Safe: No (git operations)

## Parent: 009-git
