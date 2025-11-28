---
name: 112-directory-consolidate
description: Consolidate scattered files.
model: haiku
---

## Single Task
Move scattered files to correct directories.

## Directory Structure
```
win-qemu/
├── scripts/           # Shell scripts only
├── configs/           # XML/conf files
├── docs-repo/         # All documentation
│   ├── 01-setup/
│   ├── 02-operations/
│   ├── 03-performance/
│   ├── 04-security/
│   ├── 05-troubleshooting/
│   └── 06-constitutional/
├── .claude/           # Agent definitions
│   ├── agents/
│   ├── commands/
│   └── instructions-for-agents/
└── tests/             # Test scripts
```

## Execution
1. Identify misplaced files
2. Move to correct location
3. Update any references
4. Verify no broken links

## Rules
- .md files → docs-repo/
- .sh files → scripts/
- .xml files → configs/
- Test files → tests/

## Output
```json
{
  "status": "pass | fail",
  "files_moved": 3,
  "moves": [
    {"from": "old-guide.md", "to": "docs-repo/old-guide.md"}
  ]
}
```

## Parallel-Safe: No (file operations)

## Parent: 011-cleanup
