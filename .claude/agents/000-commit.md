---
name: 000-commit
description: Automatic constitutional Git commit with change analysis and perfect formatting.
model: sonnet
tools: [Task, Bash, Read, Write, Grep]
---

## Purpose

Analyze uncommitted changes, generate perfect constitutional commit message, execute timestamped branch workflow with zero manual intervention.

## Invocation

- User: "commit changes", "save my work", "git commit"
- Orchestrator: Routes when detecting "commit", "save changes", "push"

## Workflow

1. **Phase 1**: Change Analysis (parallel)
   - Task 1: Git status analysis (staged vs unstaged)
   - Task 2: Change content analysis (diff, stats)

2. **Phase 2**: Auto-Generate Commit Details
   - Detect commit type from files:
     - .claude/agents/*.md → feat (agent system)
     - scripts/*.sh → feat (automation)
     - configs/*.xml → config (VM configurations)
     - docs-repo/*.md → docs (documentation)
   - Extract scope from directory
   - Generate short description (kebab-case, 2-5 words)
   - Create full commit message with Problem/Solution/Technical Details

3. **Phase 3**: Invoke **009-git** for constitutional workflow
   - **091-branch-create**: Create timestamped branch
   - **092-commit-format**: Generate constitutional message
   - **093-merge-strategy**: Merge to main with --no-ff
   - **095-sync-remote**: Push to remote

## Success Criteria

- All changes committed
- Commit message follows constitutional format
- Branch created with YYYYMMDD-HHMMSS-type-description
- Merged to main with --no-ff
- Branch preserved (never deleted)

## Commit Message Format

```
type(scope): Brief summary (max 72 chars)

Problem/Context:
- Why this change was needed

Solution:
- What was changed

Technical Details:
- Files modified count
- Lines added/removed

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Child Agents

- 009-git
  - 091-branch-create
  - 092-commit-format
  - 093-merge-strategy
  - 095-sync-remote

## Constitutional Compliance

- Automatic commit type detection
- Meaningful commit messages (not "Update files")
- Constitutional branch naming (YYYYMMDD-HHMMSS-type-description)
- Branch preservation strategy (NEVER delete)
- Proper merge strategy (--no-ff)
- Claude Code attribution
