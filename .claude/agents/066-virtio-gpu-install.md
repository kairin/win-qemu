---
name: 066-virtio-gpu-install
description: Install VirtIO GPU driver in Windows guest for high-resolution display.
model: haiku
---

## Single Task
Install VirtIO GPU driver in Windows guest to enable high-resolution display support (up to 4K).

## Problem
After Windows 11 installation, display is limited to 1280x800 because Windows uses
"Microsoft Basic Display Adapter" instead of the VirtIO GPU driver.

## Prerequisites
- Windows VM running and logged in
- VirtIO ISO attached as CD-ROM (virtio-win-*.iso)

## Manual Steps (GUI Required)
This driver installation requires Windows GUI interaction:

1. Open Device Manager (Win+X → Device Manager)
2. Expand "Display adapters"
3. Right-click "Microsoft Basic Display Adapter"
4. Select "Update driver"
5. Choose "Browse my computer for drivers"
6. Navigate to: `D:\viogpudo\w11\amd64\`
7. Click "Next" and allow installation
8. Reboot Windows

## Verification
```powershell
# Check if VirtIO GPU driver is installed
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion

# Expected output should show:
# Name: Red Hat VirtIO GPU DOD controller
```

## Post-Installation
- Display Settings will show multiple resolution options
- Maximum resolution depends on VRAM allocation:
  - 64MB: Up to 1920x1080
  - 256MB: Up to 4K (3840x2160)
  - 1GB+: Multiple 4K displays

## Troubleshooting
| Issue | Solution |
|-------|----------|
| Driver not found | Verify VirtIO ISO is mounted as D: drive |
| Still low resolution | Check VM VRAM allocation in libvirt config |
| No viogpudo folder | Using older VirtIO ISO - download latest |

## Input
- virtio_drive: Drive letter for VirtIO ISO (default: D)
- windows_version: w10 or w11 (default: w11)

## Output
```
status: success | error
driver_name: Red Hat VirtIO GPU DOD controller
resolution_available: true | false
```

## Parent: 002-vm-operations
