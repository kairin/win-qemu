# Win-QEMU Agent Workflows

**Purpose**: Centralized workflow documentation for all agent operations.

> **Quick Start**: See [README.md](README.md)
> **Agent Details**: See [AGENTS-REFERENCE.md](AGENTS-REFERENCE.md)

---

## Workflow 1: Complete VM Setup (Orchestrated)

**User Request**: "Create a new Windows 11 VM with full optimization"

**Duration**: 2-3 hours (automated) vs 8-11 hours (manual)

### Agent Execution Sequence

```
1. master-orchestrator (coordinator)
   │
   ├─→ 2. qemu-health-checker
   │      ↳ Validates 42 system prerequisites
   │
   ├─→ 3. project-health-auditor
   │      ↳ Verifies hardware/software compatibility
   │
   ├─→ 4. vm-operations-specialist
   │      ↳ Creates base VM (Q35/UEFI/TPM 2.0)
   │      ↳ Loads VirtIO drivers
   │
   ├─→ 5. performance-optimization-specialist
   │      ↳ Applies 14 Hyper-V enlightenments
   │      ↳ Configures CPU pinning, huge pages
   │
   ├─→ 6. security-hardening-specialist
   │      ↳ Runs 60+ security checklist
   │      ↳ Configures LUKS, firewall
   │
   ├─→ 7. virtio-fs-specialist
   │      ↳ Configures Z: drive for PST files
   │      ↳ Enforces read-only mode
   │
   ├─→ 8. qemu-automation-specialist
   │      ↳ Installs QEMU guest agent
   │
   └─→ 9. git-operations-specialist
          ↳ Commits configuration
```

### Expected Outcome

- Windows 11 VM running with Q35/UEFI/TPM 2.0
- 85-95% native performance
- All security measures in place
- PST file access configured
- Guest agent automation ready

---

## Workflow 2: Performance Optimization

**User Request**: "My VM is running slow, optimize it"

**Duration**: 1-2 hours

### Agent Execution

```
performance-optimization-specialist
   │
   ├─→ 1. Baseline Measurement
   │      ↳ Boot time, Outlook startup, disk IOPS
   │
   ├─→ 2. Hyper-V Enlightenments (14 features)
   │      ↳ relaxed, vapic, spinlocks, vpindex
   │      ↳ runtime, synic, stimer, reset
   │      ↳ vendor_id, frequencies, reenlightenment
   │      ↳ tlbflush, ipi, evmcs
   │
   ├─→ 3. CPU Configuration
   │      ↳ CPU pinning to dedicated cores
   │      ↳ NUMA topology optimization
   │
   ├─→ 4. Memory Configuration
   │      ↳ Huge pages enabled
   │      ↳ Memory locking
   │
   ├─→ 5. VirtIO Verification
   │      ↳ All devices using VirtIO drivers
   │
   └─→ 6. Benchmark and Validate
          ↳ Target: 85-95% native performance
```

### Performance Targets

| Metric | Before | After |
|--------|--------|-------|
| Boot time | 45s | <25s |
| Outlook startup | 12s | <5s |
| PST open (1GB) | 8s | <3s |
| Disk IOPS (4K) | 8,000 | >30,000 |
| Overall | 50-60% | 85-95% |

---

## Workflow 3: Security Audit

**User Request**: "Audit my VM security"

**Duration**: 30 minutes

### Agent Execution

```
security-hardening-specialist
   │
   ├─→ 1. Host Security
   │      ├─→ LUKS encryption status
   │      ├─→ UFW firewall configuration
   │      ├─→ AppArmor/SELinux profile
   │      └─→ .gitignore coverage
   │
   ├─→ 2. VM Security
   │      ├─→ virtio-fs read-only mode
   │      ├─→ VirtIO drivers verified
   │      └─→ Network isolation
   │
   ├─→ 3. Guest Security
   │      ├─→ BitLocker encryption
   │      ├─→ Windows Defender status
   │      └─→ Windows Firewall rules
   │
   ├─→ 4. Backup Verification
   │      ├─→ Snapshot existence
   │      └─→ Backup encryption
   │
   └─→ 5. Generate Security Report
          ↳ 60+ checklist items
          ↳ Recommendations
```

### Security Checklist Categories

| Category | Items | Priority |
|----------|-------|----------|
| Host encryption | 5 | CRITICAL |
| virtio-fs protection | 3 | CRITICAL |
| Firewall configuration | 8 | HIGH |
| Guest hardening | 12 | HIGH |
| Backup procedures | 5 | MEDIUM |
| Monitoring/logging | 7 | MEDIUM |

---

## Workflow 4: PST File Sharing Setup

**User Request**: "Configure PST file access for Outlook"

**Duration**: 1 hour

### Agent Execution

```
virtio-fs-specialist
   │
   ├─→ 1. Host Configuration
   │      ├─→ Create shared directory
   │      ├─→ Set permissions
   │      └─→ Configure virtio-fs in VM XML
   │
   ├─→ 2. VM XML Update
   │      ↳ Add filesystem element
   │      ↳ Enforce readonly mode
   │
   ├─→ 3. Windows Guest Setup
   │      ├─→ Install WinFsp
   │      ├─→ Configure service
   │      └─→ Mount as Z: drive
   │
   ├─→ 4. Outlook Configuration
   │      ├─→ Test PST access
   │      └─→ Verify read-only
   │
   └─→ 5. Verify Ransomware Protection
          ↳ Confirm guest cannot write to host
```

### virtio-fs XML Configuration

```xml
<filesystem type='mount' accessmode='passthrough'>
  <source dir='/home/user/outlook-data'/>
  <target dir='outlook-share'/>
  <readonly/>  <!-- CRITICAL: Ransomware protection -->
</filesystem>
```

---

## Workflow 5: Git Operations

**User Request**: "Commit my VM configuration changes"

**Duration**: <5 minutes

### Agent Execution

```
git-operations-specialist
   │
   ├─→ 1. Pre-commit Validation
   │      ├─→ Check branch naming
   │      ├─→ Scan for sensitive files
   │      │      ↳ .iso, .qcow2, .pst, .env
   │      └─→ Verify .gitignore coverage
   │
   ├─→ 2. Create Constitutional Branch
   │      ↳ YYYYMMDD-HHMMSS-type-description
   │
   ├─→ 3. Stage and Commit
   │      ↳ Constitutional commit message
   │      ↳ Claude Code attribution
   │
   ├─→ 4. Merge to Main
   │      ↳ --no-ff (preserve branch history)
   │
   └─→ 5. Push (if requested)
          ↳ NEVER delete branches
```

### Branch Naming Convention

**Format**: `YYYYMMDD-HHMMSS-type-description`

**Types**:
- `feat` - New features
- `fix` - Bug fixes
- `docs` - Documentation
- `config` - VM configuration
- `security` - Security hardening
- `perf` - Performance optimization

**Examples**:
```
20251117-150000-feat-vm-creation-automation
20251117-150515-config-hyperv-enlightenments
20251117-151030-security-luks-encryption
```

---

## Workflow 6: System Health Check

**User Request**: "Check if my system is ready for QEMU/KVM"

**Duration**: <5 minutes

### Agent Execution (Parallel)

```
┌─→ qemu-health-checker
│      ↳ System readiness (42 checks)
│      ↳ "Am I ready to build a VM?"
│
└─→ project-health-auditor
       ↳ Standards compliance
       ↳ Context7 best practices
       ↳ "Do I follow best practices?"
```

### qemu-health-checker Categories

| Category | Checks | Priority |
|----------|--------|----------|
| Hardware | 5 | CRITICAL |
| QEMU/KVM Stack | 5 | CRITICAL |
| VirtIO Tools | 5 | HIGH |
| Network/Storage | 3 | HIGH |
| Windows Prerequisites | 3 | MEDIUM |
| Environment/MCP | 3 | LOW |

---

## Workflow 7: Documentation Maintenance

**User Request**: "Check documentation consistency"

**Duration**: <5 minutes

### Agent Execution (Parallel)

```
┌─→ symlink-guardian
│      ↳ Verify CLAUDE.md → AGENTS.md
│      ↳ Verify GEMINI.md → AGENTS.md
│
├─→ constitutional-compliance-agent
│      ↳ Verify AGENTS.md <40KB
│      ↳ Check modularization
│
└─→ documentation-guardian
       ↳ Single source of truth
       ↳ Link integrity
```

---

## Workflow 8: Repository Cleanup

**User Request**: "Clean up redundant files"

**Duration**: <10 minutes

### Agent Execution

```
repository-cleanup-specialist
   │
   ├─→ 1. Scan for Redundancy
   │      ├─→ Duplicate files
   │      ├─→ Unused scripts
   │      └─→ Orphaned documentation
   │
   ├─→ 2. Generate Report
   │      ↳ Files identified
   │      ↳ Recommendations
   │
   ├─→ 3. User Approval
   │      ↳ Confirm deletions
   │
   └─→ 4. Execute Cleanup
          ↳ Rule 0: NEVER delete Git history
          ↳ Delegate to git-operations-specialist
```

---

## Agent Communication Patterns

### Delegation

Agents delegate to specialists when needed:

```
vm-operations-specialist → git-operations-specialist (commits)
performance-optimization-specialist → vm-operations-specialist (XML updates)
security-hardening-specialist → vm-operations-specialist (security config)
```

### Parallel Execution

75% of agents are parallel-safe (11/14):

```
Safe to run together:
- qemu-health-checker + project-health-auditor
- symlink-guardian + documentation-guardian + constitutional-compliance-agent
- performance-optimization-specialist + security-hardening-specialist
```

### Sequential Execution

Required for dependency-driven workflows:

```
Health checks → VM creation → Optimization → Security → Automation → Git
```

---

## Custom Workflow Template

Create your own workflows using this pattern:

```
workflow_name
   │
   ├─→ 1. [agent-name]
   │      ↳ [action description]
   │
   ├─→ 2. [agent-name]
   │      ↳ [action description]
   │
   └─→ 3. [agent-name]
          ↳ [final action]
```

---

**Last Updated**: 2025-11-17
**See Also**: [README.md](README.md) | [AGENTS-REFERENCE.md](AGENTS-REFERENCE.md)
