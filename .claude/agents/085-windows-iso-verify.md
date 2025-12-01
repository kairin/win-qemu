---
name: 085-windows-iso-verify
description: Verify Windows 11 ISO availability.
model: haiku
---

## Single Task
Verify Windows 11 ISO is available for VM installation.

## Execution
```bash
# Check common locations
find /var/lib/libvirt/images ~/Downloads -name "Win11*.iso" -o -name "windows11*.iso" 2>/dev/null

# Verify ISO is readable
file /path/to/windows11.iso

# Check ISO size (should be ~5-6GB)
ls -lh /path/to/windows11.iso

# Optional: Mount and verify contents
sudo mount -o loop,ro /path/to/windows11.iso /mnt
ls /mnt/sources/install.wim
sudo umount /mnt
```

## Requirements
- Windows 11 ISO present
- ISO size: ~5-6GB
- Contains: install.wim or install.esd

## Legal Note
Users must obtain Windows 11 ISO legally from Microsoft.
Download from: https://www.microsoft.com/software-download/windows11

## Output
```json
{
  "status": "pass | fail",
  "iso_found": true,
  "iso_path": "/var/lib/libvirt/images/Win11_23H2.iso",
  "iso_size_gb": 5.2
}
```

## Parallel-Safe: Yes

## Parent: 008-prerequisites
