---
name: 103-index-update
description: Update docs-repo/00-INDEX.md.
model: haiku
---

## Single Task
Update master documentation index with new/changed files.

## Index Location
`docs-repo/00-INDEX.md`

## Index Structure
```markdown
# Documentation Index

## Quick Links
- [Setup Guide](01-setup/...)
- [Operations](02-operations/...)

## Categories
### 01-setup/
- file1.md - Description
- file2.md - Description

### 02-operations/
...
```

## Execution
1. Scan docs-repo/ for all .md files
2. Compare with current index
3. Add new files with descriptions
4. Remove deleted files
5. Update modification dates

## Output
```json
{
  "status": "pass | fail",
  "files_indexed": 45,
  "files_added": 2,
  "files_removed": 0
}
```

## Parallel-Safe: No (file operations)

## Parent: 010-docs
