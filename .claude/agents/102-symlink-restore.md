---
name: 102-symlink-restore
description: Restore broken symlinks.
model: haiku
---

## Single Task
Restore CLAUDE.md and GEMINI.md symlinks to AGENTS.md.

## Execution
```bash
# Remove broken files (if not symlinks)
rm -f CLAUDE.md GEMINI.md

# Create symlinks
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md

# Verify
ls -la CLAUDE.md GEMINI.md
```

## Pre-Restore Check
If files exist and are NOT symlinks:
1. Check if content differs from AGENTS.md
2. If different, merge unique content into AGENTS.md first
3. Then create symlinks

## Output
```json
{
  "status": "pass | fail",
  "symlinks_created": ["CLAUDE.md", "GEMINI.md"],
  "target": "AGENTS.md"
}
```

## Parallel-Safe: No (file operations)

## Parent: 010-docs
