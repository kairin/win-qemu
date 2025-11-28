---
name: 113-safe-delete
description: Safely delete confirmed redundant files.
model: haiku
---

## Single Task
Delete files confirmed as redundant after review.

## Safety Protocol
1. **NEVER** delete without explicit approval
2. **NEVER** delete files in .git/
3. **NEVER** delete constitutional documents
4. **ALWAYS** backup before delete

## Protected Files (NEVER DELETE)
- AGENTS.md
- CLAUDE.md (symlink)
- GEMINI.md (symlink)
- docs-repo/06-constitutional/*
- Any file with "DO NOT DELETE" comment

## Execution
```bash
# Create backup first
mkdir -p .cleanup-backup/$(date +%Y%m%d)
cp "$FILE" .cleanup-backup/$(date +%Y%m%d)/

# Then delete
rm "$FILE"

# Log deletion
echo "$(date): Deleted $FILE" >> .cleanup-backup/deletion.log
```

## Output
```json
{
  "status": "pass | fail",
  "files_deleted": 2,
  "files_backed_up": 2,
  "backup_location": ".cleanup-backup/20251128/"
}
```

## Parallel-Safe: No (file operations)

## Parent: 011-cleanup
