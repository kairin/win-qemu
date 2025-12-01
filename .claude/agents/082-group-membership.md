---
name: 082-group-membership
description: Configure user group membership.
model: haiku
---

## Single Task
Add user to required groups for KVM/libvirt access.

## Execution
```bash
# Add to groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt-qemu $USER

# Verify membership
groups $USER

# Note: Logout/login required for changes to take effect
```

## Requirements
- libvirt group: VM management access
- kvm group: Hardware acceleration
- libvirt-qemu group: Disk access

## Output
```json
{
  "status": "pass | fail",
  "user": "username",
  "groups_added": ["libvirt", "kvm", "libvirt-qemu"],
  "relogin_required": true
}
```

## Parallel-Safe: Yes

## Parent: 008-prerequisites
