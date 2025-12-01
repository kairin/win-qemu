---
name: 084-virtio-iso-download
description: Download VirtIO drivers ISO.
model: haiku
---

## Single Task
Download latest VirtIO Windows drivers ISO.

## Execution
```bash
# Create directory
mkdir -p /var/lib/libvirt/images

# Download latest stable VirtIO ISO
VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

sudo wget -O /var/lib/libvirt/images/virtio-win.iso "$VIRTIO_URL"

# Verify download
ls -la /var/lib/libvirt/images/virtio-win.iso

# Optional: Verify checksum
sha256sum /var/lib/libvirt/images/virtio-win.iso
```

## Requirements
- ISO downloaded to /var/lib/libvirt/images/
- Contains: viostor, vioscsi, NetKVM, Balloon, qemu-ga

## Output
```json
{
  "status": "pass | fail",
  "iso_path": "/var/lib/libvirt/images/virtio-win.iso",
  "iso_size_mb": 500,
  "download_url": "fedorapeople.org"
}
```

## Parallel-Safe: Yes

## Parent: 008-prerequisites
