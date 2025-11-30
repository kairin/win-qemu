---
description: Identify and remove redundant files/scripts with constitutional Git workflow - FULLY AUTOMATIC
---

## Purpose

**REPOSITORY CLEANUP**: Scan for obsolete files, remove redundancies, consolidate directories, commit cleanly with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command automatically identifies cleanup targets.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the cleanup workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Cleanup Analysis (Single Agent)

**Agent**: **011-cleanup** (or **111-redundant-scan**)

**Tasks**:
1. Scan entire repository for:
   - Test scripts in root directory (test-*.sh, *_test.sh)
   - Obsolete configuration files (*.bak, *.old, *~)
   - Old log files in logs/ directory (older than 7 days)
   - Duplicate scripts with similar functionality
   - Empty directories
   - Orphaned state files in .installation-state/

2. Identify proper locations:
   - Root directory: ONLY start.sh, CLAUDE.md, AGENTS.md, README.md
   - Scripts: scripts/ directory
   - Configurations: configs/ directory
   - Documentation: docs-repo/ directory
   - ISOs: source-iso/ directory

3. Generate cleanup plan with justification for each file

**Cleanup Targets**:
```bash
# Scan for cleanup candidates
find . -name "*.bak" -o -name "*.old" -o -name "*~" 2>/dev/null
find . -name "test-*.sh" -path "./*" -not -path "./scripts/*" 2>/dev/null
find ./logs -type f -mtime +7 2>/dev/null
find . -type d -empty 2>/dev/null
```

**Skip if**: No cleanup targets found

### Phase 2: Execute Cleanup (Single Agent)

**Agent**: **113-safe-delete**

**Automatic Actions**:
```bash
# Remove identified obsolete files
git rm <file1> <file2> <file3>

# Remove old log files (not tracked by git)
rm -f logs/*.log.old logs/*-$(date -d "8 days ago" +%Y%m%d)*.log

# Clean orphaned state files
rm -f .installation-state/*.tmp .installation-state/*.bak

# Show summary
echo "Removed: X files"
echo "Freed: Y KB"
```

**Safety Requirements**:
- ✅ NEVER remove: start.sh, CLAUDE.md, AGENTS.md, README.md
- ✅ NEVER remove: scripts/*.sh (production scripts)
- ✅ NEVER remove: configs/*.xml (VM templates)
- ✅ NEVER remove: docs-repo/ contents
- ✅ NEVER remove: source-iso/*.iso (user ISOs)
- ✅ ALWAYS preserve: .gitignore, .env
- ✅ Log all removals for audit trail

### Phase 3: Verify Documentation Impact (Conditional)

**Agent**: **010-docs** (or **101-symlink-verify**)

**Tasks** (only if documentation files were modified):
1. Verify CLAUDE.md symlink:
   - CLAUDE.md → AGENTS.md
2. Verify docs-repo/00-INDEX.md is current
3. Check for broken references caused by file removals

**Skip if**: Only log files, temp files, or non-documentation files removed

### Phase 4: Constitutional Commit (Single Agent)

**Agent**: **009-git** (or **092-commit-format**)

**Tasks**:
```bash
# Create cleanup branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="$DATETIME-chore-cleanup-redundant-files"

git checkout -b "$BRANCH"
git add .
git commit -m "chore(cleanup): Remove obsolete files and logs

Cleanup Summary:
- Removed X obsolete/temporary files
- Cleaned Y old log files
- Freed Z KB of repository space

Files removed:
- [list all removed files]

Rationale:
- Root directory should only contain start.sh, CLAUDE.md, README.md
- Old logs consume space and provide no value
- Temporary files should not be committed

Constitutional Compliance:
- ✅ No production scripts removed
- ✅ No configuration templates removed
- ✅ Documentation preserved
- ✅ Branch preservation strategy

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git checkout main
git merge "$BRANCH" --no-ff -m "Merge branch '$BRANCH' into main"
```

**Branch Preservation**: NEVER delete cleanup branch

## Expected Output

```
🧹 REPOSITORY CLEANUP COMPLETE

Cleanup Analysis:
- Files scanned: 247
- Obsolete files found: 3
- Old log files found: 12
- Total removal candidates: 15

Files Removed:
- logs/installation-20251120-*.log (5 files)
- logs/verification-20251119-*.json (4 files)
- .installation-state/*.tmp (3 files)

Space Freed: 2.4 MB

Documentation Impact:
- ✅ No documentation changes needed
- ✅ CLAUDE.md symlink intact

Git Workflow:
- ✅ Branch: 20251128-210000-chore-cleanup-redundant-files
- ✅ Commit: abc1234
- ✅ Merged to main
- ✅ Branch preserved

Constitutional Compliance: ✅ 100%
```

## When to Use

Run `/guardian-cleanup` when you:
- Notice log files accumulating in logs/ directory
- See temporary files left from testing
- Want to remove debugging scripts from root directory
- Need to free up repository space
- Before major releases to ensure clean state

## What This Command Does NOT Do

- ❌ Does NOT create or manage VMs (use `/guardian-vm`)
- ❌ Does NOT apply performance optimizations (use `/guardian-optimize`)
- ❌ Does NOT run security hardening (use `/guardian-security`)
- ❌ Does NOT commit source code changes (use `/guardian-commit`)
- ❌ Does NOT diagnose health issues (use `/guardian-health`)

**Focus**: Cleanup only - removes obsolete files, commits cleanup changes.

## Constitutional Compliance

This command enforces:
- ✅ Root directory cleanliness (only essential files)
- ✅ Proper script organization (scripts/ directory)
- ✅ Log file hygiene (remove old logs)
- ✅ Constitutional commit format (type(scope): message)
- ✅ Branch naming convention (YYYYMMDD-HHMMSS-type-description)
- ✅ Branch preservation (cleanup branches never deleted)
- ✅ Audit trail (all removals logged in commit message)
