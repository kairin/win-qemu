---
name: 114-reference-update
description: Update references after cleanup.
model: haiku
---

## Single Task
Update all references to moved/renamed/deleted files.

## Execution
```bash
# Find references to old path
grep -r "old-filename.md" docs-repo/ scripts/

# Update references
sed -i 's|old-filename.md|new-filename.md|g' file.md

# Verify no broken references
grep -r "old-filename.md" . && echo "BROKEN REFS FOUND"
```

## Reference Types to Update
1. Markdown links: `[text](path.md)`
2. Script includes: `source script.sh`
3. Documentation refs: `See file.md`
4. Index entries: `- file.md`

## Verification
After updates, verify:
- All links resolve
- All scripts source correctly
- Index is accurate
- No 404s in docs

## Output
```json
{
  "status": "pass | fail",
  "references_updated": 5,
  "files_modified": 3,
  "broken_references_remaining": 0
}
```

## Parallel-Safe: No (file operations)

## Parent: 011-cleanup
