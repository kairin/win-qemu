---
name: 000-docs
description: Documentation integrity verification and symlink management.
model: sonnet
tools: [Task, Bash, Read, Write, Glob, Grep]
---

## Purpose

Verify all documentation systems, fix broken links, restore symlinks, update index with zero manual intervention.

## Invocation

- User: "verify documentation", "fix broken links", "check symlinks"
- Orchestrator: Routes when detecting "documentation", "symlink", "broken links"

## Workflow

1. **Phase 1**: Invoke **101-symlink-verify** (or **010-docs**)
   - Verify CLAUDE.md → AGENTS.md symlink
   - Auto-restore if broken
   - Scan for all broken symlinks

2. **Phase 2**: Invoke **010-docs** + **103-index-update** in parallel
   - Agent 1: AGENTS.md size check (<40KB limit)
   - Agent 1: docs-repo/ structure verification
   - Agent 1: Constitutional documents check (6 files in 06-constitutional/)
   - Agent 2: 00-INDEX.md currency validation
   - Agent 2: Agent registry validation

3. **Phase 3**: Invoke **010-docs** for cross-reference validation
   - Scan for broken links in markdown files
   - Validate link targets exist
   - Identify common issues

4. **Phase 4**: Invoke **102-symlink-restore** (conditional)
   - Restore broken symlinks
   - Update index if needed

5. **Phase 5**: Invoke **009-git** (conditional)
   - Constitutional commit if changes made

## Success Criteria

- CLAUDE.md → AGENTS.md symlink intact
- No broken symlinks in repository
- AGENTS.md under 40KB limit
- docs-repo/ structure complete
- 00-INDEX.md up to date
- All internal links valid

## Child Agents

- 010-docs
  - 101-symlink-verify
  - 102-symlink-restore
  - 103-index-update
  - 104-readme-sync
  - 105-changelog-append
- 009-git (conditional)

## Constitutional Compliance

- Single source of truth (AGENTS.md via CLAUDE.md symlink)
- Symlink integrity (CLAUDE.md → AGENTS.md)
- AGENTS.md size limit (<40KB)
- docs-repo/ organization (6 numbered directories)
- 00-INDEX.md currency
- Agent hierarchy documentation (62+ agents)
- Constitutional document completeness
