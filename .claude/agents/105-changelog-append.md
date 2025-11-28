---
name: 105-changelog-append
description: Append entry to CHANGELOG.
model: haiku
---

## Single Task
Add new entry to CHANGELOG.md.

## Changelog Format
```markdown
# Changelog

## [Unreleased]
### Added
- New feature description

### Changed
- Modified feature description

### Fixed
- Bug fix description

## [1.0.0] - 2025-11-28
### Added
- Initial release
```

## Entry Types
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security patches

## Execution
1. Read current CHANGELOG.md
2. Add entry under [Unreleased]
3. Follow Keep a Changelog format

## Output
```json
{
  "status": "pass | fail",
  "entry_type": "Added",
  "entry_description": "New VM template",
  "section": "Unreleased"
}
```

## Parallel-Safe: No (file operations)

## Parent: 010-docs
