---
name: 034-io-tuning
description: Optimize disk I/O settings.
model: haiku
---

## Single Task
Configure VirtIO-SCSI with optimal I/O settings.

## XML Configuration
```xml
<controller type='scsi' model='virtio-scsi'>
  <driver queues='4' iothread='1'/>
</controller>

<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
  <source file='/path/to/disk.qcow2'/>
  <target dev='sda' bus='scsi'/>
</disk>
```

## Key Settings
- `cache='none'`: Direct I/O (bypass host cache)
- `io='native'`: Linux AIO for async I/O
- `discard='unmap'`: TRIM support
- `queues='4'`: Multi-queue (match vCPU count)

## Input
- vm_name: Target VM name
- disk_path: Path to disk image

## Output
```
status: success | error
cache_mode: none
io_mode: native
queues: count
```

## Parent: 003-performance
