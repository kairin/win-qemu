# Dry-Run Mode Analysis Report

**Date:** 2025-01-27
**Agent:** guardian-prerequisites
**Purpose:** Analyze bash scripts for dry-run mode improvements to support PREPARATION phase (before QEMU installation)

---

## Executive Summary

**Test Results:** 6 out of 8 dry-run tests FAILED due to:
1. Scripts requiring sudo even in dry-run mode
2. Missing dependency checks (virsh, virt-xml) blocking execution
3. Service status checks (libvirtd) preventing preview mode

**Recommendation:** Implement graceful degradation pattern where dry-run mode:
- Skips sudo requirement checks
- Simulates missing commands with informative messages
- Provides detailed "would execute" feedback
- Allows users to preview functionality BEFORE installing QEMU/KVM

**Business Impact:** Improved user experience during preparation phase, allowing users to understand what scripts will do before committing to full QEMU/KVM installation.

---

## Context7 Research Findings

### Best Practices for Bash Dry-Run Mode

**Source:** `/bobbyiliev/introduction-to-bash-scripting` (High reputation, 385 code snippets)

#### Key Patterns Identified:

1. **Command Validation with Graceful Fallback:**
   ```bash
   # Check dependencies without failing
   command -v jq >/dev/null 2>&1 || error_exit "jq is not installed"
   ```

2. **Exit Status Checking:**
   ```bash
   [[ $? -eq 0 ]]  # Success
   [[ $? -gt 0 ]]  # Failure
   ```

3. **Production Script Template:**
   ```bash
   # Exit on error
   set -e

   # Prevent running as root
   if (( $EUID == 0 )); then
       echo "ERROR: Please do not run as root"
       exit 1
   fi

   # Check dependencies
   command -v jq >/dev/null 2>&1 || error_exit "jq is not installed"
   ```

4. **STDERR Redirection for Silent Checks:**
   ```bash
   ls --hello 2> /dev/null  # Discard errors
   ```

**Application to Dry-Run Mode:**
- Dry-run should invert root check: ALLOW non-root execution
- Dependencies should be checked but not required (show warnings)
- Service status checks should be simulated, not enforced
- All actual operations should be replaced with descriptive echo statements

---

## Script Analysis

### 1. create-vm.sh (794 lines)

**Current Dry-Run Implementation:**

| Feature | Status | Lines | Notes |
|---------|--------|-------|-------|
| `--dry-run` flag | ✅ Implemented | 618, 631-632 | Flag parsing works |
| Root check bypass | ❌ MISSING | 414 | `check_root()` always enforces sudo |
| ISO check simulation | ✅ Partial | 321-334, 358-360 | Shows "[DRY RUN]" messages |
| Disk creation skip | ✅ Good | 707-720 | Shows what would be created |
| XML validation skip | ❌ MISSING | N/A | Could fail on virsh commands |

**Problems in Dry-Run Mode:**

1. **Line 414: Mandatory Root Check**
   ```bash
   run_preflight_checks() {
       # ...
       check_root || ((checks_failed++))  # FAILS in dry-run
   ```
   **Impact:** Script exits with "must be run with sudo" even with `--dry-run`

2. **Line 264-267: Package Checks Require dpkg**
   ```bash
   if ! dpkg -l | grep -q "^ii.*${package}"; then
       missing_packages+=("$package")
   fi
   ```
   **Impact:** Fails if QEMU not installed, defeating preparation use case

3. **Line 557: libvirtd Service Check**
   ```bash
   check_libvirtd || exit 1
   ```
   **Impact:** Exits if libvirtd not running, even in dry-run

**Recommended Fixes:**

```bash
# Fix 1: Bypass root check in dry-run
check_root() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Skipping root check (would require sudo)"
        return 0
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        log_error "Usage: sudo $0 $*"
        exit 1
    fi
}

# Fix 2: Graceful package check
check_qemu_kvm_installed() {
    log_step "Checking QEMU/KVM installation..."
    local missing_packages=()

    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*${package}" 2>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY RUN] Missing packages detected: ${missing_packages[*]}"
            log_info "[DRY RUN] Would install with: sudo apt install -y ${missing_packages[*]}"
            return 0  # Continue in dry-run mode
        else
            log_error "Missing required packages: ${missing_packages[*]}"
            return 1
        fi
    fi

    log_success "All required QEMU/KVM packages installed"
}

# Fix 3: Simulated libvirtd check
check_libvirtd() {
    log_step "Checking libvirtd service..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Skipping libvirtd check"
        log_info "[DRY RUN] Would verify: systemctl is-active libvirtd"
        return 0
    fi

    if ! systemctl is-active --quiet libvirtd; then
        log_error "libvirtd service is not running"
        log_error "Start with: sudo systemctl start libvirtd"
        return 1
    fi
    log_success "libvirtd service is active"
}
```

---

### 2. start-vm.sh (590 lines)

**Current Dry-Run Implementation:**

| Feature | Status | Lines | Notes |
|---------|--------|-------|-------|
| `--dry-run` flag | ✅ Implemented | 78, 516-518 | Flag parsing works |
| VM existence check | ❌ MISSING | 196, 558 | Uses virsh without fallback |
| libvirtd check bypass | ❌ MISSING | 557 | `check_libvirtd()` from common.sh |
| Start command simulation | ✅ Good | 305-308 | Shows "[DRY RUN]" message |

**Problems in Dry-Run Mode:**

1. **Line 557: libvirtd Check Blocks Execution**
   ```bash
   check_libvirtd || exit 1
   ```
   **Impact:** Exits before showing what script would do

2. **Line 196: VM Existence Check Requires virsh**
   ```bash
   if ! virsh list --all | grep -qw "$VM_NAME"; then
   ```
   **Impact:** Fails with "virsh: command not found"

**Recommended Fixes:**

```bash
# Fix 1: Graceful VM existence check
check_vm_exists() {
    log_step "Checking if VM '$VM_NAME' exists..."

    if ! command -v virsh &>/dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY RUN] virsh not found (install libvirt-clients)"
            log_info "[DRY RUN] Would check: virsh list --all | grep '$VM_NAME'"
            return 0  # Continue in dry-run
        else
            log_error "virsh command not found"
            log_error "Install with: sudo apt install libvirt-clients"
            return 1
        fi
    fi

    if ! virsh list --all | grep -qw "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found"
        return 1
    fi

    log_success "VM '$VM_NAME' exists"
}

# Fix 2: Enhanced dry-run feedback
start_vm() {
    log_step "Starting VM '$VM_NAME'..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: virsh start $VM_NAME"
        log_info "[DRY RUN] Expected behavior:"
        log_info "  - Send power-on signal to VM"
        log_info "  - Boot from configured boot device"
        log_info "  - Wait up to ${BOOT_TIMEOUT}s for 'running' state"
        log_info "  - Monitor boot progress"
        return 0
    fi

    # ... actual start logic ...
}
```

---

### 3. stop-vm.sh (603 lines)

**Current Dry-Run Implementation:**

| Feature | Status | Lines | Notes |
|---------|--------|-------|-------|
| `--dry-run` flag | ✅ Implemented | 92, 516-518 | Flag parsing works |
| VM checks | ❌ MISSING | 249-256, 557 | Requires virsh |
| Graceful shutdown simulation | ✅ Good | 344-347 | Shows command |
| Force shutdown simulation | ✅ Good | 393-396 | Shows command |

**Problems in Dry-Run Mode:**

1. **Line 249: VM Existence Check**
   ```bash
   if ! virsh list --all | grep -qw "$VM_NAME"; then
   ```
   **Impact:** Fails without virsh installed

2. **Line 263: VM State Check**
   ```bash
   VM_STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
   ```
   **Impact:** Shows "unknown" state, confusing in dry-run

**Recommended Fixes:**

```bash
# Simulated VM state for dry-run
check_vm_state() {
    log_step "Checking VM state..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY RUN] Simulating VM state check"
        log_info "[DRY RUN] Would execute: virsh domstate '$VM_NAME'"
        log_info "[DRY RUN] Assumed state: running (for demonstration)"
        VM_STATE="running"  # Simulate running state
        log_success "VM is active and can be stopped (simulated)"
        return 0
    fi

    if ! command -v virsh &>/dev/null; then
        log_error "virsh command not found"
        return 1
    fi

    VM_STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
    # ... rest of actual logic ...
}
```

---

### 4. configure-performance.sh (1440 lines)

**Current Dry-Run Implementation:**

| Feature | Status | Lines | Notes |
|---------|--------|-------|-------|
| `--dry-run` flag | ✅ Implemented | 114, 1311-1314 | Flag parsing works |
| Root check bypass | ❌ MISSING | 1371-1373 | Enforces root even in dry-run |
| Dependency checks | ❌ MISSING | 224-251 | Requires virsh, virt-xml |
| XML manipulation preview | ✅ Good | 349-373, 459-467 | Shows what would change |

**Problems in Dry-Run Mode:**

1. **Line 1371-1373: Root Check Not Bypassed**
   ```bash
   if [[ "$DRY_RUN" == "false" ]]; then
       check_root
   fi
   ```
   **Good!** Already has bypass logic (one of few scripts that does)

2. **Line 224-251: Missing Dependency Check**
   ```bash
   check_requirements() {
       for cmd in "${required_commands[@]}"; do
           if ! command -v "$cmd" &> /dev/null; then
               missing_deps+=("$cmd")
           fi
       done

       if [[ ${#missing_deps[@]} -gt 0 ]]; then
           log_error "Missing required dependencies: ${missing_deps[*]}"
           exit 1  # EXITS EVEN IN DRY-RUN!
       fi
   }
   ```
   **Impact:** Script exits if virsh/virt-xml missing, preventing preview

**Recommended Fixes:**

```bash
# Fix: Graceful dependency check
check_requirements() {
    log_section "Checking Requirements"

    local missing_deps=()
    local required_commands=(
        "virsh"
        "virt-xml"
        "xmllint"
        "free"
        "nproc"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY RUN] Missing dependencies: ${missing_deps[*]}"
            log_info "[DRY RUN] Install with: sudo apt install libvirt-clients libvirt-daemon-system libxml2-utils"
            log_info "[DRY RUN] Proceeding in preview mode..."
            return 0  # Allow dry-run to continue
        else
            log_error "Missing required dependencies: ${missing_deps[*]}"
            log_info "Install with: sudo apt install libvirt-clients libvirt-daemon-system libxml2-utils"
            exit 1
        fi
    fi

    log_success "All required dependencies found"
}
```

---

## common.sh Library Analysis

**File:** `/home/kkk/Apps/win-qemu/scripts/lib/common.sh` (242 lines)

### Current Implementation:

| Function | Dry-Run Aware? | Issue |
|----------|----------------|-------|
| `check_root()` | ❌ NO | Always enforces sudo (line 192-196) |
| `check_libvirtd()` | ❌ NO | Always checks service status (line 199-207) |
| `check_vm_exists()` | ❌ NO | Requires virsh (line 209-216) |

### Recommended Enhancements:

```bash
# Enhanced check_root with dry-run support
check_root() {
    # Check if DRY_RUN is set (may be set by calling script)
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping root check (would require sudo)"
        log_info "[DRY RUN] Actual execution requires: sudo $0"
        return 0
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        log_error "Usage: sudo $0 $*"
        exit 1
    fi
}

# Enhanced check_libvirtd with dry-run support
check_libvirtd() {
    log_step "Checking libvirtd service..."

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping libvirtd service check"
        log_info "[DRY RUN] Would verify: systemctl is-active libvirtd"
        log_info "[DRY RUN] Start service with: sudo systemctl start libvirtd"
        return 0
    fi

    # Check if systemctl exists
    if ! command -v systemctl &>/dev/null; then
        log_error "systemctl command not found (systemd not available?)"
        return 1
    fi

    if ! systemctl is-active --quiet libvirtd; then
        log_error "libvirtd service is not running"
        log_error "Start with: sudo systemctl start libvirtd"
        return 1
    fi
    log_success "libvirtd service is active"
}

# Enhanced check_vm_exists with dry-run support
check_vm_exists() {
    local vm_name="$1"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping VM existence check for '$vm_name'"
        log_info "[DRY RUN] Would execute: virsh dominfo '$vm_name'"
        return 0  # Assume exists for preview purposes
    fi

    # Check if virsh exists
    if ! command -v virsh &>/dev/null; then
        log_error "virsh command not found"
        log_error "Install with: sudo apt install libvirt-clients"
        return 1
    fi

    if virsh dominfo "$vm_name" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
```

---

## Improvement Opportunities Summary

### Priority 1: CRITICAL (Blocks Dry-Run Entirely)

1. **common.sh: check_root() bypass**
   - **Impact:** All scripts fail with "must be run with sudo"
   - **Fix:** Add `DRY_RUN` check before exit
   - **Lines:** 192-196

2. **common.sh: check_libvirtd() bypass**
   - **Impact:** Scripts exit if libvirtd not running
   - **Fix:** Return 0 in dry-run mode
   - **Lines:** 199-207

3. **configure-performance.sh: check_requirements() graceful**
   - **Impact:** Exits if virsh/virt-xml missing
   - **Fix:** Warn but continue in dry-run
   - **Lines:** 224-251

### Priority 2: HIGH (Degrades Dry-Run Experience)

4. **create-vm.sh: check_qemu_kvm_installed() graceful**
   - **Impact:** Can't preview without QEMU installed
   - **Fix:** Show missing packages as warnings
   - **Lines:** 250-276

5. **start-vm.sh: check_vm_exists() graceful**
   - **Impact:** Can't see what script does without VM
   - **Fix:** Simulate VM existence in dry-run
   - **Lines:** 193-207

6. **stop-vm.sh: check_vm_state() simulation**
   - **Impact:** Shows "unknown" state confusingly
   - **Fix:** Simulate "running" state for demo
   - **Lines:** 260-283

### Priority 3: MEDIUM (Polish & User Experience)

7. **All scripts: Enhanced dry-run feedback**
   - **Current:** Basic "[DRY RUN]" messages
   - **Desired:** Detailed multi-line explanations
   - **Example:**
     ```
     [DRY RUN] Would execute: virsh start win11-vm
     [DRY RUN] Expected behavior:
       - Send power-on signal to VM
       - Boot from configured boot device
       - Wait up to 60s for 'running' state
       - Monitor boot progress with virsh domstate
       - Display connection information when ready
     ```

8. **create-vm.sh: Pre-flight summary in dry-run**
   - Show complete checklist of what would be validated
   - Display all mkdir/cp/virsh commands that would run
   - Lines: 407-438

---

## Recommended Dry-Run Mode Pattern

### Standard Template for All Scripts:

```bash
#!/bin/bash
set -euo pipefail

# Parse --dry-run flag FIRST (before any checks)
DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# Export for use in sourced libraries
export DRY_RUN

# Source common library (now aware of DRY_RUN)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Main logic with dry-run checks
main() {
    # Checks bypass in dry-run
    if [[ "$DRY_RUN" == "false" ]]; then
        check_root
        check_libvirtd
    else
        log_warning "[DRY RUN MODE] Skipping prerequisite checks"
        log_info "[DRY RUN MODE] Showing preview of script actions..."
    fi

    # Always show what would happen
    if [[ "$DRY_RUN" == "true" ]]; then
        show_dry_run_preview
        exit 0
    fi

    # Actual execution
    perform_actual_operations
}

show_dry_run_preview() {
    cat << EOF
========================================
DRY RUN PREVIEW
========================================

This script would perform the following:

1. Prerequisite Checks:
   - Verify running as root (sudo)
   - Check libvirtd service is active
   - Validate VM '$VM_NAME' exists

2. Main Operations:
   - Execute: virsh start $VM_NAME
   - Monitor boot progress (60s timeout)
   - Check for QEMU guest agent response

3. Post-Operation:
   - Display VM connection info
   - Log all actions to: $LOG_FILE

To execute these actions, run:
   sudo $0 $VM_NAME

========================================
EOF
}
```

---

## Implementation Roadmap

### Phase 1: Core Library (1 hour)
1. Update `common.sh` with dry-run aware functions
2. Add `DRY_RUN` export capability
3. Test with minimal script

### Phase 2: Critical Scripts (2 hours)
1. Fix `create-vm.sh` (highest user impact)
2. Fix `start-vm.sh`
3. Fix `stop-vm.sh`
4. Fix `configure-performance.sh`

### Phase 3: Enhanced Feedback (1 hour)
1. Add detailed dry-run previews
2. Show command sequences
3. Display expected outcomes

### Phase 4: Testing & Validation (1 hour)
1. Run all 8 dry-run tests
2. Verify 0% require QEMU installation
3. Document dry-run mode in help text

**Total Estimated Time:** 5 hours

---

## Success Metrics

### Before Improvements:
- ❌ 6/8 tests FAIL (75% failure rate)
- ❌ Requires QEMU installation to preview
- ❌ Requires sudo to see help

### After Improvements:
- ✅ 8/8 tests PASS (0% failure rate)
- ✅ No QEMU installation required for dry-run
- ✅ No sudo required for preview mode
- ✅ Detailed feedback shows exact operations
- ✅ Users can evaluate scripts BEFORE committing to setup

---

## User Experience Flow

### BEFORE (Current):
```
$ ./scripts/create-vm.sh --dry-run
[✗] This script must be run with sudo
Usage: sudo ./scripts/create-vm.sh --dry-run

$ sudo ./scripts/create-vm.sh --dry-run
[✗] Missing required packages: qemu-system-x86 qemu-kvm libvirt-daemon-system
Install with: sudo apt install -y qemu-system-x86 qemu-kvm ...

# User gives up, can't preview without full installation
```

### AFTER (Improved):
```
$ ./scripts/create-vm.sh --dry-run
[!] [DRY RUN MODE] Skipping prerequisite checks
[INFO] [DRY RUN MODE] Showing preview of script actions...

========================================
DRY RUN PREVIEW: VM Creation
========================================

Hardware Requirements:
  [!] Would check: CPU virtualization (vmx/svm)
  [!] Would check: RAM >= 16GB
  [!] Would check: SSD storage
  [!] Would check: CPU cores >= 8

Software Requirements:
  [!] Would check: qemu-system-x86 (MISSING - need to install)
  [!] Would check: libvirt-daemon-system (MISSING)
  [!] Would install: sudo apt install -y qemu-system-x86 ...

VM Creation Steps:
  1. Create disk image:
     qemu-img create -f qcow2 /var/lib/libvirt/images/win11-vm.qcow2 100G

  2. Generate XML from template:
     - Name: win11-vm
     - RAM: 8192MB
     - vCPUs: 4
     - UEFI firmware: /usr/share/OVMF/OVMF_CODE.fd
     - TPM 2.0: /var/lib/libvirt/swtpm/win11-vm/

  3. Define VM:
     virsh define /tmp/win11-vm.xml

  4. Set permissions:
     chown libvirt-qemu:kvm /var/lib/libvirt/images/win11-vm.qcow2

To execute these actions:
  sudo ./scripts/create-vm.sh

========================================

# User now understands EXACTLY what will happen
```

---

## Conclusion

**Key Insight:** Dry-run mode is currently **broken for preparation use case** due to hard dependencies on:
- Root access (sudo requirement)
- Installed packages (QEMU, libvirt)
- Running services (libvirtd)

**Solution:** Implement **graceful degradation pattern** where:
1. Dry-run mode bypasses ALL prerequisite checks
2. Missing commands are simulated with descriptive messages
3. Users see detailed preview of what WOULD happen
4. Zero barrier to entry for exploring script functionality

**Impact:** Transforms dry-run from "broken preview" to **"interactive documentation"** that teaches users what each script does before they commit to full QEMU/KVM setup.

---

## Next Steps

1. **Implement common.sh changes** (foundational fixes)
2. **Update create-vm.sh** (highest user-facing value)
3. **Test with comprehensive-dry-run.sh** (validation)
4. **Document dry-run mode** in script help text
5. **Add dry-run examples** to CLAUDE.md/AGENTS.md

**Estimated Implementation Time:** 5 hours
**Risk Level:** LOW (changes are additive, no breaking changes to actual execution)
**User Benefit:** HIGH (enables exploration without commitment)
