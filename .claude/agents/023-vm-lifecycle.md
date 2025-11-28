---
name: 023-vm-lifecycle
description: Start/stop/pause VM operations.
model: haiku
---

## Single Task
Manage VM state transitions.

## Execution
```bash
# Start VM
virsh start $VM_NAME

# Graceful shutdown
virsh shutdown $VM_NAME

# Force stop
virsh destroy $VM_NAME

# Pause/Resume
virsh suspend $VM_NAME
virsh resume $VM_NAME
```

## Input
- vm_name: Target VM name
- action: start | stop | shutdown | suspend | resume

## Output
```
status: success | error
action: performed action
previous_state: state before action
current_state: state after action
```

## Parent: 002-vm-operations
