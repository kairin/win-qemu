# Comprehensive Testing Gap Analysis & Roadmap

**Generated:** 2025-11-21
**Purpose:** Identify untested implementation areas and create prioritized testing roadmap
**Scope:** All documentation in docs-repo/, implementation guides, and research documents
**Current Test Coverage:** 54 tests, 87% pass rate (47/54 passing)

---

## Executive Summary

**Total Documentation Analyzed:** 27 documents across 6 phases + 19 implementation guides
**Implementation Promises Identified:** 127 testable claims
**Current Test Coverage:** 41 areas tested (32% coverage)
**Testing Gaps Found:** 86 untested areas (68% gap)

### Critical Findings

1. **Performance Claims Untested**: 85-95% native performance claim has no automated verification
2. **Security Hardening Unchecked**: 60+ security checklist items lack validation tests
3. **Hyper-V Enlightenments Unvalidated**: 14 enlightenments documented but not verified
4. **virtio-fs Read-Only Mode**: Critical ransomware protection not tested
5. **Constitutional Compliance**: Git workflow enforcement tested, but branch preservation not verified
6. **VM Configuration Validation**: XML templates validated for syntax, but not for correctness of values

### Coverage by Category

| Category | Documented Features | Tests Exist | Coverage | Priority |
|----------|-------------------|-------------|----------|----------|
| **Script Syntax** | 14 scripts | 14 tests | 100% | ✅ Complete |
| **Help Messages** | 9 scripts | 9 tests | 100% | ✅ Complete |
| **Dry-Run Execution** | 5 operations | 5 tests | 100% | ✅ Complete |
| **Error Handling** | 8 scenarios | 3 tests | 38% | 🟡 Medium |
| **Dependencies** | 13 packages | 4 tests | 31% | 🟡 Medium |
| **XML Configuration** | 25+ features | 2 tests | 8% | 🔴 Critical |
| **Performance Optimization** | 14 enlightenments | 0 tests | 0% | 🔴 Critical |
| **Security Hardening** | 60+ checklist items | 0 tests | 0% | 🔴 Critical |
| **virtio-fs Configuration** | 6 requirements | 0 tests | 0% | 🔴 Critical |
| **Git Workflows** | 5 workflows | 1 test | 20% | 🟡 Medium |
| **Multi-Agent System** | 14 agents | 0 tests | 0% | 🟡 Medium |
| **Hardware Validation** | 4 requirements | 0 tests | 0% | 🔴 Critical |

---

## Gap Analysis by Implementation Phase

### Phase 1: Hardware Requirements (4 Gaps - CRITICAL)

**Documentation:** `research/01-hardware-requirements-analysis.md`, `docs-repo/01-project-setup/`

**Claimed Features:**
1. ✅ CPU virtualization detection (vmx/svm)
2. ✅ RAM requirement verification (16GB minimum)
3. ✅ SSD vs HDD detection (rota=0)
4. ✅ CPU core count check (8+ cores)

**Current Test Status:** ❌ NO TESTS EXIST

**Missing Tests:**

#### Test Category: Pre-Installation Hardware Validation
```bash
# Test 1: CPU Virtualization Capability
test_name="hardware-cpu-virtualization"
expected: egrep -c '(vmx|svm)' /proc/cpuinfo > 0
assertion: System has hardware virtualization enabled
priority: CRITICAL

# Test 2: RAM Sufficiency
test_name="hardware-ram-minimum"
expected: free -b | awk '/^Mem:/ {print $2}' >= 17179869184  # 16GB in bytes
assertion: System has at least 16GB RAM
priority: CRITICAL

# Test 3: Storage Type Verification
test_name="hardware-storage-ssd"
expected: lsblk -d -o name,rota | grep -q '0$'
assertion: Primary storage is SSD (not HDD)
priority: CRITICAL

# Test 4: CPU Core Count
test_name="hardware-cpu-cores"
expected: nproc >= 8
assertion: System has at least 8 CPU cores
priority: HIGH

# Test 5: Disk Space Availability
test_name="hardware-disk-space"
expected: df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//' >= 150
assertion: At least 150GB free disk space
priority: HIGH
```

**Implementation Effort:** 30 minutes
**Integration:** Add to Phase 6 "Dependency Checks"

---

### Phase 2: Software Dependencies (9 Gaps - CRITICAL)

**Documentation:** `research/02-software-dependencies-analysis.md`

**Claimed Features:**
1. ✅ QEMU/KVM package availability (partially tested - only qemu-system-x86_64)
2. ❌ libvirt service status (NOT TESTED)
3. ❌ User group membership (libvirt, kvm) (NOT TESTED)
4. ❌ Default network existence (NOT TESTED)
5. ❌ OVMF firmware availability (NOT TESTED)
6. ❌ swtpm availability (NOT TESTED)
7. ❌ VirtIO drivers ISO location (NOT TESTED)
8. ❌ Windows 11 ISO availability (NOT TESTED)
9. ❌ WinFsp dependency for virtio-fs (NOT TESTED)

**Current Tests:** 4 tests (bash, virsh, qemu, xmllint)

**Missing Tests:**

#### Test Category: Post-Installation Verification
```bash
# Test 6: libvirtd Service Running
test_name="service-libvirtd-active"
expected: systemctl is-active libvirtd == "active"
assertion: libvirtd service is running
priority: CRITICAL
phase: Post-installation only

# Test 7: User Group Membership
test_name="user-groups-libvirt-kvm"
expected: groups | grep -E "(libvirt|kvm)"
assertion: Current user is in libvirt and kvm groups
priority: CRITICAL
phase: Post-installation only

# Test 8: Default Network Active
test_name="libvirt-default-network"
expected: virsh net-list --all | grep -q "default.*active"
assertion: libvirt default network is active
priority: HIGH
phase: Post-installation only

# Test 9: OVMF Firmware Files
test_name="firmware-ovmf-available"
expected: ls /usr/share/OVMF/OVMF_CODE*.fd 2>/dev/null | grep -q "."
assertion: OVMF UEFI firmware files exist
priority: HIGH
phase: Post-installation only

# Test 10: swtpm Package Installed
test_name="dep-swtpm"
expected: command -v swtpm
assertion: swtpm (software TPM) is installed
priority: HIGH
phase: Post-installation only

# Test 11: VirtIO Drivers ISO Availability
test_name="iso-virtio-drivers"
expected: [ -f "source-iso/virtio-win.iso" ] || [ -f "/var/lib/libvirt/images/virtio-win.iso" ]
assertion: VirtIO drivers ISO is available
priority: MEDIUM
phase: Pre-VM creation

# Test 12: Windows 11 ISO Availability
test_name="iso-windows11"
expected: ls source-iso/Win*.iso 2>/dev/null | grep -q "."
assertion: Windows 11 ISO is available
priority: MEDIUM
phase: Pre-VM creation
```

**Implementation Effort:** 45 minutes
**Integration:** Add Phase 10 "Post-Installation Verification"

---

### Phase 3: VM Configuration (18 Gaps - CRITICAL)

**Documentation:** `docs-repo/03-health-validation/05-VM-CONFIG-VALIDATION-REPORT.md`

**Claimed Features (from XML templates):**
1. ✅ XML syntax validity (TESTED - 2 tests)
2. ❌ Q35 chipset configuration (NOT TESTED)
3. ❌ UEFI firmware enabled (NOT TESTED)
4. ❌ Secure Boot configuration (NOT TESTED)
5. ❌ TPM 2.0 emulation (NOT TESTED)
6. ❌ 14 Hyper-V enlightenments (NOT TESTED)
7. ❌ VirtIO SCSI disk controller (NOT TESTED)
8. ❌ VirtIO network adapter (NOT TESTED)
9. ❌ VirtIO graphics (NOT TESTED)
10. ❌ VirtIO input devices (NOT TESTED)
11. ❌ CPU topology (NOT TESTED)
12. ❌ Memory allocation (NOT TESTED)
13. ❌ Clock/timer configuration (NOT TESTED)
14. ❌ virtio-fs filesystem (NOT TESTED)
15. ❌ Read-only mode enforcement (NOT TESTED - CRITICAL SECURITY)

**Current Tests:** 2 tests (XML syntax validation only)

**Missing Tests:**

#### Test Category: VM XML Configuration Verification
```bash
# Test 13: Q35 Chipset Configured
test_name="vm-config-q35-chipset"
command: grep -q "machine='pc-q35" configs/win11-vm.xml
assertion: VM uses Q35 chipset (modern PCI-Express)
priority: CRITICAL
phase: Pre-installation (template validation)

# Test 14: UEFI Firmware Enabled
test_name="vm-config-uefi-firmware"
command: grep -q "firmware='efi'" configs/win11-vm.xml
assertion: UEFI firmware is enabled (Windows 11 requirement)
priority: CRITICAL
phase: Pre-installation

# Test 15: Secure Boot Configured
test_name="vm-config-secure-boot"
command: grep -q "<feature enabled='yes' name='secure-boot'/>" configs/win11-vm.xml
assertion: Secure Boot is enabled (Windows 11 requirement)
priority: CRITICAL
phase: Pre-installation

# Test 16: TPM 2.0 Emulation
test_name="vm-config-tpm2"
command: grep -E "<tpm model='tpm-crb'>.*version='2.0'" configs/win11-vm.xml
assertion: TPM 2.0 is configured (Windows 11 requirement)
priority: CRITICAL
phase: Pre-installation

# Test 17: Hyper-V Enlightenments Count
test_name="vm-config-hyperv-enlightenments-count"
command: grep -oP '<(relaxed|vapic|spinlocks|vpindex|runtime|synic|stimer|reset|vendor_id|frequencies|reenlightenment|tlbflush|ipi|evmcs) state=' configs/win11-vm.xml | wc -l
expected: 14
assertion: All 14 Hyper-V enlightenments are configured
priority: CRITICAL
phase: Pre-installation

# Test 18-31: Individual Hyper-V Enlightenments (14 tests)
test_name="vm-config-hyperv-{enlightenment}"
enlightenments=(relaxed vapic spinlocks vpindex runtime synic stimer reset vendor_id frequencies reenlightenment tlbflush ipi evmcs)
for e in "${enlightenments[@]}"; do
  command: grep -q "<$e state='on'" configs/win11-vm.xml
  assertion: Hyper-V $e enlightenment is enabled
  priority: HIGH
done

# Test 32: VirtIO SCSI Controller
test_name="vm-config-virtio-scsi"
command: grep -q "model='virtio-scsi'" configs/win11-vm.xml
assertion: VirtIO SCSI controller configured (high performance storage)
priority: CRITICAL
phase: Pre-installation

# Test 33: VirtIO Network Adapter
test_name="vm-config-virtio-net"
command: grep -q "<model type='virtio'/>" configs/win11-vm.xml
assertion: VirtIO network adapter configured
priority: CRITICAL
phase: Pre-installation

# Test 34: VirtIO Graphics
test_name="vm-config-virtio-vga"
command: grep -q "<model type='virtio'" configs/win11-vm.xml
assertion: VirtIO graphics configured
priority: HIGH
phase: Pre-installation

# Test 35: Clock Timer Configuration
test_name="vm-config-hypervclock"
command: grep -q "<timer name='hypervclock' present='yes'/>" configs/win11-vm.xml
assertion: Hyper-V reference clock enabled
priority: HIGH
phase: Pre-installation
```

**Implementation Effort:** 1.5 hours
**Integration:** Add Phase 11 "VM Configuration Deep Validation"

---

### Phase 4: Performance Optimization (15 Gaps - CRITICAL)

**Documentation:** `outlook-linux-guide/09-performance-optimization-playbook.md`, `research/05-performance-optimization-research.md`

**Performance Claims:**
1. ❌ 85-95% native Windows performance (NOT TESTED)
2. ❌ Boot time <25 seconds (NOT TESTED)
3. ❌ Outlook startup <5 seconds (NOT TESTED)
4. ❌ PST file open <3 seconds (NOT TESTED)
5. ❌ Disk IOPS >40,000 (NOT TESTED)
6. ❌ UI frame rate 60fps (NOT TESTED)
7. ❌ CPU pinning configured (NOT TESTED)
8. ❌ Huge pages enabled (NOT TESTED)
9. ❌ Multi-queue SCSI (NOT TESTED)
10. ❌ Cache mode optimization (NOT TESTED)

**Current Tests:** 0 (no performance tests exist)

**Missing Tests:**

#### Test Category: Performance Baseline & Optimization Verification

**Pre-Installation Tests (Can Run Now):**
```bash
# Test 36: CPU Performance Baseline
test_name="perf-baseline-cpu"
command: sysbench cpu --cpu-max-prime=20000 --threads=1 run | grep "events per second"
assertion: Establish baseline CPU performance
priority: MEDIUM
phase: Pre-installation
purpose: Baseline for comparison after VM overhead

# Test 37: Disk Sequential Read Performance
test_name="perf-baseline-disk-seq-read"
command: dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 conv=fdatasync
expected: >500 MB/s on SSD
assertion: Establish baseline disk performance
priority: MEDIUM
phase: Pre-installation
```

**Post-Installation Tests (Require QEMU/KVM):**
```bash
# Test 38: Hyper-V Enlightenments Applied (Live VM)
test_name="vm-perf-hyperv-enlightenments-applied"
command: virsh dominfo <vm> && virsh dumpxml <vm> | grep -c "<hyperv"
assertion: Hyper-V enlightenments present in running VM
priority: CRITICAL
phase: Post-VM creation

# Test 39: VirtIO Drivers Loaded (Guest)
test_name="vm-perf-virtio-drivers-loaded"
command: virsh qemu-agent-command <vm> '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Get-PnpDevice | Where-Object {$_.FriendlyName -like \"*VirtIO*\"} | Measure-Object | Select -ExpandProperty Count"]}}'
expected: >= 5 (disk, network, graphics, input, balloon)
assertion: VirtIO drivers loaded in Windows guest
priority: CRITICAL
phase: Post-VM creation + Windows installed

# Test 40: CPU Pinning Verification
test_name="vm-perf-cpu-pinning"
command: virsh vcpupin <vm> | grep -v "VCPU" | wc -l
expected: > 0
assertion: CPU pinning is configured
priority: MEDIUM
phase: Post-optimization
```

**Post-Windows-Installation Tests (Require full VM):**
```bash
# Test 41: VM Boot Time
test_name="vm-perf-boot-time"
command: Measure boot time from virsh start to Windows login
expected: < 25 seconds
assertion: VM boot time meets performance target
priority: HIGH
phase: Post-optimization

# Test 42: Disk IOPS (4K Random Read)
test_name="vm-perf-disk-iops"
command: fio --name=randrw --ioengine=libaio --direct=1 --bs=4k --rw=randrw --size=1G --runtime=60
expected: > 40,000 IOPS
assertion: Disk IOPS meets performance target
priority: HIGH
phase: Post-optimization

# Test 43: Overall Performance Score
test_name="vm-perf-overall-score"
method: CrystalDiskMark in Windows guest + Geekbench
expected: >= 85% of bare metal scores
assertion: Overall VM performance meets 85-95% target
priority: CRITICAL
phase: Post-optimization
```

**Implementation Effort:** 2-3 hours
**Integration:** Add Phase 12 "Performance Benchmarking"

---

### Phase 5: Security Hardening (12 Gaps - CRITICAL)

**Documentation:** `research/06-security-hardening-analysis.md`

**Security Claims (60+ checklist items - testing top 12):**
1. ❌ virtio-fs read-only mode enforced (NOT TESTED - CRITICAL)
2. ❌ Host firewall configured (NOT TESTED)
3. ❌ LUKS encryption on host partition (NOT TESTED)
4. ❌ AppArmor/SELinux profile active (NOT TESTED)
5. ❌ BitLocker enabled in guest (NOT TESTED)
6. ❌ Windows Defender active (NOT TESTED)
7. ❌ Guest firewall configured (NOT TESTED)
8. ❌ TPM state directory permissions (NOT TESTED)
9. ❌ VM snapshot encryption (NOT TESTED)
10. ❌ Guest agent command restrictions (NOT TESTED)
11. ❌ No unnecessary services running (NOT TESTED)
12. ❌ Backup strategy in place (NOT TESTED)

**Current Tests:** 0 (no security tests exist)

**Missing Tests:**

#### Test Category: Security Hardening Verification

**Pre-Installation Security Tests:**
```bash
# Test 44: Host Partition Encryption
test_name="security-host-luks-encryption"
command: lsblk -o NAME,FSTYPE,MOUNTPOINT | grep -E "(crypt|luks)"
assertion: Host partition uses LUKS encryption
priority: CRITICAL
phase: Pre-installation
note: May not be applicable if system already encrypted

# Test 45: Host Firewall Status
test_name="security-host-firewall-active"
command: sudo ufw status | grep -q "Status: active"
assertion: Host firewall (ufw) is active
priority: HIGH
phase: Pre-installation
```

**Post-Installation Security Tests:**
```bash
# Test 46: virtio-fs Read-Only Mode (CRITICAL)
test_name="security-virtiofs-readonly"
command: virsh dumpxml <vm> | grep -A3 "<filesystem" | grep -q "<readonly/>"
assertion: virtio-fs is configured in read-only mode (ransomware protection)
priority: CRITICAL
phase: Post-virtio-fs setup
note: This is the MOST IMPORTANT security test

# Test 47: AppArmor QEMU Profile
test_name="security-apparmor-qemu-profile"
command: sudo aa-status | grep -q "libvirt"
assertion: AppArmor has libvirt/QEMU profiles loaded
priority: HIGH
phase: Post-installation

# Test 48: TPM State Directory Permissions
test_name="security-tpm-state-permissions"
command: sudo ls -ld /var/lib/libvirt/swtpm/* 2>/dev/null | awk '{print $1}' | grep -q "^drwx------"
assertion: TPM state directories have restrictive permissions (700)
priority: MEDIUM
phase: Post-VM creation

# Test 49: VM Network Isolation (NAT)
test_name="security-vm-network-nat"
command: virsh dumpxml <vm> | grep -A2 "<interface" | grep -q "type='network'"
assertion: VM uses NAT network (not bridged) for isolation
priority: HIGH
phase: Post-VM creation
```

**Post-Windows-Installation Security Tests:**
```bash
# Test 50: BitLocker Enabled in Guest
test_name="security-guest-bitlocker"
command: virsh qemu-agent-command <vm> '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Get-BitLockerVolume | Select -ExpandProperty ProtectionStatus"]}}'
expected: "On"
assertion: BitLocker encryption is enabled in Windows guest
priority: HIGH
phase: Post-Windows installation + hardening

# Test 51: Windows Defender Active
test_name="security-guest-defender-active"
command: virsh qemu-agent-command <vm> '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Get-MpComputerStatus | Select -ExpandProperty RealTimeProtectionEnabled"]}}'
expected: "True"
assertion: Windows Defender real-time protection is active
priority: HIGH
phase: Post-Windows installation

# Test 52: Guest Firewall Enabled
test_name="security-guest-firewall"
command: virsh qemu-agent-command <vm> '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","Get-NetFirewallProfile | Select -ExpandProperty Enabled"]}}'
expected: All "True"
assertion: Windows Firewall is enabled for all profiles
priority: MEDIUM
phase: Post-Windows installation

# Test 53: Backup Snapshot Exists
test_name="security-backup-snapshot"
command: virsh snapshot-list <vm> | grep -v "^---" | grep -v "^ Name" | wc -l
expected: >= 1
assertion: At least one VM snapshot exists for disaster recovery
priority: MEDIUM
phase: Post-optimization
```

**Implementation Effort:** 2 hours
**Integration:** Add Phase 13 "Security Hardening Validation"

---

### Phase 6: virtio-fs Configuration (6 Gaps - CRITICAL)

**Documentation:** `docs-repo/03-health-validation/07-VIRTIOFS-SETUP-GUIDE.md`

**virtio-fs Claims:**
1. ❌ virtio-fs configured in VM XML (NOT TESTED)
2. ❌ Read-only mode enforced (NOT TESTED - duplicate of security test)
3. ❌ Shared directory exists on host (NOT TESTED)
4. ❌ Correct mount tag configured (NOT TESTED)
5. ❌ WinFsp installed in guest (NOT TESTED)
6. ❌ Z: drive mounted in Windows (NOT TESTED)
7. ❌ Write operations correctly blocked (NOT TESTED)
8. ❌ PST file access working (NOT TESTED)

**Current Tests:** 1 test (test-virtio-fs.sh help message)

**Missing Tests:**

#### Test Category: virtio-fs Filesystem Sharing Validation
```bash
# Test 54: virtio-fs XML Configuration
test_name="virtiofs-xml-configured"
command: grep -q "<filesystem type='mount'" configs/virtio-fs-share.xml
assertion: virtio-fs is configured in XML template
priority: CRITICAL
phase: Pre-installation

# Test 55: Shared Directory Exists
test_name="virtiofs-host-directory-exists"
command: [ -d "/home/$(whoami)/outlook-data" ] || [ -d "/home/user/outlook-data" ]
assertion: virtio-fs shared directory exists on host
priority: HIGH
phase: Post-virtio-fs setup

# Test 56: Mount Tag Configured
test_name="virtiofs-mount-tag"
command: virsh dumpxml <vm> | grep -A5 "<filesystem" | grep -q "<target dir='outlook-share'/>"
assertion: virtio-fs mount tag is configured correctly
priority: HIGH
phase: Post-virtio-fs setup

# Test 57: Write Protection Enforcement (Integration Test)
test_name="virtiofs-write-protection"
method: Attempt to create file in Z: drive from guest, expect failure
command: virsh qemu-agent-command <vm> '{"execute":"guest-exec","arguments":{"path":"powershell.exe","arg":["-Command","New-Item Z:\\test.txt"]}}'
expected: Access denied / permission error
assertion: Write operations are blocked (ransomware protection)
priority: CRITICAL
phase: Post-Windows installation + virtio-fs setup

# Test 58: PST File Read Access (Integration Test)
test_name="virtiofs-pst-file-access"
method: Place test PST file in shared directory, verify Windows can read it
command: Copy test.pst to shared dir, then verify from guest
assertion: PST files are readable from Windows guest
priority: HIGH
phase: Post-Windows installation + virtio-fs setup
```

**Implementation Effort:** 1 hour
**Integration:** Add Phase 14 "virtio-fs Integration Testing"

---

### Phase 7: Git Workflow & Constitutional Compliance (5 Gaps - MEDIUM)

**Documentation:** `docs-repo/02-agent-system/04-git-hooks-documentation.md`, `CLAUDE.md`

**Git Workflow Claims:**
1. ✅ Pre-commit hook exists (TESTED - hook is installed)
2. ❌ Pre-commit hook blocks violations (NOT TESTED)
3. ❌ Branch naming convention enforced (NOT TESTED)
4. ❌ Branch preservation working (NOT TESTED)
5. ❌ Commit message format validated (NOT TESTED)
6. ❌ Symlink integrity maintained (NOT TESTED)

**Current Tests:** 0 (git workflow not tested)

**Missing Tests:**

#### Test Category: Git Workflow & Constitutional Compliance
```bash
# Test 59: Pre-Commit Hook Installed
test_name="git-precommit-hook-exists"
command: [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]
assertion: Pre-commit hook is installed and executable
priority: MEDIUM
phase: Pre-installation

# Test 60: Pre-Commit Hook Blocks Root MD Files
test_name="git-precommit-blocks-violations"
method: Create test-violation.md in root, attempt commit, expect failure
command: touch test-violation.md && git add test-violation.md && ! git commit -m "test" --no-verify 2>&1 | grep -q "docs-repo"
assertion: Pre-commit hook blocks .md files in root (except allowlist)
priority: MEDIUM
phase: Pre-installation

# Test 61: Symlink Integrity (CLAUDE.md → AGENTS.md)
test_name="git-symlink-claude-agents"
command: [ -L "CLAUDE.md" ] && [ "$(readlink CLAUDE.md)" = "AGENTS.md" ]
assertion: CLAUDE.md symlink points to AGENTS.md
priority: HIGH
phase: Pre-installation

# Test 62: Symlink Integrity (GEMINI.md → AGENTS.md)
test_name="git-symlink-gemini-agents"
command: [ -L "GEMINI.md" ] && [ "$(readlink GEMINI.md)" = "AGENTS.md" ]
assertion: GEMINI.md symlink points to AGENTS.md
priority: HIGH
phase: Pre-installation

# Test 63: AGENTS.md Constitutional Size Limit
test_name="git-agents-md-size-limit"
command: du -k AGENTS.md | awk '{print $1}' | awk '{if ($1 < 40) print "pass"}'
assertion: AGENTS.md is under 40KB constitutional limit
priority: MEDIUM
phase: Pre-installation
```

**Implementation Effort:** 30 minutes
**Integration:** Add Phase 15 "Git Constitutional Compliance"

---

### Phase 8: Multi-Agent System (3 Gaps - LOW)

**Documentation:** `.claude/agents/`, `docs-repo/02-agent-system/`

**Multi-Agent Claims:**
1. ❌ 14 agents implemented (NOT TESTED)
2. ❌ Agent communication working (NOT TESTED)
3. ❌ Orchestration workflows functional (NOT TESTED)

**Current Tests:** 0 (agents not tested)

**Missing Tests:**

#### Test Category: Multi-Agent System Validation
```bash
# Test 64: Agent Files Exist
test_name="agents-files-exist"
command: [ -d ".claude/agents" ] && [ $(ls .claude/agents/*.md 2>/dev/null | wc -l) -ge 14 ]
assertion: At least 14 agent markdown files exist
priority: LOW
phase: Pre-installation

# Test 65: Agent README Exists
test_name="agents-readme-exists"
command: [ -f ".claude/agents/README.md" ]
assertion: Agent system README documentation exists
priority: LOW
phase: Pre-installation

# Test 66: Agent Reference Complete
test_name="agents-reference-complete"
command: [ -f ".claude/agents/AGENTS-MD-REFERENCE.md" ]
assertion: Complete agent reference documentation exists
priority: LOW
phase: Pre-installation
```

**Implementation Effort:** 15 minutes
**Integration:** Add Phase 16 "Multi-Agent System Validation"

---

## Prioritized Testing Roadmap

### Phase 0: Immediate (Can Implement Now - 2 hours)

**Goal:** Add tests that can run on current system without QEMU/KVM installed

**Tests to Add (21 tests):**
1. Hardware validation (5 tests) - Phase 6 expansion
2. XML configuration deep validation (18 tests) - Phase 11 new
3. Git constitutional compliance (5 tests) - Phase 15 new
4. Pre-installation security (2 tests) - Phase 13 partial
5. Multi-agent system validation (3 tests) - Phase 16 new

**Expected Outcome:**
- Total tests: 54 → 75 (+38% increase)
- Pass rate: 87% → 75% (expected, due to 21 new tests, ~16 will pass now)
- Critical gaps closed: Hardware validation, XML deep checks

**Implementation Priority:**
1. **CRITICAL**: XML configuration validation (18 tests) - 45 min
2. **CRITICAL**: Hardware validation (5 tests) - 30 min
3. **HIGH**: Git constitutional compliance (5 tests) - 30 min
4. **MEDIUM**: Multi-agent validation (3 tests) - 15 min

**Estimated Effort:** 2 hours

---

### Phase 1: Post-Installation (After QEMU/KVM Installed - 1.5 hours)

**Prerequisites:** `sudo ./scripts/install-master.sh` + reboot completed

**Tests to Add (9 tests):**
1. Post-installation verification (7 tests) - Phase 10 new
2. Post-installation security (2 tests) - Phase 13 partial

**Expected Outcome:**
- Total tests: 75 → 84 (+12% increase)
- Pass rate: 75% → 85% (installation fixes existing failures)
- Dependency gaps closed: All installation-dependent tests

**Implementation Priority:**
1. **CRITICAL**: libvirtd service status - 10 min
2. **CRITICAL**: User group membership - 10 min
3. **CRITICAL**: Default network active - 10 min
4. **HIGH**: OVMF firmware availability - 10 min
5. **HIGH**: swtpm availability - 10 min
6. **MEDIUM**: ISO file availability - 15 min
7. **HIGH**: AppArmor profile verification - 15 min

**Estimated Effort:** 1.5 hours

---

### Phase 2: Post-VM Creation (After create-vm.sh - 2 hours)

**Prerequisites:** Windows 11 VM created, VirtIO drivers loaded

**Tests to Add (10 tests):**
1. VM configuration verification (live VM) - 30 min
2. Performance optimization verification - 45 min
3. Security hardening (VM-specific) - 45 min

**Expected Outcome:**
- Total tests: 84 → 94 (+11% increase)
- Coverage: VM creation workflow validated
- Performance: Hyper-V enlightenments verified

**Implementation Priority:**
1. **CRITICAL**: Hyper-V enlightenments applied (live VM)
2. **CRITICAL**: virtio-fs read-only mode enforced
3. **HIGH**: VirtIO drivers loaded in guest
4. **HIGH**: TPM state directory permissions
5. **MEDIUM**: CPU pinning verification
6. **MEDIUM**: Backup snapshot exists

**Estimated Effort:** 2 hours

---

### Phase 3: Post-Windows Installation (Full VM - 3 hours)

**Prerequisites:** Windows 11 installed, configured, optimized

**Tests to Add (15 tests):**
1. Performance benchmarking (7 tests) - 90 min
2. Security hardening validation (4 tests) - 60 min
3. virtio-fs integration testing (4 tests) - 30 min

**Expected Outcome:**
- Total tests: 94 → 109 (+16% increase)
- Coverage: End-to-end workflow validated
- Performance: 85-95% target verified

**Implementation Priority:**
1. **CRITICAL**: virtio-fs write protection enforcement
2. **CRITICAL**: Overall performance score (85-95%)
3. **HIGH**: VM boot time (<25s)
4. **HIGH**: Disk IOPS (>40,000)
5. **HIGH**: BitLocker enabled
6. **HIGH**: Windows Defender active
7. **MEDIUM**: PST file access working

**Estimated Effort:** 3 hours

---

### Phase 4: Continuous Integration (Future - 4-6 hours)

**Goal:** Automated regression testing, performance tracking

**Enhancements to Add:**
1. **GitHub Actions CI/CD Pipeline** (3 hours)
   - Automatic dry-run on every push
   - Pre-installation tests only (no VM creation in CI)
   - Block merge if critical tests fail

2. **Performance Regression Tracking** (2 hours)
   - JSON baseline file for performance metrics
   - Trend analysis over time
   - Alert on >20% slowdown

3. **Interactive HTML Test Reports** (2 hours)
   - Visual dashboard
   - Collapsible log sections
   - Historical test trends

4. **Context7 Integration for Best Practices Validation** (3 hours)
   - Automated lookup of QEMU/KVM best practices
   - Compare configurations against authoritative sources
   - Flag deviations from latest recommendations

**Expected Outcome:**
- Automated validation on every commit
- Performance regressions caught early
- Better visibility into test results

**Estimated Effort:** 10-13 hours total (optional enhancements)

---

## Test Implementation Plan

### Quick Wins (Next 30 Minutes)

**Highest ROI Tests to Add Right Now:**

```bash
# 1. Hardware CPU Virtualization (5 min)
test_name="hardware-cpu-virtualization"
if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null 2>&1; then
    virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
    if [[ $virt_support -gt 0 ]]; then
        log_test "PASS" "hardware-cpu-virt" "CPU virtualization support" 0 "${virt_support} cores"
    else
        log_test "FAIL" "hardware-cpu-virt" "CPU virtualization support" 1 "No vmx/svm flags"
    fi
fi

# 2. Hyper-V Enlightenments Count (10 min)
test_name="vm-config-hyperv-count"
if [[ -f "configs/win11-vm.xml" ]]; then
    enlightenment_count=$(grep -oP '<(relaxed|vapic|spinlocks|vpindex|runtime|synic|stimer|reset|vendor_id|frequencies|reenlightenment|tlbflush|ipi|evmcs) state=' configs/win11-vm.xml | wc -l)
    if [[ $enlightenment_count -eq 14 ]]; then
        log_test "PASS" "vm-config-hyperv-count" "Hyper-V enlightenments count" 0 "14/14 configured"
    else
        log_test "FAIL" "vm-config-hyperv-count" "Hyper-V enlightenments count" 1 "${enlightenment_count}/14 found"
    fi
fi

# 3. virtio-fs Read-Only Mode (5 min)
test_name="security-virtiofs-readonly-template"
if [[ -f "configs/virtio-fs-share.xml" ]]; then
    if grep -q "<readonly/>" configs/virtio-fs-share.xml; then
        log_test "PASS" "security-virtiofs-ro" "virtio-fs read-only mode (template)" 0 "Ransomware protection enabled"
    else
        log_test "FAIL" "security-virtiofs-ro" "virtio-fs read-only mode (template)" 1 "CRITICAL: Read-only mode NOT configured"
    fi
fi

# 4. Symlink Integrity (5 min)
test_name="git-symlink-claude"
if [[ -L "CLAUDE.md" ]] && [[ "$(readlink CLAUDE.md)" == "AGENTS.md" ]]; then
    log_test "PASS" "git-symlink-claude" "CLAUDE.md symlink integrity" 0 "Points to AGENTS.md"
else
    log_test "FAIL" "git-symlink-claude" "CLAUDE.md symlink integrity" 1 "Broken or missing symlink"
fi

# 5. Q35 Chipset Configured (5 min)
test_name="vm-config-q35"
if [[ -f "configs/win11-vm.xml" ]]; then
    if grep -q "machine='pc-q35" configs/win11-vm.xml; then
        log_test "PASS" "vm-config-q35" "Q35 chipset configuration" 0 "Modern PCI-Express support"
    else
        log_test "FAIL" "vm-config-q35" "Q35 chipset configuration" 1 "Q35 not found"
    fi
fi
```

**Integration:** Add to existing `run-dry-run-tests.sh` after Phase 7

---

### Test Suite Structure (Proposed Final State)

```
Phase 1: Syntax Validation (14 tests) ✅ Complete
Phase 2: Help Messages (9 tests) ✅ Complete
Phase 3: Dry-Run Execution (5 tests) ✅ Complete
Phase 4: Error Handling (3 tests) ✅ Complete
Phase 5: Config Validation (2 tests) ✅ Complete
Phase 6: Dependencies (4 tests → 9 tests) 🟡 Expand
Phase 7: Library Functions (2 tests) ✅ Complete
Phase 8: ShellCheck (14 tests) ✅ Complete
Phase 9: Runtime Errors (1 test) ✅ Complete

--- NEW PHASES (TO BE ADDED) ---

Phase 10: Post-Installation Verification (7 tests) 🆕 CRITICAL
  - libvirtd service status
  - User group membership
  - Default network active
  - OVMF firmware availability
  - swtpm availability
  - ISO file availability
  - AppArmor profile verification

Phase 11: VM Configuration Deep Validation (18 tests) 🆕 CRITICAL
  - Q35 chipset
  - UEFI firmware
  - Secure Boot
  - TPM 2.0
  - 14 Hyper-V enlightenments (1 count + 14 individual)
  - VirtIO devices (SCSI, network, graphics)
  - Clock/timer configuration

Phase 12: Performance Benchmarking (7 tests) 🆕 HIGH
  - Boot time measurement
  - Disk IOPS measurement
  - Overall performance score
  - VirtIO drivers loaded verification
  - CPU pinning verification
  - Huge pages verification
  - Baseline establishment

Phase 13: Security Hardening Validation (12 tests) 🆕 CRITICAL
  - virtio-fs read-only enforcement 🔴 CRITICAL
  - Host firewall status
  - Host partition encryption
  - AppArmor/SELinux profiles
  - BitLocker status (guest)
  - Windows Defender status (guest)
  - Guest firewall status
  - TPM permissions
  - Network isolation
  - Backup snapshot existence

Phase 14: virtio-fs Integration Testing (4 tests) 🆕 HIGH
  - XML configuration
  - Shared directory existence
  - Mount tag configuration
  - Write protection enforcement
  - PST file read access

Phase 15: Git Constitutional Compliance (5 tests) 🆕 MEDIUM
  - Pre-commit hook existence
  - Pre-commit hook enforcement
  - Symlink integrity (CLAUDE.md, GEMINI.md)
  - AGENTS.md size limit
  - Branch naming validation (future)

Phase 16: Multi-Agent System Validation (3 tests) 🆕 LOW
  - Agent files existence
  - README existence
  - Reference documentation existence
```

**Final Test Count:** 109 tests (current 54 + 55 new)
**Final Coverage:** 86% of documented features (109/127)

---

## Risk Assessment

### Critical Risks if Tests Not Implemented

1. **Performance Degradation Undetected (CRITICAL)**
   - Risk: VM performs at 50-60% instead of 85-95%
   - Impact: Unusable for daily work, project failure
   - Mitigation: Implement Phase 12 (Performance Benchmarking)

2. **Security Vulnerabilities Undetected (CRITICAL)**
   - Risk: virtio-fs misconfigured with write access
   - Impact: Ransomware can encrypt host files
   - Mitigation: Implement Test 46 (virtio-fs read-only mode) IMMEDIATELY

3. **Configuration Errors (HIGH)**
   - Risk: Hyper-V enlightenments not applied
   - Impact: Poor performance, user frustration
   - Mitigation: Implement Phase 11 (VM Configuration Deep Validation)

4. **Installation Failures (MEDIUM)**
   - Risk: Missing dependencies not caught early
   - Impact: Installation fails midway, wasted time
   - Mitigation: Implement Phase 10 (Post-Installation Verification)

5. **Constitutional Violations (LOW)**
   - Risk: Documentation organization breaks down
   - Impact: Technical debt, maintainability issues
   - Mitigation: Implement Phase 15 (Git Constitutional Compliance)

---

## Success Metrics

### Coverage Targets

| Milestone | Test Count | Coverage % | Timeline |
|-----------|-----------|------------|----------|
| **Current** | 54 | 32% | Now |
| **Phase 0 Complete** | 75 | 59% | +2 hours |
| **Phase 1 Complete** | 84 | 66% | +1.5 hours (post-install) |
| **Phase 2 Complete** | 94 | 74% | +2 hours (post-VM) |
| **Phase 3 Complete** | 109 | 86% | +3 hours (post-Windows) |
| **CI/CD Complete** | 109 | 86% | +10 hours (future) |

### Quality Targets

- **Pre-Installation:** 100% pass rate (all syntax, config validation)
- **Post-Installation:** 95% pass rate (expected 5% due to ISO availability)
- **Post-VM Creation:** 90% pass rate (expected 10% due to optimization pending)
- **Post-Optimization:** 100% pass rate (all features working)

---

## Recommendations

### Immediate Actions (Do This Week)

1. **CRITICAL**: Implement Test 46 (virtio-fs read-only mode validation) - 10 min
   - This is the HIGHEST security risk
   - Can run on template files right now
   - Prevents ransomware attack vector

2. **CRITICAL**: Implement Phase 11 (VM Configuration Deep Validation) - 45 min
   - Validates 18 critical XML configuration items
   - Catches Hyper-V enlightenment misconfigurations
   - Prevents performance degradation

3. **HIGH**: Implement Phase 6 expansion (Hardware Validation) - 30 min
   - Catches inadequate hardware before installation
   - Saves hours of troubleshooting
   - Improves user experience

4. **HIGH**: Implement Phase 15 (Git Constitutional Compliance) - 30 min
   - Maintains documentation quality
   - Prevents technical debt
   - Low effort, high value

### Short-Term Actions (Next 2 Weeks)

5. **CRITICAL**: Implement Phase 10 (Post-Installation Verification) - 1.5 hours
   - Run after QEMU/KVM installation
   - Validates all dependencies installed correctly
   - Catches installation issues early

6. **HIGH**: Implement Phase 13 (Security Hardening Validation) - 2 hours
   - Validates 12 critical security items
   - Ensures ransomware protection active
   - Verifies firewall, encryption, BitLocker

7. **HIGH**: Implement Phase 12 (Performance Benchmarking) - 90 min
   - Validates 85-95% performance claim
   - Catches performance regressions
   - Provides objective metrics

### Long-Term Actions (Next Month)

8. **MEDIUM**: Implement Phase 14 (virtio-fs Integration Testing) - 1 hour
   - End-to-end virtio-fs validation
   - PST file access verification
   - Write protection enforcement testing

9. **LOW**: Implement Phase 16 (Multi-Agent System Validation) - 15 min
   - Validates agent system intact
   - Low priority (agents working)

10. **OPTIONAL**: Implement Phase 4 (CI/CD Pipeline) - 10-13 hours
    - Automated testing on every commit
    - Performance regression tracking
    - Interactive HTML reports

---

## Conclusion

**Current State:**
- 54 tests, 87% pass rate
- 32% coverage of documented features
- Critical gaps in performance, security, configuration validation

**Recommended Immediate Focus:**
1. virtio-fs read-only mode test (10 min) - CRITICAL SECURITY
2. VM configuration deep validation (45 min) - CRITICAL PERFORMANCE
3. Hardware validation (30 min) - CRITICAL UX
4. Git constitutional compliance (30 min) - HIGH MAINTAINABILITY

**Total Immediate Effort:** 2 hours
**Expected Outcome:** 75 tests, 59% coverage, critical risks mitigated

**Full Roadmap Timeline:**
- Phase 0 (Immediate): +2 hours → 75 tests, 59% coverage
- Phase 1 (Post-install): +1.5 hours → 84 tests, 66% coverage
- Phase 2 (Post-VM): +2 hours → 94 tests, 74% coverage
- Phase 3 (Post-Windows): +3 hours → 109 tests, 86% coverage

**Total Investment:** 8.5 hours → 86% coverage, comprehensive validation

---

**Document Version:** 1.0
**Author:** Claude Code Analysis
**Date:** 2025-11-21
**Purpose:** Guide testing roadmap and prioritize test implementation
