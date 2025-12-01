---
description: Complete VM lifecycle workflow - health check, create, optimize, secure, test, commit - orchestrated multi-agent automation - FULLY AUTOMATIC
---

## Purpose

**COMPLETE VM SETUP**: One-command workflow to create a Windows 11 VM with full optimization, security hardening, and constitutional Git commit - zero manual configuration required.

## User Input

```text
$ARGUMENTS
```

**Expected Arguments** (all optional, defaults provided):
- `VM_NAME` - VM name (default: win11-outlook)
- `RAM_GB` - RAM allocation in GB (default: 8)
- `VCPUS` - Number of virtual CPUs (default: 4)
- `DISK_GB` - Disk size in GB (default: 100)

**Examples**:
- `/guardian-vm` → Create VM with defaults
- `/guardian-vm win11-work 16 8 150` → Custom configuration

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the complete VM creation workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Prerequisites Validation (Delegated to 007-health)

**Agent**: **007-health** → delegates to 07X Haiku agents

**Tasks**:
1. Run all 42 health checks
2. Validate CRITICAL items (hardware, QEMU/KVM stack, VirtIO)
3. Generate readiness report

**Validation Requirements**:
- ✅ Hardware virtualization enabled (VT-x/AMD-V)
- ✅ QEMU 6.0+ installed (8.0+ recommended)
- ✅ libvirt 7.0+ installed (9.0+ recommended)
- ✅ KVM module loaded
- ✅ User in libvirt and kvm groups
- ✅ OVMF firmware available (UEFI)
- ✅ TPM 2.0 emulator (swtpm) installed
- ✅ VirtIO drivers ISO present

**Blocking Conditions**:
```
IF status == "CRITICAL_ISSUES":
  STOP: "Cannot proceed - run /guardian-health for details"

IF status == "NEEDS_SETUP":
  STOP: "Prerequisites missing - follow auto-generated setup guide"
  PROVIDE: Device-specific setup script

IF status == "READY":
  PROCEED to Phase 2
```

### Phase 2: VM Creation (Delegated to 002-vm-operations)

**Agent**: **002-vm-operations** → delegates to:
- **021-vm-create**: Create VM with Q35, UEFI, TPM 2.0
- **022-vm-start**: Start VM after creation
- **023-vm-stop**: Stop VM when needed
- **024-vm-backup**: Snapshot creation
- **025-vm-restore**: Snapshot restoration

**Tasks**:
1. Parse user arguments (or use defaults)
2. Locate Windows 11 ISO and VirtIO drivers ISO
3. Generate VM XML configuration with Q35, UEFI, TPM 2.0
4. Create VM with virt-install
5. Attach VirtIO drivers ISO (for Windows installation)

**VM Configuration Template**:
```xml
<domain type='kvm'>
  <name>{{ VM_NAME }}</name>
  <memory unit='GiB'>{{ RAM_GB }}</memory>
  <vcpu placement='static'>{{ VCPUS }}</vcpu>
  <os firmware='efi'>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='threads'/>
      <source file='/var/lib/libvirt/images/{{ VM_NAME }}.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <graphics type='spice' autoport='yes'/>
    <video>
      <model type='virtio'/>
    </video>
  </devices>
</domain>
```

**virt-install Command**:
```bash
virt-install \
  --name {{ VM_NAME }} \
  --ram {{ RAM_GB * 1024 }} \
  --vcpus {{ VCPUS }} \
  --disk size={{ DISK_GB }},format=qcow2,bus=virtio \
  --cdrom {{ WIN11_ISO_PATH }} \
  --disk {{ VIRTIO_ISO_PATH }},device=cdrom \
  --os-variant win11 \
  --machine q35 \
  --boot uefi \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --network network=default,model=virtio \
  --video virtio \
  --graphics spice \
  --noautoconsole
```

**Expected Output**:
- VM created successfully
- VM XML saved to: /etc/libvirt/qemu/{{ VM_NAME }}.xml
- Disk image: /var/lib/libvirt/images/{{ VM_NAME }}.qcow2
- VM state: Shut off (ready for manual Windows installation)

### Phase 3: Performance Optimization (Delegated to 003-performance)

**Agent**: **003-performance** → delegates to:
- **031-hyperv-enlightenments**: Apply 14 Hyper-V features
- **032-virtio-tune**: VirtIO driver optimization
- **033-cpu-pinning**: CPU topology configuration
- **034-huge-pages**: Memory huge pages setup
- **035-benchmark**: Performance validation

**Tasks**:
1. Apply ALL 14 Hyper-V enlightenments
2. Configure VirtIO for all devices
3. Enable CPU pinning (if user has 8+ cores)
4. Configure huge pages (if available)

**Hyper-V Enlightenments** (MANDATORY for Windows performance):
```xml
<features>
  <hyperv mode='custom'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
    <vpindex state='on'/>
    <runtime state='on'/>
    <synic state='on'/>
    <stimer state='on'>
      <direct state='on'/>
    </stimer>
    <reset state='on'/>
    <vendor_id state='on' value='1234567890ab'/>
    <frequencies state='on'/>
    <reenlightenment state='on'/>
    <tlbflush state='on'/>
    <ipi state='on'/>
    <evmcs state='on'/>
  </hyperv>
</features>
```

**VirtIO Optimization**:
- Disk: virtio-blk with cache=none, io=threads
- Network: virtio-net with multiqueue
- Graphics: virtio-vga or virtio-gpu
- Memory: virtio-balloon

**Expected Performance**:
- Boot time: < 25 seconds
- Outlook startup: < 5 seconds
- Overall: 85-95% of native Windows performance

### Phase 4: Security Hardening (Delegated to 004-security)

**Agent**: **004-security** → delegates to:
- **041-host-security**: LUKS, .gitignore, AppArmor
- **042-vm-security**: UEFI, TPM, memory locking
- **043-network-security**: NAT mode, firewall
- **044-virtiofs-readonly**: Ransomware protection
- **045-guest-hardening**: BitLocker, Windows Defender
- **046-security-audit**: 60+ checklist validation

**Tasks**:
1. Verify QEMU process isolation
2. Configure virtio-fs read-only mode (for PST files)
3. Validate firewall configuration (M365 whitelist)
4. Check AppArmor/SELinux profile
5. Verify .gitignore excludes VM disk images

**Security Checklist** (10 critical items):
- ✅ VM disk images NOT in git (*.qcow2, *.img)
- ✅ Windows ISO NOT in git (*.iso)
- ✅ virtio-fs read-only mode (ransomware protection)
- ✅ QEMU process runs as non-root
- ✅ libvirt security driver active
- ✅ Firewall egress rules (M365 whitelist)
- ✅ TPM 2.0 for BitLocker support
- ✅ UEFI Secure Boot (optional)
- ✅ No unnecessary network exposure
- ✅ Regular backup snapshots

**Expected Output**:
- Security score: 9/10 (or 10/10 with all optional items)
- No critical security issues
- Recommendations for improvements

### Phase 5: VM Boot Test (Delegated to 002-vm-operations)

**Agent**: **022-vm-start** (delegated from 002-vm-operations)

**Tasks**:
1. Start VM
2. Wait for 60 seconds
3. Check VM status
4. Verify QEMU process running
5. Check VNC/SPICE display availability

**Boot Validation**:
```bash
# Start VM
virsh start {{ VM_NAME }}

# Wait for boot
sleep 60

# Check status
virsh list --all | grep {{ VM_NAME }}
# Expected: {{ VM_NAME }}  running

# Verify QEMU process
ps aux | grep qemu | grep {{ VM_NAME }}

# Check display
virsh domdisplay {{ VM_NAME }}
# Expected: spice://127.0.0.1:XXXXX
```

**Expected Output**:
- VM started successfully
- QEMU process running
- Display available: spice://127.0.0.1:XXXXX
- Ready for Windows installation

### Phase 6: Standards Validation (Delegated to 007-health)

**Agent**: **007-health** (with Context7 integration)

**Tasks**:
1. Query Context7 for QEMU/KVM latest best practices
2. Validate VM configuration against standards
3. Verify Hyper-V enlightenments completeness
4. Check VirtIO driver optimization

**Context7 Queries**:
- "QEMU 8.x Windows 11 VM configuration best practices"
- "Hyper-V enlightenments for Windows guests in KVM"
- "VirtIO driver optimization for Windows performance"

**Expected Output**:
- Configuration aligned with latest standards
- All recommended optimizations applied
- Priority recommendations (if any)

### Phase 7: Constitutional Commit (Delegated to 009-git)

**Agent**: **009-git** → delegates to:
- **091-branch-create**: Timestamped branch
- **092-commit-format**: Constitutional commit message
- **093-merge-strategy**: --no-ff merge to main

**Tasks**:
1. Save VM XML configuration to configs/
2. Document VM creation in research/ or docs-repo/
3. Commit with constitutional format

**Automatic Execution**:
```bash
# 1. Export VM XML
virsh dumpxml {{ VM_NAME }} > configs/{{ VM_NAME }}.xml

# 2. Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-config-vm-creation-{{ VM_NAME }}"

git checkout -b "$BRANCH"

# 3. Stage changes
git add configs/{{ VM_NAME }}.xml

# 4. Commit
git commit -m "config(vm): Create {{ VM_NAME }} with full optimization

Problem:
- Need Windows 11 VM for Microsoft 365 Outlook access
- Manual VM creation takes 2-3 hours with trial-and-error

Solution:
- Created {{ VM_NAME }} with automated workflow
- Applied all 14 Hyper-V enlightenments
- Configured VirtIO for optimal performance
- Hardened security with 10-point checklist

Technical Details:
- RAM: {{ RAM_GB }}GB
- vCPUs: {{ VCPUS }}
- Disk: {{ DISK_GB }}GB (virtio-blk, qcow2)
- Machine type: Q35 (PCI-Express)
- Firmware: UEFI (OVMF)
- TPM: 2.0 (swtpm emulator)
- Network: virtio-net (NAT mode)

Performance Targets:
- Boot time: < 25s
- Outlook startup: < 5s
- Overall: 85-95% native Windows

Security:
- virtio-fs read-only mode (ransomware protection)
- M365 egress whitelist
- AppArmor profile active
- BitLocker support (TPM 2.0)

Validation:
- Health check: READY (42/42 checks passed)
- VM boot test: PASSED
- Context7 standards: ALIGNED

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 5. Push and merge
git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
```

## Expected Output

```
🚀 COMPLETE VM CREATION WORKFLOW
═══════════════════════════════════════════════════════════════════════

VM Name: win11-outlook
Configuration:
  - RAM: 8GB
  - vCPUs: 4
  - Disk: 100GB (virtio-blk, qcow2)
  - Machine Type: Q35 (PCI-Express)
  - Firmware: UEFI (OVMF)
  - TPM: 2.0 (swtpm)

Phase 1: Prerequisites ✅ PASSED
  - Hardware virtualization: Intel VT-x
  - QEMU: 8.2.0 (optimal)
  - libvirt: 9.5.0 (optimal)
  - VirtIO drivers ISO: Found
  - Windows 11 ISO: Found
  - Readiness: READY (42/42 checks)

Phase 2: VM Creation ✅ COMPLETE
  - VM created: win11-outlook
  - Disk image: /var/lib/libvirt/images/win11-outlook.qcow2
  - XML config: /etc/libvirt/qemu/win11-outlook.xml

Phase 3: Performance Optimization ✅ COMPLETE
  - Hyper-V enlightenments: 14/14 applied
  - VirtIO devices: All configured
  - Expected performance: 85-95% native

Phase 4: Security Hardening ✅ COMPLETE
  - Security score: 9/10
  - virtio-fs: Read-only mode
  - Firewall: M365 whitelist
  - No critical issues

Phase 5: VM Boot Test ✅ PASSED
  - VM started: win11-outlook
  - QEMU process: Running
  - Display: spice://127.0.0.1:5900
  - Ready for Windows installation

Phase 6: Standards Validation ✅ ALIGNED
  - Context7 best practices: Verified
  - Configuration: Meets latest standards
  - All recommended optimizations applied

Phase 7: Constitutional Commit ✅ COMPLETE
  - Branch: 20251117-180000-config-vm-creation-win11-outlook
  - XML saved: configs/win11-outlook.xml
  - Committed and merged to main
  - Branch preserved

═══════════════════════════════════════════════════════════════════════

🎯 NEXT STEPS:

1. Connect to VM display:
   virt-manager (GUI)
   OR
   virt-viewer win11-outlook

2. Install Windows 11:
   - Boot from Windows 11 ISO
   - Load VirtIO storage driver when prompted
   - Complete Windows installation

3. After Windows installation:
   - Install remaining VirtIO drivers (network, graphics, etc.)
   - Activate Windows with valid license
   - Run /guardian-optimize (for final performance tuning)
   - Run /guardian-security (for guest hardening)

4. Configure virtio-fs for PST files:
   - Use virtio-fs-specialist agent
   - Mount as Z: drive in Windows
   - Read-only mode for ransomware protection

═══════════════════════════════════════════════════════════════════════
```

## When to Use

Run `/guardian-vm` when you need to:
- **Create new Windows 11 VM**: Automated end-to-end workflow
- **Recreate VM with different specs**: Change RAM, vCPUs, disk size
- **Deploy on new device**: After running /guardian-health
- **Test VM configuration**: Validate complete workflow

**Perfect for**: First-time VM creation with zero QEMU/KVM experience.

## What This Command Does NOT Do

- ❌ Does NOT install Windows (manual step required after VM creation)
- ❌ Does NOT install VirtIO drivers in Windows (manual or automated post-install)
- ❌ Does NOT configure Outlook (application-level setup)
- ❌ Does NOT run health checks independently (use `/guardian-health`)

**Focus**: VM infrastructure creation only - creates optimal VM, ready for Windows installation.

## Constitutional Compliance

This command enforces:
- ✅ Prerequisites validation before creation (/guardian-health integration)
- ✅ Q35 machine type (modern PCI-Express, not legacy i440FX)
- ✅ UEFI firmware (OVMF, not legacy BIOS)
- ✅ TPM 2.0 (Windows 11 requirement)
- ✅ VirtIO for ALL devices (disk, network, graphics)
- ✅ 14 Hyper-V enlightenments (Windows performance optimization)
- ✅ Security hardening (virtio-fs read-only, firewall, AppArmor)
- ✅ Context7 standards alignment (latest best practices)
- ✅ Constitutional commit (VM XML in git with proper format)
- ✅ Performance targets (85-95% native Windows)
