---
description: Verify documentation structure, fix broken links, restore symlinks, ensure single source of truth - FULLY AUTOMATIC
---

## Purpose

**DOCUMENTATION INTEGRITY**: Verify all documentation systems, fix broken links, restore symlinks, update index with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command automatically verifies all documentation.

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the documentation verification workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Symlink Verification (Single Agent)

**Agent**: **101-symlink-verify** (or **010-docs**)

**Tasks**:
1. **Verify Primary Symlink**:
   ```bash
   # Check CLAUDE.md symlink
   test -L CLAUDE.md && readlink CLAUDE.md
   # Must point to AGENTS.md
   ```

2. **Auto-Restore if Broken**:
   ```bash
   # If CLAUDE.md broken or missing
   rm -f CLAUDE.md
   ln -s AGENTS.md CLAUDE.md
   ```

3. **Scan Repository for Broken Symlinks**:
   ```bash
   find . -type l -xtype l 2>/dev/null  # Find all broken symlinks
   ```

**Expected Output**:
- ✅ CLAUDE.md → AGENTS.md (restored if needed)
- ✅ No broken symlinks in repository

**Skip if**: All symlinks intact

### Phase 2: Documentation Structure Verification (Parallel - 2 Agents)

**Agent 1: 010-docs**

**Tasks**:
1. **AGENTS.md Size Check**:
   ```bash
   du -h AGENTS.md
   wc -l AGENTS.md
   ```
   - Must be < 40KB constitutional limit
   - If > 40KB: Split sections into docs-repo/ referenced documents

2. **docs-repo/ Structure Verification**:
   ```
   docs-repo/
   ├── 00-INDEX.md (exists, current)
   ├── 01-concept/ (project overview)
   ├── 02-setup/ (installation guides)
   ├── 03-ops/ (operations guides)
   ├── 04-history/ (historical context)
   ├── 05-agents/ (agent documentation)
   └── 06-constitutional/ (core mandates)
   ```

3. **Verify Constitutional Documents**:
   ```bash
   ls -la docs-repo/06-constitutional/
   # Must contain:
   # - 01-mandates.md
   # - 02-git-policy.md
   # - 03-architecture.md
   # - 04-agent-system.md
   # - 05-workflow.md
   # - 06-guidelines.md
   ```

**Agent 2: 103-index-update**

**Tasks**:
1. **Check 00-INDEX.md Currency**:
   - Verify all docs-repo files listed in index
   - Check for missing entries
   - Identify orphan files (not in index)

2. **Agent Registry Validation**:
   - Verify agent files in .claude/agents/
   - Check agent descriptions match implementations
   - Validate numbered agent hierarchy (001-114)

**Expected Output**:
- ✅/❌ AGENTS.md: XX KB (under/over 40KB limit)
- ✅/❌ docs-repo structure: Complete
- ✅/❌ 00-INDEX.md: Up to date
- ✅/❌ Agent hierarchy: 62 agents documented

### Phase 3: Cross-Reference Validation (Single Agent)

**Agent**: **010-docs**

**Tasks**:
1. **Scan for Broken Links**:
   ```bash
   # Find all markdown files
   find docs-repo/ .claude/ -name "*.md" 2>/dev/null

   # Check for common broken patterns
   grep -r "](.*)" --include="*.md" docs-repo/ | head -50
   ```

2. **Validate Link Targets**:
   - For each internal link, verify target file exists
   - Check relative paths resolve correctly
   - Identify moved/deleted file references

3. **Common Issues to Check**:
   - ❌ Links to old directory structure
   - ❌ Links to renamed files
   - ❌ Absolute paths that should be relative

**Expected Output**:
- List of broken links with file locations
- Suggested fixes for each broken link

**Skip if**: No broken links found

### Phase 4: Auto-Fix Issues (Conditional)

**Agent**: **102-symlink-restore** (or **010-docs**)

**Tasks** (only if issues found):
1. **Restore Broken Symlinks**:
   ```bash
   # Restore CLAUDE.md if needed
   rm -f CLAUDE.md && ln -s AGENTS.md CLAUDE.md
   ```

2. **Update Index if Needed**:
   - Add missing files to 00-INDEX.md
   - Remove orphan entries

**Skip if**: No issues found

### Phase 5: Constitutional Commit (Conditional)

**Agent**: **009-git** (or **092-commit-format**)

**Tasks** (only if changes made):
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="$DATETIME-docs-fix-documentation-integrity"

git checkout -b "$BRANCH"
git add .
git commit -m "docs: Fix documentation integrity issues

Problems Fixed:
- Restored X broken symlinks
- Fixed Y broken links
- Updated 00-INDEX.md with Z new entries
- Verified AGENTS.md size compliance

Changes:
- Symlinks: CLAUDE.md → AGENTS.md
- Index: Added missing documentation entries
- Links: Fixed internal references

Validation:
- All symlinks intact
- All internal links validated
- docs-repo structure complete
- AGENTS.md under 40KB limit

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git checkout main
git merge "$BRANCH" --no-ff -m "Merge branch '$BRANCH' into main"
```

**Skip if**: No issues found, all documentation clean

## Expected Output

```
📚 DOCUMENTATION INTEGRITY REPORT
==================================

SYMLINK STATUS
==============
✅ CLAUDE.md → AGENTS.md (verified)
✅ No broken symlinks in repository

DOCUMENTATION STRUCTURE
=======================
✅ AGENTS.md: 12.4 KB (under 40KB limit)
✅ docs-repo/ structure complete:
   - 00-INDEX.md ✅
   - 01-concept/ ✅ (3 files)
   - 02-setup/ ✅ (4 files)
   - 03-ops/ ✅ (5 files)
   - 04-history/ ✅ (2 files)
   - 05-agents/ ✅ (1 file)
   - 06-constitutional/ ✅ (6 files)

AGENT DOCUMENTATION
===================
✅ Agent files: 62 agents in .claude/agents/
✅ Numbered hierarchy: 001-114 (with gaps for future)
✅ Slash commands: 9 commands in .claude/commands/

CROSS-REFERENCE INTEGRITY
=========================
✅ All internal links validated
✅ No broken references found
✅ 00-INDEX.md up to date

ACTIONS TAKEN
=============
✅ Issues found: 0
✅ No changes needed

Overall Status: ✅ EXCELLENT
All documentation systems verified.
```

## When to Use

Run `/guardian-documentation` when you need to:
- Verify documentation integrity after major changes
- Fix broken symlinks (CLAUDE.md)
- Validate docs-repo/ structure
- Update 00-INDEX.md with new files
- Ensure agent documentation is complete

**Best Practice**: Run after adding new documentation or restructuring

## What This Command Does NOT Do

- ❌ Does NOT create or manage VMs (use `/guardian-vm`)
- ❌ Does NOT clean up redundant files (use `/guardian-cleanup`)
- ❌ Does NOT commit source code changes (use `/guardian-commit`)
- ❌ Does NOT diagnose system health (use `/guardian-health`)
- ❌ Does NOT apply security hardening (use `/guardian-security`)

**Focus**: Documentation verification and fixes only.

## Constitutional Compliance

This command enforces:
- ✅ Single source of truth (AGENTS.md via CLAUDE.md symlink)
- ✅ Symlink integrity (CLAUDE.md → AGENTS.md)
- ✅ AGENTS.md size limit (< 40KB)
- ✅ docs-repo/ organization (6 numbered directories)
- ✅ 00-INDEX.md currency (all files indexed)
- ✅ Agent hierarchy documentation (62 agents)
- ✅ Constitutional document completeness (6 mandate files)
