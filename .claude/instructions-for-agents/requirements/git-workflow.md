# Git Workflow Templates

[← Back to Index](../README.md)

---

## Branch Creation

```bash
# Generate compliant branch name
BRANCH="$(date +%Y%m%d-%H%M%S)-feat-description"

# Create and checkout
git checkout -b "$BRANCH"
```

---

## Commit Message Format

```
<type>(<scope>): <summary>

<optional body>

Related changes:
- <bullet list>

Constitutional compliance:
- [x] Branch naming compliant
- [x] No sensitive files
- [x] Symlinks verified

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `perf`: Performance
- `security`: Security hardening
- `config`: Configuration
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

### Scopes (win-qemu specific)
- `vm`: VM creation, configuration, lifecycle
- `perf`: Performance optimization
- `security`: Security hardening
- `virtio-fs`: Filesystem sharing
- `automation`: QEMU guest agent
- `config`: XML templates, libvirt
- `docs`: Documentation
- `scripts`: Shell scripts

---

## Complete Git Workflow

```bash
# 1. Create compliant branch
BRANCH="$(date +%Y%m%d-%H%M%S)-feat-description"
git checkout -b "$BRANCH"

# 2. Make changes
# ... edit files ...

# 3. Stage changes (with security scan)
git add -A
git diff --staged --name-only | grep -E '\.(env|pst|qcow2)$' && exit 1

# 4. Commit with constitutional format
git commit -m "feat(scope): summary

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 5. Push to remote
git push -u origin "$BRANCH"

# 6. Merge to main (preserve branch)
git checkout main
git merge --no-ff "$BRANCH"
git push origin main

# 7. NEVER delete the branch
# git branch -d "$BRANCH"  # FORBIDDEN
```

---

## Security Scan Before Commit

```bash
# Files that MUST NOT be committed
FORBIDDEN_PATTERNS=(
  '\.env$'
  '\.pst$'
  '\.qcow2$'
  '\.img$'
  'credentials'
  'secret'
  'api[_-]?key'
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if git diff --staged --name-only | grep -qiE "$pattern"; then
    echo "BLOCKED: Sensitive file matches $pattern"
    exit 1
  fi
done
```

---

[← Back to Index](../README.md)
