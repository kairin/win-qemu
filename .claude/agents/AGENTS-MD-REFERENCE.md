# AGENTS.md Reference - Complete Agent System Documentation

> **Note**: This file contains detailed agent documentation extracted from AGENTS.md to maintain constitutional compliance (<40KB size limit).
>
> **Main File**: `/home/user/win-qemu/AGENTS.md`
>
> **Last Extracted**: 2025-11-19

---

## Multi-Agent System - Complete Documentation

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

#### Method 1: Natural Language (Recommended)

Simply describe what you want to accomplish:

```
User: "Create a new Windows 11 VM with full optimization"
→ master-orchestrator coordinates multiple agents automatically

User: "Optimize my VM for best performance"
→ performance-optimization-specialist activates

User: "Audit my VM security"
→ security-hardening-specialist runs 60+ checklist
```

#### Method 2: Direct Agent Reference

Reference the agent by name if you know which one you need:

```
User: "Use vm-operations-specialist to create a VM"
User: "Run project-health-auditor to check system status"
User: "Invoke git-operations-specialist to commit changes"
```

#### Method 3: Orchestrated Workflows

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

## Implementation Phases - Expanded Reference

### Phase 1: Hardware Verification (10 minutes)

**Objective**: Verify system meets minimum QEMU/KVM requirements

**Agent**: project-health-auditor

**Verification Commands**:
```bash
# CPU virtualization (MANDATORY)
egrep -c '(vmx|svm)' /proc/cpuinfo  # Must return > 0

# RAM check (16GB minimum, 32GB recommended)
free -h

# Storage type (SSD MANDATORY)
lsblk -d -o name,rota  # rota=0 for SSD

# CPU cores (8+ recommended)
nproc
```

**Success Criteria**:
- Hardware virtualization enabled
- Sufficient RAM and CPU cores
- SSD storage confirmed

**Reference**: [Hardware Requirements Analysis](../research/01-hardware-requirements-analysis.md)

---

### Phase 2: Software Installation (2-3 hours)

**Objective**: Install QEMU/KVM stack and dependencies

**Commands**:
```bash
# Core packages (MANDATORY)
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system \
    libvirt-clients virt-manager ovmf swtpm qemu-utils guestfs-tools

# Optional monitoring tools
sudo apt install -y virt-top libvirt-daemon-driver-qemu qemu-block-extra

# Add user to groups
sudo usermod -aG libvirt,kvm $USER

# Log out and back in for group changes to take effect
```

**Downloads Required**:
1. Windows 11 ISO: https://www.microsoft.com/software-download/windows11
2. VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

**Success Criteria**:
- All packages installed without errors
- User in libvirt/kvm groups
- ISOs downloaded and ready

**Reference**: [Software Dependencies Analysis](../research/02-software-dependencies-analysis.md)

---

### Phase 3: VM Creation (1 hour)

**Objective**: Create Windows 11 VM with Q35, UEFI, TPM 2.0

**Agent**: vm-operations-specialist

**Manual Alternative**:
```bash
virt-install --name win11-outlook \
    --ram 8192 --vcpus 4 \
    --disk size=100,format=qcow2,bus=virtio \
    --cdrom ~/ISOs/Win11.iso \
    --disk ~/ISOs/virtio-win.iso,device=cdrom \
    --os-variant win11 \
    --machine q35 \
    --boot uefi \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --network network=default,model=virtio \
    --video virtio
```

**During Installation**:
1. Load VirtIO storage driver when Windows installer asks for disk
2. Complete Windows installation
3. Install VirtIO drivers post-installation
4. Activate Windows with valid license

**Success Criteria**:
- VM boots successfully
- Windows installed and activated
- VirtIO drivers loaded

**Reference**: [Reference Architecture](../outlook-linux-guide/05-qemu-kvm-reference-architecture.md)

---

### Phase 4: Performance Optimization (1-2 hours)

**Objective**: Apply Hyper-V enlightenments and VirtIO optimizations for 85-95% native performance

**Agent**: performance-optimization-specialist

**Key Optimizations**:
1. 14 Hyper-V enlightenments (see AGENTS.md NON-NEGOTIABLE REQUIREMENTS)
2. CPU pinning for dedicated cores
3. Huge pages for memory performance
4. VirtIO drivers for all devices

**Verification**:
```bash
# Check Hyper-V enlightenments
virsh dumpxml win11-outlook | grep -c hyperv
# Should return > 0

# Performance benchmarking
# Boot time target: <25s
# Outlook startup: <5s
# PST open (1GB): <3s
```

**Success Criteria**:
- All 14 Hyper-V enlightenments applied
- Performance >85% of native Windows
- Benchmarks meet targets

**Reference**: [Performance Optimization Playbook](../outlook-linux-guide/09-performance-optimization-playbook.md)

---

### Phase 5: Filesystem Sharing (1 hour)

**Objective**: Configure virtio-fs for PST file access with read-only protection

**Agent**: virtio-fs-specialist

**Steps**:
1. Configure virtio-fs in VM XML (read-only mode)
2. Install WinFsp in Windows guest
3. Mount shared folder as Z: drive
4. Test PST file access in Outlook

**Security**: Read-only mode prevents ransomware from encrypting host files

**Success Criteria**:
- Shared folder accessible in Windows
- PST files readable in Outlook
- Read-only mode enforced

**Reference**: [Seamless Bridge Integration](../outlook-linux-guide/06-seamless-bridge-integration.md)

---

### Phase 6: Security Hardening (2-3 hours)

**Objective**: Implement 60+ security checklist items

**Agent**: security-hardening-specialist

**Key Items**:
1. LUKS encryption for VM partition
2. virtio-fs read-only mode (ransomware protection)
3. UFW firewall with M365 whitelist
4. AppArmor/SELinux profile
5. BitLocker in guest
6. Regular encrypted backups

**Success Criteria**:
- All 60+ checklist items completed
- Security report generated
- Backup strategy implemented

**Reference**: [Security Hardening Analysis](../research/06-security-hardening-analysis.md)

---

### Phase 7: Automation Setup (1 hour)

**Objective**: Install QEMU guest agent and configure automation

**Agent**: qemu-automation-specialist

**Steps**:
1. Install QEMU guest agent in Windows
2. Verify host-guest communication
3. Create automation scripts
4. Test VM lifecycle management

**Success Criteria**:
- Guest agent communication working
- Automation scripts functional
- VM lifecycle tested

**Reference**: [Automation Engine](../outlook-linux-guide/07-automation-engine.md)

---

## Troubleshooting - Complete Reference

### Issue 1: VM Won't Boot (Black Screen)

**Symptoms**:
- VM starts but displays black screen
- No Windows boot loader appears
- UEFI firmware not detected

**Diagnosis**:
```bash
# Check UEFI firmware configuration
virsh dumpxml win11-outlook | grep firmware

# Verify OVMF is installed
dpkg -l | grep ovmf
```

**Solutions**:
1. Install OVMF if missing:
   ```bash
   sudo apt install ovmf
   ```

2. Edit VM configuration:
   ```bash
   virsh edit win11-outlook
   ```
   Add:
   ```xml
   <os firmware='efi'>
     <type arch='x86_64' machine='q35'>hvm</type>
   </os>
   ```

3. Recreate VM with UEFI boot

**Prevention**: Always specify `--boot uefi` during virt-install

---

### Issue 2: Poor Performance (High CPU, Slow UI)

**Symptoms**:
- High CPU usage on host
- Sluggish Windows UI
- Slow application performance
- Frame rate <30fps

**Diagnosis**:
```bash
# Check for Hyper-V enlightenments
virsh dumpxml win11-outlook | grep -c hyperv
# Should return > 0 if configured

# Check VirtIO drivers
virsh dumpxml win11-outlook | grep 'model type'
# Should show virtio for disk, network, graphics
```

**Solutions**:
1. Apply Hyper-V enlightenments (see AGENTS.md Performance Optimization section)
2. Verify VirtIO drivers installed in Windows:
   - Device Manager → Check for VirtIO devices
3. Configure CPU pinning and huge pages
4. Use performance-optimization-specialist agent

**Expected Results**:
- 85-95% native Windows performance
- Boot time <25s
- Outlook startup <5s

**Reference**: [Performance Optimization Playbook](../outlook-linux-guide/09-performance-optimization-playbook.md)

---

### Issue 3: virtio-fs Not Working

**Symptoms**:
- Shared folder not visible in Windows
- Z: drive not mounting
- "Network path not found" errors

**Diagnosis (in Windows guest)**:
```powershell
# Check if WinFsp is installed
Get-Package -Name WinFsp

# Check services
Get-Service | Where-Object {$_.DisplayName -like "*WinFsp*"}
```

**Solutions**:
1. Install WinFsp in Windows guest:
   - Download: https://github.com/winfsp/winfsp/releases
   - Install and reboot Windows

2. Verify virtio-fs configuration in VM XML:
   ```bash
   virsh dumpxml win11-outlook | grep filesystem
   ```

3. Restart VM after WinFsp installation

4. Use virtio-fs-specialist agent for automated setup

**Prevention**: Install WinFsp before configuring virtio-fs

**Reference**: [Seamless Bridge Integration](../outlook-linux-guide/06-seamless-bridge-integration.md)

---

### Issue 4: Network Connectivity Fails

**Symptoms**:
- No internet in Windows guest
- Cannot reach M365 endpoints
- Network adapter shows "No network access"

**Diagnosis**:
```bash
# Check default network status
virsh net-list --all

# Check network details
virsh net-info default

# Verify network in VM
virsh dumpxml win11-outlook | grep 'interface type'
```

**Solutions**:
1. Start default network:
   ```bash
   sudo virsh net-start default
   sudo virsh net-autostart default
   ```

2. Verify VirtIO network driver in Windows:
   - Device Manager → Network adapters → Should show "VirtIO Ethernet Adapter"

3. Check host firewall (if using bridged networking):
   ```bash
   sudo ufw status
   ```

4. Test connectivity in Windows:
   ```powershell
   Test-NetConnection outlook.office365.com -Port 443
   ```

**Prevention**:
- Always use NAT networking for simplicity
- Ensure default network autostart enabled

**Reference**: [Network Connectivity Requirements](../research/04-network-connectivity-requirements.md)

---

### Issue 5: TPM 2.0 Not Detected (Windows 11 Installation Fails)

**Symptoms**:
- Windows 11 installer says "This PC can't run Windows 11"
- TPM check fails during installation
- Installation stops at compatibility check

**Diagnosis**:
```bash
# Check TPM configuration in VM
virsh dumpxml win11-outlook | grep tpm

# Verify swtpm is installed
dpkg -l | grep swtpm
```

**Solutions**:
1. Install swtpm if missing:
   ```bash
   sudo apt install swtpm
   ```

2. Recreate VM with TPM 2.0:
   ```bash
   virt-install --name win11-outlook \
       --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
       [other options...]
   ```

3. Edit existing VM:
   ```bash
   virsh edit win11-outlook
   ```
   Add:
   ```xml
   <tpm model='tpm-crb'>
     <backend type='emulator' version='2.0'/>
   </tpm>
   ```

**Prevention**: Always include TPM 2.0 when creating Windows 11 VMs

---

### Issue 6: VirtIO Drivers Not Loading During Installation

**Symptoms**:
- Windows installer doesn't see any disks
- "No drives were found" error
- Cannot proceed with installation

**Diagnosis**:
- VirtIO driver ISO not attached
- Wrong driver selected during installation

**Solutions**:
1. Ensure VirtIO ISO attached during installation:
   ```bash
   virt-install --disk ~/ISOs/virtio-win.iso,device=cdrom [other options...]
   ```

2. During Windows installation:
   - Click "Load driver"
   - Browse to VirtIO ISO
   - Select: `viostor\w11\amd64`
   - Install Red Hat VirtIO SCSI controller

3. After selecting driver, disk should appear

**Prevention**:
- Always attach VirtIO ISO as second CD-ROM
- Download latest VirtIO drivers before installation

**Reference**: [Software Dependencies Analysis](../research/02-software-dependencies-analysis.md)

---

### Issue 7: High Memory Usage / VM Crashes

**Symptoms**:
- VM consumes excessive RAM
- Out of memory errors
- VM becomes unresponsive
- Host system slows down

**Diagnosis**:
```bash
# Check VM memory allocation
virsh dumpxml win11-outlook | grep memory

# Monitor VM memory usage
virt-top

# Check host memory
free -h
```

**Solutions**:
1. Reduce VM RAM allocation if excessive:
   ```bash
   virsh setmaxmem win11-outlook 8G --config
   virsh setmem win11-outlook 8G --config
   ```

2. Enable memory ballooning:
   ```xml
   <memballoon model='virtio'>
     <stats period='5'/>
   </memballoon>
   ```

3. Disable unused Windows services in guest

4. Configure huge pages for better performance (not more RAM):
   ```bash
   echo 4096 | sudo tee /proc/sys/vm/nr_hugepages
   ```

**Recommendation**:
- Minimum: 8GB RAM for guest
- Recommended: 16GB for host total (8GB guest + 8GB host)

---

### Additional Troubleshooting Resources

For comprehensive troubleshooting covering:
- Boot failures
- Driver issues
- Performance problems
- Network connectivity
- Security configuration
- Licensing activation
- Backup and recovery

**See**: [Troubleshooting & Failure Modes](../research/07-troubleshooting-failure-modes.md)

---

## Version Information

**File Version**: 1.0
**Extracted From**: AGENTS.md v1.0.0
**Date**: 2025-11-19
**Purpose**: Constitutional compliance - reduce AGENTS.md size below 40KB limit

**Maintenance**: This file should be updated whenever significant changes are made to agent workflows or implementation procedures in the main project.
