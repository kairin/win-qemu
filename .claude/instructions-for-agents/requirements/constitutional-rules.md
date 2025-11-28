# Constitutional Rules (Non-Negotiable)

[← Back to Index](../README.md)

---

## Branch Preservation (SACRED)

```bash
# NEVER DELETE branches - archive instead
# FORBIDDEN: git branch -d <branch>
# FORBIDDEN: git branch -D <branch>
# FORBIDDEN: git push origin --delete <branch>

# ALLOWED: Archive non-compliant branches
git branch -m old-branch "archive-$(date +%Y%m%d)-old-branch"

# ALLOWED: Non-fast-forward merges (preserves history)
git merge --no-ff <branch>
```

---

## Branch Naming (MANDATORY)

**Format**: `YYYYMMDD-HHMMSS-type-description`

**Types**: `feat|fix|docs|config|security|perf|refactor|test|chore`

```bash
# Validation regex
^[0-9]{8}-[0-9]{6}-(feat|fix|docs|config|security|perf|refactor|test|chore)-.+$

# Examples
20251128-143022-feat-add-vm-creation
20251128-150000-fix-virtio-driver-issue
20251128-160000-docs-update-readme
```

---

## Symlink Integrity (MANDATORY)

```bash
# CLAUDE.md and GEMINI.md MUST be symlinks to AGENTS.md
ls -la CLAUDE.md  # Should show -> AGENTS.md
ls -la GEMINI.md  # Should show -> AGENTS.md

# Restore if broken
ln -sf AGENTS.md CLAUDE.md
ln -sf AGENTS.md GEMINI.md
```

---

## Security Rules (SACRED)

### virtio-fs Read-Only (CRITICAL)
```xml
<!-- MANDATORY: Prevents ransomware from encrypting host files -->
<filesystem type='mount' accessmode='passthrough'>
  <source dir='/path/to/share'/>
  <target dir='share-name'/>
  <readonly/>  <!-- NEVER REMOVE THIS -->
</filesystem>
```

### Pre-Commit Security Scan
```bash
# ALWAYS scan before commit
git diff --staged --name-only | grep -E '\.(env|eml|key|pem|credentials|pst)$' && {
  echo "HALT: Sensitive files detected"
  exit 1
}

# NEVER commit:
# - .env files (API keys)
# - .pst Outlook files
# - VM disk images (.qcow2, .img)
# - Files >100MB
```

---

## Performance Targets (MANDATORY)

| Metric | Target | Minimum |
|--------|--------|---------|
| Overall performance | 85-95% native | 80% |
| Boot time | <25 seconds | <45 seconds |
| Outlook launch | <5 seconds | <10 seconds |
| PST open (1GB) | <3 seconds | <5 seconds |
| Disk IOPS (4K) | >30,000 | >20,000 |

---

## Agent Authority (SOLE RESPONSIBILITY)

Each agent has exclusive ownership of its domain:
- **009-git**: ALL Git operations (no other agent may commit/push)
- **002-vm-operations**: ALL VM lifecycle (create/start/stop/delete)
- **004-security**: ALL security hardening (LUKS, firewall, audit)
- **001-orchestrator**: ALL multi-agent coordination

**Delegation Required**: Agents MUST delegate to specialists, never overlap.

---

[← Back to Index](../README.md)
