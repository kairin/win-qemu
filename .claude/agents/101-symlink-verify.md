---
name: 101-symlink-verify
description: Verify CLAUDE.md symlink integrity.
model: haiku
---

## Single Task
Verify CLAUDE.md and GEMINI.md are symlinks to AGENTS.md.

## Execution
```bash
# Check if symlinks exist
ls -la CLAUDE.md GEMINI.md 2>/dev/null

# Verify symlink targets
readlink CLAUDE.md
readlink GEMINI.md

# Should point to AGENTS.md
# CLAUDE.md -> AGENTS.md
# GEMINI.md -> AGENTS.md
```

## Single Source of Truth
- AGENTS.md is the master document
- CLAUDE.md must be symlink to AGENTS.md
- GEMINI.md must be symlink to AGENTS.md
- Never edit CLAUDE.md or GEMINI.md directly

## Output
```json
{
  "status": "pass | fail",
  "claude_md_symlink": true,
  "gemini_md_symlink": true,
  "target": "AGENTS.md"
}
```

## Parallel-Safe: Yes

## Parent: 010-docs
