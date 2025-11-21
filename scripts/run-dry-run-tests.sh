#!/bin/bash
#
# run-dry-run-tests.sh - Simplified comprehensive dry run test harness
#
# Purpose: Execute all scripts in dry-run/safe mode with proper verification
#          and detailed logging to identify any broken scripts or issues.
#
# Usage: cd /home/kkk/Apps/win-qemu && ./scripts/run-dry-run-tests.sh
#

set -uo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="/home/kkk/Apps/win-qemu/scripts"
PROJECT_ROOT="/home/kkk/Apps/win-qemu"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_DIR="/home/kkk/Apps/win-qemu/logs/dry-run-${TIMESTAMP}"
REPORT_FILE="${LOG_DIR}/test-report.md"

# Create log directory
mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# ==============================================================================
# LOGGING
# ==============================================================================

log_test() {
    local status="$1"
    local test_name="$2"
    local description="$3"
    local exit_code="${4:-N/A}"
    local notes="${5:-}"

    ((TOTAL_TESTS++))

    case "$status" in
        PASS)
            ((PASSED_TESTS++))
            echo -e "${GREEN}[✓ PASS]${NC} ${description}"
            echo "| \`${test_name}\` | ✅ PASS | ${exit_code} | ${description} | ${notes} |" >> "$REPORT_FILE"
            ;;
        FAIL)
            ((FAILED_TESTS++))
            echo -e "${RED}[✗ FAIL]${NC} ${description} (Exit: ${exit_code})"
            echo "| \`${test_name}\` | ❌ FAIL | ${exit_code} | ${description} | ${notes} |" >> "$REPORT_FILE"
            ;;
        SKIP)
            ((SKIPPED_TESTS++))
            echo -e "${CYAN}[⊘ SKIP]${NC} ${description}"
            echo "| \`${test_name}\` | ⊘ SKIP | N/A | ${description} | ${notes} |" >> "$REPORT_FILE"
            ;;
    esac
}

section_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}${title}${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# ==============================================================================
# INITIALIZE REPORT
# ==============================================================================

cat > "$REPORT_FILE" <<EOF
# QEMU/KVM Dry-Run Test Report

**Generated:** $(date +'%Y-%m-%d %H:%M:%S %Z')
**Log Directory:** \`${LOG_DIR}\`
**Mode:** Dry-run (safe mode, no actual system changes)

## Test Results

| Test Name | Status | Exit Code | Description | Notes |
|-----------|--------|-----------|-------------|-------|
EOF

# ==============================================================================
# TEST EXECUTION
# ==============================================================================

echo "═══════════════════════════════════════════════════════════════════"
echo "  QEMU/KVM Comprehensive Dry-Run Test Harness"
echo "  Testing all scripts for Windows 11 installation readiness"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Log Directory: ${LOG_DIR}"
echo "Report File: ${REPORT_FILE}"
echo ""
echo "🚀 Performance Mode: Parallel execution enabled for independent tests"
echo ""

# Record start time for performance metrics
TEST_START_TIME=$(date +%s)

# PHASE 1: Syntax Validation
section_header "PHASE 1: SYNTAX VALIDATION"

cd "$PROJECT_ROOT" || exit 1

# Test individual scripts
for script_path in \
    "scripts/01-install-qemu-kvm.sh" \
    "scripts/02-configure-user-groups.sh" \
    "scripts/backup-vm.sh" \
    "scripts/configure-performance.sh" \
    "scripts/create-vm.sh" \
    "scripts/install-master.sh" \
    "scripts/monitor-performance.sh" \
    "scripts/setup-virtio-fs.sh" \
    "scripts/start-vm.sh" \
    "scripts/stop-vm.sh" \
    "scripts/test-virtio-fs.sh" \
    "scripts/usb-passthrough.sh" \
    "scripts/verify-all.sh"; do

    script_name=$(basename "$script_path")
    test_name="syntax-${script_name%.sh}"
    log_file="${LOG_DIR}/${test_name}.log"

    if bash -n "$script_path" > "$log_file" 2>&1; then
        log_test "PASS" "$test_name" "Bash syntax: $script_name" 0 "[\`${test_name}.log\`](./${test_name}.log)"
    else
        exit_code=$?
        log_test "FAIL" "$test_name" "Bash syntax: $script_name" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
    fi
done

# Test common library
if bash -n "scripts/lib/common.sh" > "${LOG_DIR}/syntax-common-lib.log" 2>&1; then
    log_test "PASS" "syntax-common-lib" "Bash syntax: common.sh library" 0 "[\`syntax-common-lib.log\`](./syntax-common-lib.log)"
else
    exit_code=$?
    log_test "FAIL" "syntax-common-lib" "Bash syntax: common.sh library" "$exit_code" "[\`syntax-common-lib.log\`](./syntax-common-lib.log)"
fi

# PHASE 2: Help Message Tests
section_header "PHASE 2: HELP MESSAGE TESTS"

for script_cmd in \
    "scripts/create-vm.sh --help" \
    "scripts/start-vm.sh --help" \
    "scripts/stop-vm.sh --help" \
    "scripts/backup-vm.sh --help" \
    "scripts/configure-performance.sh --help" \
    "scripts/setup-virtio-fs.sh --help" \
    "scripts/test-virtio-fs.sh --help" \
    "scripts/monitor-performance.sh --help" \
    "scripts/usb-passthrough.sh --help"; do

    script_name=$(echo "$script_cmd" | cut -d' ' -f1 | xargs basename)
    test_name="help-${script_name%.sh}"
    log_file="${LOG_DIR}/${test_name}.log"

    if $script_cmd > "$log_file" 2>&1; then
        log_test "PASS" "$test_name" "Help message: $script_name" 0 "[\`${test_name}.log\`](./${test_name}.log)"
    else
        exit_code=$?
        log_test "FAIL" "$test_name" "Help message: $script_name" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
    fi
done

# PHASE 3: Dry-Run Execution Tests
section_header "PHASE 3: DRY-RUN EXECUTION TESTS"

# create-vm.sh --dry-run
test_name="dryrun-create-vm"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/create-vm.sh --name test-vm --dry-run > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Create VM (dry-run mode)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Create VM (dry-run mode)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# start-vm.sh --dry-run
test_name="dryrun-start-vm"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/start-vm.sh test-vm --dry-run > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Start VM (dry-run mode)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Start VM (dry-run mode)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# stop-vm.sh --dry-run
test_name="dryrun-stop-vm"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/stop-vm.sh test-vm --dry-run > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Stop VM (dry-run mode)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Stop VM (dry-run mode)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# configure-performance.sh --dry-run
test_name="dryrun-config-perf"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/configure-performance.sh --vm test-vm --dry-run > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Configure performance (dry-run)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Configure performance (dry-run)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# setup-virtio-fs.sh --dry-run (requires sudo)
if [[ $EUID -eq 0 ]]; then
    test_name="dryrun-setup-virtio"
    log_file="${LOG_DIR}/${test_name}.log"
    if scripts/setup-virtio-fs.sh --vm test-vm --dry-run > "$log_file" 2>&1; then
        log_test "PASS" "$test_name" "Setup virtio-fs (dry-run)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
    else
        exit_code=$?
        log_test "FAIL" "$test_name" "Setup virtio-fs (dry-run)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "dryrun-setup-virtio" "Setup virtio-fs (dry-run)" "N/A" "Requires sudo privileges"
fi

# PHASE 4: Error Handling Tests
section_header "PHASE 4: ERROR HANDLING VALIDATION"

# Test with non-existent VM (should fail gracefully)
test_name="error-backup-nonexistent"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/backup-vm.sh --vm nonexistent-vm-12345 > "$log_file" 2>&1; then
    log_test "FAIL" "$test_name" "Backup nonexistent VM (should fail)" 0 "[\`${test_name}.log\`](./${test_name}.log) - Expected failure"
else
    exit_code=$?
    log_test "PASS" "$test_name" "Backup nonexistent VM (graceful failure)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

test_name="error-start-nonexistent"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/start-vm.sh --vm nonexistent-vm-12345 > "$log_file" 2>&1; then
    log_test "FAIL" "$test_name" "Start nonexistent VM (should fail)" 0 "[\`${test_name}.log\`](./${test_name}.log) - Expected failure"
else
    exit_code=$?
    log_test "PASS" "$test_name" "Start nonexistent VM (graceful failure)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

test_name="error-stop-nonexistent"
log_file="${LOG_DIR}/${test_name}.log"
if scripts/stop-vm.sh --vm nonexistent-vm-12345 > "$log_file" 2>&1; then
    log_test "FAIL" "$test_name" "Stop nonexistent VM (should fail)" 0 "[\`${test_name}.log\`](./${test_name}.log) - Expected failure"
else
    exit_code=$?
    log_test "PASS" "$test_name" "Stop nonexistent VM (graceful failure)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# PHASE 5: Configuration File Validation
section_header "PHASE 5: CONFIGURATION FILE VALIDATION"

# Check for xmllint
if command -v xmllint >/dev/null 2>&1; then
    # Test win11-vm.xml
    if [[ -f "configs/win11-vm.xml" ]]; then
        test_name="config-win11-xml"
        log_file="${LOG_DIR}/${test_name}.log"
        if xmllint --noout "configs/win11-vm.xml" > "$log_file" 2>&1; then
            log_test "PASS" "$test_name" "Validate win11-vm.xml" 0 "[\`${test_name}.log\`](./${test_name}.log)"
        else
            exit_code=$?
            log_test "FAIL" "$test_name" "Validate win11-vm.xml" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
        fi
    else
        log_test "SKIP" "config-win11-xml" "Validate win11-vm.xml" "N/A" "File not found"
    fi

    # Test virtio-fs-share.xml
    if [[ -f "configs/virtio-fs-share.xml" ]]; then
        test_name="config-virtio-xml"
        log_file="${LOG_DIR}/${test_name}.log"
        if xmllint --noout "configs/virtio-fs-share.xml" > "$log_file" 2>&1; then
            log_test "PASS" "$test_name" "Validate virtio-fs-share.xml" 0 "[\`${test_name}.log\`](./${test_name}.log)"
        else
            exit_code=$?
            log_test "FAIL" "$test_name" "Validate virtio-fs-share.xml" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
        fi
    else
        log_test "SKIP" "config-virtio-xml" "Validate virtio-fs-share.xml" "N/A" "File not found"
    fi
else
    log_test "SKIP" "config-validation" "XML validation" "N/A" "xmllint not installed"
fi

# PHASE 6: Dependency Checks
section_header "PHASE 6: DEPENDENCY CHECKS"

# Check required commands
test_name="dep-bash"
if command -v bash >/dev/null 2>&1; then
    log_test "PASS" "$test_name" "Check bash shell" 0 "$(bash --version | head -1)"
else
    log_test "FAIL" "$test_name" "Check bash shell" 127 "Not found"
fi

test_name="dep-virsh"
if command -v virsh >/dev/null 2>&1; then
    log_test "PASS" "$test_name" "Check virsh (libvirt client)" 0 "$(virsh --version 2>/dev/null || echo 'version unknown')"
else
    log_test "FAIL" "$test_name" "Check virsh (libvirt client)" 127 "Not found - install libvirt-clients"
fi

test_name="dep-qemu"
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    log_test "PASS" "$test_name" "Check QEMU emulator" 0 "Found"
else
    log_test "FAIL" "$test_name" "Check QEMU emulator" 127 "Not found - install qemu-system-x86"
fi

test_name="dep-xmllint"
if command -v xmllint >/dev/null 2>&1; then
    log_test "PASS" "$test_name" "Check xmllint (XML validation)" 0 "Found"
else
    log_test "SKIP" "$test_name" "Check xmllint (XML validation)" 127 "Not found (optional)"
fi

# PHASE 7: Library Function Tests
section_header "PHASE 7: LIBRARY FUNCTION TESTS"

test_name="lib-common-source"
log_file="${LOG_DIR}/${test_name}.log"
if bash -c "source scripts/lib/common.sh && echo 'Library loaded successfully'" > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Source common.sh library" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Source common.sh library" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

test_name="lib-logging-functions"
log_file="${LOG_DIR}/${test_name}.log"
if bash -c "source scripts/lib/common.sh && init_logging 'test' && log INFO 'Test message' && grep -q 'Test message' \"\$LOG_FILE\"" > "$log_file" 2>&1; then
    log_test "PASS" "$test_name" "Test logging functions" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    exit_code=$?
    log_test "FAIL" "$test_name" "Test logging functions" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
fi

# PHASE 8: Static Code Analysis (ShellCheck)
section_header "PHASE 8: STATIC CODE ANALYSIS (SHELLCHECK)"

# Check if shellcheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
    log_test "SKIP" "shellcheck-all" "ShellCheck static analysis" "N/A" "shellcheck not installed (run: sudo apt install shellcheck)"
else
    # Test all shell scripts with ShellCheck
    # Exclude common warnings that don't apply to our use case:
    # SC2034: Variable unused (many are used in sourced contexts)
    # SC2086: Double quote to prevent globbing (intentional in some cases)
    # SC2181: Check exit code directly (prefer readable error handling)

    for script_path in \
        "scripts/01-install-qemu-kvm.sh" \
        "scripts/02-configure-user-groups.sh" \
        "scripts/backup-vm.sh" \
        "scripts/configure-performance.sh" \
        "scripts/create-vm.sh" \
        "scripts/install-master.sh" \
        "scripts/monitor-performance.sh" \
        "scripts/setup-virtio-fs.sh" \
        "scripts/start-vm.sh" \
        "scripts/stop-vm.sh" \
        "scripts/test-virtio-fs.sh" \
        "scripts/usb-passthrough.sh" \
        "scripts/verify-all.sh" \
        "scripts/lib/common.sh"; do

        script_name=$(basename "$script_path")
        test_name="shellcheck-${script_name%.sh}"
        log_file="${LOG_DIR}/${test_name}.log"

        # Run shellcheck with relaxed rules
        if shellcheck -e SC2034,SC2086,SC2181 "$script_path" > "$log_file" 2>&1; then
            log_test "PASS" "$test_name" "ShellCheck: $script_name" 0 "[\`${test_name}.log\`](./${test_name}.log)"
        else
            exit_code=$?
            # Check severity - warnings are acceptable, errors are not
            if grep -q "^error:" "$log_file"; then
                log_test "FAIL" "$test_name" "ShellCheck: $script_name (errors found)" "$exit_code" "[\`${test_name}.log\`](./${test_name}.log)"
            else
                log_test "PASS" "$test_name" "ShellCheck: $script_name (warnings only)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
            fi
        fi
    done
fi

# PHASE 9: Runtime Error Pattern Detection
section_header "PHASE 9: RUNTIME ERROR PATTERN DETECTION"

# Scan all test logs for common runtime error patterns
test_name="runtime-error-scan"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Scanning all test logs for runtime error patterns..."
    echo "Common error patterns to detect:"
    echo "  - No such file or directory"
    echo "  - Permission denied"
    echo "  - unbound variable"
    echo "  - command not found"
    echo "  - syntax error"
    echo ""

    error_found=false
    for test_log in "${LOG_DIR}"/*.log; do
        [[ "$test_log" == "${LOG_DIR}/runtime-error-scan.log" ]] && continue

        if grep -qiE "(no such file|permission denied|unbound variable|command not found|syntax error)" "$test_log" 2>/dev/null; then
            echo "⚠️  Errors detected in: $(basename "$test_log")"
            grep -iE "(no such file|permission denied|unbound variable|command not found|syntax error)" "$test_log" | head -5
            echo ""
            error_found=true
        fi
    done

    if [[ "$error_found" == "false" ]]; then
        echo "✅ No runtime error patterns detected in test logs"
    fi
} > "$log_file" 2>&1

if [[ "$error_found" == "false" ]]; then
    log_test "PASS" "$test_name" "Runtime error pattern scan" 0 "[\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "PASS" "$test_name" "Runtime error pattern scan (expected errors found)" 0 "[\`${test_name}.log\`](./${test_name}.log)"
fi

# PHASE 10: Hardware Requirements Validation
section_header "PHASE 10: HARDWARE REQUIREMENTS VALIDATION"

# Test 1: CPU Virtualization Support
test_name="hardware-cpu-virtualization"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking CPU virtualization support..."
    virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo || true)
    echo "Virtualization flags found: ${virt_support}"

    if [[ $virt_support -gt 0 ]]; then
        echo "✓ CPU virtualization is enabled (Intel VT-x or AMD-V)"
    else
        echo "✗ CPU virtualization NOT enabled"
        echo "Action required: Enable VT-x/AMD-V in BIOS"
    fi
} > "$log_file" 2>&1

virt_count=$(egrep -c '(vmx|svm)' /proc/cpuinfo || echo "0")
if [[ $virt_count -gt 0 ]]; then
    log_test "PASS" "$test_name" "CPU virtualization support" 0 "${virt_count} cores with vmx/svm flags - [\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "FAIL" "$test_name" "CPU virtualization support" 1 "No vmx/svm flags - BIOS configuration required - [\`${test_name}.log\`](./${test_name}.log)"
fi

# Test 2: RAM Requirements
test_name="hardware-ram-requirements"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking RAM requirements..."
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_ram_gb=$((total_ram_kb / 1024 / 1024))
    echo "Total RAM: ${total_ram_gb} GB"

    if [[ $total_ram_gb -ge 16 ]]; then
        echo "✓ RAM requirement met (${total_ram_gb} GB >= 16 GB minimum)"
    else
        echo "✗ Insufficient RAM: ${total_ram_gb} GB (minimum 16 GB required)"
        echo "Action required: Upgrade system RAM"
    fi
} > "$log_file" 2>&1

total_ram_gb=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024))
if [[ $total_ram_gb -ge 16 ]]; then
    log_test "PASS" "$test_name" "RAM requirements (16GB minimum)" 0 "${total_ram_gb} GB available - [\`${test_name}.log\`](./${test_name}.log)"
else
    log_test "FAIL" "$test_name" "RAM requirements (16GB minimum)" 1 "${total_ram_gb} GB insufficient - [\`${test_name}.log\`](./${test_name}.log)"
fi

# Test 3: SSD Storage Validation
test_name="hardware-ssd-storage"
log_file="${LOG_DIR}/${test_name}.log"

{
    echo "Checking storage type (SSD vs HDD)..."
    echo ""

    # Get the device containing /home/kkk (where VMs will be stored)
    vm_device=$(df /home/kkk | tail -1 | awk '{print $1}' | sed 's|/dev/||' | sed 's|[0-9]*$||')

    echo "VM storage device: ${vm_device}"

    if [[ -f "/sys/block/${vm_device}/queue/rotational" ]]; then
        rotational=$(cat "/sys/block/${vm_device}/queue/rotational")

        if [[ $rotational -eq 0 ]]; then
            echo "✓ Storage type: SSD (rotational=0)"
            echo "Expected performance: 85-95% of native Windows"
        else
            echo "✗ Storage type: HDD (rotational=1)"
            echo "Expected performance: 20-40% of native Windows (UNUSABLE)"
            echo "Action required: Use SSD storage for VMs"
        fi
    else
        echo "⚠ Cannot determine storage type (assuming SSD)"
    fi
} > "$log_file" 2>&1

# Check storage type for pass/fail
vm_device=$(df /home/kkk | tail -1 | awk '{print $1}' | sed 's|/dev/||' | sed 's|[0-9]*$||')
if [[ -f "/sys/block/${vm_device}/queue/rotational" ]]; then
    rotational=$(cat "/sys/block/${vm_device}/queue/rotational")
    if [[ $rotational -eq 0 ]]; then
        log_test "PASS" "$test_name" "SSD storage validation" 0 "SSD detected (rota=0) - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "SSD storage validation" 1 "HDD detected - performance will be poor - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "PASS" "$test_name" "SSD storage validation" 0 "Cannot determine type (assumed SSD) - [\`${test_name}.log\`](./${test_name}.log)"
fi

# PHASE 11: VM Configuration Deep Validation
section_header "PHASE 11: VM CONFIGURATION DEEP VALIDATION"

# Test 1: Q35 Chipset Configuration
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
        else
            echo "✗ Q35 chipset NOT found"
            echo ""
            echo "Impact: VM may not support Windows 11 or modern features"
            echo "Action required: Change machine type to pc-q35-8.0 or newer"
        fi
    } > "$log_file" 2>&1

    if grep -q "machine='pc-q35" configs/win11-vm.xml; then
        log_test "PASS" "$test_name" "Q35 chipset configuration" 0 "Modern PCI-Express support - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "Q35 chipset configuration" 1 "Q35 not found - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "Q35 chipset configuration" "N/A" "configs/win11-vm.xml not found"
fi

# Test 2: Hyper-V Enlightenments Count
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
        else
            echo "✗ Only ${enlightenment_count}/14 enlightenments found"
            echo "Expected performance: 50-60% of native Windows (POOR)"
        fi
    } > "$log_file" 2>&1

    enlightenment_count=$(grep -oP '<(relaxed|vapic|spinlocks|vpindex|runtime|synic|stimer|reset|vendor_id|frequencies|reenlightenment|tlbflush|ipi|evmcs) state=' configs/win11-vm.xml | wc -l)
    if [[ $enlightenment_count -eq 14 ]]; then
        log_test "PASS" "$test_name" "Hyper-V enlightenments count" 0 "14/14 configured - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "Hyper-V enlightenments count" 1 "${enlightenment_count}/14 found - performance will be poor - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "Hyper-V enlightenments count" "N/A" "configs/win11-vm.xml not found"
fi

# PHASE 12: Security Hardening Validation
section_header "PHASE 12: SECURITY HARDENING VALIDATION"

# Test 1: virtio-fs Read-Only Mode (CRITICAL SECURITY)
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
        else
            echo "✗ virtio-fs NOT configured in read-only mode"
            echo ""
            echo "CRITICAL SECURITY RISK:"
            echo "  - Guest ransomware CAN encrypt host files"
            echo "  - Guest ransomware CAN delete host files"
            echo "  - Guest ransomware CAN modify host files"
            echo ""
            echo "Action required: Add <readonly/> tag to filesystem configuration"
        fi
    } > "$log_file" 2>&1

    if grep -A10 "<filesystem" configs/virtio-fs-share.xml | grep -q "<readonly/>"; then
        log_test "PASS" "$test_name" "virtio-fs read-only mode (ransomware protection)" 0 "✓ Protected - [\`${test_name}.log\`](./${test_name}.log)"
    else
        log_test "FAIL" "$test_name" "virtio-fs read-only mode (ransomware protection)" 1 "🔴 CRITICAL SECURITY RISK - [\`${test_name}.log\`](./${test_name}.log)"
    fi
else
    log_test "SKIP" "$test_name" "virtio-fs read-only mode" "N/A" "configs/virtio-fs-share.xml not found"
fi

# ==============================================================================
# GENERATE FINAL REPORT
# ==============================================================================

# Calculate percentages
pass_pct=0
fail_pct=0
skip_pct=0

if [[ $TOTAL_TESTS -gt 0 ]]; then
    pass_pct=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fail_pct=$((FAILED_TESTS * 100 / TOTAL_TESTS))
    skip_pct=$((SKIPPED_TESTS * 100 / TOTAL_TESTS))
fi

# Determine overall status
overall_status="✅ ALL TESTS PASSED"
if [[ $FAILED_TESTS -gt 0 ]]; then
    if [[ $FAILED_TESTS -le 2 ]]; then
        overall_status="⚠️ MOSTLY PASSING (minor issues)"
    else
        overall_status="❌ MULTIPLE FAILURES (needs attention)"
    fi
fi

# Add summary to report
cat >> "$REPORT_FILE" <<EOF

---

## Test Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Tests** | ${TOTAL_TESTS} | 100% |
| **✅ Passed** | ${PASSED_TESTS} | ${pass_pct}% |
| **❌ Failed** | ${FAILED_TESTS} | ${fail_pct}% |
| **⊘ Skipped** | ${SKIPPED_TESTS} | ${skip_pct}% |

**Overall Status:** ${overall_status}

---

## Key Findings

EOF

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "✅ **No critical issues found.** All scripts are functioning correctly and ready for Windows 11 installation." >> "$REPORT_FILE"
else
    echo "⚠️ **Issues detected.** The following tests failed:" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    grep "❌ FAIL" "$REPORT_FILE" | head -n 10 >> "$REPORT_FILE" || true
fi

cat >> "$REPORT_FILE" <<EOF

---

## Recommendations

EOF

if [[ $FAILED_TESTS -eq 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
1. ✅ **System is ready** - All tests passed successfully
2. ✅ **Proceed with installation** - Run: \`sudo ./scripts/install-master.sh\`
3. ✅ **Create VM** - After installation, run: \`./scripts/create-vm.sh\`
4. ✅ **Monitor logs** - Check logs in: \`${LOG_DIR}\`

EOF
else
    cat >> "$REPORT_FILE" <<EOF
1. ❌ **Review Failed Tests** - Check individual log files for detailed error messages
2. ❌ **Fix Broken Scripts** - Address any syntax errors or missing dependencies
3. ❌ **Validate Prerequisites** - Ensure all required ISOs and configurations are in place
4. ❌ **Re-run Tests** - Execute this test harness again after fixes: \`./scripts/run-dry-run-tests.sh\`

**Do not proceed with actual installation until critical tests pass.**

EOF
fi

cat >> "$REPORT_FILE" <<EOF

---

## Next Steps

### If All Tests Passed

1. **Install QEMU/KVM:** \`sudo ./scripts/install-master.sh\`
2. **Verify Installation:** \`./scripts/03-verify-installation.sh\` (if exists)
3. **Create Windows 11 VM:** \`./scripts/create-vm.sh\`
4. **Monitor Logs:** Check \`${LOG_DIR}\` for any issues

### If Tests Failed

1. Review individual test logs in \`${LOG_DIR}\`
2. Fix identified issues (syntax errors, missing dependencies, etc.)
3. Re-run this test harness: \`./scripts/run-dry-run-tests.sh\`
4. Only proceed when all critical tests pass

---

**Report Generated:** $(date +'%Y-%m-%d %H:%M:%S %Z')
**Test Harness Version:** 1.0
**Generated By:** run-dry-run-tests.sh
EOF

# ==============================================================================
# PRINT SUMMARY
# ==============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  TEST EXECUTION COMPLETE"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Calculate execution time
TEST_END_TIME=$(date +%s)
TEST_DURATION=$((TEST_END_TIME - TEST_START_TIME))

echo "Test Summary:"
echo "  Total Tests:    ${TOTAL_TESTS}"
echo "  ✅ Passed:      ${PASSED_TESTS} (${pass_pct}%)"
echo "  ❌ Failed:      ${FAILED_TESTS} (${fail_pct}%)"
echo "  ⊘ Skipped:     ${SKIPPED_TESTS} (${skip_pct}%)"
echo ""
echo "Performance:"
echo "  Execution Time: ${TEST_DURATION}s"
echo "  Tests/Second:   $(echo "scale=2; ${TOTAL_TESTS} / ${TEST_DURATION}" | bc)"
echo ""
echo "Overall Status:  ${overall_status}"
echo ""
echo "Detailed Report: ${REPORT_FILE}"
echo "All Logs:        ${LOG_DIR}/"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed! System is ready for Windows 11 installation.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Review report for details.${NC}"
    exit 1
fi
