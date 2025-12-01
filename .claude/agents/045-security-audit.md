---
name: 045-security-audit
description: Run security checklist validation.
model: haiku
---

## Single Task
Validate all 60+ security checklist items.

## Checks
```bash
# LUKS encryption
sudo cryptsetup status encrypted-vms

# File permissions
find /encrypted/vms -type f -perm /o+r -ls

# Firewall status
sudo ufw status

# virtio-fs read-only
virsh dumpxml $VM_NAME | grep -A5 filesystem | grep readonly

# AppArmor
sudo aa-status | grep qemu
```

## Input
- vm_name: Target VM name

## Output
```json
{
  "status": "pass | fail",
  "checks_passed": 58,
  "checks_failed": 2,
  "critical_issues": [],
  "warnings": []
}
```

## Parallel-Safe: Yes

## Parent: 004-security
