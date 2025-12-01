---
name: 044-virtiofs-readonly
description: Enforce read-only virtio-fs mount (CRITICAL).
model: haiku
---

## Single Task
Configure virtio-fs share with mandatory read-only mode.

## XML Configuration (MANDATORY)
```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs' queue='1024'/>
  <source dir='/host/path'/>
  <target dir='share-name'/>
  <readonly/>  <!-- CRITICAL: NEVER REMOVE -->
</filesystem>
```

## Validation
```bash
# Verify read-only is set
virsh dumpxml $VM_NAME | grep -A5 filesystem | grep readonly
# MUST return: <readonly/>
```

## Input
- vm_name: Target VM name
- source_dir: Host directory to share
- target_name: Share name in guest

## Output
```
status: success | error
readonly_enforced: true
share_path: host path
```

## CRITICAL: Never configure write access - ransomware protection

## Parent: 004-security
