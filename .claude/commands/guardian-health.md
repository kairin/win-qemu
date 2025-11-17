---
description: Comprehensive QEMU/KVM health check - validates 42 prerequisites, hardware compatibility, generates JSON reports, auto-generates setup guides - FULLY AUTOMATIC
---

## Purpose

**SYSTEM READINESS**: Validate all QEMU/KVM prerequisites (hardware, software, VirtIO drivers), detect issues BEFORE VM setup begins, generate device-specific setup guides with zero manual intervention.

## User Input

```text
$ARGUMENTS
```

**Note**: User input is OPTIONAL. Command automatically validates all 42 health check items.

## Automatic Workflow

You **MUST** invoke the **master-orchestrator** agent to coordinate the health check workflow.

Pass the following instructions to master-orchestrator:

### Phase 1: System Readiness Validation (Single Agent)

**Agent**: **qemu-health-checker**

**Tasks**:
1. **Category 1: Hardware Prerequisites** (8 CRITICAL checks):
   - CPU virtualization support (VT-x/AMD-V) - MANDATORY
   - RAM capacity (16GB+ required, 32GB recommended)
   - Storage type (SSD MANDATORY, HDD = unusable performance)
   - Free storage space (150GB+ required)
   - CPU cores (8+ recommended, 4+ minimum)
   - OS compatibility (Ubuntu 22.04+, Debian 11+)
   - Kernel version (5.15+ for modern KVM)
   - 64-bit architecture

2. **Category 2: QEMU/KVM Stack** (9 CRITICAL checks):
   - QEMU installation and version (8.0+ recommended)
   - libvirt installation and version (9.0+ recommended)
   - libvirtd daemon status (must be running)
   - KVM kernel module (must be loaded)
   - User in libvirt group
   - User in kvm group
   - Essential packages (ovmf, swtpm, qemu-utils, guestfs-tools)

3. **Category 3: VirtIO Components** (7 HIGH PRIORITY checks):
   - VirtIO drivers ISO for Windows (virtio-win)
   - OVMF/UEFI firmware
   - TPM 2.0 emulator (swtpm) - Windows 11 requirement
   - QEMU guest agent package
   - WinFsp documentation
   - virt-manager (optional)
   - virt-top (optional)

4. **Category 4: Network & Storage** (5 MEDIUM PRIORITY checks):
   - Default libvirt network exists and active
   - Network autostart enabled
   - Storage pool configured
   - virtio-fs shared directory documented

5. **Category 5: Windows Guest Resources** (5 MEDIUM PRIORITY checks):
   - Windows 11 ISO downloaded and size validated
   - Licensing documentation present
   - Windows guest tools documentation
   - .gitignore excludes ISOs

6. **Category 6: Development Environment** (8 LOW PRIORITY checks):
   - Git version (2.x+)
   - GitHub CLI authentication
   - CONTEXT7_API_KEY configured
   - .env in .gitignore
   - MCP servers configured
   - Documentation structure complete
   - AGENTS.md symlinks (delegated)
   - VM creation scripts (optional)

**Health Check Execution**:
```bash
# Run all 42 checks
# Generate JSON report
# Calculate readiness score (0-100%)
# Determine overall status: READY | NEEDS_SETUP | CRITICAL_ISSUES
```

**Expected Output** (JSON + Human-Readable):
```json
{
  "overall_status": "READY|NEEDS_SETUP|CRITICAL_ISSUES",
  "readiness_score": "85%",
  "categories": {
    "hardware_prerequisites": {"status": "passed", "checks": 8, "passed": 7, "warnings": 1},
    "qemu_kvm_stack": {"status": "warning", "checks": 9, "passed": 7, "warnings": 2},
    "virtio_components": {"status": "warning", "checks": 7, "passed": 5, "warnings": 2},
    "network_storage": {"status": "passed", "checks": 5, "passed": 5},
    "windows_guest_resources": {"status": "warning", "checks": 5, "passed": 3, "warnings": 2},
    "development_environment": {"status": "passed", "checks": 8, "passed": 7, "warnings": 1}
  },
  "summary": {
    "total_checks": 42,
    "passed": 34,
    "warnings": 8,
    "failed": 0,
    "critical_failures": 0
  },
  "recommendations": [...]
}
```

### Phase 2: Standards Compliance Validation (Conditional - If Status = READY)

**Agent**: **project-health-auditor**

**Tasks** (only if readiness check passed):
1. Query Context7 for QEMU/KVM latest best practices
2. Validate Hyper-V enlightenments configuration
3. Verify VirtIO driver optimization techniques
4. Check security hardening standards
5. Provide priority recommendations

**Skip if**: Status is NEEDS_SETUP or CRITICAL_ISSUES (fix prerequisites first)

### Phase 3: Setup Guide Generation (Conditional - If Status = NEEDS_SETUP)

**Agent**: **qemu-health-checker**

**Tasks** (only if components missing):
1. Identify all missing prerequisites
2. Generate device-specific setup script
3. Create actionable installation commands
4. Provide step-by-step guide

**Auto-Generated Setup Guide** (example):
```bash
#!/bin/bash
# Auto-generated QEMU/KVM setup guide
# Device: laptop-ubuntu
# Generated: 2025-11-17 10:00:00

echo "=== QEMU/KVM Setup Guide ==="

# Step 1: Install missing packages
echo "Step 1: Installing QEMU/KVM packages..."
sudo apt update
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system \
    libvirt-clients ovmf swtpm qemu-utils guestfs-tools

# Step 2: Add user to groups
echo "Step 2: Adding user to libvirt and kvm groups..."
sudo usermod -aG libvirt,kvm $USER

# Step 3: Enable and start libvirtd
echo "Step 3: Enabling libvirtd service..."
sudo systemctl enable --now libvirtd

# Step 4: Download VirtIO drivers ISO
echo "Step 4: Download VirtIO drivers..."
echo "Download from: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/"
echo "Save to: ~/Downloads/"

# Step 5: Download Windows 11 ISO
echo "Step 5: Download Windows 11 ISO..."
echo "Download from: https://www.microsoft.com/software-download/windows11"
echo "Save to: ~/Downloads/"

# Step 6: Logout and log back in
echo "=== SETUP COMPLETE ==="
echo "⚠️  CRITICAL: Logout and log back in for group changes to take effect"
echo "Then run: /guardian-health (to verify)"

exit 0
```

### Phase 4: Critical Failure Handling (Conditional - If Status = CRITICAL_ISSUES)

**Agent**: **qemu-health-checker**

**Tasks** (only if critical failures detected):
1. Identify blocking issues
2. Provide detailed resolution steps
3. Explain impact of each failure

**Critical Failure Examples**:

**No Hardware Virtualization**:
```
🚨 CRITICAL FAILURE: No Hardware Virtualization Support

Diagnosis:
- CPU does not support Intel VT-x or AMD-V
- OR virtualization disabled in BIOS/UEFI

Resolution:
1. Verify CPU supports virtualization (Intel: VT-x, AMD: AMD-V)
2. Enable in BIOS/UEFI:
   - Reboot and enter BIOS (F2, F10, or DEL)
   - Enable "Virtualization Technology" option
   - Save and reboot
3. Verify: egrep -c '(vmx|svm)' /proc/cpuinfo (should return > 0)

If CPU does not support: Cannot proceed, hardware upgrade required
```

**HDD Instead of SSD**:
```
🚨 CRITICAL PERFORMANCE ISSUE: HDD Detected (No SSD)

Impact:
- VM boot time: 22s → 120s+ (5x slower)
- Outlook startup: 4s → 20s+ (5x slower)
- Overall performance: 85-95% → 30-50% (unusable for daily work)

Resolution:
1. Migrate VM images to SSD partition (if available)
2. If no SSD: Hardware upgrade required (SSD installation)
3. Or use cloud VM with SSD storage

Minimum viable workaround (NOT RECOMMENDED):
- Performance will be severely degraded (30-50% native)
- Only for testing, not production use
```

## Expected Output

```
🏥 QEMU/KVM COMPREHENSIVE HEALTH REPORT
═══════════════════════════════════════════════════════════════════════

📊 OVERALL STATUS: READY
Readiness Score: 85%

✅ CATEGORY RESULTS:
──────────────────────────────────────────────────────────────────────
1. Hardware Prerequisites:     ✅ 8/8 PASSED
   - CPU Virtualization:        ✅ Intel VT-x
   - RAM Capacity:              ✅ 32GB (optimal)
   - Storage Type:              ✅ NVMe SSD
   - Free Space:                ✅ 450GB
   - CPU Cores:                 ✅ 16 cores (optimal)
   - OS Compatibility:          ✅ Ubuntu 25.10
   - Kernel Version:            ✅ 6.17.0
   - Architecture:              ✅ x86_64

2. QEMU/KVM Stack:             ⚠️  7/9 PASSED (2 warnings)
   - QEMU Installed:            ✅ 8.2.0 (optimal)
   - libvirt Installed:         ✅ 9.5.0 (optimal)
   - libvirtd Status:           ✅ Running
   - KVM Module:                ✅ Loaded (kvm_intel)
   - libvirt Group:             ⚠️  NOT MEMBER (logout required)
   - kvm Group:                 ⚠️  NOT MEMBER (logout required)
   - Essential Packages:        ✅ All installed

3. VirtIO Components:          ⚠️  5/7 PASSED (2 warnings)
   - VirtIO Drivers ISO:        ⚠️  NOT FOUND (download required)
   - OVMF Firmware:             ✅ Installed
   - TPM 2.0 (swtpm):           ✅ Installed
   - QEMU Guest Agent:          ✅ Installed
   - WinFsp Docs:               ✅ Documented
   - virt-manager:              ✅ Installed
   - virt-top:                  ℹ️  Not installed (optional)

4. Network & Storage:          ✅ 5/5 PASSED
   - Default Network:           ✅ Exists and active
   - Network Autostart:         ✅ Enabled
   - Storage Pool:              ✅ Configured
   - virtio-fs Docs:            ✅ Documented

5. Windows Guest Resources:    ⚠️  3/5 PASSED (2 warnings)
   - Windows 11 ISO:            ⚠️  NOT FOUND (download required)
   - Licensing Docs:            ✅ Present
   - Guest Tools Docs:          ✅ Documented
   - .gitignore (ISOs):         ✅ Excluded

6. Development Environment:    ✅ 7/8 PASSED (1 warning)
   - Git Version:               ✅ 2.43.0
   - GitHub CLI:                ✅ Authenticated
   - CONTEXT7_API_KEY:          ✅ Configured
   - .env in .gitignore:        ✅ Ignored
   - MCP Servers:               ✅ Configured
   - Documentation:             ✅ Complete
   - AGENTS.md Symlinks:        ✅ Verified
   - VM Creation Scripts:       ℹ️  Not created (optional)

📋 SUMMARY:
──────────────────────────────────────────────────────────────────────
Total Checks:        42
Passed:              34 (81%)
Warnings:            8 (19%)
Failed:              0 (0%)
Critical Failures:   0

🎯 NEXT ACTIONS (Priority Order):
──────────────────────────────────────────────────────────────────────

HIGH PRIORITY (Fix before VM creation):
1. Logout and log back in for group membership changes
   Command: logout
   Impact: Cannot manage VMs without root

MEDIUM PRIORITY (Required for VM creation):
2. Download VirtIO drivers ISO
   URL: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/
   Save to: ~/Downloads/
   Impact: VM will not boot without VirtIO storage drivers

3. Download Windows 11 ISO
   URL: https://www.microsoft.com/software-download/windows11
   Save to: ~/Downloads/
   Impact: Cannot create Windows VM

OPTIONAL:
4. Install virt-top for performance monitoring
   Command: sudo apt install virt-top

🚀 READY TO PROCEED:
──────────────────────────────────────────────────────────────────────
After completing HIGH PRIORITY actions:
- Run: /guardian-vm (to create Windows 11 VM)
- Or: /guardian-optimize (to optimize existing VM)
- Or: /guardian-security (to harden security)

Context7 Best Practices Validation: ✅ Available (delegated to project-health-auditor)

═══════════════════════════════════════════════════════════════════════
```

## When to Use

Run `/guardian-health` when you need to:
- **First-time setup**: Validate prerequisites before starting
- **New device setup**: Clone repository to new laptop/desktop
- **Troubleshooting**: VM won't start or performance issues
- **Pre-creation check**: Before running /guardian-vm
- **Cross-device validation**: Ensure setup works on different machines
- **Baseline establishment**: Before performance optimization

**Best Practice**: Run FIRST before any QEMU/KVM operations

## What This Command Does NOT Do

- ❌ Does NOT create VMs (use `/guardian-vm`)
- ❌ Does NOT optimize performance (use `/guardian-optimize`)
- ❌ Does NOT commit changes (use `/guardian-commit`)
- ❌ Does NOT harden security (use `/guardian-security`)

**Focus**: Health check and readiness validation only - detects issues, provides setup guidance.

## Constitutional Compliance

This command enforces:
- ✅ Hardware prerequisite validation (prevents 2-4 hours wasted on incompatible hardware)
- ✅ QEMU/KVM stack verification (all 10 mandatory packages)
- ✅ VirtIO component availability (performance drivers)
- ✅ Cross-device compatibility (works on any Ubuntu/Debian system)
- ✅ JSON report generation (machine-readable for other agents)
- ✅ Auto-generated setup guides (device-specific installation scripts)
- ✅ Critical failure detection (hardware virtualization, SSD vs HDD)
- ✅ Readiness gating (blocks VM creation until prerequisites met)
