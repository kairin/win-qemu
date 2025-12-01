---
name: 000-virtiofs
description: Complete virtio-fs filesystem sharing - host setup, VM config, read-only enforcement.
model: sonnet
tools: [Task, Bash, Read, Write]
---

## Purpose

Configure complete virtio-fs filesystem sharing between Ubuntu host and Windows 11 guest with mandatory read-only security for ransomware protection.

## Invocation

- User: "setup file sharing", "configure virtiofs", "share files with VM"
- Orchestrator: Routes when detecting "virtiofs", "file sharing", "shared folder"

## Workflow

1. **Phase 1**: Invoke **007-health** + **002-vm-operations** in parallel
   - **072-qemu-stack-check**: Verify virtiofsd available
   - **023-vm-lifecycle**: Verify VM exists and state

2. **Phase 2**: Invoke **005-virtiofs** → delegates to:
   - **051-virtiofs-setup**: Configure host daemon
   - Create shared directory with proper permissions

3. **Phase 3**: Invoke **005-virtiofs** → delegates to:
   - **051-virtiofs-setup**: Add filesystem device to VM XML
   - Verify configuration added correctly

4. **Phase 4**: Invoke **004-security** → delegates to:
   - **044-virtiofs-readonly**: CRITICAL - Enforce read-only mode
   - Run security validation tests
   - Block if read-only not enforced

5. **Phase 5**: Invoke **005-virtiofs** → delegates to:
   - **052-winfsp-install**: Generate Windows guest instructions
   - Provide WinFsp and driver installation steps

6. **Phase 6**: Invoke **009-git** for constitutional commit
   - **091-branch-create**: Timestamped branch
   - **092-commit-format**: Constitutional message
   - **093-merge-strategy**: --no-ff merge to main

## Default Configuration

- Source directory: /home/$USER/vm-shared
- Target tag: host-share
- Mode: READ-ONLY (mandatory)
- Queue size: 1024

## Success Criteria

- virtiofsd available and configured
- VM filesystem device added
- READ-ONLY mode enforced (CRITICAL)
- Security validation passed
- Guest setup instructions provided
- Constitutional commit completed

## Child Agents

- 007-health → 072-qemu-stack-check (stack validation)
- 002-vm-operations → 023-vm-lifecycle (VM state)
- 005-virtiofs → 051-055 (virtiofs configuration)
- 004-security → 044-virtiofs-readonly (security enforcement)
- 009-git → 091-095 (constitutional commit)

## Constitutional Compliance

- **MANDATORY READ-ONLY MODE** - Never configure writable virtio-fs
- Host filesystem protection (ransomware prevention)
- Proper permissions (755 on source directory)
- Security validation before completion
- Constitutional commit format
- Branch preservation strategy
- Guest setup instructions provided

## Security Warning

```
CRITICAL: virtio-fs MUST be read-only

If Windows guest is compromised by ransomware:
- Read-only: Host files PROTECTED
- Writable: Host files DESTROYED

Always verify <readonly/> in VM XML before starting VM.
```
