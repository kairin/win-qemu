---
name: 091-branch-create
description: Create constitutional branch.
model: haiku
---

## Single Task
Create new branch following naming convention.

## Execution
```bash
# Format: YYYYMMDD-HHMMSS-description
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH_NAME="${TIMESTAMP}-${DESCRIPTION}"

# Create and checkout
git checkout -b "$BRANCH_NAME"

# Verify
git branch --show-current
```

## Naming Convention
- Format: `YYYYMMDD-HHMMSS-description`
- Example: `20251128-143000-add-vm-template`
- Description: lowercase, hyphen-separated

## NEVER Delete
- main
- feature/* (after merge, archive only)

## Output
```json
{
  "status": "pass | fail",
  "branch_name": "20251128-143000-add-vm-template",
  "base_branch": "main"
}
```

## Parallel-Safe: No (git operations)

## Parent: 009-git
