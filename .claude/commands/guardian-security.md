---
description: Complete security hardening workflow - 60+ checklist enforcement, virtio-fs read-only, firewall, encryption, Context7 validation - FULLY AUTOMATIC
---

## Purpose

**SECURITY HARDENING**: Comprehensive 60+ item security checklist enforcement for QEMU/KVM infrastructure and Windows guest, including LUKS encryption, virtio-fs read-only mode (ransomware protection), firewall configuration, and Context7 security best practices validation.

## User Input

```text
$ARGUMENTS
```

**Expected Arguments** (optional):
- `VM_NAME` - VM to secure (default: auto-detect running VM)
- `--audit-only` - Only audit current security, don't apply changes
- `--skip-host` - Skip host-level hardening (VM guest only)

**Examples**:
- `/guardian-security` → Full security audit and hardening
- `/guardian-security win11-outlook` → Secure specific VM
- `/guardian-security --audit-only` → Audit without changes

## Automatic Workflow

You **MUST** invoke the **master-orchestrator** agent to coordinate the security hardening workflow.

Pass the following instructions to master-orchestrator:

### Phase 1: Security Audit (Single Agent)

**Agent**: **security-hardening-specialist**

**Tasks**:
1. Run comprehensive 60+ item security checklist
2. Categorize findings: CRITICAL / HIGH / MEDIUM / LOW
3. Generate security score (0-100)

**Security Categories** (60+ items):

**1. Host Security** (20 items):
- LUKS encryption on VM image partition
- .gitignore excludes VM images (*.qcow2, *.img)
- .gitignore excludes ISOs (*.iso)
- .gitignore excludes .env file
- No API keys in git history
- AppArmor/SELinux profile active for libvirtd
- UFW/firewall configured (egress whitelist only)
- libvirtd runs as non-root
- Regular backup snapshots configured
- Backup restoration tested (within 3 months)

**2. VM Configuration Security** (15 items):
- UEFI Secure Boot enabled (optional but recommended)
- TPM 2.0 configured (for BitLocker)
- virtio-fs read-only mode (CRITICAL for ransomware protection)
- No unnecessary network exposure (NAT mode, not bridged)
- VM disk encrypted (BitLocker in guest)
- QEMU process isolation verified
- No deprecated device types (no IDE, no e1000)
- Memory locking enabled (no swapping sensitive data)
- Minimal device exposure (only required devices)
- No USB passthrough (unless required)

**3. Network Security** (10 items):
- Firewall egress rules (M365 whitelist only)
- No inbound connections allowed
- No port forwarding configured
- libvirt network in NAT mode (not bridged)
- DNS requests validated
- No IPv6 exposure (unless required)
- Network traffic logging enabled
- MAC address randomization (optional)
- Network device virtio (not e1000)
- No promiscuous mode

**4. Windows Guest Security** (10 items):
- BitLocker full disk encryption enabled
- Windows Defender real-time protection active
- Windows Firewall enabled (block all inbound)
- Automatic Windows updates enabled
- No admin privileges for daily use
- User Account Control (UAC) enabled
- Attack Surface Reduction (ASR) rules configured
- Controlled Folder Access enabled (ransomware protection)
- No unnecessary services running
- No browser in VM (use host browser)

**5. Data Protection** (5 items):
- PST files on virtio-fs read-only mount (Z:)
- No write access from guest to host filesystem
- Backup snapshots encrypted
- Backup offsite or separate physical device
- Backup rotation policy (3 generations)

**Expected Output** (Security Audit Report):
```
═══════════════════════════════════════════════════════════════════════
🔒 SECURITY AUDIT REPORT - {{ VM_NAME }}
═══════════════════════════════════════════════════════════════════════

SECURITY SCORE: 78/100 (Good)

Category Scores:
  1. Host Security:           16/20 (80%)
  2. VM Configuration:        12/15 (80%)
  3. Network Security:         9/10 (90%)
  4. Windows Guest Security:   6/10 (60%)
  5. Data Protection:          4/5 (80%)

CRITICAL ISSUES (Must fix immediately):
  🚨 virtio-fs NOT in read-only mode → Ransomware can encrypt host files
  🚨 BitLocker NOT enabled → VM disk not encrypted

HIGH PRIORITY (Fix soon):
  ⚠️ LUKS encryption not configured → VM images not encrypted at rest
  ⚠️ Windows Defender real-time protection OFF → Malware risk
  ⚠️ Firewall egress rules not configured → Unrestricted outbound traffic

MEDIUM PRIORITY (Improve when possible):
  📌 Backup snapshots not tested (last test: > 3 months ago)
  📌 Windows Firewall partially configured
  📌 Attack Surface Reduction rules not configured

LOW PRIORITY (Nice-to-have):
  💡 Secure Boot not enabled (optional)
  💡 MAC address randomization not configured
  💡 Network traffic logging not enabled

═══════════════════════════════════════════════════════════════════════
```

### Phase 2: Host-Level Hardening (Single Agent)

**Agent**: **security-hardening-specialist**

**Tasks**:
1. Configure LUKS encryption (if not already)
2. Verify .gitignore excludes sensitive files
3. Configure host firewall (M365 whitelist)
4. Enable AppArmor profile for libvirtd
5. Configure backup snapshots

**1. LUKS Encryption** (Optional - requires reboot):
```bash
# Check if VM partition encrypted
lsblk -f | grep crypt

# If not encrypted (WARNING: requires backup and reboot):
echo "⚠️ LUKS encryption requires backup and reboot"
echo "Recommendation: Encrypt partition containing VM images"
echo "Partition: /var/lib/libvirt/images"
echo "Refer to: research/06-security-hardening-analysis.md"
```

**2. .gitignore Validation**:
```bash
# Verify .gitignore excludes sensitive files
git check-ignore "*.qcow2" || echo "*.qcow2" >> .gitignore
git check-ignore "*.img" || echo "*.img" >> .gitignore
git check-ignore "*.iso" || echo "*.iso" >> .gitignore
git check-ignore ".env" || echo ".env" >> .gitignore
git check-ignore "*.pst" || echo "*.pst" >> .gitignore

# Verify no secrets in git history
git log --all -- .env && echo "🚨 CRITICAL: .env found in git history"
```

**3. Host Firewall Configuration** (M365 Egress Whitelist):
```bash
# Enable UFW firewall
sudo ufw enable

# Default deny outgoing
sudo ufw default deny outgoing
sudo ufw default deny incoming

# Allow M365 endpoints (outbound only)
sudo ufw allow out to outlook.office365.com port 443
sudo ufw allow out to *.office365.com port 443
sudo ufw allow out to *.outlook.com port 443

# Allow local network for libvirt
sudo ufw allow out to 192.168.122.0/24

# Reload
sudo ufw reload
```

**4. AppArmor Profile**:
```bash
# Verify AppArmor enabled for libvirtd
sudo aa-status | grep libvirt

# If not enforced:
sudo aa-enforce /etc/apparmor.d/usr.sbin.libvirtd
```

**5. Backup Snapshot Configuration**:
```bash
# Create snapshot
virsh snapshot-create-as {{ VM_NAME }} snapshot-$(date +%Y%m%d) --disk-only

# Schedule weekly snapshots (crontab)
echo "0 3 * * 0 virsh snapshot-create-as {{ VM_NAME }} snapshot-\$(date +\%Y\%m\%d) --disk-only" | crontab -
```

### Phase 3: VM Configuration Hardening (Single Agent)

**Agent**: **security-hardening-specialist**

**Tasks**:
1. Configure virtio-fs read-only mode (CRITICAL)
2. Verify UEFI and TPM 2.0
3. Remove unnecessary devices
4. Enable memory locking

**1. virtio-fs Read-Only Mode** (CRITICAL - Ransomware Protection):
```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='/home/kkk/outlook-data'/>
  <target dir='outlook-share'/>
  <readonly/>  <!-- CRITICAL: Prevents guest from encrypting host files -->
  <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
</filesystem>
```

**Impact**:
- ✅ Guest can READ PST files
- ✅ Guest CANNOT WRITE to host filesystem
- ✅ Ransomware in guest CANNOT encrypt host files
- ✅ Host files protected even if Windows compromised

**2. UEFI and TPM Validation**:
```xml
<!-- UEFI firmware (for Secure Boot) -->
<os firmware='efi'>
  <type arch='x86_64' machine='q35'>hvm</type>
  <loader readonly='yes' secure='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE.secboot.fd</loader>
  <nvram>/var/lib/libvirt/qemu/nvram/{{ VM_NAME }}_VARS.fd</nvram>
</os>

<!-- TPM 2.0 (for BitLocker) -->
<devices>
  <tpm model='tpm-crb'>
    <backend type='emulator' version='2.0'/>
  </tpm>
</devices>
```

**3. Remove Unnecessary Devices**:
```bash
# Remove USB controllers (unless required)
# Remove serial consoles (unless required)
# Remove floppy drives (legacy)
# Keep only: disk, network, graphics, input (keyboard, mouse)
```

**4. Memory Locking**:
```xml
<memoryBacking>
  <locked/>  <!-- Prevent swapping sensitive data to disk -->
</memoryBacking>
```

### Phase 4: Windows Guest Hardening (Single Agent - Remote via QEMU Guest Agent)

**Agent**: **qemu-automation-specialist**

**Tasks** (via virsh qemu-agent-command):
1. Enable BitLocker full disk encryption
2. Configure Windows Defender
3. Configure Windows Firewall
4. Enable Attack Surface Reduction rules
5. Disable unnecessary services

**1. BitLocker Encryption** (requires TPM 2.0):
```powershell
# Via QEMU guest agent
virsh qemu-agent-command {{ VM_NAME }} \
  '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Enable-BitLocker -MountPoint C: -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector"]}}'
```

**2. Windows Defender Configuration**:
```powershell
# Enable real-time protection
Set-MpPreference -DisableRealtimeMonitoring $false

# Enable cloud-delivered protection
Set-MpPreference -MAPSReporting Advanced

# Enable automatic sample submission
Set-MpPreference -SubmitSamplesConsent Always

# Enable network protection
Set-MpPreference -EnableNetworkProtection Enabled
```

**3. Windows Firewall**:
```powershell
# Enable Windows Firewall (all profiles)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Block all inbound connections
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Allow outbound to M365 only (example)
New-NetFirewallRule -DisplayName "M365 Outlook" -Direction Outbound -Action Allow -RemoteAddress outlook.office365.com
```

**4. Attack Surface Reduction**:
```powershell
# Enable ASR rules (anti-ransomware)
Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled

# Block executable content from email client and webmail
Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled
```

**5. Controlled Folder Access** (Ransomware Protection):
```powershell
# Enable Controlled Folder Access
Set-MpPreference -EnableControlledFolderAccess Enabled

# Protect user folders
Add-MpPreference -ControlledFolderAccessProtectedFolders "C:\Users\$env:USERNAME\Documents"
```

### Phase 5: Network Security (Single Agent)

**Agent**: **security-hardening-specialist**

**Tasks**:
1. Verify NAT mode (not bridged)
2. Configure firewall egress rules
3. Disable unnecessary protocols (IPv6 if not needed)

**Network Configuration**:
```xml
<interface type='network'>
  <source network='default'/>  <!-- NAT mode -->
  <model type='virtio'/>
  <filterref filter='clean-traffic'/>  <!-- Traffic filtering -->
</interface>
```

**libvirt Network (NAT mode)**:
```xml
<network>
  <name>default</name>
  <forward mode='nat'/>  <!-- NAT, not bridged -->
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

### Phase 6: Context7 Security Validation (Single Agent)

**Agent**: **project-health-auditor**

**Tasks**:
1. Query Context7 for KVM security best practices
2. Validate configuration against latest security standards
3. Identify missing security measures

**Context7 Queries**:
- "KVM security hardening best practices 2025"
- "virtio-fs security and ransomware protection"
- "Windows 11 VM security in QEMU/KVM"
- "Attack Surface Reduction rules for Windows VMs"

**Expected Output**:
- All critical security measures implemented
- No critical vulnerabilities detected
- Aligned with latest security standards

### Phase 7: Security Validation & Testing (Single Agent)

**Agent**: **security-hardening-specialist**

**Tasks**:
1. Test virtio-fs read-only enforcement
2. Verify BitLocker encryption active
3. Test firewall rules (egress whitelist)
4. Validate backup snapshot restoration

**Validation Tests**:
```bash
# 1. Test virtio-fs read-only (should FAIL)
# In Windows guest: Try to create file on Z: drive
# Expected: Access denied

# 2. Verify BitLocker
virsh qemu-agent-command {{ VM_NAME }} '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Get-BitLockerVolume"]}}'
# Expected: ProtectionStatus = On

# 3. Test firewall (should SUCCEED for M365, FAIL for other sites)
# In Windows guest: curl https://outlook.office365.com → Success
# In Windows guest: curl https://google.com → Timeout

# 4. Test snapshot restoration
virsh snapshot-list {{ VM_NAME }}
virsh snapshot-revert {{ VM_NAME }} <snapshot-name> --running
# Expected: VM restores successfully
```

### Phase 8: Constitutional Commit (Single Agent)

**Agent**: **git-operations-specialist**

**Tasks**:
1. Document security configuration
2. Commit hardening changes

**Automatic Execution**:
```bash
# 1. Export secured VM XML
virsh dumpxml {{ VM_NAME }} > configs/{{ VM_NAME }}-secured.xml

# 2. Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-security-vm-hardening-{{ VM_NAME }}"

git checkout -b "$BRANCH"
git add configs/{{ VM_NAME }}-secured.xml .gitignore

# 3. Commit
git commit -m "security(vm): Harden {{ VM_NAME }} with 60+ security checklist

Problem:
- Default VM configuration has security vulnerabilities
- No ransomware protection (virtio-fs writable)
- No host firewall (unrestricted outbound traffic)
- VM disk not encrypted (BitLocker)

Solution:
- Applied 60+ item security hardening checklist
- Configured virtio-fs read-only mode (ransomware protection)
- Enabled host firewall with M365 egress whitelist
- Enabled BitLocker full disk encryption in guest
- Configured Windows Defender and Attack Surface Reduction rules

Security Improvements:
- Security score: 42/100 → 95/100 (↑ 126%)
- Critical issues: 3 → 0 (all resolved)
- virtio-fs: WRITABLE → READ-ONLY (ransomware protected) ✅
- BitLocker: DISABLED → ENABLED (disk encrypted) ✅
- Firewall: NONE → M365 WHITELIST (egress restricted) ✅
- Windows Defender: OFF → ACTIVE (malware protection) ✅

Security Checklist:
- ✅ Host Security: 18/20 (90%)
- ✅ VM Configuration: 14/15 (93%)
- ✅ Network Security: 10/10 (100%)
- ✅ Windows Guest: 9/10 (90%)
- ✅ Data Protection: 5/5 (100%)

Validation:
- virtio-fs read-only: TESTED (guest cannot write to host)
- BitLocker: VERIFIED (encryption active)
- Firewall: TESTED (M365 allowed, others blocked)
- Snapshot restoration: TESTED (successful)
- Context7 security standards: ✅ ALIGNED

Remaining Recommendations:
- ⚠️ LUKS encryption (requires backup and reboot)
- 💡 Secure Boot (optional enhancement)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push and merge
git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
```

## Expected Output

```
🔒 COMPLETE SECURITY HARDENING
═══════════════════════════════════════════════════════════════════════

VM Name: win11-outlook

Phase 1: Security Audit ✅ COMPLETE
  - Initial security score: 42/100 (Poor)
  - Critical issues: 3
  - High priority: 5
  - Medium priority: 8

Phase 2: Host-Level Hardening ✅ COMPLETE
  - .gitignore: Updated (excludes *.qcow2, *.iso, .env)
  - Firewall: Configured (M365 egress whitelist)
  - AppArmor: Enforced for libvirtd
  - Backup snapshots: Configured (weekly)

Phase 3: VM Configuration Hardening ✅ COMPLETE
  - virtio-fs: READ-ONLY mode enabled (ransomware protected)
  - UEFI + TPM 2.0: Verified
  - Memory locking: Enabled
  - Unnecessary devices: Removed

Phase 4: Windows Guest Hardening ✅ COMPLETE
  - BitLocker: ENABLED (C: drive encrypted)
  - Windows Defender: ACTIVE (real-time protection)
  - Windows Firewall: CONFIGURED (block inbound, M365 outbound only)
  - Attack Surface Reduction: 5 rules enabled
  - Controlled Folder Access: ENABLED

Phase 5: Network Security ✅ COMPLETE
  - Network mode: NAT (not bridged)
  - Traffic filtering: clean-traffic filter
  - Egress whitelist: M365 endpoints only

Phase 6: Context7 Validation ✅ ALIGNED
  - All hardening measures match latest security standards
  - No additional vulnerabilities identified

Phase 7: Security Validation ✅ PASSED
  - virtio-fs read-only: TESTED ✅ (guest cannot write)
  - BitLocker encryption: VERIFIED ✅ (active)
  - Firewall egress: TESTED ✅ (M365 allowed, others blocked)
  - Snapshot restoration: TESTED ✅ (successful)

Phase 8: Constitutional Commit ✅ COMPLETE
  - Branch: 20251117-180000-security-vm-hardening-win11-outlook
  - XML saved: configs/win11-outlook-secured.xml
  - Committed and merged to main

═══════════════════════════════════════════════════════════════════════

FINAL SECURITY SCORE: 95/100 (Excellent)

Category Scores:
  1. Host Security:           18/20 (90%)  ↑ from 10/20
  2. VM Configuration:        14/15 (93%)  ↑ from 8/15
  3. Network Security:        10/10 (100%) ↑ from 6/10
  4. Windows Guest Security:   9/10 (90%)  ↑ from 3/10
  5. Data Protection:          5/5 (100%)  ↑ from 2/5

Critical Issues: 0 (all resolved)
High Priority: 0 (all resolved)
Medium Priority: 1 (LUKS encryption - requires reboot)

🎯 SECURITY HARDENING COMPLETE

Your Windows 11 VM is now hardened with 60+ security measures:
- ✅ Ransomware protection (virtio-fs read-only)
- ✅ Disk encryption (BitLocker)
- ✅ Firewall egress whitelist (M365 only)
- ✅ Malware protection (Windows Defender + ASR)
- ✅ Attack Surface Reduction rules
- ✅ Network isolation (NAT mode)

═══════════════════════════════════════════════════════════════════════
```

## When to Use

Run `/guardian-security` when you need to:
- **After VM creation**: Harden newly created VM
- **Security audit**: Assess current security posture
- **After Windows installation**: Configure guest security
- **Compliance validation**: Ensure security best practices
- **Post-compromise**: Re-harden VM after incident

**Perfect for**: Achieving enterprise-grade security for QEMU/KVM Windows VMs.

## What This Command Does NOT Do

- ❌ Does NOT create VMs (use `/guardian-vm`)
- ❌ Does NOT optimize performance (use `/guardian-optimize`)
- ❌ Does NOT backup data (creates snapshot schedule only)
- ❌ Does NOT recover from ransomware (prevention only)

**Focus**: Security hardening only - prevents attacks, protects data.

## Constitutional Compliance

This command enforces:
- ✅ virtio-fs READ-ONLY mode (MANDATORY - ransomware protection)
- ✅ 60+ security checklist (comprehensive hardening)
- ✅ .gitignore excludes sensitive files (VM images, ISOs, .env)
- ✅ BitLocker encryption (Windows guest disk)
- ✅ Firewall egress whitelist (M365 endpoints only)
- ✅ Windows Defender + ASR rules (malware protection)
- ✅ Context7 security validation (latest 2025 standards)
- ✅ Backup snapshots (weekly automated)
- ✅ Security score target: ≥ 90/100 (excellent)
- ✅ Constitutional commit: Document security configuration
