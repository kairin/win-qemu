---
description: Complete virtio-fs filesystem sharing workflow - host setup, VM config, security validation, read-only enforcement - FULLY AUTOMATIC
---

## Purpose

**VIRTIOFS SETUP**: Configure complete virtio-fs filesystem sharing between Ubuntu host and Windows 11 guest with mandatory read-only security.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Provide VM name and source directory if known, otherwise command will prompt.

**Example inputs**:
- `win11 /home/user/shared` - Configure for specific VM and directory
- `win11` - Configure for VM, use default shared directory
- (empty) - Auto-detect or prompt for VM

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the virtio-fs setup workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Pre-Flight Validation (Parallel - 2 Agents)

**Agent 1: 007-health** (or **072-qemu-stack-check**)

**Tasks**:
```bash
# Verify virtiofsd available
command -v virtiofsd || command -v /usr/libexec/virtiofsd

# Check QEMU version supports virtio-fs
qemu-system-x86_64 --version | head -1

# Verify libvirt supports filesystem passthrough
virsh capabilities | grep -i "filesystem"
```

**Agent 2: 002-vm-operations** (or **023-vm-lifecycle**)

**Tasks**:
```bash
# Get VM name from user input or list available VMs
VM_NAME="${1:-win11}"

# Verify VM exists
virsh -c qemu:///system dominfo "$VM_NAME"

# Check VM state (must be shut off for config changes)
virsh -c qemu:///system domstate "$VM_NAME"
```

**Skip if**: Pre-flight already passed in this session

### Phase 2: Host Configuration (Single Agent)

**Agent**: **051-virtiofs-setup** (or **005-virtiofs**)

**Tasks**:
1. **Create Shared Directory**:
   ```bash
   SOURCE_DIR="${2:-/home/$USER/vm-shared}"

   # Create directory if not exists
   mkdir -p "$SOURCE_DIR"

   # Set proper permissions (read-only for guest)
   chmod 755 "$SOURCE_DIR"
   ```

2. **Verify virtiofsd Configuration**:
   ```bash
   # Check if virtiofsd socket directory exists
   mkdir -p /var/run/virtiofsd

   # Verify permissions for libvirt
   chown root:kvm /var/run/virtiofsd 2>/dev/null || true
   ```

**Expected Output**:
- ✅ Source directory created: /home/user/vm-shared
- ✅ Permissions set: 755 (read-only for guest)
- ✅ virtiofsd socket directory ready

### Phase 3: VM XML Configuration (Single Agent)

**Agent**: **051-virtiofs-setup** (or **022-vm-configure**)

**Tasks**:
1. **Stop VM if Running**:
   ```bash
   if [ "$(virsh -c qemu:///system domstate $VM_NAME)" == "running" ]; then
       virsh -c qemu:///system shutdown "$VM_NAME"
       sleep 10
   fi
   ```

2. **Add virtio-fs Device to VM**:
   ```bash
   # Backup current XML
   virsh -c qemu:///system dumpxml "$VM_NAME" > /tmp/${VM_NAME}-backup.xml

   # Add filesystem element (using setup-virtio-fs.sh)
   ./scripts/setup-virtio-fs.sh --vm "$VM_NAME" --source "$SOURCE_DIR" --target "host-share"
   ```

3. **Verify Configuration**:
   ```bash
   # Check filesystem element added
   virsh -c qemu:///system dumpxml "$VM_NAME" | grep -A5 "<filesystem"

   # Verify read-only mode
   virsh -c qemu:///system dumpxml "$VM_NAME" | grep "<readonly/>"
   ```

**CRITICAL**: Read-only mode is MANDATORY. Never configure writable virtio-fs.

### Phase 4: Security Validation (Single Agent)

**Agent**: **044-virtiofs-readonly** (or **004-security**)

**Tasks**:
1. **Verify Read-Only Enforcement**:
   ```bash
   # Extract filesystem config
   virsh -c qemu:///system dumpxml "$VM_NAME" | grep -A10 "<filesystem"

   # MUST contain <readonly/>
   if ! virsh -c qemu:///system dumpxml "$VM_NAME" | grep -q "<readonly/>"; then
       echo "CRITICAL: Read-only mode NOT enabled!"
       exit 1
   fi
   ```

2. **Run Security Test**:
   ```bash
   ./scripts/test-virtio-fs.sh --vm "$VM_NAME" --source "$SOURCE_DIR" --verbose
   ```

**Expected Output**:
- ✅ Read-only mode: ENFORCED
- ✅ Security validation: PASSED
- ✅ No write permissions to host filesystem

### Phase 5: Guest Instructions (Single Agent)

**Agent**: **052-winfsp-install** (or **005-virtiofs**)

**Tasks**:
Generate instructions for Windows guest setup:

```
═══════════════════════════════════════════════════════════
  WINDOWS GUEST SETUP REQUIRED
═══════════════════════════════════════════════════════════

After starting the VM, install in Windows:

1. INSTALL WinFsp (Windows File System Proxy)
   Download: https://github.com/winfsp/winfsp/releases
   File: winfsp-2.0.23075.msi (or latest)

2. INSTALL virtio-fs Driver
   - Open Device Manager
   - Find "Mass Storage Controller" (unknown device)
   - Update Driver → Browse → virtio-win.iso → viofs\w11\amd64

3. START virtio-fs Service
   Open PowerShell as Administrator:
   ```powershell
   sc.exe create VirtioFsSvc binpath="C:\Program Files\Virtio-Win\VioFS\virtiofs.exe" start=auto
   sc.exe start VirtioFsSvc
   ```

4. MOUNT Share as Drive Letter
   ```powershell
   # Mount as Z: drive (read-only)
   net use Z: \\host-share\share
   ```

5. VERIFY Access
   - Open File Explorer
   - Navigate to Z:\
   - Confirm files are visible but NOT writable

═══════════════════════════════════════════════════════════
```

### Phase 6: Constitutional Commit (Single Agent)

**Agent**: **009-git**

**Tasks**:
```bash
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="$DATETIME-feat-virtiofs-setup-$VM_NAME"

git checkout -b "$BRANCH"
git add .
git commit -m "feat(virtiofs): Configure filesystem sharing for $VM_NAME

Configuration:
- VM: $VM_NAME
- Source: $SOURCE_DIR
- Target: host-share
- Mode: READ-ONLY (mandatory)

Security:
- ✅ Read-only mode enforced
- ✅ Host filesystem protected
- ✅ Ransomware protection active

Guest Setup Required:
- WinFsp installation
- virtio-fs driver from virtio-win.iso
- virtiofs.exe service configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git checkout main
git merge "$BRANCH" --no-ff -m "Merge branch '$BRANCH' into main"
```

**Skip if**: No configuration changes made

## Expected Output

```
📁 VIRTIOFS SETUP COMPLETE
===========================

Pre-Flight Validation:
- ✅ virtiofsd: Available
- ✅ QEMU version: 8.2.0 (virtio-fs supported)
- ✅ VM exists: win11
- ✅ VM state: shut off

Host Configuration:
- ✅ Source directory: /home/kkk/vm-shared
- ✅ Permissions: 755 (read-only for guest)
- ✅ Socket directory: /var/run/virtiofsd

VM Configuration:
- ✅ Filesystem device added
- ✅ Source: /home/kkk/vm-shared
- ✅ Target tag: host-share
- ✅ Queue size: 1024

SECURITY VALIDATION (CRITICAL)
==============================
✅ Read-only mode: ENFORCED
✅ <readonly/> present in XML
✅ Host filesystem PROTECTED

Guest Setup:
- ⏳ WinFsp installation required
- ⏳ virtio-fs driver installation required
- ⏳ Service configuration required
- 📋 Instructions displayed above

Git Workflow:
- ✅ Branch: 20251128-215000-feat-virtiofs-setup-win11
- ✅ Commit: def5678
- ✅ Merged to main

Overall Status: ✅ HOST SETUP COMPLETE
Guest setup instructions provided - complete in Windows.
```

## When to Use

Run `/guardian-virtiofs` when you need to:
- Set up filesystem sharing for a new VM
- Reconfigure virtio-fs after VM changes
- Verify read-only security is enforced
- Get guest-side setup instructions
- Access PST/Outlook data files from host

**Best Practice**: Run after VM creation, before first boot with file sharing needs

## What This Command Does NOT Do

- ❌ Does NOT create the VM (use `/guardian-vm`)
- ❌ Does NOT start/stop the VM (use `/guardian-vm`)
- ❌ Does NOT install WinFsp in guest (manual step required)
- ❌ Does NOT configure writable shares (read-only mandatory)
- ❌ Does NOT apply other performance optimizations (use `/guardian-optimize`)

**Focus**: virtio-fs host configuration and security validation only.

## Constitutional Compliance

This command enforces:
- ✅ **MANDATORY READ-ONLY MODE** - Never configure writable virtio-fs
- ✅ Host filesystem protection (ransomware prevention)
- ✅ Proper permissions (755 on source directory)
- ✅ Security validation before completion
- ✅ Constitutional commit format
- ✅ Branch preservation strategy
- ✅ Guest setup instructions provided
