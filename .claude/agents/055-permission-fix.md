---
name: 055-permission-fix
description: Fix virtio-fs permission issues.
model: haiku
---

## Single Task
Resolve permission problems with shared files.

## Common Fixes (Host)
```bash
# Set correct ownership
sudo chown -R $USER:$USER /path/to/share

# Set permissions (read-only share)
chmod -R 755 /path/to/share
chmod 644 /path/to/share/*.pst

# Verify SELinux/AppArmor not blocking
sudo aa-status | grep virtiofsd
```

## Input
- share_path: Path to shared directory

## Output
```
status: success | error
owner: user:group
permissions: octal mode
selinux_ok: true | false
```

## Parent: 005-virtiofs
