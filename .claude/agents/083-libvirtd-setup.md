---
name: 083-libvirtd-setup
description: Configure libvirtd service.
model: haiku
---

## Single Task
Enable and configure libvirtd daemon.

## Execution
```bash
# Enable and start libvirtd
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# Enable virtlogd for logging
sudo systemctl enable virtlogd
sudo systemctl start virtlogd

# Configure default network
sudo virsh net-autostart default
sudo virsh net-start default 2>/dev/null || true

# Verify status
systemctl status libvirtd --no-pager
virsh net-list --all
```

## Requirements
- libvirtd: Running and enabled
- virtlogd: Running for VM logging
- default network: Active with autostart

## Output
```json
{
  "status": "pass | fail",
  "libvirtd_running": true,
  "virtlogd_running": true,
  "default_network_active": true
}
```

## Parallel-Safe: No (modifies system services)

## Parent: 008-prerequisites
