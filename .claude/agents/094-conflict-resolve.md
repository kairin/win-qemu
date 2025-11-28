---
name: 094-conflict-resolve
description: Resolve merge conflicts.
model: haiku
---

## Single Task
Identify and resolve git merge conflicts.

## Execution
```bash
# List conflicted files
git status --porcelain | grep "^UU"

# Show conflict markers
git diff --name-only --diff-filter=U

# For each file, resolve conflicts
# Then mark as resolved
git add <resolved-file>

# Continue merge
git merge --continue
```

## Resolution Rules
1. Preserve all constitutional changes
2. Keep newer timestamp branches
3. Merge documentation additively
4. For code: prefer working version

## NEVER
- Use `--force` to override
- Delete conflicting branches
- Ignore constitutional rules

## Output
```json
{
  "status": "pass | fail",
  "conflicts_found": 2,
  "conflicts_resolved": 2,
  "files_affected": ["file1.md", "file2.sh"]
}
```

## Parallel-Safe: No (git operations)

## Parent: 009-git
