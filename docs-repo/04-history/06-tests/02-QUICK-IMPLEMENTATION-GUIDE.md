# Quick Test Implementation Guide

**Purpose:** Fastest path to add highest-value tests
**Time Investment:** 30 minutes → Close critical security & configuration gaps
**Target Audience:** Developers adding tests to run-dry-run-tests.sh

---

## 5 Critical Tests to Add Right Now (30 Minutes)

These 5 tests close the most critical gaps with minimal effort. Add them to `/home/kkk/Apps/win-qemu/scripts/run-dry-run-tests.sh` after Phase 9 (Runtime Error Pattern Detection).

---

### Test 1: CPU Virtualization Support (5 min) - CRITICAL

**What It Tests:** Hardware virtualization capability (vmx/svm flags)
**Why Critical:** Without this, QEMU/KVM will fail or run extremely slowly
**Where to Add:** New Phase 10 "Hardware Requirements Validation"

```bash
# PHASE 10: Hardware Requirements Validation
section_header "PHASE 10: HARDWARE REQUIREMENTS VALIDATION"

# Test 1: CPU Virtualization Support
test_name="hardware-cpu-virtualization"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking CPU virtualization support..."
    virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
    echo "Virtualization flags found: ${virt_support}"

    if [[ $virt_support -gt 0 ]]; then
        echo "✓ CPU virtualization is enabled (Intel VT-x or AMD-V)"
        exit 0
    else
        echo "✗ CPU virtualization NOT enabled"
        echo "Action required: Enable VT-x/AMD-V in BIOS"
        exit 1
    fi
} > "$log_file" 2>&1

if [[ $? -eq 0 ]]; then
    virt_count=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
    log_test "PASS" "$test_name" "CPU virtualization support" 0 "${virt_count} cores with vmx/svm flags - [\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "FAIL" "$test_name" "CPU virtualization support" 1 "No vmx/svm flags - BIOS configuration required - [\`${test_name}.log\`](./${test_name}.log)"
fi
```

**Expected Result:** PASS (your system has virtualization enabled)
**If FAIL:** Critical blocker - must enable VT-x/AMD-V in BIOS before proceeding

---

### Test 2: Hyper-V Enlightenments Count (10 min) - CRITICAL

**What It Tests:** All 14 Hyper-V enlightenments configured in VM template
**Why Critical:** Missing enlightenments = 50-60% performance instead of 85-95%
**Where to Add:** New Phase 11 "VM Configuration Deep Validation"

```bash
# PHASE 11: VM Configuration Deep Validation
section_header "PHASE 11: VM CONFIGURATION DEEP VALIDATION"

# Test 1: Hyper-V Enlightenments Count
test_name="vm-config-hyperv-enlightenments-count"
log_file="${LOG_DIR}/${test_name}.log"

if [[ -f "configs/win11-vm.xml" ]]; then
    {
        echo "Counting Hyper-V enlightenments in VM template..."

        # Count all enlightenment tags with state='on'
        enlightenment_count=$(grep -oP '<(relaxed|vapic|spinlocks|vpindex|runtime|synic|stimer|reset|vendor_id|frequencies|reenlightenment|tlbflush|ipi|evmcs) state=' configs/win11-vm.xml | wc -l)

        echo "Found: ${enlightenment_count} / 14 enlightenments"
        echo ""
        echo "Expected enlightenments:"
        echo "  1. relaxed"
        echo "  2. vapic"
        echo "  3. spinlocks"
        echo "  4. vpindex"
        echo "  5. runtime"
        echo "  6. synic"
        echo "  7. stimer"
        echo "  8. reset"
        echo "  9. vendor_id"
        echo " 10. frequencies"
        echo " 11. reenlightenment"
        echo " 12. tlbflush"
        echo " 13. ipi"
        echo " 14. evmcs"
        echo ""

        if [[ $enlightenment_count -eq 14 ]]; then
            echo "✓ All 14 Hyper-V enlightenments configured"
            echo "Expected performance: 85-95% of native Windows"
            exit 0
        else
            echo "✗ Only ${enlightenment_count}/14 enlightenments found"
            echo "Expected performance: 50-60% of native Windows (POOR)"
            exit 1
        fi
    } > "$log_file" 2>&1

    if [[ $? -eq 0 ]]; then
        log_test "PASS" "$test_name" "Hyper-V enlightenments count" 0 "14/14 configured - [\`${test_name}.log\`](./${test_name}.log)"
    else
        enlightenment_count=$(grep -oP '<(relaxed|vapic|spinlocks|vpindex|runtime|synic|stimer|reset|vendor_id|frequencies|reenlightenment|tlbflush|ipi|evmcs) state=' configs/win11-vm.xml | wc -l)
        log_test "FAIL" "$test_name" "Hyper-V enlightenments count" 1 "${enlightenment_count}/14 found - performance will be poor - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "Hyper-V enlightenments count" "N/A" "configs/win11-vm.xml not found"
fi
```

**Expected Result:** PASS (all 14 enlightenments in template)
**If FAIL:** Performance will be degraded - must fix VM template

---

### Test 3: virtio-fs Read-Only Mode (5 min) - CRITICAL SECURITY

**What It Tests:** virtio-fs configured in read-only mode (ransomware protection)
**Why Critical:** Without read-only, guest malware can encrypt host files
**Where to Add:** Phase 11 (after Test 2)

```bash
# Test 2: virtio-fs Read-Only Mode (CRITICAL SECURITY)
test_name="security-virtiofs-readonly-template"
log_file="${LOG_DIR}/${test_name}.log"

if [[ -f "configs/virtio-fs-share.xml" ]]; then
    {
        echo "Checking virtio-fs read-only mode configuration..."
        echo ""

        # Check if <readonly/> tag exists in filesystem configuration
        if grep -A10 "<filesystem" configs/virtio-fs-share.xml | grep -q "<readonly/>"; then
            echo "✓ virtio-fs configured in READ-ONLY mode"
            echo ""
            echo "Security benefit: Ransomware protection"
            echo "  - Guest malware CANNOT encrypt host files"
            echo "  - Guest malware CANNOT delete host files"
            echo "  - Guest malware CANNOT modify host files"
            echo ""
            echo "This is the PRIMARY security control for this project."
            exit 0
        else
            echo "✗ virtio-fs NOT configured in read-only mode"
            echo ""
            echo "CRITICAL SECURITY RISK:"
            echo "  - Guest ransomware CAN encrypt host files"
            echo "  - Guest ransomware CAN delete host files"
            echo "  - Guest ransomware CAN modify host files"
            echo ""
            echo "Action required: Add <readonly/> tag to filesystem configuration"
            exit 1
        fi
    } > "$log_file" 2>&1

    if [[ $? -eq 0 ]]; then
        log_test "PASS" "$test_name" "virtio-fs read-only mode (ransomware protection)" 0 "✓ Protected - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "virtio-fs read-only mode (ransomware protection)" 1 "🔴 CRITICAL SECURITY RISK - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "virtio-fs read-only mode" "N/A" "configs/virtio-fs-share.xml not found"
fi
```

**Expected Result:** PASS (read-only mode configured)
**If FAIL:** CRITICAL security vulnerability - must fix immediately

---

### Test 4: Q35 Chipset Configuration (5 min) - HIGH

**What It Tests:** VM uses Q35 chipset (modern PCI-Express support)
**Why Critical:** Older chipsets lack features needed for Windows 11 and VirtIO
**Where to Add:** Phase 11 (after Test 3)

```bash
# Test 3: Q35 Chipset Configuration
test_name="vm-config-q35-chipset"
log_file="${LOG_DIR}/${test_name}.log"

if [[ -f "configs/win11-vm.xml" ]]; then
    {
        echo "Checking VM chipset configuration..."
        echo ""

        if grep -q "machine='pc-q35" configs/win11-vm.xml; then
            echo "✓ Q35 chipset configured"
            echo ""
            echo "Benefits:"
            echo "  - Modern PCI-Express support"
            echo "  - UEFI firmware compatible"
            echo "  - Better device passthrough"
            echo "  - Required for Windows 11"
            exit 0
        else
            echo "✗ Q35 chipset NOT found"
            echo ""
            echo "Impact: VM may not support Windows 11 or modern features"
            echo "Action required: Change machine type to pc-q35-8.0 or newer"
            exit 1
        fi
    } > "$log_file" 2>&1

    if [[ $? -eq 0 ]]; then
        log_test "PASS" "$test_name" "Q35 chipset configuration" 0 "Modern PCI-Express support - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "Q35 chipset configuration" 1 "Q35 not found - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "Q35 chipset configuration" "N/A" "configs/win11-vm.xml not found"
fi
```

**Expected Result:** PASS (Q35 chipset in template)
**If FAIL:** VM may not work with Windows 11

---

### Test 5: CLAUDE.md Symlink Integrity (5 min) - HIGH

**What It Tests:** CLAUDE.md symlink correctly points to AGENTS.md
**Why Critical:** Constitutional requirement - single source of truth
**Where to Add:** New Phase 12 "Git Constitutional Compliance"

```bash
# PHASE 12: Git Constitutional Compliance
section_header "PHASE 12: GIT CONSTITUTIONAL COMPLIANCE"

# Test 1: CLAUDE.md Symlink Integrity
test_name="git-symlink-claude-agents"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking CLAUDE.md symlink integrity..."
    echo ""

    if [[ -L "CLAUDE.md" ]]; then
        target=$(readlink CLAUDE.md)
        echo "CLAUDE.md is a symlink"
        echo "Points to: ${target}"
        echo ""

        if [[ "$target" == "AGENTS.md" ]]; then
            echo "✓ Symlink target is correct"
            echo "Constitutional compliance: MAINTAINED"
            exit 0
        else
            echo "✗ Symlink points to wrong target: ${target}"
            echo "Expected: AGENTS.md"
            echo "Constitutional violation: AGENTS.md is single source of truth"
            exit 1
        fi
    else
        echo "✗ CLAUDE.md is not a symlink"
        echo "Constitutional violation: Must be symlink to AGENTS.md"
        exit 1
    fi
} > "$log_file" 2>&1

if [[ $? -eq 0 ]]; then
    log_test "PASS" "$test_name" "CLAUDE.md symlink integrity" 0 "Points to AGENTS.md - [\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "FAIL" "$test_name" "CLAUDE.md symlink integrity" 1 "Constitutional violation - [\`${test_name}.log\`](./${test_name}.log)"
fi

# Test 2: GEMINI.md Symlink Integrity
test_name="git-symlink-gemini-agents"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking GEMINI.md symlink integrity..."
    echo ""

    if [[ -L "GEMINI.md" ]]; then
        target=$(readlink GEMINI.md)
        echo "GEMINI.md is a symlink"
        echo "Points to: ${target}"
        echo ""

        if [[ "$target" == "AGENTS.md" ]]; then
            echo "✓ Symlink target is correct"
            echo "Constitutional compliance: MAINTAINED"
            exit 0
        else
            echo "✗ Symlink points to wrong target: ${target}"
            echo "Expected: AGENTS.md"
            exit 1
        fi
    else
        echo "✗ GEMINI.md is not a symlink"
        echo "Constitutional violation: Must be symlink to AGENTS.md"
        exit 1
    fi
} > "$log_file" 2>&1

if [[ $? -eq 0 ]]; then
    log_test "PASS" "$test_name" "GEMINI.md symlink integrity" 0 "Points to AGENTS.md - [\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "FAIL" "$test_name" "GEMINI.md symlink integrity" 1 "Constitutional violation - [\`${test_name}.log\`](./${test_name}.log)"
fi
```

**Expected Result:** PASS (both symlinks correct)
**If FAIL:** Documentation integrity compromised

---

## Summary of 5 Critical Tests

| # | Test Name | Phase | Lines | Priority | Time |
|---|-----------|-------|-------|----------|------|
| 1 | CPU Virtualization | Phase 10 (new) | 25 | CRITICAL | 5 min |
| 2 | Hyper-V Enlightenments Count | Phase 11 (new) | 45 | CRITICAL | 10 min |
| 3 | virtio-fs Read-Only Mode | Phase 11 | 40 | CRITICAL | 5 min |
| 4 | Q35 Chipset | Phase 11 | 30 | HIGH | 5 min |
| 5 | Symlinks Integrity | Phase 12 (new) | 60 (2 tests) | HIGH | 5 min |
| **TOTAL** | **6 tests** | **3 new phases** | **200 lines** | - | **30 min** |

---

## Expected Outcome

**Before:**
- Total tests: 54
- Pass rate: 87% (47/54)
- Phases: 9
- Critical gaps: Hardware, VM config, security

**After (30 minutes):**
- Total tests: 60 (+6)
- Pass rate: ~88% (53/60 expected)
- Phases: 12 (+3)
- Critical gaps: CLOSED for hardware, VM config template, security template

**New Test Distribution:**
```
Phase 10: Hardware Requirements (1 test)
Phase 11: VM Configuration (3 tests)
Phase 12: Git Constitutional Compliance (2 tests)
```

---

## Next Steps After These 5 Tests

Once these 5 critical tests pass, proceed with:

1. **Add remaining hardware tests** (Phase 10 expansion) - 20 min
   - RAM sufficiency
   - SSD vs HDD detection
   - CPU core count
   - Disk space availability

2. **Add remaining VM config tests** (Phase 11 expansion) - 30 min
   - UEFI firmware enabled
   - Secure Boot configured
   - TPM 2.0 emulation
   - Individual enlightenments (14 tests)
   - VirtIO devices (3 tests)

3. **Add post-installation tests** (Phase 13) - 1 hour
   - libvirtd service status
   - User group membership
   - Default network active
   - OVMF firmware availability
   - swtpm availability

**Total Additional Effort:** 1.5 hours → 75 tests total → 59% coverage

---

## Integration Instructions

### Step 1: Backup Current Test Script
```bash
cp scripts/run-dry-run-tests.sh scripts/run-dry-run-tests.sh.backup
```

### Step 2: Edit Test Script
```bash
vim scripts/run-dry-run-tests.sh
```

### Step 3: Add New Phases
Insert the 3 new phases (Phase 10, 11, 12) after Phase 9 (Runtime Error Pattern Detection) and before the "Generate Final Report" section.

The insertion point is around line 448, just before:
```bash
# ==============================================================================
# GENERATE FINAL REPORT
# ==============================================================================
```

### Step 4: Test Immediately
```bash
./scripts/run-dry-run-tests.sh
```

Expected output:
```
...
═══════════════════════════════════════════════════════
PHASE 10: HARDWARE REQUIREMENTS VALIDATION
═══════════════════════════════════════════════════════

[✓ PASS] CPU virtualization support (16 cores with vmx/svm flags)

═══════════════════════════════════════════════════════
PHASE 11: VM CONFIGURATION DEEP VALIDATION
═══════════════════════════════════════════════════════

[✓ PASS] Hyper-V enlightenments count (14/14 configured)
[✓ PASS] virtio-fs read-only mode (ransomware protection)
[✓ PASS] Q35 chipset configuration (Modern PCI-Express support)

═══════════════════════════════════════════════════════
PHASE 12: GIT CONSTITUTIONAL COMPLIANCE
═══════════════════════════════════════════════════════

[✓ PASS] CLAUDE.md symlink integrity (Points to AGENTS.md)
[✓ PASS] GEMINI.md symlink integrity (Points to AGENTS.md)
...

Test Summary:
  Total Tests:    60
  ✓ Passed:      53 (88%)
  ✗ Failed:      6 (10%)
  ⊘ Skipped:     1 (2%)
```

### Step 5: Commit Changes
```bash
git add scripts/run-dry-run-tests.sh
git commit -m "test: Add 6 critical tests for hardware, VM config, and git compliance

Added 3 new test phases:
- Phase 10: Hardware Requirements (CPU virtualization)
- Phase 11: VM Configuration (Hyper-V, virtio-fs, Q35)
- Phase 12: Git Constitutional Compliance (symlinks)

Critical gaps closed:
- Hardware virtualization detection
- Hyper-V enlightenments count (14/14)
- virtio-fs read-only mode (ransomware protection)
- Q35 chipset configuration
- Symlink integrity (CLAUDE.md, GEMINI.md)

Test coverage: 54 → 60 tests (+11%)
Estimated pass rate: 88%

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Troubleshooting

### If Tests Fail

**Test 1 (CPU Virtualization) FAILS:**
- **Cause:** VT-x/AMD-V disabled in BIOS
- **Fix:** Reboot, enter BIOS, enable "Intel Virtualization Technology" or "AMD-V"
- **Verify:** `egrep -c '(vmx|svm)' /proc/cpuinfo` should return > 0

**Test 2 (Hyper-V Enlightenments) FAILS:**
- **Cause:** Missing enlightenments in configs/win11-vm.xml
- **Fix:** Review VM config validation report: `docs-repo/03-health-validation/05-VM-CONFIG-VALIDATION-REPORT.md`
- **Verify:** `grep -c "<hyperv" configs/win11-vm.xml` should return > 0

**Test 3 (virtio-fs Read-Only) FAILS:**
- **Cause:** Missing `<readonly/>` tag in configs/virtio-fs-share.xml
- **Fix:** Edit configs/virtio-fs-share.xml, add `<readonly/>` inside `<filesystem>` block
- **Verify:** `grep -q "<readonly/>" configs/virtio-fs-share.xml && echo PASS`

**Test 4 (Q35 Chipset) FAILS:**
- **Cause:** Wrong machine type in VM template
- **Fix:** Edit configs/win11-vm.xml, change machine type to `pc-q35-8.0` or newer
- **Verify:** `grep "machine=" configs/win11-vm.xml`

**Test 5 (Symlinks) FAILS:**
- **Cause:** Symlinks broken or missing
- **Fix:** `ln -sf AGENTS.md CLAUDE.md && ln -sf AGENTS.md GEMINI.md`
- **Verify:** `readlink CLAUDE.md` should output `AGENTS.md`

---

## Performance Impact

**Test Execution Time:**
- Before: 1-2 seconds (54 tests)
- After: 1-2 seconds (60 tests)
- Impact: Negligible (+0.1s estimated)

**Why So Fast:**
- All tests are grep/file checks (no heavy operations)
- No VM operations required (template validation only)
- Parallel execution potential (future optimization)

---

**Document Version:** 1.0
**Author:** Claude Code
**Date:** 2025-11-21
**Purpose:** Fastest path to add highest-value tests (30 minutes)
