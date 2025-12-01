---
name: 073-virtio-check
description: Validate VirtIO drivers availability.
model: haiku
---

## Single Task
Check VirtIO drivers ISO is available.

## Execution
```bash
# Check for VirtIO ISO
find /var/lib/libvirt/images -name "virtio-win*.iso" 2>/dev/null

# Or in common locations
ls -la ~/Downloads/virtio-win*.iso 2>/dev/null

# Verify ISO contents
isoinfo -l -i /path/to/virtio-win.iso | head -20
```

## Requirements
- VirtIO ISO downloaded
- Contains: viostor, vioscsi, NetKVM, Balloon, qemu-ga

## Input
- search_paths: Directories to search (optional)

## Output
```json
{
  "status": "pass | fail",
  "iso_found": true,
  "iso_path": "/path/to/virtio-win.iso",
  "drivers_present": ["viostor", "vioscsi", "NetKVM"]
}
```

## Parallel-Safe: Yes

## Parent: 007-health
