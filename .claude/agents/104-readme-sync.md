---
name: 104-readme-sync
description: Sync README with project state.
model: haiku
---

## Single Task
Update README.md to reflect current project state.

## Sections to Update
1. **Quick Start** - Verify commands work
2. **Prerequisites** - Match current requirements
3. **Installation** - Current package list
4. **Usage** - Current script names
5. **Status** - Phase completion

## Execution
1. Read current README.md
2. Verify all referenced files exist
3. Check all commands are valid
4. Update version numbers
5. Update status badges if present

## Output
```json
{
  "status": "pass | fail",
  "sections_updated": ["Quick Start", "Prerequisites"],
  "broken_links_fixed": 0,
  "outdated_commands_fixed": 1
}
```

## Parallel-Safe: No (file operations)

## Parent: 010-docs
