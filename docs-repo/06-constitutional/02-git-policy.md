# Git Strategy & Branch Management

## Branch Preservation (MANDATORY)
- **NEVER DELETE BRANCHES** without permission.
- **Preserve History**: Automatic merge to main, but keep the feature branch.

## Branch Naming (MANDATORY SCHEMA)
**Format**: `YYYYMMDD-HHMMSS-type-short-description`

**Prefixes**:
- `feat-`: New features
- `fix-`: Bug fixes
- `docs-`: Documentation
- `config-`: Configuration changes
- `security-`: Hardening
- `perf-`: Optimization

**Example**: `20251117-150000-feat-vm-creation`

## Git Workflow (MANDATORY)
1. **Create Branch**: `git checkout -b "YYYYMMDD-HHMMSS-type-desc"`
2. **Changes**: Implement and test.
3. **Commit**: Use descriptive messages.
4. **Push**: `git push -u origin branch-name`
5. **Merge**: Merge to main (`--no-ff`), preserve branch.
