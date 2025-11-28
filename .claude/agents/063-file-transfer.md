---
name: 063-file-transfer
description: Transfer files between host and guest.
model: haiku
---

## Single Task
Copy files using guest agent.

## Execution
```bash
# Write file to guest
virsh qemu-agent-command $VM_NAME '{
  "execute": "guest-file-open",
  "arguments": {
    "path": "C:\\temp\\file.txt",
    "mode": "w"
  }
}'

# Read file from guest
virsh qemu-agent-command $VM_NAME '{
  "execute": "guest-file-read",
  "arguments": {
    "handle": HANDLE,
    "count": 1024
  }
}'
```

## Input
- vm_name: Target VM
- source: Source file path
- destination: Destination path
- direction: host-to-guest | guest-to-host

## Output
```
status: success | error
bytes_transferred: count
destination: final path
```

## Parent: 006-automation
