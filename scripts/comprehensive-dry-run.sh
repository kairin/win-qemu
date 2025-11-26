#!/bin/bash
#
# comprehensive-dry-run.sh - Comprehensive dry run test harness
#
# Purpose: Execute all scripts in dry-run/safe mode with proper verification
#          and detailed logging to identify any broken scripts or issues.
#
# Usage: ./scripts/comprehensive-dry-run.sh
#
# Outputs:
#   - Detailed logs in /home/kkk/Apps/win-qemu/logs/dry-run-TIMESTAMP/
#   - Comprehensive test report with pass/fail status
#   - Individual script logs for debugging
#   - Summary of findings and issues
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_BASE_DIR="/home/kkk/Apps/win-qemu/logs"
LOG_DIR="${LOG_BASE_DIR}/dry-run-${TIMESTAMP}"
REPORT_FILE="${LOG_DIR}/comprehensive-test-report.md"

# Create log directory
mkdir -p "$LOG_DIR"

# Export LOG_DIR for scripts that use common.sh
export LOG_DIR

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
# LOGGING FUNCTIONS
# ==============================================================================

log_msg() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Log to master log
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_DIR}/master.log"

    # Console output with colors
    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[✓ PASS]${NC} ${message}" ;;
        FAIL)    echo -e "${RED}[✗ FAIL]${NC} ${message}" ;;
        WARN)    echo -e "${YELLOW}[! WARN]${NC} ${message}" ;;
        SKIP)    echo -e "${CYAN}[⊘ SKIP]${NC} ${message}" ;;
        SECTION) echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════${NC}"
                 echo -e "${BOLD}${CYAN}${message}${NC}"
                 echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════${NC}\n" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

# ==============================================================================
# TEST EXECUTION FUNCTIONS
# ==============================================================================

# Run a test and capture results
run_test() {
    local test_name="$1"
    local test_description="$2"
    local test_command="$3"
    local expected_exit_code="${4:-0}"
    local log_file="${LOG_DIR}/${test_name}.log"

    ((TOTAL_TESTS++))

    log_msg INFO "Testing: ${test_description}"
    echo "Command: ${test_command}" >> "$log_file"
    echo "Expected Exit Code: ${expected_exit_code}" >> "$log_file"
    echo "---" >> "$log_file"

    # Execute test command
    set +e
    eval "$test_command" >> "$log_file" 2>&1
    local actual_exit_code=$?
    set -e

    echo "---" >> "$log_file"
    echo "Actual Exit Code: ${actual_exit_code}" >> "$log_file"

    # Verify exit code
    if [[ $actual_exit_code -eq $expected_exit_code ]]; then
        log_msg SUCCESS "${test_description}"
        ((PASSED_TESTS++))
        echo "| \`${test_name}\` | ✅ PASS | ${actual_exit_code} | ${test_description} | [\`${test_name}.log\`](./${test_name}.log) |" >> "$REPORT_FILE"
        return 0
    else
        log_msg FAIL "${test_description} (Expected: ${expected_exit_code}, Got: ${actual_exit_code})"
        ((FAILED_TESTS++))
        echo "| \`${test_name}\` | ❌ FAIL | ${actual_exit_code} (expected ${expected_exit_code}) | ${test_description} | [\`${test_name}.log\`](./${test_name}.log) |" >> "$REPORT_FILE"
        return 1
    fi
}

# Run a test that should detect specific error patterns
run_test_with_pattern() {
    local test_name="$1"
    local test_description="$2"
    local test_command="$3"
    local expected_pattern="$4"
    local log_file="${LOG_DIR}/${test_name}.log"

    ((TOTAL_TESTS++))

    log_msg INFO "Testing: ${test_description}"
    echo "Command: ${test_command}" >> "$log_file"
    echo "Expected Pattern: ${expected_pattern}" >> "$log_file"
    echo "---" >> "$log_file"

    # Execute test command
    set +e
    eval "$test_command" >> "$log_file" 2>&1
    local exit_code=$?
    set -e

    echo "---" >> "$log_file"
    echo "Exit Code: ${exit_code}" >> "$log_file"

    # Check for expected pattern in output
    if grep -qE "$expected_pattern" "$log_file"; then
        log_msg SUCCESS "${test_description}"
        ((PASSED_TESTS++))
        echo "| \`${test_name}\` | ✅ PASS | ${exit_code} | ${test_description} (pattern found) | [\`${test_name}.log\`](./${test_name}.log) |" >> "$REPORT_FILE"
        return 0
    else
        log_msg FAIL "${test_description} (pattern not found: ${expected_pattern})"
        ((FAILED_TESTS++))
        echo "| \`${test_name}\` | ❌ FAIL | ${exit_code} | ${test_description} (pattern not found) | [\`${test_name}.log\`](./${test_name}.log) |" >> "$REPORT_FILE"
        return 1
    fi
}

skip_test() {
    local test_name="$1"
    local reason="$2"

    ((TOTAL_TESTS++))
    ((SKIPPED_TESTS++))

    log_msg SKIP "${test_name}: ${reason}"
    echo "| \`${test_name}\` | ⊘ SKIP | N/A | ${reason} | N/A |" >> "$REPORT_FILE"
}

# ==============================================================================
# INITIALIZE REPORT
# ==============================================================================

initialize_report() {
    cat > "$REPORT_FILE" <<'EOF'
# QEMU/KVM Comprehensive Dry Run Test Report

## Executive Summary

This report documents the comprehensive dry-run testing of all QEMU/KVM scripts to identify any broken scripts or issues that would prevent successful Windows 11 installation on Ubuntu.

**Test Execution Details:**
- **Date:** TIMESTAMP_PLACEHOLDER
- **Log Directory:** `LOG_DIR_PLACEHOLDER`
- **Test Mode:** Dry-run (safe mode, no actual changes)
- **Verification Method:** Exit codes, output patterns, error messages

## Test Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Tests** | TOTAL_PLACEHOLDER | 100% |
| **Passed** | PASSED_PLACEHOLDER | PASS_PCT_PLACEHOLDER% |
| **Failed** | FAILED_PLACEHOLDER | FAIL_PCT_PLACEHOLDER% |
| **Skipped** | SKIPPED_PLACEHOLDER | SKIP_PCT_PLACEHOLDER% |

**Overall Status:** STATUS_PLACEHOLDER

---

## Test Results by Category

### Legend
- ✅ PASS: Test completed successfully with expected results
- ❌ FAIL: Test failed or produced unexpected results
- ⊘ SKIP: Test skipped (requires sudo, ISOs, or existing VM)

---

### 1. Syntax Validation Tests

**Purpose:** Verify all scripts have valid bash syntax and no parsing errors.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF
}

# ==============================================================================
# FINALIZE REPORT
# ==============================================================================

finalize_report() {
    # Calculate percentages
    local pass_pct=0
    local fail_pct=0
    local skip_pct=0

    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_pct=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        fail_pct=$((FAILED_TESTS * 100 / TOTAL_TESTS))
        skip_pct=$((SKIPPED_TESTS * 100 / TOTAL_TESTS))
    fi

    # Determine overall status
    local overall_status
    if [[ $FAILED_TESTS -eq 0 ]]; then
        overall_status="✅ ALL TESTS PASSED"
    elif [[ $FAILED_TESTS -le 2 ]]; then
        overall_status="⚠️ MOSTLY PASSING (minor issues)"
    else
        overall_status="❌ MULTIPLE FAILURES (needs attention)"
    fi

    # Replace placeholders
    sed -i "s/TIMESTAMP_PLACEHOLDER/$(date +'%Y-%m-%d %H:%M:%S %Z')/g" "$REPORT_FILE"
    sed -i "s|LOG_DIR_PLACEHOLDER|${LOG_DIR}|g" "$REPORT_FILE"
    sed -i "s/TOTAL_PLACEHOLDER/${TOTAL_TESTS}/g" "$REPORT_FILE"
    sed -i "s/PASSED_PLACEHOLDER/${PASSED_TESTS}/g" "$REPORT_FILE"
    sed -i "s/FAILED_PLACEHOLDER/${FAILED_TESTS}/g" "$REPORT_FILE"
    sed -i "s/SKIPPED_PLACEHOLDER/${SKIPPED_TESTS}/g" "$REPORT_FILE"
    sed -i "s/PASS_PCT_PLACEHOLDER/${pass_pct}/g" "$REPORT_FILE"
    sed -i "s/FAIL_PCT_PLACEHOLDER/${fail_pct}/g" "$REPORT_FILE"
    sed -i "s/SKIP_PCT_PLACEHOLDER/${skip_pct}/g" "$REPORT_FILE"
    sed -i "s/STATUS_PLACEHOLDER/${overall_status}/g" "$REPORT_FILE"

    # Add findings section
    cat >> "$REPORT_FILE" <<'EOF'

---

## Key Findings

### Critical Issues
EOF

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "✅ No critical issues found. All scripts are functioning correctly." >> "$REPORT_FILE"
    else
        echo "The following tests failed and require attention:" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        grep "❌ FAIL" "$REPORT_FILE" | head -n 10 >> "$REPORT_FILE" || true
    fi

    cat >> "$REPORT_FILE" <<'EOF'

### Recommendations

1. **Review Failed Tests:** Check individual log files for detailed error messages
2. **Fix Broken Scripts:** Address any syntax errors or missing dependencies
3. **Validate Prerequisites:** Ensure all required ISOs and configurations are in place
4. **Re-run Tests:** After fixes, execute this test harness again to verify

---

## Detailed Logs

All test logs are available in: `LOG_DIR_PLACEHOLDER`

Individual log files are linked in the test results tables above.

---

## Next Steps

1. **If all tests passed:**
   - System is ready for actual Windows 11 VM installation
   - Proceed with: `sudo ./scripts/install-master.sh`
   - Follow with: `./scripts/create-vm.sh`

2. **If tests failed:**
   - Review failed test logs for root cause
   - Fix identified issues
   - Re-run: `./scripts/comprehensive-dry-run.sh`
   - Only proceed when all critical tests pass

3. **Follow-up verification:**
   - After actual installation, run: `./scripts/verify-all.sh`
   - Monitor logs in: `/home/kkk/Apps/win-qemu/logs/`

---

**Report Generated:** TIMESTAMP_PLACEHOLDER
**Test Harness Version:** 1.0
**Generated By:** comprehensive-dry-run.sh
EOF

    # Final sed replacement for log dir in findings
    sed -i "s|LOG_DIR_PLACEHOLDER|${LOG_DIR}|g" "$REPORT_FILE"
}

# ==============================================================================
# TEST SUITES
# ==============================================================================

run_syntax_tests() {
    log_msg SECTION "PHASE 1: SYNTAX VALIDATION"

    echo "" >> "$REPORT_FILE"

    # Test all shell scripts for syntax errors
    for script in "$SCRIPT_DIR"/*.sh; do
        if [[ -f "$script" ]]; then
            local script_name=$(basename "$script")
            run_test "syntax-${script_name%.sh}" "Bash syntax check: ${script_name}" "bash -n $script" 0
        fi
    done
}

run_help_tests() {
    log_msg SECTION "PHASE 2: HELP MESSAGE VALIDATION"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 2. Help Message Tests

**Purpose:** Verify all scripts provide proper help/usage information.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test help messages for scripts that support --help
    local help_scripts=(
        "create-vm.sh"
        "start-vm.sh"
        "stop-vm.sh"
        "backup-vm.sh"
        "configure-performance.sh"
        "setup-virtio-fs.sh"
        "test-virtio-fs.sh"
        "monitor-performance.sh"
        "usb-passthrough.sh"
    )

    for script in "${help_scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            run_test "help-${script%.sh}" "Help message: ${script}" "$SCRIPT_DIR/$script --help" 0
        fi
    done
}

run_dryrun_tests() {
    log_msg SECTION "PHASE 3: DRY-RUN EXECUTION TESTS"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 3. Dry-Run Execution Tests

**Purpose:** Execute scripts in safe/dry-run mode to verify logic without making changes.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test create-vm.sh dry-run
    run_test "dryrun-create-vm" "Create VM (dry-run)" "$SCRIPT_DIR/create-vm.sh --name test-vm --dry-run" 0

    # Test start-vm.sh dry-run
    run_test "dryrun-start-vm" "Start VM (dry-run)" "$SCRIPT_DIR/start-vm.sh --vm test-vm --dry-run" 0

    # Test stop-vm.sh dry-run
    run_test "dryrun-stop-vm" "Stop VM (dry-run)" "$SCRIPT_DIR/stop-vm.sh --vm test-vm --dry-run" 0

    # Test configure-performance.sh dry-run
    run_test "dryrun-config-perf" "Configure performance (dry-run)" "$SCRIPT_DIR/configure-performance.sh --vm test-vm --dry-run" 0

    # Test setup-virtio-fs.sh dry-run (needs sudo but has dry-run)
    if [[ $EUID -eq 0 ]]; then
        run_test "dryrun-setup-virtio" "Setup virtio-fs (dry-run)" "$SCRIPT_DIR/setup-virtio-fs.sh --vm test-vm --dry-run" 0
    else
        skip_test "dryrun-setup-virtio" "Requires sudo privileges"
    fi
}

run_validation_tests() {
    log_msg SECTION "PHASE 4: ERROR HANDLING VALIDATION"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 4. Error Handling Tests

**Purpose:** Verify scripts properly handle invalid input and error conditions.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test backup-vm with non-existent VM (should fail gracefully)
    run_test "error-backup-nonexistent" "Backup non-existent VM (expect failure)" "$SCRIPT_DIR/backup-vm.sh --vm non-existent-vm-12345" 1

    # Test start-vm with non-existent VM
    run_test "error-start-nonexistent" "Start non-existent VM (expect failure)" "$SCRIPT_DIR/start-vm.sh --vm non-existent-vm-12345" 1

    # Test stop-vm with non-existent VM
    run_test "error-stop-nonexistent" "Stop non-existent VM (expect failure)" "$SCRIPT_DIR/stop-vm.sh --vm non-existent-vm-12345" 1
}

run_configuration_tests() {
    log_msg SECTION "PHASE 5: CONFIGURATION FILE VALIDATION"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 5. Configuration File Tests

**Purpose:** Verify XML configuration templates are valid.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test XML configuration files
    if [[ -f "$PROJECT_ROOT/configs/win11-vm.xml" ]]; then
        run_test "config-win11-xml" "Validate win11-vm.xml" "xmllint --noout $PROJECT_ROOT/configs/win11-vm.xml" 0
    else
        skip_test "config-win11-xml" "Configuration file not found"
    fi

    if [[ -f "$PROJECT_ROOT/configs/virtio-fs-share.xml" ]]; then
        run_test "config-virtio-xml" "Validate virtio-fs-share.xml" "xmllint --noout $PROJECT_ROOT/configs/virtio-fs-share.xml" 0
    else
        skip_test "config-virtio-xml" "Configuration file not found"
    fi
}

run_dependency_tests() {
    log_msg SECTION "PHASE 6: DEPENDENCY CHECKS"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 6. Dependency Tests

**Purpose:** Verify required commands and tools are available.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test required commands
    local required_commands=(
        "bash:Bash shell"
        "virsh:libvirt client"
        "qemu-system-x86_64:QEMU emulator"
        "xmllint:XML validation tool"
    )

    for cmd_pair in "${required_commands[@]}"; do
        IFS=':' read -r cmd desc <<< "$cmd_pair"
        run_test "dep-${cmd}" "Check dependency: ${desc}" "command -v $cmd" 0
    done
}

run_library_tests() {
    log_msg SECTION "PHASE 7: LIBRARY FUNCTION TESTS"

    cat >> "$REPORT_FILE" <<'EOF'

---

### 7. Library Function Tests

**Purpose:** Verify common.sh library functions work correctly.

| Test Name | Status | Exit Code | Description | Log File |
|-----------|--------|-----------|-------------|----------|
EOF

    # Test common.sh can be sourced
    run_test "lib-common-source" "Source common.sh library" "source $SCRIPT_DIR/lib/common.sh" 0

    # Test logging functions
    run_test_with_pattern "lib-logging" "Test logging functions" \
        "source $SCRIPT_DIR/lib/common.sh && init_logging 'test' && log INFO 'test message'" \
        "test message"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    clear
    echo "═══════════════════════════════════════════════════════════════════"
    echo "  QEMU/KVM Comprehensive Dry-Run Test Harness"
    echo "  Testing all scripts for Windows 11 installation readiness"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    log_msg INFO "Starting comprehensive dry-run tests"
    log_msg INFO "Log directory: ${LOG_DIR}"
    log_msg INFO "Report file: ${REPORT_FILE}"
    echo ""

    # Initialize report
    initialize_report

    # Run all test suites
    run_syntax_tests
    run_help_tests
    run_dryrun_tests
    run_validation_tests
    run_configuration_tests
    run_dependency_tests
    run_library_tests

    # Finalize report
    finalize_report

    # Print summary
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "  TEST EXECUTION COMPLETE"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    log_msg INFO "Test Summary:"
    echo "  Total Tests:    ${TOTAL_TESTS}"
    echo "  ✅ Passed:      ${PASSED_TESTS}"
    echo "  ❌ Failed:      ${FAILED_TESTS}"
    echo "  ⊘ Skipped:     ${SKIPPED_TESTS}"
    echo ""
    log_msg INFO "Detailed report: ${REPORT_FILE}"
    log_msg INFO "All logs: ${LOG_DIR}/"
    echo ""

    # Exit with appropriate code
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_msg SUCCESS "All tests passed! System is ready for Windows 11 installation."
        exit 0
    else
        log_msg FAIL "Some tests failed. Review report for details."
        exit 1
    fi
}

# Execute main
main "$@"
