---
name: 065-display-resize
description: Enable automatic display resize.
model: haiku
---

## Single Task
Configure auto display resize with QXL/VirtIO-GPU.

## Configuration
```xml
<!-- VirtIO-GPU with resize support -->
<video>
  <model type='virtio' heads='2' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>

<!-- QXL alternative -->
<video>
  <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
</video>
```

## Guest Verification
```powershell
# Check display driver
Get-WmiObject Win32_VideoController | Select Name
# Should show VirtIO GPU or QXL
```

## Input
- vm_name: Target VM

## Output
```
status: success | error
gpu_type: virtio | qxl
resize_enabled: true | false
```

## Parent: 006-automation
