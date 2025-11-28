---
name: 051-virtiofs-setup
description: Configure host virtiofs daemon.
model: haiku
---

## Single Task
Set up virtiofsd daemon on host.

## Execution
```bash
# Verify virtiofsd installed
which virtiofsd

# Start daemon (libvirt handles this automatically)
# Manual start for testing:
/usr/libexec/virtiofsd --socket-path=/tmp/vhost.sock \
  --shared-dir=/path/to/share --cache=auto

# Verify in VM XML
virsh dumpxml $VM_NAME | grep -A10 filesystem
```

## Input
- share_path: Host directory to share

## Output
```
status: success | error
socket_path: virtiofs socket location
share_path: configured share directory
```

## Parent: 005-virtiofs
