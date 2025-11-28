---
name: 093-merge-strategy
description: Execute merge to main.
model: haiku
---

## Single Task
Merge feature branch to main with proper strategy.

## Execution
```bash
# Ensure on feature branch
CURRENT=$(git branch --show-current)

# Switch to main
git checkout main

# Pull latest
git pull origin main

# Merge with no-ff (preserves history)
git merge --no-ff "$CURRENT" -m "Merge branch '$CURRENT'"

# Push to remote
git push origin main

# Do NOT delete the feature branch
```

## CRITICAL: Branch Preservation
- NEVER delete branches after merge
- Feature branches are archived, not deleted
- Use `--no-ff` to preserve merge history

## Output
```json
{
  "status": "pass | fail",
  "merged_branch": "20251128-143000-feature",
  "target": "main",
  "strategy": "no-ff"
}
```

## Parallel-Safe: No (git operations)

## Parent: 009-git
