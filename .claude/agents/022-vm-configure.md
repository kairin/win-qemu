---
name: 022-vm-configure
description: Update VM configuration settings.
model: haiku
---

## Single Task
Modify existing VM configuration.

## Execution
```bash
# Edit VM XML
virsh edit $VM_NAME

# Or apply specific changes
virsh setvcpus $VM_NAME $COUNT --config
virsh setmem $VM_NAME $SIZE --config
```

## Input
- vm_name: Target VM name
- setting: Configuration to change
- value: New value

## Output
```
status: success | error
changed: setting name
old_value: previous value
new_value: applied value
```

## Parent: 002-vm-operations
