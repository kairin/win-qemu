---
name: 111-redundant-scan
description: Scan for redundant files.
model: haiku
---

## Single Task
Identify redundant, duplicate, or obsolete files.

## Execution
```bash
# Find duplicate files by content
find . -type f -name "*.md" -exec md5sum {} \; | sort | uniq -d -w32

# Find empty files
find . -type f -empty

# Find backup files
find . -name "*.bak" -o -name "*.backup" -o -name "*~"

# Find old/obsolete patterns
find . -name "*.old" -o -name "*.orig"

# Find orphaned scripts
find scripts/ -name "*.sh" -exec grep -L "#!/bin/bash" {} \;
```

## Criteria for Redundancy
1. Duplicate content (same MD5)
2. Empty files with no purpose
3. Backup files (.bak, .backup, ~)
4. Obsolete files (.old, .orig)
5. Scripts not referenced anywhere

## Output
```json
{
  "status": "pass | fail",
  "duplicates_found": 2,
  "empty_files": 0,
  "backup_files": 3,
  "obsolete_files": 1,
  "files_to_review": ["file1.bak", "file2.old"]
}
```

## Parallel-Safe: Yes

## Parent: 011-cleanup
