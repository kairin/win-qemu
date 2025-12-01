---
name: 054-pst-access
description: Configure Outlook PST file access.
model: haiku
---

## Single Task
Enable PST file access through virtio-fs share.

## Execution (PowerShell in guest)
```powershell
# Verify PST files accessible
Get-ChildItem Z:\*.pst

# Test read access
$pst = Get-Item "Z:\archive.pst"
$pst.Length  # Should return file size

# Configure Outlook to use PST
# User must add PST in Outlook: File > Open > Outlook Data File
```

## Input
- pst_path: Path to PST file on share

## Output
```
status: success | error
pst_path: path to PST
size_mb: file size
readable: true | false
```

## Parallel-Safe: Yes

## Parent: 005-virtiofs
