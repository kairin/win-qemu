---
name: 062-guest-agent-commands
description: Execute commands in guest via agent.
model: haiku
---

## Single Task
Run commands in Windows guest from host.

## Execution
```bash
# Ping guest agent
virsh qemu-agent-command $VM_NAME '{"execute":"guest-ping"}'

# Execute command
virsh qemu-agent-command $VM_NAME '{
  "execute": "guest-exec",
  "arguments": {
    "path": "cmd.exe",
    "arg": ["/c", "dir C:\\"]
  }
}'

# Get command output
virsh qemu-agent-command $VM_NAME '{
  "execute": "guest-exec-status",
  "arguments": {"pid": PID}
}'
```

## Input
- vm_name: Target VM
- command: Command to execute
- args: Command arguments

## Output
```
status: success | error
pid: process ID
exitcode: exit code
stdout: command output
```

## Parent: 006-automation
