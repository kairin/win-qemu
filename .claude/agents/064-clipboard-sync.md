---
name: 064-clipboard-sync
description: Synchronize clipboard between host and guest.
model: haiku
---

## Single Task
Enable clipboard sharing via spice-vdagent.

## Configuration
```xml
<!-- VM XML clipboard channel -->
<channel type='spicevmc'>
  <target type='vdagent' name='com.redhat.spice.0'/>
</channel>

<!-- Graphics with clipboard -->
<graphics type='spice' autoport='yes'>
  <clipboard copypaste='yes'/>
</graphics>
```

## Guest Setup
```powershell
# spice-vdagent usually auto-installed with VirtIO drivers
# Verify service
Get-Service vdservice
```

## Input
- vm_name: Target VM

## Output
```
status: success | error
clipboard_enabled: true | false
vdagent_running: true | false
```

## Parent: 006-automation
