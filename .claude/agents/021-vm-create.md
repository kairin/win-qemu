---
name: 021-vm-create
description: Create Windows 11 VM with Q35, UEFI, TPM 2.0.
model: haiku
---

## Single Task
Create new VM with standardized configuration.

## Execution
```bash
virt-install \
  --name $VM_NAME \
  --ram $RAM_MB \
  --vcpus $VCPUS \
  --disk path=$DISK_PATH,size=$DISK_GB,bus=scsi \
  --os-variant win11 \
  --machine q35 \
  --boot uefi \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --cdrom $WINDOWS_ISO \
  --disk $VIRTIO_ISO,device=cdrom
```

## Input
- vm_name: Name for the VM
- ram_mb: Memory in MB (default: 8192)
- vcpus: CPU count (default: 4)
- disk_gb: Disk size in GB (default: 100)

## Output
```
status: success | error
vm_name: created VM name
error: error message if failed
```

## Parent: 002-vm-operations
