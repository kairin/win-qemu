---
name: 072-qemu-stack-check
description: Validate QEMU/KVM/libvirt installation.
model: haiku
---

## Single Task
Verify QEMU/KVM stack is properly installed.

## Execution
```bash
# QEMU version
qemu-system-x86_64 --version

# KVM module
lsmod | grep kvm

# libvirt daemon
systemctl status libvirtd

# User groups
groups $USER | grep -E "libvirt|kvm"
```

## Requirements
- qemu-system-x86: Installed
- kvm module: Loaded
- libvirtd: Running
- User: In libvirt and kvm groups

## Input
None required

## Output
```json
{
  "status": "pass | fail",
  "qemu_version": "8.0.0",
  "kvm_loaded": true,
  "libvirtd_running": true,
  "user_groups_ok": true,
  "issues": []
}
```

## Parallel-Safe: Yes

## Parent: 007-health
