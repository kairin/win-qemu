---
name: 000-cleanup
description: Repository hygiene workflow - scan, remove redundant files, commit cleanly.
model: sonnet
tools: [Task, Bash, Read, Write, Glob, Grep]
---

## Purpose

Scan for obsolete files, remove redundancies, consolidate directories, commit cleanly with zero manual intervention.

## Invocation

- User: "clean up the repo", "remove obsolete files", "repository hygiene"
- Orchestrator: Routes when detecting "cleanup", "redundant", "obsolete files"

## Workflow

1. **Phase 1**: Invoke **011-cleanup** (or **111-redundant-scan**) for analysis
   - Scan for test scripts in root directory
   - Find obsolete config files (*.bak, *.old, *~)
   - Identify old log files (>7 days)
   - Detect duplicate scripts
   - Find empty directories

2. **Phase 2**: Invoke **113-safe-delete** for execution
   - Remove identified obsolete files
   - Clean orphaned state files
   - Enforce safety requirements (never remove production files)

3. **Phase 3**: Invoke **010-docs** (conditional) for documentation impact
   - Verify CLAUDE.md symlink
   - Check for broken references

4. **Phase 4**: Invoke **009-git** for constitutional commit
   - Create timestamped branch
   - Commit with cleanup summary
   - Merge to main with --no-ff

## Success Criteria

- All obsolete files removed
- No production files affected
- Documentation integrity verified
- Constitutional commit completed
- Branch preserved (never deleted)

## Safety Requirements

- NEVER remove: start.sh, CLAUDE.md, AGENTS.md, README.md
- NEVER remove: scripts/*.sh (production scripts)
- NEVER remove: configs/*.xml (VM templates)
- NEVER remove: docs-repo/ contents
- NEVER remove: source-iso/*.iso (user ISOs)
- ALWAYS preserve: .gitignore, .env

## Child Agents

- 011-cleanup (111-redundant-scan)
- 113-safe-delete
- 010-docs (101-symlink-verify)
- 009-git (092-commit-format)

## Constitutional Compliance

- Root directory cleanliness (only essential files)
- Proper script organization (scripts/ directory)
- Log file hygiene (remove old logs)
- Constitutional commit format
- Branch preservation strategy
- Audit trail (all removals logged)
