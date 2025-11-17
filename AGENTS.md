# QEMU/KVM Windows Virtualization - LLM Instructions (2025 Edition)

> 🔧 **CRITICAL**: This file contains NON-NEGOTIABLE requirements that ALL AI assistants (Claude, Gemini, ChatGPT, etc.) working on this repository MUST follow at ALL times.

## 🎯 Project Overview

**QEMU/KVM Windows Virtualization** is a comprehensive solution for running native Microsoft 365 Outlook desktop application on Ubuntu 25.10 using hardware-assisted virtualization with near-native performance (85-95%).

**Core Problem**: Running Microsoft 365 Outlook in a constrained enterprise environment where:
- Graph API access is prohibited (Constraint #1)
- Third-party email clients are blocked (Constraint #2)
- Direct .pst file access is required (Constraint #3)
- Custom automation is needed (Constraint #4)
- Free and open-source solutions are preferred (Constraint #5)

**Solution**: QEMU/KVM virtualization with VirtIO drivers, Hyper-V enlightenments, virtio-fs filesystem sharing, and QEMU guest agent automation.

**Quick Links:** [README](outlook-linux-guide/00-README.md) • [Research Index](research/00-RESEARCH-INDEX.md) • [Implementation Guide](outlook-linux-guide/05-qemu-kvm-reference-architecture.md) • [Performance Optimization](outlook-linux-guide/09-performance-optimization-playbook.md) • [Security Hardening](research/06-security-hardening-analysis.md)

## ⚡ NON-NEGOTIABLE REQUIREMENTS

### 🚨 CRITICAL: Hardware Requirements (MANDATORY)

**Minimum System Requirements** - These are NON-NEGOTIABLE:

```bash
# CPU: Hardware virtualization MUST be enabled
egrep -c '(vmx|svm)' /proc/cpuinfo  # Must return > 0
# Intel VT-x or AMD-V required

# RAM: Minimum 16GB, Recommended 32GB
free -h  # Must show at least 16GB total
# 8GB for guest VM, 8GB for host OS

# Storage: SSD MANDATORY (HDD = unusable performance)
lsblk -d -o name,rota  # Must show rota=0 (SSD)
# Minimum 150GB free space

# CPU Cores: Minimum 8 cores (4 for guest, 4 for host)
nproc  # Must return >= 8
```

**Performance Baseline**:
- SSD vs HDD: 10-30x faster I/O performance
- With optimization: 85-95% native Windows performance
- Without optimization: Only 50-60% (unusable for daily work)

**Reference Document**: `research/01-hardware-requirements-analysis.md`

### 🚨 CRITICAL: Software Dependencies (MANDATORY)

**Ubuntu Host Packages** (10 mandatory + 3 optional):

```bash
# Core QEMU/KVM Stack (MANDATORY)
sudo apt install -y \
    qemu-system-x86 \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    ovmf \
    swtpm \
    qemu-utils \
    guestfs-tools

# Performance Monitoring (OPTIONAL but recommended)
sudo apt install -y \
    virt-top \
    libvirt-daemon-driver-qemu \
    qemu-block-extra
```

**Windows Guest Requirements**:
1. Windows 11 ISO (download from: https://www.microsoft.com/software-download/windows11)
2. VirtIO drivers for Windows (ISO from: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/)
3. WinFsp (for virtio-fs support: https://github.com/winfsp/winfsp/releases)
4. QEMU Guest Agent (included in virtio-win ISO)

**Installation Sequence** (8 phases - MUST follow in order):
1. Host package installation
2. Libvirt user group configuration
3. Windows 11 VM creation (Q35, UEFI, TPM 2.0)
4. VirtIO driver loading during Windows installation
5. Post-installation VirtIO driver configuration
6. WinFsp installation for virtio-fs
7. QEMU Guest Agent installation
8. Performance optimization (Hyper-V enlightenments)

**Reference Document**: `research/02-software-dependencies-analysis.md`

### 🚨 CRITICAL: Licensing & Legal Compliance (HIGH RISK)

**Windows 11 Licensing** (MANDATORY):
- **REQUIRED**: Windows 11 Pro **Retail** license (~$199 USD)
- **PROHIBITED**: OEM licenses (tied to hardware, non-transferable to VMs)
- **PROHIBITED**: Volume licensing without proper authorization
- **VERIFICATION**: Check license type with `slmgr.vbs /dlv` in Windows

**Microsoft 365 Licensing**:
- VM counts toward 5-device activation limit
- Corporate M365 accounts require IT approval
- **HIGH RISK**: Using corporate M365 without approval = Shadow IT violation

**Decision Framework** - Proceed ONLY if ALL conditions met:
- [ ] Using **personal** M365 account OR have **written IT approval**
- [ ] Will purchase legitimate **Windows 11 Pro Retail** license
- [ ] Organization **not in regulated industry** OR have compliance approval
- [ ] Willing to implement **full security hardening**
- [ ] Understand this is **unsupported by IT department**

**Do NOT Proceed** if ANY apply:
- [ ] No IT approval for **corporate M365** access
- [ ] Regulated industry (HIPAA, SOX, FINRA, FedRAMP)
- [ ] Corporate policy prohibits BYOD/VMs
- [ ] Storing sensitive data in PST files on personal system
- [ ] Unwilling to purchase proper Windows license
- [ ] Employment contract prohibits shadow IT

**Reference Document**: `research/03-licensing-legal-compliance.md`

### 🚨 CRITICAL: Network & Connectivity (MANDATORY)

**Network Architecture** (RECOMMENDED: NAT mode):

```xml
<!-- NAT Network (Recommended) - Provides isolation -->
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>

<!-- Bridged Network (Alternative) - For RemoteApp -->
<!-- Only if seamless window integration needed -->
<interface type='bridge'>
  <source bridge='br0'/>
  <model type='virtio'/>
</interface>
```

**Microsoft 365 Connectivity Requirements**:
- Outbound HTTPS (443) to `*.office365.com`, `*.outlook.com`
- No inbound connections required for NAT mode
- Corporate VPN: Test connectivity from inside VM
- Firewall: Whitelist M365 endpoints (see research doc)

**SSL/TLS Inspection**:
- If corporate SSL inspection is active, import root CA into Windows guest
- Test with: `Test-NetConnection outlook.office365.com -Port 443`

**Reference Document**: `research/04-network-connectivity-requirements.md`

### 🚨 CRITICAL: Performance Optimization (MANDATORY for Daily Use)

**Hyper-V Enlightenments** (The "secret sauce" - MANDATORY):

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

**VirtIO Performance** (ALL devices must use VirtIO):
- Disk: `virtio-blk` or `virtio-scsi` (NOT IDE/SATA)
- Network: `virtio-net` (NOT e1000/rtl8139)
- Graphics: `virtio-vga` or `virtio-gpu`
- Filesystem: `virtio-fs` (NOT Samba/9p)

**CPU Pinning** (For consistent performance):
```xml
<vcpu placement='static' cpuset='0-7'>8</vcpu>
<cputune>
  <vcpupin vcpu='0' cpuset='0'/>
  <vcpupin vcpu='1' cpuset='1'/>
  <!-- Pin each vCPU to dedicated physical core -->
</cputune>
```

**Memory Optimization** (Huge pages for better performance):
```bash
# Enable huge pages on host
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# VM configuration
<memoryBacking>
  <hugepages/>
  <locked/>
</memoryBacking>
```

**Performance Expectations** (Fully Optimized):
| Metric | Default | Optimized | Native |
|--------|---------|-----------|--------|
| Boot Time | 45s | 22s | 15s |
| Outlook Startup | 12s | 4s | 3s |
| .pst Open (1GB) | 8s | 2s | 1.5s |
| UI Frame Rate | 30fps | 60fps | 60fps |
| Disk IOPS (4K) | 8,000 | 45,000 | 52,000 |
| **Overall** | **50-60%** | **85-95%** | **100%** |

**Reference Documents**:
- `outlook-linux-guide/09-performance-optimization-playbook.md`
- `research/05-performance-optimization-research.md`
- `research/05-performance-quick-reference.md`

### 🚨 CRITICAL: Security Hardening (MANDATORY)

**Host Security** (60+ checklist items):

```bash
# 1. LUKS Encryption (MANDATORY for PST files)
# Encrypt partition containing VM images and PST files
sudo cryptsetup luksFormat /dev/sdX
sudo cryptsetup open /dev/sdX encrypted_vm

# 2. virtio-fs Read-Only Mode (CRITICAL for ransomware protection)
<filesystem type='mount' accessmode='passthrough'>
  <source dir='/home/user/outlook-data'/>
  <target dir='outlook-share'/>
  <readonly/>  <!-- MANDATORY: Prevents guest malware from encrypting host files -->
</filesystem>

# 3. Egress Firewall (Whitelist M365 endpoints only)
sudo ufw enable
sudo ufw default deny outgoing
sudo ufw allow out to outlook.office365.com port 443
sudo ufw allow out to *.office365.com port 443

# 4. AppArmor/SELinux Profile (Restrict QEMU process)
# Use libvirt's built-in security driver

# 5. Regular Backups (Encrypted, tested restores)
sudo virsh snapshot-create-as win11-vm snapshot1 --disk-only
```

**Guest Security**:
- [ ] BitLocker encryption enabled
- [ ] Windows Defender real-time protection
- [ ] Windows Firewall enabled (block all inbound except M365)
- [ ] Automatic updates enabled
- [ ] No admin privileges for daily use

**Attack Surface Reduction**:
- Disable unnecessary services in guest
- Minimal software installation (Windows + Office + VirtIO drivers only)
- No browser in VM (use host browser)
- No file sharing except virtio-fs

**Reference Document**: `research/06-security-hardening-analysis.md`

### 🚨 CRITICAL: Branch Management & Git Strategy

#### Branch Preservation (MANDATORY)
- **NEVER DELETE BRANCHES** without explicit user permission
- **ALL BRANCHES** contain valuable configuration and research history
- **NO** automatic cleanup with `git branch -d`
- **YES** to automatic merge to main branch, preserving dedicated branch

#### Branch Naming (MANDATORY SCHEMA)
**Format**: `YYYYMMDD-HHMMSS-type-short-description`

**Type Prefixes**:
- `feat-` - New features (VM creation scripts, automation tools)
- `fix-` - Bug fixes (configuration errors, performance issues)
- `docs-` - Documentation updates (research, guides)
- `config-` - Configuration changes (XML templates, libvirt)
- `security-` - Security hardening (firewall, encryption)
- `perf-` - Performance optimizations (Hyper-V enlightenments, tuning)

**Examples**:
- `20251117-150000-feat-vm-creation-automation`
- `20251117-150515-config-hyperv-enlightenments`
- `20251117-151030-docs-troubleshooting-guide`
- `20251117-151545-security-luks-encryption`

#### Git Workflow (MANDATORY)
```bash
# 1. Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"

# 2. Make changes and test
# ... code/config changes ...

# 3. Commit with standard message
git add .
git commit -m "Descriptive commit message

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push branch
git push -u origin "$BRANCH_NAME"

# 5. Merge to main (preserve branch)
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main

# 6. NEVER DELETE BRANCH (preservation MANDATORY)
# ❌ WRONG: git branch -d "$BRANCH_NAME"
# ✅ CORRECT: Keep branch for historical reference
```

#### Constitutional Compliance
- **MANDATORY**: Every VM configuration change uses timestamped branch
- **MANDATORY**: All script/automation development uses branch workflow
- **MANDATORY**: Documentation updates follow same strategy
- **VIOLATION**: Direct commits to main without branch = constitutional violation

## 🏗️ System Architecture

### Directory Structure (RECOMMENDED)

```
win-qemu/
├── outlook-linux-guide/          # Implementation documentation (10 files)
│   ├── 00-README.md              # Main guide index
│   ├── 05-qemu-kvm-reference-architecture.md  # ⭐ Primary setup guide
│   ├── 09-performance-optimization-playbook.md  # ⭐ Performance tuning
│   └── ...
├── research/                     # Technical analysis (9 files)
│   ├── 00-RESEARCH-INDEX.md      # Research overview
│   ├── 01-hardware-requirements-analysis.md
│   ├── 02-software-dependencies-analysis.md
│   └── ...
├── scripts/                      # Automation scripts (TO BE CREATED)
│   ├── create-vm.sh              # Automated VM creation
│   ├── install-virtio-drivers.sh # Driver installation automation
│   ├── configure-performance.sh  # Apply Hyper-V enlightenments
│   ├── setup-virtio-fs.sh        # Configure filesystem sharing
│   └── health-check.sh           # System validation
├── configs/                      # Configuration templates (TO BE CREATED)
│   ├── win11-vm.xml              # VM XML definition template
│   ├── virtio-fs-share.xml       # Filesystem sharing config
│   └── network-nat.xml           # NAT network configuration
├── .claude/                      # Claude Code configuration
├── AGENTS.md                     # ⭐ This file (single source of truth)
├── CLAUDE.md -> AGENTS.md        # Symlink for Claude Code
└── GEMINI.md -> AGENTS.md        # Symlink for Gemini CLI
```

### Technology Stack (NON-NEGOTIABLE)

**Virtualization Layer**:
- QEMU 8.0+ (hardware emulation)
- KVM (kernel-based virtual machine)
- libvirt 9.0+ (management API)
- Q35 chipset (modern PCI-Express)
- OVMF/EDK2 (UEFI firmware)
- swtpm (TPM 2.0 emulation for Windows 11)

**Performance Drivers** (VirtIO):
- virtio-blk/virtio-scsi (storage)
- virtio-net (network)
- virtio-vga/virtio-gpu (graphics)
- virtio-fs (filesystem sharing)
- virtio-balloon (memory management)

**Integration Layer**:
- QEMU Guest Agent (host-guest communication)
- virsh (libvirt CLI for automation)
- WinFsp (Windows userspace filesystem for virtio-fs)

**Optional Components**:
- FreeRDP (for RemoteApp seamless window integration)
- virt-manager (GUI management)
- virt-top (performance monitoring)

## 🤖 Multi-Agent System

### Overview

This project includes a sophisticated **13-agent system** designed to automate and orchestrate all aspects of QEMU/KVM Windows virtualization, from VM creation to performance optimization, security hardening, and documentation maintenance.

**Agent Architecture**:
- **8 Core Infrastructure Agents**: Documentation integrity, Git operations, orchestration, health monitoring
- **5 QEMU/KVM Specialized Agents**: VM operations, performance optimization, security hardening, virtio-fs, automation

**Key Benefits**:
- 87.7% time savings through parallel execution
- 100% constitutional compliance enforcement
- Automated best practices verification
- Self-documenting workflows

**Detailed Documentation**: `.claude/agents/README.md`

---

### Agent Inventory

#### Core Infrastructure Agents (8)

1. **symlink-guardian** - Verify CLAUDE.md/GEMINI.md → AGENTS.md symlinks
2. **documentation-guardian** - Enforce AGENTS.md as single source of truth
3. **constitutional-compliance-agent** - Keep AGENTS.md modular (<40KB)
4. **git-operations-specialist** - ALL Git operations (commit, push, merge, branch)
5. **constitutional-workflow-orchestrator** - Shared Git workflow templates
6. **master-orchestrator** - Multi-agent coordination and parallel execution
7. **project-health-auditor** - System health assessment and QEMU/KVM verification
8. **repository-cleanup-specialist** - Identify and consolidate redundant files

#### QEMU/KVM Specialized Agents (5)

9. **vm-operations-specialist** - VM lifecycle management (create, start, stop, destroy)
10. **performance-optimization-specialist** - Hyper-V enlightenments, VirtIO tuning, benchmarking
11. **security-hardening-specialist** - Security checklist enforcement, LUKS, firewall, AppArmor
12. **virtio-fs-specialist** - VirtIO filesystem sharing setup and management
13. **qemu-automation-specialist** - QEMU guest agent automation, virsh scripting

---

### How to Invoke Agents

**Method 1: Natural Language (Recommended)**

Simply describe what you want to accomplish:

```
User: "Create a new Windows 11 VM with full optimization"
→ master-orchestrator coordinates multiple agents automatically

User: "Optimize my VM for best performance"
→ performance-optimization-specialist activates

User: "Audit my VM security"
→ security-hardening-specialist runs 60+ checklist
```

**Method 2: Direct Agent Reference**

Reference the agent by name if you know which one you need:

```
User: "Use vm-operations-specialist to create a VM"
User: "Run project-health-auditor to check system status"
User: "Invoke git-operations-specialist to commit changes"
```

**Method 3: Orchestrated Workflows**

For complex multi-step tasks, the master-orchestrator automatically:
- Analyzes task requirements
- Identifies required agents
- Executes agents in parallel where possible
- Manages dependencies and sequencing
- Handles error recovery

---

### Agent Selection Guide

| Need | Recommended Agent(s) | Estimated Time |
|------|---------------------|----------------|
| Create new VM | vm-operations-specialist | 1 hour |
| Optimize performance | performance-optimization-specialist | 1-2 hours |
| Harden security | security-hardening-specialist | 2-3 hours |
| Share PST files | virtio-fs-specialist | 1 hour |
| Automate tasks | qemu-automation-specialist | 1 hour |
| Git operations | git-operations-specialist | <5 minutes |
| Multi-step workflow | master-orchestrator | Varies |
| Health check | project-health-auditor | <5 minutes |
| Cleanup repository | repository-cleanup-specialist | <10 minutes |
| Documentation sync | documentation-guardian, symlink-guardian | <5 minutes |

---

### Common Workflows

#### Workflow 1: Complete VM Setup (Orchestrated)

**User Request**: "Create a new Windows 11 VM with full optimization"

**Agent Execution Sequence**:
1. **master-orchestrator** - Coordinates all agents
2. **project-health-auditor** - Verify hardware/software compatibility
3. **vm-operations-specialist** - Create base VM with Q35/UEFI/TPM
4. **performance-optimization-specialist** - Apply 14 Hyper-V enlightenments
5. **security-hardening-specialist** - Run 60+ security checklist
6. **virtio-fs-specialist** - Configure PST file sharing (Z: drive)
7. **qemu-automation-specialist** - Install QEMU guest agent
8. **git-operations-specialist** - Commit configuration with constitutional format

**Duration**: 2-3 hours (automated) vs 8-11 hours (manual)
**Time Savings**: 60-75%

---

#### Workflow 2: Performance Optimization (Single Agent)

**User Request**: "My VM is running slow, optimize it"

**Agent Execution**:
1. **performance-optimization-specialist** activates
   - Baseline performance measurement
   - Apply Hyper-V enlightenments (14 features)
   - Configure CPU pinning and huge pages
   - VirtIO driver optimization
   - Benchmark and validate (target: 85-95% native)
   - Generate performance report

**Duration**: 1-2 hours

---

#### Workflow 3: Security Audit (Single Agent)

**User Request**: "Audit my VM security"

**Agent Execution**:
1. **security-hardening-specialist** activates
   - Run 60+ security checklist items
   - Verify LUKS encryption status
   - Check firewall configuration (M365 whitelist)
   - Validate virtio-fs read-only mode (ransomware protection)
   - Verify BitLocker and Windows Defender in guest
   - Generate security report with recommendations

**Duration**: 30 minutes

---

#### Workflow 4: Git Operations (Single Agent)

**User Request**: "Commit my VM configuration changes"

**Agent Execution**:
1. **git-operations-specialist** activates
   - Validate branch naming (YYYYMMDD-HHMMSS-type-description)
   - Check for sensitive files (.iso, .qcow2, .pst, .env)
   - Create constitutional commit message
   - Execute Git operations with proper formatting
   - Push to remote (if requested)

**Duration**: <5 minutes

---

### Agent Communication Patterns

**Delegation**: Agents delegate to other agents when needed
- **vm-operations-specialist** → **git-operations-specialist** (for config commits)
- **performance-optimization-specialist** → **vm-operations-specialist** (for XML updates)
- **security-hardening-specialist** → **vm-operations-specialist** (for security config)

**Parallel Execution**: Multiple agents run simultaneously when safe
- 75% of agents are parallel-safe (9/12 operational agents)
- Example: documentation-guardian + symlink-guardian + constitutional-compliance-agent

**Sequential Execution**: Dependency-driven workflows
- Health checks → VM creation → Optimization → Security → Automation → Git commit

---

### Agent Best Practices

**DO**:
- ✅ Let master-orchestrator handle complex multi-step tasks
- ✅ Use specific agents for single-purpose operations
- ✅ Trust agent recommendations for workflow optimization
- ✅ Review agent-generated reports before proceeding

**DON'T**:
- ❌ Bypass agents for manual Git operations (violates constitutional compliance)
- ❌ Skip health checks before VM operations
- ❌ Ignore security-hardening-specialist recommendations
- ❌ Delete branches without git-operations-specialist approval

---

### Agent System Files

```
.claude/agents/
├── README.md                              # Agent system overview and quick start
├── COMPLETE-AGENT-SYSTEM-REPORT.md        # Full implementation report
├── PHASE-1-COMPLETION-REPORT.md           # Phase 1 detailed results
│
├── # CORE INFRASTRUCTURE (8 agents)
├── symlink-guardian.md
├── documentation-guardian.md
├── constitutional-compliance-agent.md
├── git-operations-specialist.md
├── constitutional-workflow-orchestrator.md
├── master-orchestrator.md
├── project-health-auditor.md
├── repository-cleanup-specialist.md
│
└── # QEMU/KVM SPECIALIZED (5 agents)
    ├── vm-operations-specialist.md
    ├── performance-optimization-specialist.md
    ├── security-hardening-specialist.md
    ├── virtio-fs-specialist.md
    └── qemu-automation-specialist.md
```

**Total Documentation**: 9,728 lines, ~255 KB

---

### Getting Started with Agents

**First-Time Setup**:
1. Read `.claude/agents/README.md` for complete overview
2. Run health check: "Check my system for QEMU/KVM compatibility"
3. Review agent capabilities in README.md
4. Start with simple workflows, progress to complex orchestration

**Example First Interaction**:
```
User: "Check if my system is ready for QEMU/KVM"
→ project-health-auditor activates
→ Verifies hardware, software, VirtIO drivers, VMs
→ Generates actionable recommendations
```

**For More Information**:
- **Quick Reference**: `.claude/agents/README.md`
- **Complete Report**: `.claude/agents/COMPLETE-AGENT-SYSTEM-REPORT.md`
- **Implementation Details**: `.claude/agents/PHASE-1-COMPLETION-REPORT.md`

---

## 📊 Implementation Phases

This project follows a **7-phase implementation approach** for complete VM setup. Detailed scripts and step-by-step instructions are available in the referenced documentation files.

### Phase Overview

| Phase | Description | Duration | Agent | Reference |
|-------|-------------|----------|-------|-----------|
| **1** | Hardware Verification | 10 min | project-health-auditor | [Hardware Analysis](research/01-hardware-requirements-analysis.md) |
| **2** | Software Installation | 2-3 hrs | Manual + scripts | [Software Dependencies](research/02-software-dependencies-analysis.md) |
| **3** | VM Creation | 1 hr | vm-operations-specialist | [Reference Architecture](outlook-linux-guide/05-qemu-kvm-reference-architecture.md) |
| **4** | Performance Optimization | 1-2 hrs | performance-optimization-specialist | [Performance Playbook](outlook-linux-guide/09-performance-optimization-playbook.md) |
| **5** | Filesystem Sharing | 1 hr | virtio-fs-specialist | [Bridge Integration](outlook-linux-guide/06-seamless-bridge-integration.md) |
| **6** | Security Hardening | 2-3 hrs | security-hardening-specialist | [Security Analysis](research/06-security-hardening-analysis.md) |
| **7** | Automation Setup | 1 hr | qemu-automation-specialist | [Automation Engine](outlook-linux-guide/07-automation-engine.md) |

**Total Time**: 8-11 hours (first-time setup)

---

### Quick Implementation Commands

**Phase 1: Hardware Check**
```bash
# Use project-health-auditor agent or run manually:
egrep -c '(vmx|svm)' /proc/cpuinfo  # Must be > 0
free -h  # Minimum 16GB RAM
lsblk -d -o name,rota  # SSD required (rota=0)
nproc  # Minimum 8 cores recommended
```

**Phase 2: Install QEMU/KVM**
```bash
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system \
    libvirt-clients virt-manager ovmf swtpm qemu-utils guestfs-tools
sudo usermod -aG libvirt,kvm $USER
# Log out and back in for group changes
```

**Phase 3: Create VM (Use vm-operations-specialist)**
```bash
# Download ISOs first:
# - Windows 11: https://www.microsoft.com/software-download/windows11
# - VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/

# Agent handles virt-install with Q35, UEFI, TPM 2.0, VirtIO
# Manual: Load VirtIO storage driver during Windows installation
```

**Phase 4: Optimize Performance (Use performance-optimization-specialist)**
- Apply 14 Hyper-V enlightenments (see NON-NEGOTIABLE REQUIREMENTS above)
- Configure CPU pinning and huge pages
- VirtIO driver optimization
- Target: 85-95% native Windows performance

**Phase 5: Configure virtio-fs (Use virtio-fs-specialist)**
- Setup read-only filesystem sharing (ransomware protection)
- Install WinFsp in Windows guest
- Mount as Z: drive for PST file access

**Phase 6: Harden Security (Use security-hardening-specialist)**
- 60+ checklist items (LUKS, UFW firewall, AppArmor)
- BitLocker + Windows Defender in guest
- Backup snapshots

**Phase 7: Setup Automation (Use qemu-automation-specialist)**
- Install QEMU guest agent
- Test virsh qemu-agent-command
- Configure PowerShell automation

---

### Using Agents for Automated Setup

**Complete Orchestrated Workflow**:
```
User: "Create a new Windows 11 VM with full optimization"
→ master-orchestrator coordinates all 7 phases automatically
→ Duration: 2-3 hours vs 8-11 hours manual (60-75% time savings)
```

**Individual Phase Execution**:
```
User: "Run project-health-auditor to verify my system"
User: "Use vm-operations-specialist to create a VM"
User: "Apply performance optimizations with performance-optimization-specialist"
User: "Run security-hardening-specialist checklist"
```

See **Multi-Agent System** section above for complete agent usage documentation.

## 🔍 Troubleshooting & Diagnostics

### Common Issues & Solutions

**Issue 1: VM Won't Boot (Black Screen)**
```bash
# Diagnosis
virsh dumpxml win11-outlook | grep firmware
# Verify UEFI firmware is configured

# Solution: Ensure OVMF is installed
sudo apt install ovmf
virsh edit win11-outlook
# Add: <os firmware='efi'>
```

**Issue 2: Poor Performance (High CPU, Slow UI)**
```bash
# Diagnosis
virsh dumpxml win11-outlook | grep -c hyperv
# Should return > 0 (Hyper-V enlightenments present)

# Solution: Apply performance optimization (Phase 4)
./scripts/configure-performance.sh
```

**Issue 3: virtio-fs Not Working**
```bash
# Diagnosis (in Windows guest)
# Check if WinFsp is installed
Get-Package -Name WinFsp

# Solution: Install WinFsp
# Download: https://github.com/winfsp/winfsp/releases
# Install and reboot Windows
```

**Issue 4: Network Connectivity Fails**
```bash
# Diagnosis
virsh net-list --all
virsh net-info default

# Solution: Start default network
sudo virsh net-start default
sudo virsh net-autostart default
```

**Reference**: `research/07-troubleshooting-failure-modes.md`

## 📋 Implementation Checklist

**Phase 1: Pre-Flight Validation** (1 hour)
- [ ] Hardware verification script executed
- [ ] All requirements met (CPU, RAM, SSD, cores)
- [ ] Reviewed licensing compliance requirements
- [ ] Decision framework criteria verified
- [ ] IT approval obtained (if corporate M365)

**Phase 2: Software Installation** (2-3 hours)
- [ ] QEMU/KVM packages installed
- [ ] User added to libvirt/kvm groups
- [ ] Windows 11 ISO downloaded
- [ ] VirtIO drivers ISO downloaded
- [ ] Logged out and back in (group changes)

**Phase 3: VM Creation** (1 hour)
- [ ] VM created with Q35, UEFI, TPM 2.0
- [ ] Windows 11 installed with VirtIO drivers
- [ ] Post-installation VirtIO drivers configured
- [ ] Windows activated with valid license
- [ ] Windows updates installed

**Phase 4: Performance Optimization** (1-2 hours)
- [ ] Hyper-V enlightenments configured (all 14)
- [ ] VirtIO drivers for all devices verified
- [ ] CPU pinning configured (if applicable)
- [ ] Huge pages enabled
- [ ] Performance benchmarked (>80% native)

**Phase 5: Filesystem Sharing** (1 hour)
- [ ] virtio-fs configured in VM XML
- [ ] WinFsp installed in Windows guest
- [ ] Shared folder mounted as Z: drive
- [ ] PST file access tested in Outlook
- [ ] Read-only mode verified (ransomware protection)

**Phase 6: Security Hardening** (2-3 hours)
- [ ] Host firewall configured (M365 whitelist)
- [ ] virtio-fs read-only mode enforced
- [ ] BitLocker enabled in guest
- [ ] Windows Defender active
- [ ] Backup snapshot created
- [ ] Full 60+ checklist reviewed

**Phase 7: Automation Setup** (1 hour)
- [ ] QEMU guest agent installed
- [ ] Guest agent communication verified
- [ ] Automation scripts created
- [ ] VM lifecycle management tested

**Total Estimated Time**: 8-11 hours (first-time setup)

## 🚀 Quick Start Guide

**For Experienced Users** (Fast track):

```bash
# 1. Hardware verification
egrep -c '(vmx|svm)' /proc/cpuinfo && free -h && lsblk -d -o name,rota

# 2. Install QEMU/KVM
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients \
    virt-manager ovmf swtpm qemu-utils guestfs-tools
sudo usermod -aG libvirt,kvm $USER

# 3. Download ISOs
# - Windows 11: https://www.microsoft.com/software-download/windows11
# - VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/

# 4. Create VM (adjust paths)
virt-install --name win11-outlook --ram 8192 --vcpus 4 \
    --disk size=100,format=qcow2,bus=virtio \
    --cdrom ~/ISOs/Win11.iso --disk ~/ISOs/virtio-win.iso,device=cdrom \
    --os-variant win11 --machine q35 --boot uefi \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --network network=default,model=virtio --video virtio

# 5. Follow detailed guides for optimization
# - outlook-linux-guide/05-qemu-kvm-reference-architecture.md
# - outlook-linux-guide/09-performance-optimization-playbook.md
```

## 📖 Documentation Hierarchy

**For Implementation** (Start here):
1. `outlook-linux-guide/00-README.md` - Overview and guide structure
2. `outlook-linux-guide/05-qemu-kvm-reference-architecture.md` - Step-by-step setup
3. `outlook-linux-guide/09-performance-optimization-playbook.md` - Performance tuning

**For Deep Understanding** (Research phase):
1. `research/00-RESEARCH-INDEX.md` - Complete research overview
2. `research/01-hardware-requirements-analysis.md` - Hardware deep dive
3. `research/02-software-dependencies-analysis.md` - Software dependencies
4. `research/03-licensing-legal-compliance.md` - Legal and compliance
5. `research/04-network-connectivity-requirements.md` - Network architecture
6. `research/05-performance-optimization-research.md` - Performance analysis
7. `research/06-security-hardening-analysis.md` - Security deep dive
8. `research/07-troubleshooting-failure-modes.md` - Failure modes and recovery

**Quick References**:
- `research/05-performance-quick-reference.md` - Performance tuning cheat sheet

## 🎯 AI Assistant Behavior Guidelines

### When Working on This Project

**ALWAYS**:
- ✅ Verify hardware requirements before proceeding with installation
- ✅ Use timestamped branch workflow for all changes
- ✅ Follow 8-phase installation sequence in order
- ✅ Apply ALL Hyper-V enlightenments (14 configurations)
- ✅ Use virtio-fs in read-only mode for PST file sharing
- ✅ Implement security hardening checklist
- ✅ Reference specific documentation files in responses
- ✅ Warn about licensing and compliance risks
- ✅ Create automation scripts for repeatable tasks

**NEVER**:
- ❌ Skip hardware verification steps
- ❌ Use IDE/SATA instead of VirtIO for storage
- ❌ Use Samba/9p instead of virtio-fs for file sharing
- ❌ Skip Hyper-V enlightenments (results in poor performance)
- ❌ Delete branches without explicit user permission
- ❌ Recommend OEM Windows licenses for VMs
- ❌ Proceed without IT approval for corporate M365
- ❌ Configure virtio-fs with write access (ransomware risk)

### Code Generation Standards

**Scripts**:
- Always include error checking and validation
- Provide clear status messages during execution
- Reference documentation for manual steps
- Include verification commands

**Configuration Files**:
- Use XML format for libvirt configurations
- Include comments explaining each section
- Follow performance optimization guidelines
- Validate with `virsh define` before use

**Documentation**:
- Use markdown format
- Include command examples with expected output
- Reference related documents with relative paths
- Update CHANGELOG.md for significant changes

## 📊 Success Metrics

**Performance Targets** (After full optimization):
- [ ] Boot time < 25 seconds (target: 22s)
- [ ] Outlook startup < 5 seconds (target: 4s)
- [ ] PST file open < 3 seconds for 1GB file (target: 2s)
- [ ] UI frame rate 60fps
- [ ] Disk IOPS > 40,000 (4K random)
- [ ] Overall performance > 80% of native Windows

**Security Targets**:
- [ ] Host partition encrypted (LUKS)
- [ ] virtio-fs read-only mode enforced
- [ ] Egress firewall active (M365 whitelist)
- [ ] BitLocker enabled in guest
- [ ] 60+ hardening checklist items complete

**Operational Targets**:
- [ ] VM starts automatically on host boot
- [ ] Guest agent automation working
- [ ] Backup snapshots created weekly
- [ ] Monitoring and logging configured
- [ ] Documentation up-to-date

## ⚖️ Legal & Compliance Disclaimer

**This project documentation is provided for educational and informational purposes only.**

**The maintainers and AI assistants**:
- Do NOT endorse violating corporate IT policies
- Do NOT recommend bypassing security controls
- Do NOT provide legal advice regarding compliance
- STRONGLY RECOMMEND obtaining proper approvals before implementation

**Users are solely responsible for**:
- Compliance with corporate policies and IT approval requirements
- Adherence to Microsoft licensing requirements (Windows + M365)
- Security of their systems and data
- Any consequences of implementation decisions in regulated industries
- Ensuring proper authorization for Shadow IT deployments

**High-Risk Scenarios** (Requires legal/compliance review):
- Using corporate M365 accounts without IT approval
- Storing regulated data (HIPAA, SOX, FINRA, FedRAMP)
- Deploying in environments with strict BYOD policies
- Accessing company resources from personal systems

**Always consult your IT department, legal team, and compliance officers before implementing this solution with corporate accounts or in regulated environments.**

---

## 📝 Document Maintenance

**Version**: 1.0.0
**Last Updated**: 2025-11-17
**Maintained By**: AI Assistants (Claude, Gemini) + User
**Review Frequency**: After each major update or implementation phase

**Change Log**:
- 2025-11-17: Initial AGENTS.md creation based on ghostty-config-files pattern
  - Comprehensive non-negotiable requirements defined
  - 7-phase implementation roadmap documented
  - Security and compliance guidelines established
  - Branch preservation strategy implemented
- 2025-11-17: Added Multi-Agent System documentation
  - 13-agent system overview and usage guidelines
  - Agent inventory (8 core infrastructure + 5 QEMU/KVM specialized)
  - Common workflows and invocation methods
  - Agent communication patterns and best practices
  - References to detailed documentation in `.claude/agents/`
- 2025-11-17: Constitutional compliance modularization
  - Reduced file size from 39.9 KB to 35.7 KB (Orange Zone → improved margin)
  - Replaced verbose implementation phases with concise summary + references
  - Maintained all essential information with links to detailed guides
  - Compliance status: 🟠 ORANGE ZONE (89.4% of 40 KB limit, 4.3 KB buffer)

**Related Files**:
- `CLAUDE.md` → Symlink to this file (Claude Code integration)
- `GEMINI.md` → Symlink to this file (Gemini CLI integration)
- `.claude/` → Claude Code configuration directory
- `.claude/agents/` → Multi-agent system (13 agents, 9,728 lines, ~255 KB documentation)
- `.claude/agents/README.md` → Agent system overview and quick start guide

---

*This file serves as the single source of truth for ALL AI assistants working on the QEMU/KVM Windows Virtualization project. Any conflicts between this file and other documentation should be resolved in favor of this file, with subsequent updates to align all documentation.*
