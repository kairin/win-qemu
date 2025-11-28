---
name: 092-commit-format
description: Format commit message.
model: haiku
---

## Single Task
Create properly formatted commit message.

## Commit Format
```
type(scope): description

## Summary
- Bullet point 1
- Bullet point 2

## Changes
- file1.md: Description
- file2.sh: Description

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Types
- feat: New feature
- fix: Bug fix
- docs: Documentation
- refactor: Code restructure
- test: Testing
- chore: Maintenance

## Execution
```bash
git commit -m "$(cat <<'EOF'
type(scope): description

## Summary
- Change description

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Parallel-Safe: No (git operations)

## Parent: 009-git
