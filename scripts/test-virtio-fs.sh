#!/bin/bash
################################################################################
# VirtIO-FS Verification Test Script
# ===================================
#
# PURPOSE:
#   Verifies that virtio-fs filesystem sharing is working correctly and
#   read-only mode is properly enforced for ransomware protection.
#
# USAGE:
#   # On Ubuntu host:
#   sudo ./scripts/test-virtio-fs.sh --vm <vm-name> --source ~/Documents
#
#   # In Windows guest (PowerShell as Administrator):
#   # Run the commands shown in the output
#
# TESTS PERFORMED:
#   1. Host-side: Create test file in shared directory
#   2. Host-side: Verify file permissions and ownership
#   3. Host-side: Confirm virtio-fs configuration in VM XML
#   4. Guest-side: Verify file is visible on Z: drive (manual)
#   5. Guest-side: Attempt to create file (should fail - read-only)
#   6. Guest-side: Attempt to delete file (should fail - read-only)
#   7. Guest-side: Attempt to modify file (should fail - read-only)
#
# VERSION: 1.0.0 (January 2025)
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Compatibility aliases
readonly RESET=$NC

# Get user home directory (works correctly with sudo)
_get_user_home() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        eval echo "~$SUDO_USER"
    else
        echo "$HOME"
    fi
}

# Get XDG Documents folder with fallback
_get_documents_dir() {
    local xdg_docs=""
    if command -v xdg-user-dir &>/dev/null; then
        xdg_docs="$(xdg-user-dir DOCUMENTS 2>/dev/null)"
    fi
    if [[ -n "$xdg_docs" && -d "$xdg_docs" ]]; then
        echo "$xdg_docs"
    else
        echo "$(_get_user_home)/Documents"
    fi
}

# Configuration
VM_NAME=""
SOURCE_DIR="$(_get_documents_dir)"
TARGET_TAG="outlook-share"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------

test_result() {
    local status="$1"
    local message="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$status" == "PASS" ]]; then
        log_success "Test $TESTS_TOTAL: $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ "$status" == "FAIL" ]]; then
        log_error "Test $TESTS_TOTAL: $message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        log_warning "Test $TESTS_TOTAL: $message"
    fi
}

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

show_help() {
    cat << EOF
${BOLD}VirtIO-FS Verification Test Script${RESET}

${BOLD}USAGE:${RESET}
    sudo ./scripts/test-virtio-fs.sh --vm <vm-name> [OPTIONS]

${BOLD}OPTIONS:${RESET}
    --vm <name>           VM name (REQUIRED)
    --source <path>       Source directory (default: XDG Documents folder)
    --target <tag>        Mount tag (default: outlook-share)
    --help                Show this help message

${BOLD}EXAMPLES:${RESET}
    sudo ./scripts/test-virtio-fs.sh --vm win11-outlook
    sudo ./scripts/test-virtio-fs.sh --vm win11-outlook --source /custom/path

EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --vm)
                VM_NAME="$2"
                shift 2
                ;;
            --source)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --target)
                TARGET_TAG="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [[ -z "$VM_NAME" ]]; then
        echo "Error: --vm is required"
        show_help
    fi
}

#------------------------------------------------------------------------------
# Host-Side Tests
#------------------------------------------------------------------------------

test_vm_exists() {
    log_step "Test 1: VM Existence Check"

    if virsh dominfo "$VM_NAME" &>/dev/null; then
        test_result "PASS" "VM '$VM_NAME' exists"
    else
        test_result "FAIL" "VM '$VM_NAME' not found"
        exit 1
    fi
}

test_virtiofs_configured() {
    log_step "Test 2: VirtIO-FS Configuration Check"

    if virsh dumpxml "$VM_NAME" | grep -q "type='virtiofs'"; then
        test_result "PASS" "VirtIO-FS device configured in VM"

        echo ""
        print_color "$CYAN" "Current configuration:"
        virsh dumpxml "$VM_NAME" | grep -A 7 "type='virtiofs'"
        echo ""
    else
        test_result "FAIL" "VirtIO-FS device not found in VM XML"
        echo ""
        print_color "$RED" "Run setup script first: sudo ./scripts/setup-virtio-fs.sh --vm $VM_NAME"
        exit 1
    fi
}

test_readonly_mode() {
    log_step "Test 3: Read-Only Mode Verification"

    if virsh dumpxml "$VM_NAME" | grep -A 5 "type='virtiofs'" | grep -q "<readonly/>"; then
        test_result "PASS" "Read-only mode enforced (ransomware protection active)"
    else
        test_result "FAIL" "CRITICAL: Read-only mode NOT enforced - SECURITY RISK!"
        print_color "$RED" "Guest malware can encrypt host files!"
        print_color "$RED" "Fix immediately: Add <readonly/> tag to virtio-fs configuration"
    fi
}

test_source_directory() {
    log_step "Test 4: Source Directory Check"

    if [[ -d "$SOURCE_DIR" ]]; then
        test_result "PASS" "Source directory exists: $SOURCE_DIR"

        echo ""
        print_color "$CYAN" "Directory details:"
        ls -ld "$SOURCE_DIR"
        echo ""
    else
        test_result "FAIL" "Source directory not found: $SOURCE_DIR"
        echo ""
        print_color "$YELLOW" "Create directory: sudo mkdir -p $SOURCE_DIR"
    fi
}

test_directory_permissions() {
    log_step "Test 5: Directory Permissions Check"

    local perms
    perms=$(stat -c "%a" "$SOURCE_DIR" 2>/dev/null || echo "000")

    if [[ "$perms" == "755" ]] || [[ "$perms" == "775" ]] || [[ "$perms" == "770" ]]; then
        test_result "PASS" "Directory permissions: $perms (acceptable)"
    else
        test_result "WARN" "Directory permissions: $perms (may cause access issues)"
        print_color "$YELLOW" "Recommended: sudo chmod 755 $SOURCE_DIR"
    fi
}

test_create_host_file() {
    log_step "Test 6: Host File Creation Test"

    local test_file="$SOURCE_DIR/test-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$test_file" << EOF
VirtIO-FS Test File
==================

Created: $(date '+%Y-%m-%d %H:%M:%S')
Test ID: $(date +%s)
VM: $VM_NAME
Source: $SOURCE_DIR
Target: $TARGET_TAG

VERIFICATION INSTRUCTIONS:
==========================

1. In Windows guest, open File Explorer
2. Navigate to Z: drive (or your configured drive letter)
3. You should see this file
4. Open it and verify the contents match

If you can read this file, virtio-fs is working correctly!

SECURITY TEST:
==============
Try to DELETE this file from Windows guest.
Expected result: "Access Denied" error (read-only mode)

If you CAN delete this file, read-only mode is NOT enforced!
Contact system administrator immediately - SECURITY RISK!
EOF

    if [[ -f "$test_file" ]]; then
        test_result "PASS" "Test file created: $test_file"
        echo ""
        print_color "$CYAN" "File contents:"
        head -n 5 "$test_file"
        echo "..."
        echo ""
    else
        test_result "FAIL" "Failed to create test file"
    fi
}

test_file_readable() {
    log_step "Test 7: Host File Readability Test"

    local test_file
    test_file=$(ls -t "$SOURCE_DIR"/test-*.txt 2>/dev/null | head -n 1)

    if [[ -z "$test_file" ]]; then
        test_result "WARN" "No test files found"
        return
    fi

    if [[ -r "$test_file" ]]; then
        test_result "PASS" "Test file is readable: $(basename "$test_file")"
    else
        test_result "FAIL" "Test file is not readable - permission issue"
    fi
}

#------------------------------------------------------------------------------
# Windows Guest Test Instructions
#------------------------------------------------------------------------------

show_guest_instructions() {
    print_header "WINDOWS GUEST VERIFICATION INSTRUCTIONS"

    local test_file
    test_file=$(ls -t "$SOURCE_DIR"/test-*.txt 2>/dev/null | head -n 1)

    cat << EOF
The following tests must be performed MANUALLY in the Windows guest:

${BOLD}Prerequisites:${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. WinFsp is installed
2. VirtIO-FS Service is running
3. Z: drive is mounted: ${CYAN}net use Z: \\\\svc\\$TARGET_TAG${RESET}

${BOLD}Test 8: File Visibility Test${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open File Explorer in Windows
2. Navigate to ${CYAN}Z:${RESET} drive
3. Look for file: ${CYAN}$(basename "$test_file")${RESET}
4. Open the file and verify contents

${GREEN}Expected: File is visible and readable${RESET}
${RED}If file NOT visible: virtio-fs mount failed - check services.msc${RESET}

${BOLD}Test 9: Read-Only Mode Test (File Creation)${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. In File Explorer, navigate to ${CYAN}Z:${RESET} drive
2. Right-click → New → Text Document
3. Try to create a new file

${GREEN}Expected: "Access Denied" or "Insufficient permissions" error ✓${RESET}
${RED}If file CREATED: CRITICAL SECURITY ISSUE - read-only mode NOT enforced!${RESET}

${BOLD}Test 10: Read-Only Mode Test (File Deletion)${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Select test file: ${CYAN}$(basename "$test_file")${RESET}
2. Press Delete key or Right-click → Delete

${GREEN}Expected: "Access Denied" error ✓${RESET}
${RED}If file DELETED: CRITICAL SECURITY ISSUE!${RESET}

${BOLD}Test 11: Read-Only Mode Test (File Modification)${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open test file: ${CYAN}$(basename "$test_file")${RESET}
2. Try to edit the file in Notepad
3. Try to save changes

${GREEN}Expected: "Access Denied" when saving ✓${RESET}
${RED}If save SUCCEEDS: CRITICAL SECURITY ISSUE!${RESET}

${BOLD}Test 12: PowerShell Verification${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run these commands in ${CYAN}PowerShell${RESET} to verify configuration:

${CYAN}# Check if Z: drive is mounted
Get-PSDrive Z

# List files on Z: drive
Get-ChildItem Z:

# Check WinFsp installation
Get-Package -Name WinFsp

# Check VirtIO-FS Service status
Get-Service | Where-Object {\\$_.Name -like "*virti*"}

# Test read-only mode (should fail)
New-Item -Path "Z:\\test-write.txt" -ItemType File${RESET}

${BOLD}If ALL tests pass:${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${GREEN}✓ VirtIO-FS is working correctly${RESET}
${GREEN}✓ Read-only mode is enforced${RESET}
${GREEN}✓ Ransomware protection is active${RESET}
${GREEN}✓ Safe to use for .pst file access${RESET}

You can now:
1. Copy .pst files to ${CYAN}$SOURCE_DIR${RESET} on the host
2. Access them from Outlook via ${CYAN}Z:${RESET} drive in Windows
3. Set up Outlook data files pointing to Z: drive

${BOLD}If ANY test fails:${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${RED}DO NOT PROCEED with production use${RESET}

${YELLOW}Troubleshooting steps:${RESET}
1. Check WinFsp installation: ${CYAN}Get-Package -Name WinFsp${RESET}
2. Restart VirtIO-FS Service in ${CYAN}services.msc${RESET}
3. Remount Z: drive: ${CYAN}net use Z: /delete${RESET} then ${CYAN}net use Z: \\\\svc\\$TARGET_TAG${RESET}
4. Check Event Viewer for errors
5. Verify host-side configuration: ${CYAN}sudo ./scripts/test-virtio-fs.sh --vm $VM_NAME${RESET}

EOF
}

#------------------------------------------------------------------------------
# Test Summary
#------------------------------------------------------------------------------

show_summary() {
    print_header "TEST SUMMARY"

    echo ""
    print_color "$BOLD" "Results:"
    print_color "$GREEN" "  Passed: $TESTS_PASSED"
    print_color "$RED" "  Failed: $TESTS_FAILED"
    print_color "$CYAN" "  Total:  $TESTS_TOTAL"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_color "$GREEN$BOLD" "✓ All host-side tests PASSED!"
        echo ""
        print_color "$CYAN" "Next steps:"
        print_color "$CYAN" "1. Complete Windows guest verification (see instructions above)"
        print_color "$CYAN" "2. Test .pst file access in Outlook"
        print_color "$CYAN" "3. Verify read-only mode in guest"
    else
        print_color "$RED$BOLD" "✗ Some tests FAILED - review output above"
        echo ""
        print_color "$YELLOW" "Fix issues before proceeding to Windows guest tests"
    fi

    echo ""
}

#------------------------------------------------------------------------------
# Main Execution
#------------------------------------------------------------------------------

main() {
    init_logging "test-virtio-fs"
    log_step "VirtIO-FS Verification Test Suite"

    echo "Testing virtio-fs configuration for VM: $BOLD$VM_NAME$RESET"
    echo "Source directory: $BOLD$SOURCE_DIR$RESET"
    echo "Target mount tag: $BOLD$TARGET_TAG$RESET"
    echo ""

    # Run host-side tests
    test_vm_exists
    test_virtiofs_configured
    test_readonly_mode
    test_source_directory
    test_directory_permissions
    test_create_host_file
    test_file_readable

    # Show Windows guest instructions
    show_guest_instructions

    # Display summary
    show_summary
}

# Parse arguments and run
parse_arguments "$@"
main

exit 0
