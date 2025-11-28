#!/bin/bash
#
# 03-verify-installation.sh - Verify QEMU/KVM Installation
#
# Purpose: Verify that QEMU/KVM virtualization stack is properly installed and functional
# Requirements: Run after 01-install-qemu-kvm.sh and 02-configure-user-groups.sh
# Duration: < 30 seconds
# Idempotent: Safe to run multiple times (verification only, no modifications)
#
# Usage:
#   ./scripts/03-verify-installation.sh [--fix] [--json]
#
# Options:
#   --fix   Attempt to fix issues found (requires sudo)
#   --json  Output results in JSON format
#   --help  Show this help message
#
# Output:
#   - Human-readable verification report
#   - State: .installation-state/verification-YYYYMMDD-HHMMSS.json
#
# Exit Codes:
#   0 - All checks passed
#   1 - One or more checks failed
#   2 - Critical error (cannot proceed)
#
# Author: AI-assisted (Claude Code)
# Created: 2025-11-28
# Version: 1.0
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# State file for verification results
STATE_FILE="${STATE_DIR}/verification-$(date +%Y%m%d-%H%M%S).json"

# Options
FIX_MODE=false
JSON_OUTPUT=false

# Track results
declare -A RESULTS
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Verify QEMU/KVM installation and configuration.

OPTIONS:
    --fix     Attempt to fix issues found (requires sudo)
    --json    Output results in JSON format
    --help    Show this help message

EXAMPLES:
    $(basename "$0")              # Run verification
    $(basename "$0") --fix        # Run verification and fix issues
    $(basename "$0") --json       # Output JSON for scripting

EXIT CODES:
    0 - All checks passed
    1 - One or more checks failed
    2 - Critical error

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done
}

# ==============================================================================
# VERIFICATION FUNCTIONS
# ==============================================================================

record_check() {
    local name="$1"
    local status="$2"  # pass, fail, warn
    local message="$3"
    
    RESULTS["$name"]="$status:$message"
    ((TOTAL_CHECKS++))
    
    case "$status" in
        pass)
            ((PASSED_CHECKS++))
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                log SUCCESS "$name: $message"
            fi
            ;;
        fail)
            ((FAILED_CHECKS++))
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                log ERROR "$name: $message"
            fi
            ;;
        warn)
            ((WARNINGS++))
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                log WARN "$name: $message"
            fi
            ;;
    esac
}

# Check if required packages are installed
check_packages() {
    local packages=(
        "qemu-system-x86"
        "qemu-kvm"
        "libvirt-daemon-system"
        "libvirt-clients"
        "bridge-utils"
        "virt-manager"
        "ovmf"
        "swtpm"
        "swtpm-tools"
        "qemu-utils"
    )
    
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking installed packages..."
    fi
    
    local all_installed=true
    local missing_packages=()
    
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null 2>&1; then
            record_check "Package: $pkg" "pass" "Installed"
        else
            record_check "Package: $pkg" "fail" "Not installed"
            missing_packages+=("$pkg")
            all_installed=false
        fi
    done
    
    if [[ "$all_installed" == "false" && "$FIX_MODE" == "true" ]]; then
        if [[ "$JSON_OUTPUT" != "true" ]]; then
            log INFO "Attempting to install missing packages..."
        fi
        if [[ $EUID -eq 0 ]]; then
            apt update && apt install -y "${missing_packages[@]}"
            # Re-check after install
            for pkg in "${missing_packages[@]}"; do
                if dpkg -l "$pkg" &>/dev/null 2>&1; then
                    record_check "Package: $pkg (fixed)" "pass" "Installed after fix"
                    ((FAILED_CHECKS--))
                    ((PASSED_CHECKS++))
                fi
            done
        else
            if [[ "$JSON_OUTPUT" != "true" ]]; then
                log ERROR "Cannot fix packages without root privileges. Run with sudo."
            fi
        fi
    fi
}

# Check libvirt daemon status
check_libvirtd() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking libvirtd service..."
    fi
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q libvirtd; then
        record_check "libvirtd service" "fail" "Service not found"
        return
    fi
    
    # Check if service is enabled
    if systemctl is-enabled libvirtd &>/dev/null; then
        record_check "libvirtd enabled" "pass" "Service is enabled"
    else
        record_check "libvirtd enabled" "fail" "Service not enabled"
        if [[ "$FIX_MODE" == "true" && $EUID -eq 0 ]]; then
            systemctl enable libvirtd
            record_check "libvirtd enabled (fixed)" "pass" "Enabled after fix"
            ((FAILED_CHECKS--))
            ((PASSED_CHECKS++))
        fi
    fi
    
    # Check if service is running
    if systemctl is-active libvirtd &>/dev/null; then
        record_check "libvirtd running" "pass" "Service is running"
    else
        record_check "libvirtd running" "fail" "Service not running"
        if [[ "$FIX_MODE" == "true" && $EUID -eq 0 ]]; then
            systemctl start libvirtd
            if systemctl is-active libvirtd &>/dev/null; then
                record_check "libvirtd running (fixed)" "pass" "Started after fix"
                ((FAILED_CHECKS--))
                ((PASSED_CHECKS++))
            fi
        fi
    fi
}

# Check user group membership
check_user_groups() {
    local user="${SUDO_USER:-$USER}"
    
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking user group membership for '$user'..."
    fi
    
    # Check libvirt group
    if id -nG "$user" | grep -qw libvirt; then
        record_check "User in libvirt group" "pass" "'$user' is in libvirt group"
    else
        record_check "User in libvirt group" "fail" "'$user' not in libvirt group"
        if [[ "$FIX_MODE" == "true" && $EUID -eq 0 ]]; then
            usermod -aG libvirt "$user"
            record_check "User in libvirt group (fixed)" "warn" "Added - logout required"
        fi
    fi
    
    # Check kvm group
    if id -nG "$user" | grep -qw kvm; then
        record_check "User in kvm group" "pass" "'$user' is in kvm group"
    else
        record_check "User in kvm group" "fail" "'$user' not in kvm group"
        if [[ "$FIX_MODE" == "true" && $EUID -eq 0 ]]; then
            usermod -aG kvm "$user"
            record_check "User in kvm group (fixed)" "warn" "Added - logout required"
        fi
    fi
}

# Check OVMF firmware
check_ovmf() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking UEFI firmware (OVMF)..."
    fi
    
    local ovmf_paths=(
        "/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
        "/usr/share/OVMF/OVMF_CODE.fd"
        "/usr/share/ovmf/OVMF.fd"
    )
    
    local ovmf_found=false
    for path in "${ovmf_paths[@]}"; do
        if [[ -f "$path" ]]; then
            record_check "OVMF firmware" "pass" "Found at $path"
            ovmf_found=true
            break
        fi
    done
    
    if [[ "$ovmf_found" == "false" ]]; then
        record_check "OVMF firmware" "fail" "Not found in standard locations"
    fi
}

# Check swtpm (TPM emulation)
check_swtpm() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking TPM 2.0 emulation (swtpm)..."
    fi
    
    if command -v swtpm &>/dev/null; then
        local swtpm_version=$(swtpm --version 2>/dev/null | head -1)
        record_check "swtpm binary" "pass" "$swtpm_version"
    else
        record_check "swtpm binary" "fail" "swtpm not found"
    fi
    
    if command -v swtpm_setup &>/dev/null; then
        record_check "swtpm_setup" "pass" "Available"
    else
        record_check "swtpm_setup" "fail" "swtpm_setup not found"
    fi
}

# Check KVM kernel module
check_kvm_module() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking KVM kernel modules..."
    fi
    
    if lsmod | grep -q "^kvm "; then
        record_check "KVM module" "pass" "Loaded"
    else
        record_check "KVM module" "fail" "Not loaded"
    fi
    
    # Check for Intel or AMD specific module
    if lsmod | grep -q "^kvm_intel "; then
        record_check "KVM Intel module" "pass" "Intel VT-x enabled"
    elif lsmod | grep -q "^kvm_amd "; then
        record_check "KVM AMD module" "pass" "AMD-V enabled"
    else
        record_check "KVM vendor module" "warn" "No Intel/AMD KVM module loaded"
    fi
}

# Check /dev/kvm access
check_dev_kvm() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking /dev/kvm access..."
    fi
    
    if [[ -c /dev/kvm ]]; then
        record_check "/dev/kvm exists" "pass" "Character device exists"
        
        # Check permissions
        local kvm_perms=$(stat -c "%a" /dev/kvm)
        if [[ "$kvm_perms" =~ ^(660|666)$ ]]; then
            record_check "/dev/kvm permissions" "pass" "Permissions: $kvm_perms"
        else
            record_check "/dev/kvm permissions" "warn" "Permissions: $kvm_perms (expected 660)"
        fi
        
        # Check if current user can access
        if [[ -r /dev/kvm && -w /dev/kvm ]]; then
            record_check "/dev/kvm accessible" "pass" "Read/write access confirmed"
        else
            record_check "/dev/kvm accessible" "fail" "Cannot access /dev/kvm"
        fi
    else
        record_check "/dev/kvm exists" "fail" "Device not found - KVM not available"
    fi
}

# Check virsh connectivity
check_virsh() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking virsh connectivity..."
    fi
    
    if command -v virsh &>/dev/null; then
        local virsh_version=$(virsh --version 2>/dev/null)
        record_check "virsh binary" "pass" "Version $virsh_version"
        
        # Try to connect to QEMU
        if virsh -c qemu:///system version &>/dev/null; then
            record_check "virsh QEMU connection" "pass" "Connected to qemu:///system"
        else
            record_check "virsh QEMU connection" "fail" "Cannot connect to qemu:///system"
        fi
    else
        record_check "virsh binary" "fail" "virsh not found"
    fi
}

# Check default network
check_network() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking libvirt default network..."
    fi
    
    if virsh -c qemu:///system net-info default &>/dev/null 2>&1; then
        local net_active=$(virsh -c qemu:///system net-info default 2>/dev/null | grep "Active:" | awk '{print $2}')
        local net_autostart=$(virsh -c qemu:///system net-info default 2>/dev/null | grep "Autostart:" | awk '{print $2}')
        
        if [[ "$net_active" == "yes" ]]; then
            record_check "Default network active" "pass" "Network is active"
        else
            record_check "Default network active" "fail" "Network not active"
            if [[ "$FIX_MODE" == "true" ]]; then
                virsh -c qemu:///system net-start default 2>/dev/null || true
            fi
        fi
        
        if [[ "$net_autostart" == "yes" ]]; then
            record_check "Default network autostart" "pass" "Autostart enabled"
        else
            record_check "Default network autostart" "warn" "Autostart not enabled"
            if [[ "$FIX_MODE" == "true" ]]; then
                virsh -c qemu:///system net-autostart default 2>/dev/null || true
            fi
        fi
    else
        record_check "Default network" "warn" "Default network not defined"
    fi
}

# Check VirtIO drivers ISO
check_virtio_iso() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        log STEP "Checking VirtIO drivers ISO..."
    fi
    
    local virtio_locations=(
        "${PROJECT_ROOT}/source-iso/virtio-win.iso"
        "${PROJECT_ROOT}/source-iso/virtio-win-*.iso"
        "/var/lib/libvirt/images/virtio-win.iso"
    )
    
    local virtio_found=false
    for pattern in "${virtio_locations[@]}"; do
        for path in $pattern; do
            if [[ -f "$path" ]]; then
                local size=$(du -h "$path" | cut -f1)
                record_check "VirtIO drivers ISO" "pass" "Found: $path ($size)"
                virtio_found=true
                break 2
            fi
        done
    done
    
    if [[ "$virtio_found" == "false" ]]; then
        record_check "VirtIO drivers ISO" "warn" "Not found - download from fedorapeople.org"
    fi
}

# ==============================================================================
# OUTPUT FUNCTIONS
# ==============================================================================

output_json() {
    local status="pass"
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        status="fail"
    elif [[ $WARNINGS -gt 0 ]]; then
        status="warn"
    fi
    
    cat << EOF
{
    "timestamp": "$(date -Iseconds)",
    "status": "$status",
    "summary": {
        "total": $TOTAL_CHECKS,
        "passed": $PASSED_CHECKS,
        "failed": $FAILED_CHECKS,
        "warnings": $WARNINGS
    },
    "checks": {
EOF
    
    local first=true
    for key in "${!RESULTS[@]}"; do
        local value="${RESULTS[$key]}"
        local check_status="${value%%:*}"
        local check_message="${value#*:}"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        printf '        "%s": {"status": "%s", "message": "%s"}' "$key" "$check_status" "$check_message"
    done
    
    cat << EOF

    }
}
EOF
}

output_summary() {
    echo ""
    echo "=============================================="
    echo "        VERIFICATION SUMMARY"
    echo "=============================================="
    echo ""
    echo -e "  Total Checks:  ${BOLD}$TOTAL_CHECKS${NC}"
    echo -e "  Passed:        ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "  Failed:        ${RED}$FAILED_CHECKS${NC}"
    echo -e "  Warnings:      ${YELLOW}$WARNINGS${NC}"
    echo ""
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}All critical checks passed!${NC}"
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "${YELLOW}Some warnings require attention.${NC}"
        fi
    else
        echo -e "${RED}Some checks failed. Run with --fix to attempt repairs.${NC}"
    fi
    echo ""
    
    echo "Next steps:"
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo "  1. Run: sudo ./scripts/03-verify-installation.sh --fix"
        echo "  2. Log out and log back in (for group changes)"
        echo "  3. Re-run verification"
    else
        echo "  1. Download Windows 11 ISO to source-iso/"
        echo "  2. Download VirtIO drivers ISO to source-iso/"
        echo "  3. Run: ./start.sh to create your VM"
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"
    
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo ""
        echo "========================================"
        echo "  QEMU/KVM Installation Verification"
        echo "========================================"
        echo ""
    fi
    
    # Run all checks
    check_packages
    check_libvirtd
    check_user_groups
    check_kvm_module
    check_dev_kvm
    check_ovmf
    check_swtpm
    check_virsh
    check_network
    check_virtio_iso
    
    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json
    else
        output_summary
    fi
    
    # Save state
    output_json > "$STATE_FILE" 2>/dev/null || true
    
    # Exit code
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
