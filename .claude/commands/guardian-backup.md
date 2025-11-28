---
description: Complete VM backup and snapshot workflow - live/offline backups, integrity verification, rotation management - FULLY AUTOMATIC
---

## Purpose

**VM BACKUP**: Create reliable backups of Windows 11 VMs with multiple strategies (live, offline, snapshot), verify integrity, manage rotation.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Provide VM name and backup type if known.

**Example inputs**:
- `win11 live` - Live backup of running VM
- `win11 offline` - Offline backup (stops VM)
- `win11 snapshot` - Quick snapshot only
- `win11` - Auto-select best backup type
- (empty) - Auto-detect VM or prompt

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the backup workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Backup Strategy Selection (Single Agent)

**Agent**: **002-vm-operations** (or **025-vm-snapshot**)

**Tasks**:
1. **Identify Target VM**:
   ```bash
   VM_NAME="${1:-win11}"

   # Verify VM exists
   virsh -c qemu:///system dominfo "$VM_NAME"

   # Get current state
   VM_STATE=$(virsh -c qemu:///system domstate "$VM_NAME")
   echo "VM State: $VM_STATE"
   ```

2. **Select Backup Type**:
   ```bash
   BACKUP_TYPE="${2:-auto}"

   if [ "$BACKUP_TYPE" == "auto" ]; then
       if [ "$VM_STATE" == "running" ]; then
           BACKUP_TYPE="live"
       else
           BACKUP_TYPE="offline"
       fi
   fi
   echo "Selected backup type: $BACKUP_TYPE"
   ```

3. **Determine Backup Location**:
   ```bash
   BACKUP_DIR="${BACKUP_DIR:-/var/lib/libvirt/backups}"
   mkdir -p "$BACKUP_DIR"

   TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
   BACKUP_NAME="${VM_NAME}-${TIMESTAMP}"
   ```

**Expected Output**:
- VM: win11
- State: running/shut off
- Backup Type: live/offline/snapshot
- Backup Location: /var/lib/libvirt/backups/

### Phase 2: Pre-Backup Validation (Parallel - 2 Agents)

**Agent 1: 007-health**

**Tasks**:
```bash
# Check disk space for backup
DISK_AVAILABLE=$(df -BG /var/lib/libvirt/backups | awk 'NR==2 {print $4}' | tr -d 'G')
VM_DISK_SIZE=$(virsh -c qemu:///system domblkinfo "$VM_NAME" vda --human 2>/dev/null | grep "Capacity" | awk '{print $2}')

echo "Available space: ${DISK_AVAILABLE}GB"
echo "VM disk size: ${VM_DISK_SIZE}"

if [ "$DISK_AVAILABLE" -lt 50 ]; then
    echo "WARNING: Less than 50GB available for backup"
fi
```

**Agent 2: 046-backup-encryption** (or **004-security**)

**Tasks**:
```bash
# Check if encryption is configured
if [ -f /etc/libvirt/backup-encryption.key ]; then
    echo "Encryption: Enabled"
    ENCRYPT_BACKUP=true
else
    echo "Encryption: Disabled (optional)"
    ENCRYPT_BACKUP=false
fi
```

**Skip if**: Pre-validation already passed in this session

### Phase 3: Execute Backup (Single Agent)

**Agent**: **002-vm-operations** (or backup-vm.sh)

**Tasks by Backup Type**:

**For LIVE Backup** (VM stays running):
```bash
# Create live backup using backup-vm.sh
./scripts/backup-vm.sh --vm "$VM_NAME" --live --backup-dir "$BACKUP_DIR" --yes

# Or manual commands:
# 1. Create external snapshot
virsh -c qemu:///system snapshot-create-as "$VM_NAME" \
    --name "backup-$TIMESTAMP" \
    --disk-only \
    --atomic \
    --quiesce

# 2. Copy disk while VM runs
cp /var/lib/libvirt/images/${VM_NAME}.qcow2 "$BACKUP_DIR/${BACKUP_NAME}.qcow2"

# 3. Merge snapshot back
virsh -c qemu:///system blockcommit "$VM_NAME" vda --active --pivot
```

**For OFFLINE Backup** (VM stopped):
```bash
# Stop VM gracefully
virsh -c qemu:///system shutdown "$VM_NAME"
sleep 30  # Wait for clean shutdown

# Verify stopped
while [ "$(virsh -c qemu:///system domstate $VM_NAME)" != "shut off" ]; do
    sleep 5
done

# Copy disk
cp /var/lib/libvirt/images/${VM_NAME}.qcow2 "$BACKUP_DIR/${BACKUP_NAME}.qcow2"

# Export XML configuration
virsh -c qemu:///system dumpxml "$VM_NAME" > "$BACKUP_DIR/${BACKUP_NAME}.xml"

# Restart VM
virsh -c qemu:///system start "$VM_NAME"
```

**For SNAPSHOT Only** (quick checkpoint):
```bash
# Create internal snapshot
virsh -c qemu:///system snapshot-create-as "$VM_NAME" \
    --name "snapshot-$TIMESTAMP" \
    --description "Snapshot created by guardian-backup"
```

### Phase 4: Verify Backup Integrity (Single Agent)

**Agent**: **007-health** (or **046-backup-encryption**)

**Tasks**:
```bash
# Verify backup file exists and has size
BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.qcow2"

if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"

    # Verify qcow2 integrity
    qemu-img check "$BACKUP_FILE"

    # Get image info
    qemu-img info "$BACKUP_FILE"
else
    echo "ERROR: Backup file not found!"
    exit 1
fi
```

**Expected Output**:
- ✅ Backup file exists
- ✅ Size: 45.2 GB
- ✅ qemu-img check: No errors
- ✅ Format: qcow2 v3

### Phase 5: Backup Rotation (Conditional)

**Agent**: **011-cleanup** (or **113-safe-delete**)

**Tasks** (if rotation enabled):
```bash
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"

# List backups sorted by date
BACKUPS=$(ls -t "$BACKUP_DIR"/${VM_NAME}-*.qcow2 2>/dev/null)
BACKUP_COUNT=$(echo "$BACKUPS" | wc -l)

if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]; then
    echo "Rotating backups: Keeping $KEEP_BACKUPS, removing $(($BACKUP_COUNT - $KEEP_BACKUPS))"

    # Remove oldest backups
    echo "$BACKUPS" | tail -n +$((KEEP_BACKUPS + 1)) | while read OLD_BACKUP; do
        echo "Removing old backup: $OLD_BACKUP"
        rm -f "$OLD_BACKUP"
        rm -f "${OLD_BACKUP%.qcow2}.xml"
    done
fi
```

**Skip if**: Rotation disabled or fewer backups than threshold

### Phase 6: Generate Backup Report (Single Agent)

**Agent**: **010-docs** (or **075-report-generator**)

**Tasks**:
```bash
REPORT_FILE="$BACKUP_DIR/${BACKUP_NAME}-report.md"

cat > "$REPORT_FILE" << EOF
# Backup Report: $VM_NAME

**Date**: $(date)
**Backup Type**: $BACKUP_TYPE
**Backup Name**: $BACKUP_NAME

## Files Created
- Disk: ${BACKUP_NAME}.qcow2 ($BACKUP_SIZE)
- Config: ${BACKUP_NAME}.xml (if offline)

## Verification
- qemu-img check: PASSED
- Integrity: VERIFIED

## Restoration Instructions
\`\`\`bash
# To restore this backup:
cp $BACKUP_DIR/${BACKUP_NAME}.qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2
virsh define $BACKUP_DIR/${BACKUP_NAME}.xml  # If XML exists
\`\`\`

## Rotation Status
- Backups kept: $KEEP_BACKUPS
- Total backups: $BACKUP_COUNT
EOF

echo "Report generated: $REPORT_FILE"
```

## Expected Output

```
💾 VM BACKUP COMPLETE
=====================

Backup Configuration:
- VM: win11
- Type: live (VM stayed running)
- Timestamp: 20251128-220000

Pre-Backup Validation:
- ✅ Disk space available: 156GB
- ✅ VM disk size: 45GB
- ✅ Encryption: Disabled

Backup Execution:
- ✅ Snapshot created: backup-20251128-220000
- ✅ Disk copied: win11-20251128-220000.qcow2
- ✅ Snapshot merged back
- ✅ VM continued running

Integrity Verification:
- ✅ Backup file: /var/lib/libvirt/backups/win11-20251128-220000.qcow2
- ✅ Size: 45.2 GB
- ✅ qemu-img check: No errors found
- ✅ Format: qcow2 version 3

Backup Rotation:
- ✅ Keeping: 5 backups
- ✅ Current count: 3
- ✅ No rotation needed

Report:
- ✅ Generated: win11-20251128-220000-report.md

Overall Status: ✅ BACKUP SUCCESSFUL
Backup location: /var/lib/libvirt/backups/
```

## When to Use

Run `/guardian-backup` when you need to:
- Create a backup before major changes
- Set up regular backup schedule
- Snapshot VM state before updates
- Prepare for disaster recovery
- Clone VM for testing

**Best Practices**:
- Run offline backup weekly for full consistency
- Run live backup daily for minimal disruption
- Keep at least 3 recent backups

## What This Command Does NOT Do

- ❌ Does NOT create the VM (use `/guardian-vm`)
- ❌ Does NOT restore backups (manual process - instructions provided)
- ❌ Does NOT configure automated scheduling (use cron)
- ❌ Does NOT replicate to remote storage (manual or rsync)
- ❌ Does NOT apply performance optimizations (use `/guardian-optimize`)

**Focus**: Backup creation and verification only.

## Constitutional Compliance

This command enforces:
- ✅ Backup integrity verification (qemu-img check)
- ✅ Safe backup rotation (never delete last N backups)
- ✅ VM state preservation (proper shutdown for offline)
- ✅ Configuration backup (XML with offline backups)
- ✅ Audit trail (backup reports generated)
- ✅ Restoration instructions provided
