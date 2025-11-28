---
name: 074-network-check
description: Validate network configuration.
model: haiku
---

## Single Task
Check libvirt network configuration.

## Execution
```bash
# Default network
virsh net-list --all

# Network info
virsh net-info default

# IP address
virsh net-dhcp-leases default

# Bridge interface
ip addr show virbr0
```

## Requirements
- default network: Active
- virbr0: Bridge exists
- DHCP: Working

## Input
None required

## Output
```json
{
  "status": "pass | fail",
  "default_network": "active",
  "bridge": "virbr0",
  "dhcp_range": "192.168.122.2-254",
  "issues": []
}
```

## Parallel-Safe: Yes

## Parent: 007-health
