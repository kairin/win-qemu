---
name: 061-guest-agent-install
description: Install QEMU guest agent in Windows.
model: haiku
---

## Single Task
Install qemu-ga from VirtIO drivers ISO.

## Execution (PowerShell in guest)
```powershell
# Install from VirtIO ISO (D: drive)
msiexec /i "D:\guest-agent\qemu-ga-x86_64.msi" /quiet

# Verify service
Get-Service QEMU-GA

# Start if not running
Start-Service QEMU-GA
```

## Input
- virtio_drive: Drive letter of VirtIO ISO (default: D)

## Output
```
status: success | error
service_name: QEMU-GA
service_status: running | stopped
```

## Parent: 006-automation
