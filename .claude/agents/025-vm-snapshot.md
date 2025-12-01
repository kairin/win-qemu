---
name: 025-vm-snapshot
description: Manage VM snapshots.
model: haiku
---

## Single Task
Create, list, restore, or delete VM snapshots.

## Execution
```bash
# Create snapshot
virsh snapshot-create-as $VM_NAME $SNAPSHOT_NAME --description "$DESC"

# List snapshots
virsh snapshot-list $VM_NAME

# Restore snapshot
virsh snapshot-revert $VM_NAME $SNAPSHOT_NAME

# Delete snapshot
virsh snapshot-delete $VM_NAME $SNAPSHOT_NAME
```

## Input
- vm_name: Target VM name
- action: create | list | restore | delete
- snapshot_name: Snapshot identifier

## Output
```
status: success | error
action: performed action
snapshot_name: affected snapshot
snapshots: [list if action=list]
```

## Parent: 002-vm-operations
