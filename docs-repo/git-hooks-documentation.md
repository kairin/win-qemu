# Git Hooks Documentation - docs-repo/ Constitutional Enforcement

**Created**: 2025-11-17
**Purpose**: Document the pre-commit hook that enforces `docs-repo/` constitutional requirement
**Hook Location**: `.git/hooks/pre-commit`
**Agent**: General-purpose (Git hooks + bash scripting specialist)

---

## Overview

This repository includes a **pre-commit Git hook** that automatically enforces the constitutional requirement that all repository-wide documentation must reside in the `docs-repo/` directory.

**Constitutional Basis** (from AGENTS.md):
- Repository-wide documentation MUST be in `docs-repo/`
- Root directory ONLY allows: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README.md`
- Symlinks are always permitted

---

## Hook Functionality

### What It Does

The pre-commit hook:

1. **Scans staged files** for `.md` files in the repository root directory
2. **Checks against allowlist**:
   - `AGENTS.md` (constitutional document)
   - `CLAUDE.md` (symlink to AGENTS.md)
   - `GEMINI.md` (symlink to AGENTS.md)
   - `README.md` (project overview)
3. **Allows all symlinks** automatically (regardless of name)
4. **Blocks commit** if violations found
5. **Provides clear remediation guidance** in error message

### What It Prevents

- Accidental commits of misplaced `.md` files to root directory
- Gradual accumulation of documentation clutter in root
- Constitutional violations that bypass the `docs-repo/` requirement
- Documentation fragmentation across the repository

---

## Hook Installation

### Automatic Installation

The hook is already installed at:
```
.git/hooks/pre-commit
```

### Manual Installation (If Needed)

```bash
# 1. Copy hook to hooks directory
cp /path/to/pre-commit .git/hooks/pre-commit

# 2. Make executable
chmod +x .git/hooks/pre-commit

# 3. Verify installation
ls -lh .git/hooks/pre-commit
```

---

## Usage Examples

### ✅ ALLOWED: Committing to docs-repo/

```bash
# Create new documentation file
vim docs-repo/my-new-guide.md

# Stage and commit (NO VIOLATIONS)
git add docs-repo/my-new-guide.md
git commit -m "Add new guide to docs-repo/"

# Output:
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified
# [branch] Commit successful
```

### ✅ ALLOWED: Updating constitutional files

```bash
# Update AGENTS.md (allowed in root)
vim AGENTS.md

# Stage and commit (NO VIOLATIONS)
git add AGENTS.md
git commit -m "Update AGENTS.md"

# Output:
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified
# [branch] Commit successful
```

### ✅ ALLOWED: Creating symlinks

```bash
# Create symlink in root (always allowed)
ln -s AGENTS.md NEW_SYMLINK.md

# Stage and commit (NO VIOLATIONS)
git add NEW_SYMLINK.md
git commit -m "Add symlink"

# Output:
# ✓ Symlink allowed: NEW_SYMLINK.md
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified
# [branch] Commit successful
```

### ❌ BLOCKED: Committing .md file to root

```bash
# Accidentally create documentation in root
vim installation-guide.md

# Stage and commit (VIOLATION!)
git add installation-guide.md
git commit -m "Add installation guide"

# Output:
# ════════════════════════════════════════════════════════════════
# ⚠️  PRE-COMMIT HOOK: Constitutional Violation Detected
# ════════════════════════════════════════════════════════════════
#
# VIOLATION: Attempt to commit .md file(s) to repository root directory
#
# Blocked Files:
#   ✗ installation-guide.md
#
# Constitutional Requirement (AGENTS.md):
#   • Repository-wide documentation MUST reside in docs-repo/
#   • Root directory ONLY allows:
#       - AGENTS.md (constitutional document)
#       - CLAUDE.md, GEMINI.md (symlinks to AGENTS.md)
#       - README.md (project overview)
#
# Remediation Steps:
#
#   1. Move misplaced file(s) to docs-repo/:
#      $ git mv installation-guide.md docs-repo/
#
#   2. Re-stage your changes:
#      $ git add docs-repo/
#
#   3. Retry your commit:
#      $ git commit
#
# ════════════════════════════════════════════════════════════════
# Commit ABORTED - Fix violations and retry
# ════════════════════════════════════════════════════════════════
```

---

## Remediation Process

When the hook blocks a commit, follow these steps:

### Step 1: Move the file to docs-repo/

```bash
# Use git mv to preserve Git history
git mv violating-file.md docs-repo/
```

### Step 2: Re-stage your changes

```bash
# Stage the moved file
git add docs-repo/

# Verify staged changes
git status
```

### Step 3: Retry your commit

```bash
# Commit with original message
git commit -m "Your commit message"

# Hook will now pass
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified
```

---

## Exception Process

### When Root Placement IS Legitimate

If a `.md` file **genuinely belongs** in the root directory (rare), you must:

1. **Justify the exception** (e.g., GitHub requires `README.md` in root)
2. **Update the allowlist** in `.git/hooks/pre-commit`:

```bash
# Edit the hook
vim .git/hooks/pre-commit

# Find the ALLOWED_ROOT_MD_FILES array:
ALLOWED_ROOT_MD_FILES=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    "README.md"
    "YOUR_NEW_EXCEPTION.md"  # Add your exception here
)
```

3. **Document the exception** in this file (git-hooks-documentation.md)
4. **Commit the hook update** separately

### Current Exceptions

| File | Justification | Added |
|------|---------------|-------|
| `AGENTS.md` | Constitutional document (single source of truth) | 2025-11-17 |
| `CLAUDE.md` | Symlink to AGENTS.md (Claude Code integration) | 2025-11-17 |
| `GEMINI.md` | Symlink to AGENTS.md (Gemini CLI integration) | 2025-11-17 |
| `README.md` | GitHub standard (project overview) | 2025-11-17 |

---

## Technical Implementation

### Hook Architecture

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 1. Define allowlist
ALLOWED_ROOT_MD_FILES=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    "README.md"
)

# 2. Scan staged files (git diff --cached)
for file in $(git diff --cached --name-only --diff-filter=ACM); do
    # Check if file is in root AND is .md
    if [[ "$file" == *.md ]] && [[ "$file" != */* ]]; then
        # Check if symlink (always allowed)
        if [[ -L "$file" ]]; then
            continue
        fi

        # Check if in allowlist
        if ! is_allowed_file "$file"; then
            # VIOLATION: Add to array
            VIOLATIONS+=("$file")
        fi
    fi
done

# 3. If violations found, block commit
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    # Display error message
    # Exit 1 (block commit)
fi

# 4. No violations - allow commit
exit 0
```

### Key Features

1. **Staged Files Only**: Uses `git diff --cached` to check only files being committed
2. **Symlink Detection**: Uses `[[ -L "$file" ]]` to automatically allow all symlinks
3. **Allowlist Pattern**: Easy to extend by adding to `ALLOWED_ROOT_MD_FILES` array
4. **Clear Error Messages**: Color-coded output with step-by-step remediation
5. **Exit Codes**: Proper exit codes (0 = allow, 1 = block)

---

## Testing & Verification

### Test 1: Verify Hook is Executable

```bash
# Check file permissions
ls -lh .git/hooks/pre-commit

# Expected output:
# -rwx--x--x ... .git/hooks/pre-commit
#  ^^^
#  Executable bits set
```

### Test 2: Test with Allowed File

```bash
# Modify AGENTS.md
echo "# Test comment" >> AGENTS.md

# Stage and commit
git add AGENTS.md
git commit -m "Test allowed file"

# Expected: Commit SUCCEEDS
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified
```

### Test 3: Test with Blocked File

```bash
# Create test file in root
echo "# Test" > test-violation.md

# Stage and commit
git add test-violation.md
git commit -m "Test violation"

# Expected: Commit BLOCKED
# ⚠️  PRE-COMMIT HOOK: Constitutional Violation Detected
# Blocked Files:
#   ✗ test-violation.md

# Clean up
git reset HEAD test-violation.md
rm test-violation.md
```

### Test 4: Test with Symlink

```bash
# Create symlink in root
ln -s docs-repo/some-file.md test-symlink.md

# Stage and commit
git add test-symlink.md
git commit -m "Test symlink"

# Expected: Commit SUCCEEDS (symlinks always allowed)
# ✓ Symlink allowed: test-symlink.md
# ✓ Pre-commit hook: docs-repo/ constitutional compliance verified

# Clean up
git reset HEAD test-symlink.md
rm test-symlink.md
```

---

## Troubleshooting

### Issue 1: Hook Not Running

**Symptom**: Commits succeed even with violations

**Diagnosis**:
```bash
# Check if hook is executable
ls -lh .git/hooks/pre-commit

# Check if hook exists
test -f .git/hooks/pre-commit && echo "Exists" || echo "Missing"
```

**Solution**:
```bash
# Make hook executable
chmod +x .git/hooks/pre-commit

# Verify
ls -lh .git/hooks/pre-commit
```

---

### Issue 2: Hook Blocks Legitimate Symlinks

**Symptom**: Symlink commits are blocked incorrectly

**Diagnosis**:
```bash
# Check if file is actually a symlink
ls -lh /path/to/file.md
# Should show: lrwxrwxrwx ... file.md -> target
```

**Solution**:
- If file is a symlink, this is a hook bug (report to maintainer)
- If file is NOT a symlink, move to `docs-repo/`

---

### Issue 3: Need to Bypass Hook (Emergency)

**Symptom**: Hook is blocking a critical commit

**Solution**:
```bash
# TEMPORARY bypass (NOT RECOMMENDED)
git commit --no-verify -m "Emergency commit"

# Then immediately:
# 1. Fix the violation properly
# 2. Create a follow-up commit with proper compliance
```

**WARNING**: `--no-verify` should ONLY be used in emergencies

---

## Maintenance

### Updating the Allowlist

When adding a new exception:

```bash
# 1. Edit the hook
vim .git/hooks/pre-commit

# 2. Add file to ALLOWED_ROOT_MD_FILES array
ALLOWED_ROOT_MD_FILES=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    "README.md"
    "NEW_EXCEPTION.md"  # Add here
)

# 3. Save and exit

# 4. Document the exception in this file (git-hooks-documentation.md)

# 5. Commit the documentation update
git add docs-repo/git-hooks-documentation.md
git commit -m "Document new root .md exception: NEW_EXCEPTION.md"
```

### Hook Updates

When updating the hook logic:

```bash
# 1. Edit the hook
vim .git/hooks/pre-commit

# 2. Make changes

# 3. Test thoroughly (see Testing & Verification above)

# 4. Update this documentation

# 5. Commit documentation changes
git add docs-repo/git-hooks-documentation.md
git commit -m "Update git hooks documentation"
```

**NOTE**: Git hooks are NOT tracked in the repository by default. To share hook updates:
1. Store hook template in `docs-repo/git-hooks/pre-commit.template`
2. Document installation process in this file
3. Users manually copy to `.git/hooks/pre-commit`

---

## Best Practices

### For Developers

1. **Always stage files carefully**: Review `git status` before committing
2. **Use docs-repo/ by default**: Place all new documentation in `docs-repo/`
3. **Test before committing**: Run `git commit` to verify hook passes
4. **Read error messages**: Hook provides clear remediation steps
5. **Don't bypass hooks**: Use `--no-verify` only in emergencies

### For Maintainers

1. **Keep allowlist minimal**: Only add exceptions with strong justification
2. **Document all exceptions**: Update this file for every allowlist change
3. **Test hook updates**: Verify with allowed/blocked/symlink test cases
4. **Monitor violations**: If hook frequently blocks legitimate files, reconsider architecture
5. **Review hook logs**: Check Git commit messages for `--no-verify` usage

---

## References

### Official Documentation

- **Git Hooks**: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- **Bash Scripting**: https://www.gnu.org/software/bash/manual/
- **Git diff --cached**: https://git-scm.com/docs/git-diff

### Project Documentation

- **AGENTS.md**: Constitutional requirements (docs-repo/ mandate)
- **docs-repo/repository-structure.md**: Complete repository organization guidelines
- **.claude/agents/git-operations-specialist.md**: Git workflow automation

### Related Files

- `.git/hooks/pre-commit` - The actual hook script
- `docs-repo/repository-structure.md` - Repository organization guidelines
- `AGENTS.md` - Constitutional source of truth

---

## Changelog

### 2025-11-17 - Initial Hook Creation

**Changes**:
- Created pre-commit hook for docs-repo/ enforcement
- Implemented allowlist validation (4 files)
- Added symlink detection and auto-allow
- Comprehensive error messages with remediation steps
- Color-coded terminal output
- Testing verification suite

**Agent**: general-purpose (Git hooks + bash scripting)
**Commit**: (pending git-operations-specialist)

---

## License

This Git hook is part of the **QEMU/KVM Windows Virtualization** project and follows the same license as the repository.

---

**Document Status**: ✅ ACTIVE
**Last Updated**: 2025-11-17
**Maintained By**: AI Agents (Claude Code) + User
**Review Frequency**: After each hook update or constitutional change
