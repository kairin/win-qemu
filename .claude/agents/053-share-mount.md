---
name: 053-share-mount
description: Mount/unmount virtio-fs shares in guest.
model: haiku
---

## Single Task
Mount virtio-fs share as network drive in Windows.

## Execution (PowerShell in guest)
```powershell
# Mount share as Z: drive
net use Z: \\.\virtiofs\outlook-share

# Verify mount
Get-PSDrive Z

# Unmount
net use Z: /delete
```

## Input
- drive_letter: Drive letter to use (default: Z)
- share_name: virtio-fs share name

## Output
```
status: success | error
drive_letter: mounted drive
share_name: virtiofs share
accessible: true | false
```

## Parent: 005-virtiofs
