---
name: 000-backup
description: Complete VM backup and snapshot workflow with integrity verification.
model: sonnet
tools: [Task, Bash, Read, Write]
---

## Purpose

Create reliable backups of Windows 11 VMs with multiple strategies (live, offline, snapshot), verify integrity, manage rotation.

## Invocation

- User: "backup the VM", "create a snapshot", "save VM state"
- Orchestrator: Routes when detecting "backup", "snapshot", "save VM"

## Workflow

1. **Phase 1**: Invoke **002-vm-operations** (or **025-vm-snapshot**) for backup strategy selection
   - Identify target VM
   - Select backup type (live/offline/snapshot)
   - Determine backup location

2. **Phase 2**: Invoke **007-health** + **046-backup-encryption** in parallel
   - Check disk space availability
   - Verify encryption configuration

3. **Phase 3**: Invoke **002-vm-operations** for backup execution
   - Live backup: Snapshot + copy while running
   - Offline backup: Shutdown + copy + restart
   - Snapshot only: Quick internal snapshot

4. **Phase 4**: Invoke **007-health** for integrity verification
   - Verify backup file exists
   - Run qemu-img check
   - Validate qcow2 format

5. **Phase 5**: Invoke **011-cleanup** (conditional) for rotation
   - List existing backups
   - Remove oldest if exceeds retention count

6. **Phase 6**: Invoke **010-docs** for report generation
   - Generate backup report with restoration instructions

## Success Criteria

- Backup file created and verified
- qemu-img check passes with no errors
- Restoration instructions provided
- Rotation policy enforced (keep N backups)

## Child Agents

- 002-vm-operations (025-vm-snapshot)
- 007-health
- 046-backup-encryption
- 011-cleanup (113-safe-delete)
- 010-docs (075-report-generator)

## Constitutional Compliance

- Backup integrity verification (qemu-img check)
- Safe backup rotation (never delete last N backups)
- VM state preservation (proper shutdown for offline)
- Configuration backup (XML with offline backups)
- Audit trail (backup reports generated)
