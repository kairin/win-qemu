---
name: 046-backup-encryption
description: Manage encrypted backups.
model: haiku
---

## Single Task
Create and manage encrypted VM backups.

## Execution
```bash
# Create encrypted backup
tar -czf - /encrypted/vms/$VM_NAME.qcow2 | \
  gpg --symmetric --cipher-algo AES256 > backup-$(date +%Y%m%d).tar.gz.gpg

# Verify backup
gpg --decrypt backup-*.gpg | tar -tzf -

# Restore
gpg --decrypt backup-*.gpg | tar -xzf - -C /encrypted/vms/
```

## Input
- vm_name: VM to backup
- backup_path: Where to store backup

## Output
```
status: success | error
backup_file: path to backup
size_mb: backup size
encrypted: true
```

## Parent: 004-security
