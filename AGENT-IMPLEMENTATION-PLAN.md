# Win-QEMU Agent Implementation Plan

**Date**: 2025-11-17
**Source**: Adapted from ghostty-config-files agent architecture
**Target**: QEMU/KVM Windows Virtualization Project

---

## 🎯 Executive Summary

This plan adapts the sophisticated multi-agent system from ghostty-config-files to create a specialized agent ecosystem for win-qemu, combining:
- **Core documentation/Git agents** (adapted from ghostty-config-files)
- **QEMU/KVM specialized agents** (new, project-specific)
- **Orchestration layer** (adapted for VM operations)

**Total Agents**: 13 (8 adapted + 5 new)

---

## 📊 Agent Categories

### Category A: Core Infrastructure (Adapted - 8 agents)

These agents handle fundamental repository operations and are adapted from ghostty-config-files:

#### 1. **symlink-guardian.md** ✅ ADAPT
- **Purpose**: Verify CLAUDE.md/GEMINI.md → AGENTS.md symlinks
- **Adaptation**: Minimal (same symlink pattern)
- **Priority**: CRITICAL (pre-commit check)

#### 2. **documentation-guardian.md** ✅ ADAPT
- **Purpose**: AGENTS.md single source of truth enforcement
- **Adaptation**: Update project references (ghostty → qemu)
- **Priority**: CRITICAL (documentation integrity)

#### 3. **constitutional-compliance-agent.md** ✅ ADAPT
- **Purpose**: Keep AGENTS.md modular (<40KB), split large sections
- **Adaptation**: Update thresholds for win-qemu (more technical docs)
- **Priority**: HIGH (maintainability)

#### 4. **git-operations-specialist.md** ✅ ADAPT
- **Purpose**: ALL Git operations (commit, push, merge, branch)
- **Adaptation**: Update branch naming patterns, commit scopes
- **Priority**: CRITICAL (Git enforcement)
- **Win-qemu scopes**: `vm`, `config`, `performance`, `security`, `docs`, `scripts`

#### 5. **constitutional-workflow-orchestrator.md** ✅ ADAPT
- **Purpose**: Shared Git workflow templates (branch naming, commit format)
- **Adaptation**: Update type/scope definitions for VM operations
- **Priority**: CRITICAL (workflow standardization)

#### 6. **master-orchestrator.md** ✅ ADAPT
- **Purpose**: Multi-agent coordination, parallel execution
- **Adaptation**: Add QEMU/KVM agent registry, update dependency graph
- **Priority**: HIGH (complex workflows)

#### 7. **project-health-auditor.md** ✅ ADAPT
- **Purpose**: Project health assessment, Context7 integration
- **Adaptation**: Update health checks (QEMU/KVM versions, VM status)
- **Priority**: MEDIUM (monitoring)
- **Win-qemu checks**: QEMU version, libvirt status, VM state, VirtIO drivers

#### 8. **repository-cleanup-specialist.md** ✅ ADAPT
- **Purpose**: Cleanup redundant files, consolidate directories
- **Adaptation**: Minimal (same patterns apply)
- **Priority**: MEDIUM (hygiene)

---

### Category B: QEMU/KVM Specialized (New - 5 agents)

These agents are specific to QEMU/KVM virtualization workflows:

#### 9. **vm-operations-specialist.md** 🆕 CREATE
- **Purpose**: VM lifecycle management (create, start, stop, destroy)
- **Responsibilities**:
  - VM creation with Q35, UEFI, TPM 2.0
  - VM state management (virsh start/stop/shutdown)
  - VM configuration editing (virsh edit)
  - ISO management (Windows 11, VirtIO drivers)
  - Snapshot management (virsh snapshot-*)
- **Delegates to**: git-operations-specialist (for config commits)
- **Uses**: virtio-fs-specialist (for filesystem sharing setup)
- **Priority**: CRITICAL (core functionality)

#### 10. **performance-optimization-specialist.md** 🆕 CREATE
- **Purpose**: Hyper-V enlightenments, VirtIO tuning, benchmarking
- **Responsibilities**:
  - Apply 14 Hyper-V enlightenment features
  - Configure CPU pinning and huge pages
  - Benchmark VM performance (boot time, IOPS, latency)
  - Validate >80% native Windows performance target
  - Generate performance reports
- **Delegates to**: vm-operations-specialist (for VM XML updates)
- **Priority**: HIGH (performance critical)

#### 11. **security-hardening-specialist.md** 🆕 CREATE
- **Purpose**: Security checklist enforcement, LUKS, firewall, AppArmor
- **Responsibilities**:
  - LUKS encryption setup for VM images/PST files
  - UFW firewall configuration (M365 whitelist)
  - virtio-fs read-only mode enforcement (ransomware protection)
  - BitLocker validation in guest
  - Security audit checklist (60+ items)
- **Delegates to**: vm-operations-specialist (for VM config updates)
- **Priority**: HIGH (security critical)

#### 12. **virtio-fs-specialist.md** 🆕 CREATE
- **Purpose**: VirtIO filesystem sharing setup and management
- **Responsibilities**:
  - Configure virtio-fs in VM XML
  - WinFsp installation guidance in Windows guest
  - Mount Z: drive in Windows
  - Test PST file access from Outlook
  - Enforce read-only mode (ransomware protection)
- **Delegates to**: vm-operations-specialist (for VM updates)
- **Priority**: MEDIUM (integration)

#### 13. **qemu-automation-specialist.md** 🆕 CREATE
- **Purpose**: QEMU guest agent automation, virsh scripting
- **Responsibilities**:
  - QEMU guest agent installation/verification
  - virsh qemu-agent-command execution
  - Guest OS automation (PowerShell commands)
  - VM IP address retrieval
  - Guest file operations
- **Delegates to**: vm-operations-specialist (for agent config)
- **Priority**: MEDIUM (automation)

---

## 🗂️ Directory Structure

```
win-qemu/
├── .claude/
│   └── agents/
│       ├── README.md                              # Agent system overview
│       │
│       ├── # CORE INFRASTRUCTURE (Adapted)
│       ├── symlink-guardian.md                    # ✅ ADAPT
│       ├── documentation-guardian.md              # ✅ ADAPT
│       ├── constitutional-compliance-agent.md     # ✅ ADAPT
│       ├── git-operations-specialist.md           # ✅ ADAPT
│       ├── constitutional-workflow-orchestrator.md # ✅ ADAPT
│       ├── master-orchestrator.md                 # ✅ ADAPT
│       ├── project-health-auditor.md              # ✅ ADAPT
│       ├── repository-cleanup-specialist.md       # ✅ ADAPT
│       │
│       └── # QEMU/KVM SPECIALIZED (New)
│           ├── vm-operations-specialist.md        # 🆕 CREATE
│           ├── performance-optimization-specialist.md # 🆕 CREATE
│           ├── security-hardening-specialist.md   # 🆕 CREATE
│           ├── virtio-fs-specialist.md            # 🆕 CREATE
│           └── qemu-automation-specialist.md      # 🆕 CREATE
│
├── AGENTS.md                                      # Single source of truth (exists)
├── CLAUDE.md → AGENTS.md                          # Symlink (exists)
└── GEMINI.md → AGENTS.md                          # Symlink (to be created)
```

---

## 🔄 Agent Interaction Flow

### Example: Complete VM Setup Workflow

```mermaid
graph TD
    User[User: "Create optimized Windows 11 VM"]

    User --> Master[master-orchestrator]

    Master --> Phase1[Phase 1: Parallel Health Checks]
    Phase1 --> Symlink[symlink-guardian]
    Phase1 --> Health[project-health-auditor]

    Master --> Phase2[Phase 2: VM Creation]
    Phase2 --> VMOps[vm-operations-specialist]
    VMOps --> CreateVM[Create Q35/UEFI/TPM VM]

    Master --> Phase3[Phase 3: Parallel Optimization]
    Phase3 --> Perf[performance-optimization-specialist]
    Phase3 --> Sec[security-hardening-specialist]
    Phase3 --> VirtioFS[virtio-fs-specialist]

    Perf --> ApplyHyperV[Apply 14 Hyper-V enlightenments]
    Sec --> ConfigFirewall[Configure UFW + LUKS]
    VirtioFS --> SetupFS[Setup virtio-fs read-only]

    Master --> Phase4[Phase 4: Testing & Automation]
    Phase4 --> QemuAuto[qemu-automation-specialist]
    QemuAuto --> TestGuest[Test guest agent]

    Master --> Phase5[Phase 5: Git Operations]
    Phase5 --> GitOps[git-operations-specialist]
    GitOps --> Commit[Constitutional commit + push]
```

---

## 📝 Adaptation Details

### Branch Naming Pattern (Constitutional Requirement)

**Format**: `YYYYMMDD-HHMMSS-type-description`

**Win-qemu specific types**:
```yaml
types:
  feat:       # New VM features, capabilities
  fix:        # VM bugs, configuration errors
  perf:       # Performance optimizations (new for win-qemu)
  security:   # Security hardening (new for win-qemu)
  config:     # Configuration changes
  docs:       # Documentation updates
  scripts:    # Automation scripts
  refactor:   # Code restructuring
  test:       # Testing additions
  chore:      # Maintenance tasks
```

**Examples**:
- `20251117-150000-feat-vm-creation-automation`
- `20251117-150515-perf-hyperv-enlightenments`
- `20251117-151030-security-luks-encryption`
- `20251117-151545-config-virtio-fs-readonly`

### Commit Scope Pattern

**Win-qemu specific scopes**:
```yaml
scopes:
  vm:           # VM operations (creation, lifecycle)
  perf:         # Performance tuning
  security:     # Security hardening
  virtio-fs:    # Filesystem sharing
  automation:   # QEMU guest agent
  config:       # Configuration files
  docs:         # Documentation
  scripts:      # Shell scripts
  ci-cd:        # CI/CD workflows
```

---

## 🚀 Implementation Phases

### Phase 1: Core Infrastructure (Day 1)
**Priority**: CRITICAL
1. Create `.claude/agents/` directory
2. Adapt and install 8 core agents:
   - symlink-guardian
   - documentation-guardian
   - constitutional-compliance-agent
   - git-operations-specialist
   - constitutional-workflow-orchestrator
   - master-orchestrator
   - project-health-auditor
   - repository-cleanup-specialist
3. Test symlink verification
4. Test Git operations with new scopes

### Phase 2: QEMU/KVM Specialized Agents (Day 2)
**Priority**: HIGH
1. Create vm-operations-specialist (most critical)
2. Create performance-optimization-specialist
3. Create security-hardening-specialist
4. Test VM creation + optimization workflow

### Phase 3: Integration Agents (Day 3)
**Priority**: MEDIUM
1. Create virtio-fs-specialist
2. Create qemu-automation-specialist
3. Test end-to-end VM setup workflow

### Phase 4: Testing & Documentation (Day 4)
**Priority**: MEDIUM
1. Create `.claude/agents/README.md` (agent system overview)
2. Update AGENTS.md with agent usage guidelines
3. Test master-orchestrator with complex workflows
4. Verify all agents integrate correctly

---

## ✅ Success Criteria

### Documentation Integrity
- ✅ CLAUDE.md → AGENTS.md symlink verified
- ✅ GEMINI.md → AGENTS.md symlink created and verified
- ✅ AGENTS.md remains <40KB (modularized if needed)

### Git Operations
- ✅ All commits use constitutional format
- ✅ All branches follow YYYYMMDD-HHMMSS-type-description pattern
- ✅ Branches preserved (never deleted without permission)
- ✅ Merge strategy: --no-ff

### QEMU/KVM Operations
- ✅ VM creation automated with Q35/UEFI/TPM
- ✅ Hyper-V enlightenments applied automatically
- ✅ Security hardening checklist enforced
- ✅ virtio-fs configured with read-only mode
- ✅ Performance >80% of native Windows

### Orchestration
- ✅ Complex workflows decomposed into parallel tasks
- ✅ Agent dependencies managed correctly
- ✅ Error handling and retry logic functional

---

## 🔐 Security Considerations

### API Key Management (Context7 MCP)
- ✅ `.env` file with CONTEXT7_API_KEY (if available)
- ✅ `.env` in `.gitignore`
- ✅ project-health-auditor NEVER displays API keys

### VM Security
- ✅ LUKS encryption enforced by security-hardening-specialist
- ✅ virtio-fs read-only mode (ransomware protection)
- ✅ UFW firewall whitelist (M365 only)
- ✅ Pre-commit hooks prevent committing .env, credentials

---

## 📊 Estimated Impact

### Efficiency Gains
- **VM Setup Time**: 8-11 hours manual → 2-3 hours automated (60-75% reduction)
- **Error Rate**: Manual configuration errors eliminated
- **Consistency**: 100% constitutional compliance
- **Documentation**: Self-updating with agent-driven workflows

### Code Quality
- **Branch Naming**: 100% compliance (enforced by git-operations-specialist)
- **Commit Messages**: Standardized format (constitutional-workflow-orchestrator)
- **Documentation**: Symlink integrity guaranteed (symlink-guardian)
- **Cleanup**: Automated redundancy removal (repository-cleanup-specialist)

---

## 🎯 Next Steps

1. **Review this plan** - User approval before implementation
2. **Confirm priorities** - Which agents are most critical for immediate needs?
3. **Execute Phase 1** - Core infrastructure (Day 1)
4. **Iterative deployment** - Add specialized agents as needed

---

## 📚 References

- **Source project**: `/home/kkk/Apps/ghostty-config-files/.claude/agents/`
- **Target project**: `/home/kkk/Apps/win-qemu`
- **Constitutional requirements**: `/home/kkk/Apps/win-qemu/CLAUDE.md` (AGENTS.md)
- **Research documentation**: `/home/kkk/Apps/win-qemu/research/` (9 research docs)
- **Implementation guides**: `/home/kkk/Apps/win-qemu/outlook-linux-guide/` (10 guides)

---

**Question for User**: Would you like me to proceed with implementing these agents? If yes, should I:
1. **Start with Phase 1** (Core infrastructure - 8 agents)?
2. **Focus on specific agents** you need most urgently?
3. **Modify the plan** based on your priorities?
