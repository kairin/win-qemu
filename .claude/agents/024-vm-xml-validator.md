---
name: 024-vm-xml-validator
description: Validate libvirt XML configuration.
model: haiku
---

## Single Task
Validate VM XML against requirements.

## Execution
```bash
# Dump and validate
virsh dumpxml $VM_NAME > /tmp/vm.xml
virt-xml-validate /tmp/vm.xml

# Check specific requirements
virsh dumpxml $VM_NAME | grep -E "machine='pc-q35"
virsh dumpxml $VM_NAME | grep -E "tpm model"
virsh dumpxml $VM_NAME | grep -E "loader.*pflash"
```

## Input
- vm_name: Target VM name

## Output
```
status: valid | invalid
machine_type: q35 | other
tpm_present: true | false
uefi_enabled: true | false
issues: [list of validation issues]
```

## Parallel-Safe: Yes

## Parent: 002-vm-operations
