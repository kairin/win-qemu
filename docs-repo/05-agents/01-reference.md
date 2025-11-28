# AGENTS.md Reference - Complete Agent Documentation

> **Quick Start**: See [README.md](README.md)
> **Workflows**: See [WORKFLOWS.md](WORKFLOWS.md)
> **This file was extracted from AGENTS.md for constitutional compliance (<40KB limit).**

---

## Agent Inventory - Detailed

### Core Infrastructure Agents (8)

#### 1. symlink-guardian (376 lines, 14 KB)

**Purpose**: Verify and maintain CLAUDE.md/GEMINI.md → AGENTS.md symlinks

**Invocation Triggers**:
- Automatically before commits
- After merges
- When symlink divergence detected

**Key Features**:
- Content merging from diverged files
- Backup creation before restoration
- Symlink restoration

**Example Usage**:
```
User: "Check if CLAUDE.md is properly linked"
→ symlink-guardian verifies and reports status
```

---

#### 2. documentation-guardian (451 lines, 18 KB)

**Purpose**: Enforce AGENTS.md as single source of truth

**Invocation Triggers**:
- After AGENTS.md modifications
- When symlink divergence detected
- During documentation audits

**Key Features**:
- Intelligent content merging
- Symlink restoration
- Documentation consistency verification

---

#### 3. constitutional-compliance-agent (490 lines, 18 KB)

**Purpose**: Keep AGENTS.md modular and under 40KB size limit

**Invocation Triggers**:
- When AGENTS.md exceeds 35KB (warning)
- When AGENTS.md exceeds 40KB (critical)
- Proactive audits

**Key Features**:
- Size monitoring with zone alerts (Green <30KB, Orange 30-40KB, Red >40KB)
- Link integrity verification
- Modularization recommendations

---

#### 4. git-operations-specialist (613 lines, 20 KB)

**Purpose**: ALL Git operations (commit, push, merge, branch)

**Invocation Triggers**:
- Any Git operation requested
- Commit message generation
- Branch management

**Key Features**:
- 9 branch types: feat, fix, docs, config, security, perf, refactor, test, chore
- 9 commit scopes: vm, perf, security, virtio-fs, automation, config, docs, scripts, ci-cd
- Branch preservation (NEVER delete)
- Security scanning for sensitive files

**Branch Naming**:
```
YYYYMMDD-HHMMSS-type-description
Example: 20251117-150000-feat-vm-creation-automation
```

---

#### 5. constitutional-workflow-orchestrator (493 lines)

**Purpose**: Shared Git workflow templates (reusable library)

**Note**: Not invoked directly - used as a library by other agents

**Templates Provided**:
1. Branch creation workflow
2. Commit message workflow
3. Merge workflow
4. Validation workflow
5. Complete workflow (end-to-end)

---

#### 6. master-orchestrator (760 lines)

**Purpose**: Multi-agent coordination and parallel execution

**Invocation Triggers**:
- Complex multi-step tasks
- Tasks requiring multiple agents
- First-time setup

**Key Features**:
- 62-agent hierarchical registry (4-tier: Opus/Sonnet/Haiku)
- 5-phase execution model
- Dependency management
- Parallel execution optimization (75% of agents)

---

#### 7. project-health-auditor (551 lines, 34 KB)

**Purpose**: System health assessment and standards compliance

**Invocation Triggers**:
- First-time setup
- Health checks
- Standards validation

**Key Features**:
- 15+ QEMU/KVM health checks
- Context7 MCP integration
- Hardware validation
- Best practices verification

**Differentiation from qemu-health-checker**:
- Focus: "Do I follow best practices?"
- Context7 queries for latest standards
- Standards compliance vs. system readiness

---

#### 8. repository-cleanup-specialist (543 lines, 25 KB)

**Purpose**: Identify and consolidate redundant files

**Invocation Triggers**:
- Post-migration cleanup
- Clutter detected
- Scheduled maintenance

**Key Features**:
- Inline execution (no new scripts created)
- Rule 0 enforcement (NEVER delete Git history)
- Redundancy detection

---

### QEMU/KVM Specialized Agents (6)

#### 9. vm-operations-specialist (814 lines, 25 KB)

**Purpose**: VM lifecycle management

**Invocation Triggers**:
- VM creation
- VM start/stop/destroy
- Snapshot management
- Troubleshooting

**Key Features**:
- Q35 chipset configuration
- UEFI/OVMF boot
- TPM 2.0 emulation
- VirtIO driver loading
- 10 lifecycle operations

**virt-install Example**:
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

---

#### 10. performance-optimization-specialist (1,205 lines, 36 KB)

**Purpose**: Optimize VM performance (target: 85-95% native)

**Invocation Triggers**:
- After VM creation
- Performance issues detected
- Benchmarking requests

**Key Features**:
- 14 Hyper-V enlightenments
- CPU pinning and NUMA
- Huge pages configuration
- VirtIO optimization
- Performance benchmarking

**Hyper-V Enlightenments** (all 14):
```xml
<hyperv mode='custom'>
  <relaxed state='on'/>
  <vapic state='on'/>
  <spinlocks state='on' retries='8191'/>
  <vpindex state='on'/>
  <runtime state='on'/>
  <synic state='on'/>
  <stimer state='on'><direct state='on'/></stimer>
  <reset state='on'/>
  <vendor_id state='on' value='1234567890ab'/>
  <frequencies state='on'/>
  <reenlightenment state='on'/>
  <tlbflush state='on'/>
  <ipi state='on'/>
  <evmcs state='on'/>
</hyperv>
```

---

#### 11. security-hardening-specialist (1,262 lines)

**Purpose**: Security hardening (60+ checklist items)

**Invocation Triggers**:
- After VM creation
- Security audits
- Compliance checks

**Key Features**:
- LUKS encryption setup
- UFW firewall configuration (M365 whitelist)
- virtio-fs read-only mode (ransomware protection)
- AppArmor/SELinux profiles
- BitLocker guidance
- 60+ security checklist items

**Critical Security Measures**:
1. **LUKS Encryption**: Host partition with VM images
2. **virtio-fs Read-Only**: Prevents guest malware from encrypting host
3. **UFW Firewall**: M365 endpoints whitelist only
4. **BitLocker**: Guest OS encryption
5. **Windows Defender**: Real-time protection

---

#### 12. virtio-fs-specialist (952 lines, 27 KB)

**Purpose**: virtio-fs filesystem sharing for PST files

**Invocation Triggers**:
- After VM creation
- Filesystem sharing needed
- PST access configuration

**Key Features**:
- WinFsp integration
- Z: drive mounting
- Read-only enforcement
- PST file access testing

**virtio-fs XML Configuration**:
```xml
<filesystem type='mount' accessmode='passthrough'>
  <source dir='/home/user/outlook-data'/>
  <target dir='outlook-share'/>
  <readonly/>  <!-- CRITICAL: Ransomware protection -->
</filesystem>
```

---

#### 13. qemu-automation-specialist (1,218 lines, 38 KB)

**Purpose**: QEMU guest agent automation

**Invocation Triggers**:
- After VM creation
- Automation needs
- PowerShell execution

**Key Features**:
- QEMU guest agent installation
- virsh guest commands
- PowerShell automation
- Outlook scripting

**Guest Agent Commands**:
```bash
# Ping guest
virsh qemu-agent-command win11 '{"execute":"guest-ping"}'

# Execute command
virsh qemu-agent-command win11 '{"execute":"guest-exec","arguments":{"path":"cmd.exe","arg":["/c","dir"]}}'
```

---

#### 14. qemu-health-checker (600-800 lines)

**Purpose**: System readiness validation (42 prerequisites)

**Invocation Triggers**:
- First-time setup
- New device setup
- Pre-VM creation validation
- Troubleshooting

**Key Features**:
- 42 validation checks across 6 categories
- JSON report output
- Setup guide generation
- Category-specific diagnostics

**Health Check Categories**:

| Category | Checks | Priority |
|----------|--------|----------|
| Hardware | 5 | CRITICAL |
| QEMU/KVM Stack | 5 | CRITICAL |
| VirtIO Tools | 5 | HIGH |
| Network/Storage | 3 | HIGH |
| Windows Prerequisites | 3 | MEDIUM |
| Environment/MCP | 3 | LOW |

**Differentiation from project-health-auditor**:
- Focus: "Am I ready to build a VM?"
- System prerequisites validation
- JSON output for automation
- Setup guide generation

---

## Agent Best Practices

### DO

- Let master-orchestrator handle complex multi-step tasks
- Use specific agents for single-purpose operations
- Trust agent recommendations for workflow optimization
- Review agent-generated reports before proceeding
- Run qemu-health-checker before first VM creation

### DON'T

- Bypass agents for manual Git operations (violates constitutional compliance)
- Skip health checks before VM operations
- Ignore security-hardening-specialist recommendations
- Delete branches without git-operations-specialist approval
- Configure virtio-fs with write access (ransomware risk)

---

## Troubleshooting - Extended

### VM Won't Boot (Black Screen)

**Diagnosis**:
```bash
virsh dumpxml win11-outlook | grep firmware
dpkg -l | grep ovmf
```

**Solutions**:
1. Install OVMF: `sudo apt install ovmf`
2. Add UEFI to VM XML:
   ```xml
   <os firmware='efi'>
     <type arch='x86_64' machine='q35'>hvm</type>
   </os>
   ```

---

### Poor Performance

**Diagnosis**:
```bash
virsh dumpxml win11-outlook | grep -c hyperv
virsh dumpxml win11-outlook | grep 'model type'
```

**Solutions**:
1. Apply all 14 Hyper-V enlightenments
2. Verify VirtIO drivers in Device Manager
3. Configure CPU pinning and huge pages
4. Use performance-optimization-specialist agent

---

### virtio-fs Not Working

**Diagnosis (Windows guest)**:
```powershell
Get-Package -Name WinFsp
Get-Service | Where-Object {$_.DisplayName -like "*WinFsp*"}
```

**Solutions**:
1. Install WinFsp from https://github.com/winfsp/winfsp/releases
2. Verify virtio-fs configuration in VM XML
3. Restart VM after WinFsp installation

---

### Network Connectivity Fails

**Diagnosis**:
```bash
virsh net-list --all
virsh net-info default
```

**Solutions**:
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

Test in Windows:
```powershell
Test-NetConnection outlook.office365.com -Port 443
```

---

### TPM 2.0 Not Detected

**Diagnosis**:
```bash
virsh dumpxml win11-outlook | grep tpm
dpkg -l | grep swtpm
```

**Solutions**:
1. Install swtpm: `sudo apt install swtpm`
2. Add TPM to VM:
   ```xml
   <tpm model='tpm-crb'>
     <backend type='emulator' version='2.0'/>
   </tpm>
   ```

---

### VirtIO Drivers Not Loading

**During Windows installation**:
1. Click "Load driver"
2. Browse to VirtIO ISO
3. Select: `viostor\w11\amd64`
4. Install Red Hat VirtIO SCSI controller

---

## File Structure

```
.claude/agent-docs/
├── README.md                              # Quick start (this references)
├── WORKFLOWS.md                           # Centralized workflows
├── AGENTS-REFERENCE.md                    # This file
├── IMPLEMENTATION-HISTORY.md              # Chronological implementation
├── HEALTH-CHECKER-EVALUATION-REPORT.md    # Full evaluation (982 lines)
├── HEALTH-CHECKER-EXECUTIVE-SUMMARY.md    # Executive summary (264 lines)
├── INDEX.md                               # Navigation index
└── archive/                               # Archived reports
    ├── COMPLETE-AGENT-SYSTEM-REPORT.md
    ├── PHASE-1-COMPLETION-REPORT.md
    └── ADAPTATION-REPORT.md
```

---

**Last Updated**: 2025-11-17
**Extracted From**: AGENTS.md
**Purpose**: Constitutional compliance - reduce AGENTS.md size below 40KB limit
