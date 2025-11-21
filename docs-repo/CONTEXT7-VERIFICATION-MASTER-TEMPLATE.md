# Context7 Verification Master Template

**Purpose**: Comprehensive Context7-based verification workflow for QEMU/KVM scripts and configurations

**Created**: 2025-11-21
**Status**: Master Template (duplicate for each script/config)

---

## 📋 Script/Config Information

**File**: [TO BE FILLED - e.g., scripts/create-vm.sh]
**Type**: [Shell Script | XML Config | Python Script]
**Size**: [TO BE FILLED - e.g., 26 KB]
**Lines**: [TO BE FILLED - e.g., 650 lines]
**Purpose**: [TO BE FILLED - brief description]

---

## 🔍 Phase 1: Technology Identification

**Primary Technologies Used** (check all that apply):
- [ ] QEMU (qemu-system-x86_64, qemu-img)
- [ ] KVM (kernel-based virtual machine)
- [ ] libvirt (virsh, virt-install, libvirt API)
- [ ] VirtIO drivers (virtio-blk, virtio-net, virtio-fs, virtio-scsi)
- [ ] OVMF/EDK2 (UEFI firmware)
- [ ] swtpm (TPM 2.0 emulation)
- [ ] WinFsp (Windows virtio-fs support)
- [ ] Hyper-V enlightenments (hyperv features in XML)
- [ ] XML (libvirt domain configuration)
- [ ] Bash scripting (error handling, validation)

**Secondary Technologies**:
- [ ] Linux user/group management (usermod, groups)
- [ ] systemd (service management)
- [ ] apt package manager
- [ ] Filesystem operations
- [ ] Network configuration
- [ ] Other: [specify]

---

## 🌐 Phase 2: Context7 Library Resolution

**Instructions**: Use `mcp__context7__resolve-library-id` to get proper library IDs for each technology

### QEMU/KVM Core
```
Technology: QEMU
Context7 Query: "QEMU hardware emulation"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

```
Technology: KVM
Context7 Query: "KVM kernel virtual machine Linux"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

```
Technology: libvirt
Context7 Query: "libvirt virtualization management API"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

### VirtIO Technologies
```
Technology: VirtIO drivers
Context7 Query: "VirtIO paravirtualized drivers"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

```
Technology: virtio-fs
Context7 Query: "virtio-fs filesystem sharing"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

### Firmware & Emulation
```
Technology: OVMF/EDK2
Context7 Query: "OVMF EDK2 UEFI firmware"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

```
Technology: swtpm
Context7 Query: "swtpm TPM emulator"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

### Windows Guest Technologies
```
Technology: Hyper-V enlightenments
Context7 Query: "Hyper-V enlightenments QEMU KVM"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

```
Technology: WinFsp (if applicable)
Context7 Query: "WinFsp Windows filesystem"
Library ID: [TO BE FILLED after Context7 lookup]
Confidence: [High | Medium | Low]
```

---

## 📖 Phase 3: Documentation Lookup

**Instructions**: Use `mcp__context7__get-library-docs` to fetch best practices for each technology

### For Each Technology:

**Technology**: [e.g., QEMU]
**Library ID**: [from Phase 2]
**Topic**: [e.g., "VM creation best practices"]

**Context7 Lookup Results**:
```
Page 1 Results:
[TO BE FILLED - key recommendations from Context7]

Key Takeaways:
1. [Best practice #1]
2. [Best practice #2]
3. [Best practice #3]
```

**Repeat for each major technology used in the script**

---

## ✅ Phase 4: Code Comparison Checklist

**Instructions**: Compare actual script implementation against Context7 recommendations

### 4.1 Architecture & Design Patterns

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| VM creation method | [e.g., virt-install vs virsh define] | [e.g., uses virt-install] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Chipset type | [e.g., Q35 recommended] | [e.g., Q35] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| UEFI firmware | [e.g., OVMF required for Win11] | [e.g., OVMF] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| TPM emulation | [e.g., swtpm for Win11] | [e.g., swtpm] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

### 4.2 VirtIO Configuration

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| Disk driver | [e.g., virtio-scsi recommended] | [e.g., virtio-scsi] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Network driver | [e.g., virtio-net] | [e.g., virtio-net] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Graphics driver | [e.g., virtio-vga] | [e.g., virtio-vga] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Filesystem sharing | [e.g., virtio-fs preferred over 9p] | [e.g., virtio-fs] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

### 4.3 Performance Optimization

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| Hyper-V enlightenments | [e.g., all 14 recommended for Win11] | [e.g., 14/14 applied] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| CPU pinning | [e.g., optional for dedicated workloads] | [e.g., optional/commented] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Huge pages | [e.g., optional for memory-intensive] | [e.g., optional/commented] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Cache mode | [e.g., writeback for local storage] | [e.g., writeback] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

### 4.4 Security Configuration

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| virtio-fs access mode | [e.g., read-only for shared data] | [e.g., read-only enforced] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Network isolation | [e.g., NAT mode for security] | [e.g., NAT mode] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| UEFI Secure Boot | [e.g., enabled for Win11] | [e.g., enabled] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| TPM configuration | [e.g., TPM 2.0 for BitLocker] | [e.g., TPM 2.0] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

### 4.5 Error Handling & Validation

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| Input validation | [e.g., validate user inputs] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Error checking | [e.g., check command exit codes] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Rollback support | [e.g., backup before changes] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Logging | [e.g., detailed operation logs] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

### 4.6 Code Quality & Best Practices

| Aspect | Context7 Recommendation | Current Implementation | Status | Notes |
|--------|------------------------|------------------------|--------|-------|
| Shellcheck compliance | [e.g., no critical issues] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Idempotency | [e.g., safe to run multiple times] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Documentation | [e.g., inline comments, help text] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |
| Dry-run support | [e.g., preview mode available] | [TO BE FILLED] | ✅ Pass / ❌ Fail / ⚠️ Partial | |

---

## 🐛 Phase 5: Issue Tracking

**Instructions**: Document all deviations from Context7 best practices

### Critical Issues (Must Fix)

**Issue #1**: [Title]
- **Category**: [Architecture | VirtIO | Performance | Security | Code Quality]
- **Severity**: Critical
- **Current Implementation**: [What the script does now]
- **Context7 Recommendation**: [What it should do]
- **Impact**: [Performance degradation | Security risk | Compatibility issue]
- **Fix Required**: [Specific code changes needed]
- **Estimated Effort**: [1 hour | 1 day | 1 week]

### Medium Priority Issues (Should Fix)

**Issue #2**: [Title]
- **Category**: [Architecture | VirtIO | Performance | Security | Code Quality]
- **Severity**: Medium
- **Current Implementation**: [What the script does now]
- **Context7 Recommendation**: [What it should do]
- **Impact**: [Suboptimal performance | Minor security concern]
- **Fix Required**: [Specific code changes needed]
- **Estimated Effort**: [1 hour | 1 day | 1 week]

### Low Priority Issues (Nice to Have)

**Issue #3**: [Title]
- **Category**: [Architecture | VirtIO | Performance | Security | Code Quality]
- **Severity**: Low
- **Current Implementation**: [What the script does now]
- **Context7 Recommendation**: [What it should do]
- **Impact**: [Minor optimization opportunity]
- **Fix Required**: [Specific code changes needed]
- **Estimated Effort**: [1 hour | 1 day | 1 week]

### Intentional Deviations (Documented, No Fix Needed)

**Deviation #1**: [Title]
- **Reason**: [Why we deviate from Context7 recommendation]
- **Trade-off**: [Benefits vs risks]
- **Acceptance Criteria**: [Why this is acceptable]

---

## 🔧 Phase 6: Fix Implementation

**Instructions**: Track implementation of required fixes

### Fix Tracking

**Fix #1**: [Issue title from Phase 5]
- **Branch**: [e.g., 20251121-120000-fix-virtio-config]
- **Implementation Status**: [ ] Not Started | [ ] In Progress | [ ] Complete
- **Code Changes**: [Files modified, line numbers]
- **Testing**: [ ] Unit tests | [ ] Integration tests | [ ] Manual verification
- **Validation**: [ ] Context7 re-check passed
- **Notes**: [Any additional context]

**Fix #2**: [Issue title from Phase 5]
- **Branch**: [e.g., 20251121-130000-fix-hyperv-enlightenments]
- **Implementation Status**: [ ] Not Started | [ ] In Progress | [ ] Complete
- **Code Changes**: [Files modified, line numbers]
- **Testing**: [ ] Unit tests | [ ] Integration tests | [ ] Manual verification
- **Validation**: [ ] Context7 re-check passed
- **Notes**: [Any additional context]

---

## ✅ Phase 7: Final Validation

**Instructions**: Confirm all fixes align with Context7 best practices

### Re-Validation Checklist

**Architecture & Design**:
- [ ] All critical architecture issues resolved
- [ ] VM configuration follows Context7 recommendations
- [ ] Chipset, firmware, TPM configuration verified

**VirtIO Configuration**:
- [ ] All VirtIO drivers use recommended configurations
- [ ] Filesystem sharing uses virtio-fs (not Samba/9p)
- [ ] Network and storage drivers optimized

**Performance Optimization**:
- [ ] Hyper-V enlightenments complete (14/14 for Windows)
- [ ] Performance benchmarks meet targets (85-95% native)
- [ ] No known performance bottlenecks

**Security Configuration**:
- [ ] virtio-fs read-only mode enforced (if applicable)
- [ ] Network isolation configured correctly
- [ ] UEFI Secure Boot and TPM 2.0 enabled

**Code Quality**:
- [ ] All critical shellcheck issues resolved
- [ ] Error handling comprehensive
- [ ] Idempotency verified
- [ ] Documentation complete

### Context7 Re-Check

**Re-run Context7 lookups for technologies with fixes**:

**Technology**: [e.g., VirtIO]
**Original Issue**: [e.g., incorrect cache mode]
**Fix Applied**: [e.g., changed cache=none to cache=writeback]
**Context7 Re-Check**: ✅ Now aligns with best practices

### Final Sign-Off

- [ ] All critical issues resolved
- [ ] All medium priority issues resolved or documented as accepted deviations
- [ ] Low priority issues prioritized for future work
- [ ] Context7 verification complete
- [ ] Script/config production-ready

**Verified By**: [Agent name or human reviewer]
**Verification Date**: [YYYY-MM-DD]
**Status**: ✅ PASSED | ⚠️ PASSED WITH CAVEATS | ❌ FAILED

---

## 📊 Summary Report

**Script/Config**: [Name]
**Total Issues Found**: [X critical, Y medium, Z low]
**Issues Resolved**: [X critical, Y medium, Z low]
**Intentional Deviations**: [N items]
**Overall Compliance**: [High | Medium | Low]
**Production Ready**: [Yes | No | With Caveats]

**Key Improvements**:
1. [Improvement #1]
2. [Improvement #2]
3. [Improvement #3]

**Remaining Work**:
1. [Low priority issue #1]
2. [Low priority issue #2]

**Recommendations**:
1. [Future enhancement #1]
2. [Future enhancement #2]

---

## 🔗 Related Documentation

**Project Documentation**:
- [Link to main script README]
- [Link to implementation guide]
- [Link to troubleshooting doc]

**Context7 Libraries Referenced**:
- [Library 1: /org/project]
- [Library 2: /org/project]
- [Library 3: /org/project]

**External References**:
- [Official QEMU documentation]
- [Libvirt XML format reference]
- [VirtIO specification]

---

**Template Version**: 1.0
**Last Updated**: 2025-11-21
**Status**: Master Template (Ready for Duplication)
