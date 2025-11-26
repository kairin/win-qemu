# Context7 Verification Workflow - Execution Plan

**Created**: 2025-11-21
**Purpose**: Comprehensive Context7-based verification for all QEMU/KVM scripts and configurations
**Status**: Ready for Execution

---

## 📋 Executive Summary

**Total Files to Verify**: 12 files (10 shell scripts + 2 XML configs)
**Total Size**: ~198 KB
**Total Lines**: ~5,080 lines of production code
**Estimated Effort**: 24-36 hours (2-3 hours per file average)
**Parallel Execution**: 4-6 files can be verified concurrently

---

## 📊 Complete Inventory

### Shell Scripts (10 files, 162 KB, ~4,200 lines)

#### Installation Scripts (3 files)

**1. scripts/01-install-qemu-kvm.sh**
- **Size**: 14 KB (~350 lines)
- **Purpose**: Install QEMU/KVM packages and enable virtualization services
- **Technologies**: apt, systemd, libvirt, QEMU, KVM
- **Complexity**: Medium
- **Assigned Agent**: qemu-health-checker
- **Priority**: High (foundational)
- **Estimated Time**: 2 hours

**2. scripts/02-configure-user-groups.sh**
- **Size**: 9.5 KB (~240 lines)
- **Purpose**: Add user to libvirt and kvm groups
- **Technologies**: Linux user/group management, libvirt
- **Complexity**: Low
- **Assigned Agent**: qemu-health-checker
- **Priority**: High (foundational)
- **Estimated Time**: 1.5 hours

**3. scripts/install-master.sh**
- **Size**: 18 KB (~450 lines)
- **Purpose**: Installation orchestrator (calls 01 + 02)
- **Technologies**: Bash scripting, orchestration
- **Complexity**: Low
- **Assigned Agent**: master-orchestrator
- **Priority**: High (foundational)
- **Estimated Time**: 1.5 hours

#### VM Management Scripts (4 files)

**4. scripts/create-vm.sh**
- **Size**: 26 KB (~650 lines)
- **Purpose**: Create Windows 11 VM with optimal configuration
- **Technologies**: virt-install, libvirt, QEMU, Q35, OVMF, swtpm, VirtIO
- **Complexity**: Very High
- **Assigned Agent**: vm-operations-specialist
- **Priority**: Critical (core functionality)
- **Estimated Time**: 4 hours

**5. scripts/configure-performance.sh**
- **Size**: 47 KB (~1,200 lines)
- **Purpose**: Apply Hyper-V enlightenments and VirtIO optimizations
- **Technologies**: Hyper-V enlightenments, VirtIO, libvirt XML manipulation, CPU pinning, huge pages
- **Complexity**: Very High
- **Assigned Agent**: performance-optimization-specialist
- **Priority**: Critical (performance)
- **Estimated Time**: 5 hours

**6. scripts/setup-virtio-fs.sh**
- **Size**: 30 KB (~750 lines)
- **Purpose**: Configure virtio-fs filesystem sharing
- **Technologies**: virtio-fs, libvirt XML, filesystem permissions
- **Complexity**: High
- **Assigned Agent**: virtio-fs-specialist
- **Priority**: High (functionality)
- **Estimated Time**: 3 hours

**7. scripts/test-virtio-fs.sh**
- **Size**: 15 KB (~400 lines)
- **Purpose**: Verify virtio-fs security (read-only enforcement)
- **Technologies**: virtio-fs, security validation, XML parsing
- **Complexity**: Medium
- **Assigned Agent**: security-hardening-specialist
- **Priority**: Medium (validation)
- **Estimated Time**: 2 hours

#### Operational Scripts (3 files)

**8. scripts/start-vm.sh**
- **Size**: 19 KB (~480 lines)
- **Purpose**: Start VM with validation and health checks
- **Technologies**: virsh, libvirt, health checking
- **Complexity**: Medium
- **Assigned Agent**: vm-operations-specialist
- **Priority**: Medium (operational)
- **Estimated Time**: 2 hours

**9. scripts/stop-vm.sh**
- **Size**: 19 KB (~480 lines)
- **Purpose**: Graceful VM shutdown with validation
- **Technologies**: virsh, libvirt, QEMU guest agent
- **Complexity**: Medium
- **Assigned Agent**: vm-operations-specialist
- **Priority**: Medium (operational)
- **Estimated Time**: 2 hours

**10. scripts/backup-vm.sh**
- **Size**: 33 KB (~820 lines)
- **Purpose**: VM backup with snapshots and verification
- **Technologies**: virsh snapshots, qemu-img, filesystem operations
- **Complexity**: High
- **Assigned Agent**: vm-operations-specialist
- **Priority**: Medium (operational)
- **Estimated Time**: 3 hours

### XML Configuration Templates (2 files, 36 KB, ~880 lines)

**11. configs/win11-vm.xml**
- **Size**: 25 KB (~650 lines)
- **Purpose**: Complete Windows 11 VM template with all optimizations
- **Technologies**: libvirt XML, Q35, OVMF, TPM 2.0, Hyper-V enlightenments, VirtIO drivers
- **Complexity**: Very High
- **Assigned Agent**: performance-optimization-specialist + security-hardening-specialist
- **Priority**: Critical (foundational)
- **Estimated Time**: 4 hours

**12. configs/virtio-fs-share.xml**
- **Size**: 11 KB (~232 lines)
- **Purpose**: Filesystem sharing configuration for PST file access
- **Technologies**: virtio-fs, security (read-only mode)
- **Complexity**: Medium
- **Assigned Agent**: virtio-fs-specialist
- **Priority**: High (security-critical)
- **Estimated Time**: 2 hours

---

## 🌐 Context7 Library Mapping

**Technologies to Verify Against Context7**:

### Core Virtualization Technologies

**QEMU**
- **Context7 Query**: "QEMU hardware emulation virtualization"
- **Expected Library**: `/qemu/qemu` or similar
- **Used In**: All scripts, both XML configs
- **Verification Priority**: Critical

**KVM**
- **Context7 Query**: "KVM kernel virtual machine Linux"
- **Expected Library**: Linux kernel KVM documentation
- **Used In**: All VM-related scripts
- **Verification Priority**: Critical

**libvirt**
- **Context7 Query**: "libvirt virtualization management API XML"
- **Expected Library**: `/libvirt/libvirt` or similar
- **Used In**: All scripts, both XML configs
- **Verification Priority**: Critical

### VirtIO Technologies

**VirtIO Drivers**
- **Context7 Query**: "VirtIO paravirtualized drivers QEMU KVM"
- **Expected Library**: VirtIO specification or implementation docs
- **Used In**: create-vm.sh, configure-performance.sh, win11-vm.xml
- **Verification Priority**: Critical

**virtio-fs**
- **Context7 Query**: "virtio-fs filesystem sharing QEMU KVM"
- **Expected Library**: virtio-fs.gitlab.io documentation
- **Used In**: setup-virtio-fs.sh, test-virtio-fs.sh, virtio-fs-share.xml
- **Verification Priority**: High

### Firmware & Emulation

**OVMF/EDK2**
- **Context7 Query**: "OVMF EDK2 UEFI firmware QEMU"
- **Expected Library**: EDK2 project documentation
- **Used In**: create-vm.sh, win11-vm.xml
- **Verification Priority**: High

**swtpm**
- **Context7 Query**: "swtpm TPM emulator QEMU"
- **Expected Library**: swtpm project documentation
- **Used In**: create-vm.sh, win11-vm.xml
- **Verification Priority**: High

### Performance Technologies

**Hyper-V Enlightenments**
- **Context7 Query**: "Hyper-V enlightenments QEMU KVM Windows performance"
- **Expected Library**: QEMU documentation, Microsoft virtualization docs
- **Used In**: configure-performance.sh, win11-vm.xml
- **Verification Priority**: Critical (performance impact)

**CPU Pinning**
- **Context7 Query**: "CPU pinning libvirt QEMU performance tuning"
- **Expected Library**: libvirt performance tuning documentation
- **Used In**: configure-performance.sh, win11-vm.xml (commented)
- **Verification Priority**: Medium

**Huge Pages**
- **Context7 Query**: "huge pages memory libvirt QEMU performance"
- **Expected Library**: Linux kernel huge pages documentation
- **Used In**: configure-performance.sh, win11-vm.xml (commented)
- **Verification Priority**: Medium

### Guest Technologies

**QEMU Guest Agent**
- **Context7 Query**: "QEMU guest agent communication"
- **Expected Library**: QEMU guest agent documentation
- **Used In**: stop-vm.sh (graceful shutdown)
- **Verification Priority**: Medium

**WinFsp**
- **Context7 Query**: "WinFsp Windows filesystem userspace"
- **Expected Library**: WinFsp project documentation
- **Used In**: setup-virtio-fs.sh (Windows guest requirement)
- **Verification Priority**: Medium

### System Technologies

**systemd**
- **Context7 Query**: "systemd service management Linux"
- **Expected Library**: systemd documentation
- **Used In**: 01-install-qemu-kvm.sh
- **Verification Priority**: Low

**virt-install**
- **Context7 Query**: "virt-install VM creation libvirt"
- **Expected Library**: virt-manager project documentation
- **Used In**: create-vm.sh
- **Verification Priority**: High

---

## 🤖 Agent Assignment Matrix

### Phase 1: Foundational Scripts (Parallel Execution)

**Agent**: qemu-health-checker
**Scripts**:
1. scripts/01-install-qemu-kvm.sh (2h)
2. scripts/02-configure-user-groups.sh (1.5h)

**Agent**: master-orchestrator
**Scripts**:
1. scripts/install-master.sh (1.5h)

**Total Phase 1 Time**: 2 hours (parallel) + 1.5 hours (orchestrator) = 3.5 hours
**Deliverable**: Validated installation scripts

### Phase 2: Critical VM Operations (Sequential Dependencies)

**Agent**: vm-operations-specialist
**Scripts**:
1. scripts/create-vm.sh (4h) - MUST complete first
2. scripts/start-vm.sh (2h) - depends on create-vm
3. scripts/stop-vm.sh (2h) - depends on create-vm
4. scripts/backup-vm.sh (3h) - depends on create-vm

**Total Phase 2 Time**: 11 hours (sequential)
**Deliverable**: Validated VM lifecycle scripts

### Phase 3: Performance & Security (Parallel After Phase 2)

**Agent**: performance-optimization-specialist
**Files**:
1. scripts/configure-performance.sh (5h)
2. configs/win11-vm.xml (4h) - shared with security agent

**Agent**: security-hardening-specialist
**Files**:
1. configs/win11-vm.xml (4h) - shared with performance agent
2. scripts/test-virtio-fs.sh (2h)

**Agent**: virtio-fs-specialist
**Files**:
1. scripts/setup-virtio-fs.sh (3h)
2. configs/virtio-fs-share.xml (2h)

**Total Phase 3 Time**: 5 hours (parallel, accounting for shared files)
**Deliverable**: Validated performance, security, and filesystem scripts

---

## 📅 Execution Timeline

### Sequential Execution (1 agent at a time)
- **Total Time**: 32 hours (sum of all individual times)
- **Timeline**: 4 full workdays (8 hours/day)
- **Pros**: Simple, no coordination needed
- **Cons**: Inefficient, slow

### Parallel Execution (Recommended, 3-4 agents)
- **Phase 1**: 3.5 hours (3 agents)
- **Phase 2**: 11 hours (1 agent, sequential dependencies)
- **Phase 3**: 5 hours (3 agents, parallel)
- **Total Time**: 19.5 hours
- **Timeline**: 2.5 workdays (8 hours/day)
- **Time Savings**: 39% reduction vs sequential
- **Pros**: Efficient, respects dependencies
- **Cons**: Requires coordination

### Aggressive Parallel (4-6 agents, maximum parallelism)
- **Phase 1**: 2 hours (all 3 scripts in parallel)
- **Phase 2**: Split VM operations across 2 agents where possible: ~7 hours
- **Phase 3**: 4 hours (all 6 files in parallel, accounting for dependencies)
- **Total Time**: 13 hours
- **Timeline**: 1.5 workdays (8 hours/day)
- **Time Savings**: 59% reduction vs sequential
- **Pros**: Maximum efficiency
- **Cons**: Higher Context7 API usage, more complex coordination

**Recommended Approach**: Parallel Execution (3-4 agents, 19.5 hours)

---

## 🔄 Execution Order (Optimized for Dependencies)

### Batch 1: Foundation (Parallel, 3.5 hours)
```
START
├─ [qemu-health-checker] 01-install-qemu-kvm.sh (2h)
├─ [qemu-health-checker] 02-configure-user-groups.sh (1.5h)
└─ [master-orchestrator] install-master.sh (1.5h)
WAIT FOR ALL TO COMPLETE
```

### Batch 2: VM Creation (Sequential, 4 hours)
```
START
└─ [vm-operations-specialist] create-vm.sh (4h)
WAIT FOR COMPLETION (required for all subsequent VM scripts)
```

### Batch 3: VM Operations (Parallel, 3 hours)
```
START
├─ [vm-operations-specialist] start-vm.sh (2h)
├─ [vm-operations-specialist] stop-vm.sh (2h)
└─ [vm-operations-specialist] backup-vm.sh (3h)
WAIT FOR ALL TO COMPLETE
```

### Batch 4: Optimization & Security (Parallel, 5 hours)
```
START
├─ [performance-optimization-specialist] configure-performance.sh (5h)
├─ [performance-optimization-specialist + security-hardening-specialist] win11-vm.xml (4h, coordinated)
├─ [security-hardening-specialist] test-virtio-fs.sh (2h)
├─ [virtio-fs-specialist] setup-virtio-fs.sh (3h)
└─ [virtio-fs-specialist] virtio-fs-share.xml (2h)
WAIT FOR ALL TO COMPLETE
```

**Total Optimized Time**: 15.5 hours (3.5 + 4 + 3 + 5)

---

## 📂 Directory Structure

```
docs-repo/
├── CONTEXT7-VERIFICATION-MASTER-TEMPLATE.md     # Master template (this document's companion)
├── CONTEXT7-VERIFICATION-EXECUTION-PLAN.md      # This document
│
├── context7-verification/                       # Per-file verification tasks
│   ├── scripts/                                 # Shell script verifications
│   │   ├── 01-install-qemu-kvm.md              # Duplicate of master template, filled in
│   │   ├── 02-configure-user-groups.md
│   │   ├── install-master.md
│   │   ├── create-vm.md
│   │   ├── configure-performance.md
│   │   ├── setup-virtio-fs.md
│   │   ├── test-virtio-fs.md
│   │   ├── start-vm.md
│   │   ├── stop-vm.md
│   │   └── backup-vm.md
│   │
│   └── configs/                                 # XML config verifications
│       ├── win11-vm.md
│       └── virtio-fs-share.md
│
└── context7-libraries/                          # Context7 lookup results cache
    ├── qemu-library-info.md
    ├── libvirt-library-info.md
    ├── virtio-library-info.md
    ├── hyperv-enlightenments-library-info.md
    └── ...
```

---

## 🚀 Getting Started

### Step 1: Duplicate Master Template

For each file in the inventory:

```bash
# Example for create-vm.sh
cp docs-repo/CONTEXT7-VERIFICATION-MASTER-TEMPLATE.md \
   docs-repo/context7-verification/scripts/create-vm.md

# Edit and fill in script-specific information
nano docs-repo/context7-verification/scripts/create-vm.md
```

### Step 2: Context7 Library Resolution

For each unique technology (do once, reuse across scripts):

```
Use mcp__context7__resolve-library-id for:
1. QEMU
2. KVM
3. libvirt
4. VirtIO drivers
5. virtio-fs
6. OVMF/EDK2
7. swtpm
8. Hyper-V enlightenments
9. QEMU guest agent
10. WinFsp

Document results in docs-repo/context7-libraries/
```

### Step 3: Execute Verification Batches

Follow execution order defined above:

```
Batch 1 (Parallel):
- Agent: qemu-health-checker
  Task: Verify 01-install-qemu-kvm.sh
  Task: Verify 02-configure-user-groups.sh

- Agent: master-orchestrator
  Task: Verify install-master.sh

Batch 2 (Sequential):
- Agent: vm-operations-specialist
  Task: Verify create-vm.sh

... continue through all batches
```

### Step 4: Aggregate Results

After all verifications complete:

```bash
# Create summary report
docs-repo/CONTEXT7-VERIFICATION-SUMMARY-REPORT.md

# Include:
- Total issues found (critical/medium/low)
- Issues resolved
- Intentional deviations documented
- Overall compliance score
- Recommendations for improvements
```

---

## 📊 Success Metrics

**Completion Criteria**:
- [ ] All 12 files have completed verification documents
- [ ] All Context7 library IDs resolved
- [ ] All critical issues identified and tracked
- [ ] All medium/low priority issues documented
- [ ] Agent assignment complete
- [ ] Execution timeline finalized

**Quality Metrics**:
- **Target**: 95%+ compliance with Context7 best practices
- **Acceptable**: 85%+ compliance (with documented deviations)
- **Concerning**: <85% compliance (requires fixes)

**Issue Tracking**:
- **Critical Issues**: 0 acceptable in production
- **Medium Issues**: <5 acceptable with documented trade-offs
- **Low Issues**: <10 acceptable, tracked for future work

---

## 🔧 Tools & Resources

**Context7 MCP Tools**:
- `mcp__context7__resolve-library-id` - Get library IDs
- `mcp__context7__get-library-docs` - Fetch documentation

**Agent Specialists**:
- vm-operations-specialist
- performance-optimization-specialist
- security-hardening-specialist
- virtio-fs-specialist
- qemu-health-checker
- master-orchestrator

**Project Documentation**:
- `scripts/README.md` - Script inventory
- `configs/README.md` - Config template inventory
- `AGENTS.md` - Agent system reference
- `.claude/agents/AGENTS-MD-REFERENCE.md` - Complete agent documentation

**External References**:
- QEMU Documentation: https://www.qemu.org/docs/master/
- Libvirt XML Format: https://libvirt.org/formatdomain.html
- VirtIO Specification: https://docs.oasis-open.org/virtio/virtio/
- virtio-fs: https://virtio-fs.gitlab.io/

---

## 🎯 Next Steps

**Immediate Actions**:
1. Review this execution plan
2. Approve agent assignments and timeline
3. Create timestamped branch for verification workflow
4. Begin Batch 1 (Foundation scripts) verification

**Human Intervention Points**:
- Approval for Context7 library selections (if multiple good matches)
- Decision on intentional deviations (trade-offs)
- Prioritization of medium/low priority issues for future work
- Final sign-off on production readiness

**Expected Deliverables**:
- 12 completed verification documents (one per file)
- Context7 library mapping cache (reusable)
- Summary report with compliance scores
- Issue tracking database for future fixes

---

**Document Version**: 1.0
**Created**: 2025-11-21
**Status**: Ready for Execution
**Estimated Completion**: 2025-11-23 (2.5 workdays with parallel execution)
