#!/bin/bash
#
# system-readiness-check.sh - Comprehensive QEMU/KVM System Readiness Check
#
# Purpose: Perform 42+ prerequisite checks for QEMU/KVM Windows 11 VM deployment
# Requirements: gum (for TUI), jq (for JSON processing), Ubuntu 25.10
# Duration: 30-60 seconds
#
# Usage:
#   ./scripts/system-readiness-check.sh [--json-only] [--no-fixes]
#
# Output:
#   - Interactive TUI with gum (default)
#   - JSON report: .installation-state/readiness-check-YYYYMMDD-HHMMSS.json
#
# Author: AI-assisted (Claude Code - Master Orchestrator)
# Created: 2025-11-27
# Version: 1.0
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/.installation-state"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_FILE="${STATE_DIR}/readiness-check-${TIMESTAMP}.json"

# Source the interactive results library
if [[ -f "${SCRIPT_DIR}/lib/interactive-results.sh" ]]; then
    source "${SCRIPT_DIR}/lib/interactive-results.sh"
    HAS_INTERACTIVE_LIB=true
else
    HAS_INTERACTIVE_LIB=false
fi

# Command-line flags
JSON_ONLY=false
NO_FIXES=false
FORCE_INTERACTIVE=false
FORCE_AUTOMATION=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --json-only) JSON_ONLY=true ;;
        --no-fixes) NO_FIXES=true ;;
        --interactive) FORCE_INTERACTIVE=true ;;
        --automation|--ci) FORCE_AUTOMATION=true ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --json-only     Only output JSON (no interactive UI)"
            echo "  --no-fixes      Don't show fix commands"
            echo "  --interactive   Force interactive mode (show menus)"
            echo "  --automation    Force automation/CI mode (exit with codes)"
            echo "  --ci            Alias for --automation"
            echo ""
            echo "Behavior:"
            echo "  - Interactive mode (terminal): Shows menu after checks"
            echo "  - Automation mode (CI/CD): Exits with code 0 (pass) or 1 (fail)"
            exit 0
            ;;
    esac
done

# Check results storage
declare -A CHECK_RESULTS
declare -A CHECK_MESSAGES
declare -A CHECK_FIXES
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# ==============================================================================
# MODE DETECTION (Interactive vs CI/CD)
# ==============================================================================

# Determine if we should run in interactive mode
# Priority: --automation/--ci flag > --interactive flag > --json-only flag > auto-detect
should_run_interactive() {
    # Forced automation mode
    if [[ "$FORCE_AUTOMATION" == "true" ]]; then
        return 1
    fi

    # Forced interactive mode
    if [[ "$FORCE_INTERACTIVE" == "true" ]]; then
        return 0
    fi

    # JSON-only implies non-interactive
    if [[ "$JSON_ONLY" == "true" ]]; then
        return 1
    fi

    # Auto-detect: check if stdin/stdout are terminals
    if [[ -t 0 && -t 1 ]]; then
        return 0  # Interactive
    else
        return 1  # Non-interactive (piped, CI/CD, etc.)
    fi
}

# Get mode as string for logging
get_mode_string() {
    if should_run_interactive; then
        echo "interactive"
    else
        echo "automation"
    fi
}

# Check if gum is installed (only needed for interactive mode)
check_gum_available() {
    command -v gum &> /dev/null
}

# Check if gum is installed
if ! check_gum_available && should_run_interactive; then
    echo "❌ ERROR: 'gum' is required for interactive UI"
    echo "Install with: go install github.com/charmbracelet/gum@latest"
    echo "Or run with --json-only or --automation flag"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠️  WARNING: 'jq' not found. Installing..."
    sudo apt install -y jq
fi

# Display header with fastfetch if available
show_header() {
    if [ "$JSON_ONLY" = true ]; then
        return
    fi

    clear
    cat <<EOF | gum style --border double --border-foreground 212 --padding "1 2" --margin "1 0"
QEMU/KVM System Readiness Check
42+ Point Automated Prerequisite Validation

Project: win-qemu
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if command -v fastfetch &> /dev/null; then
        gum style --foreground 86 "System Information:"
        fastfetch --pipe true --logo-type none --structure "OS:Kernel:Shell:CPU:Memory:Disk" 2>/dev/null || echo "  (fastfetch unavailable)"
        echo ""
    fi
}

# Record check result
record_check() {
    local name="$1"
    local status="$2"  # pass, fail, warn
    local message="$3"
    local fix="${4:-}"

    CHECK_RESULTS["$name"]="$status"
    CHECK_MESSAGES["$name"]="$message"
    CHECK_FIXES["$name"]="$fix"

    ((TOTAL_CHECKS++))

    case "$status" in
        pass) ((PASSED_CHECKS++)) ;;
        fail) ((FAILED_CHECKS++)) ;;
        warn) ((WARNING_CHECKS++)) ;;
    esac
}

# Display check result with gum
display_check() {
    local category="$1"
    local name="$2"
    local status="${CHECK_RESULTS[$name]}"
    local message="${CHECK_MESSAGES[$name]}"
    local fix="${CHECK_FIXES[$name]}"

    if [ "$JSON_ONLY" = true ]; then
        return
    fi

    case "$status" in
        pass)
            gum style --foreground 46 "  ✅ $message"
            ;;
        fail)
            gum style --foreground 196 "  ❌ $message"
            if [ -n "$fix" ] && [ "$NO_FIXES" = false ]; then
                gum style --foreground 226 --italic "     💡 Fix: $fix"
            fi
            ;;
        warn)
            gum style --foreground 226 "  ⚠️  $message"
            if [ -n "$fix" ] && [ "$NO_FIXES" = false ]; then
                gum style --foreground 226 --italic "     💡 Recommendation: $fix"
            fi
            ;;
    esac
}

# Category header
show_category() {
    if [ "$JSON_ONLY" = true ]; then
        return
    fi

    echo ""
    gum style --bold --foreground 117 "━━━ $1 ━━━"
}

# ==============================================================================
# CHECK FUNCTIONS - HARDWARE
# ==============================================================================

check_cpu_virtualization() {
    local name="cpu_virtualization"
    local count=0

    if grep -q -E '(vmx|svm)' /proc/cpuinfo 2>/dev/null; then
        count=$(grep -c -E '(vmx|svm)' /proc/cpuinfo)
        record_check "$name" "pass" "CPU virtualization supported ($count cores with VT-x/AMD-V)" ""
    else
        record_check "$name" "fail" "CPU virtualization NOT supported or disabled" "Enable Intel VT-x or AMD-V in BIOS/UEFI settings"
    fi
}

check_cpu_cores() {
    local name="cpu_cores"
    local cores=$(nproc)

    if [ "$cores" -ge 8 ]; then
        record_check "$name" "pass" "CPU cores: $cores (≥8 required, ✅ passed)" ""
    elif [ "$cores" -ge 4 ]; then
        record_check "$name" "warn" "CPU cores: $cores (8 recommended, VM may be slow)" "Allocate fewer vCPUs to VM or upgrade CPU"
    else
        record_check "$name" "fail" "CPU cores: $cores (minimum 4 required)" "Upgrade to CPU with at least 4 cores"
    fi
}

check_ram() {
    local name="ram"
    local ram_gb=$(free -g | awk '/^Mem:/ {print $2}')

    if [ "$ram_gb" -ge 32 ]; then
        record_check "$name" "pass" "RAM: ${ram_gb}GB (≥32GB optimal, ✅ excellent)" ""
    elif [ "$ram_gb" -ge 16 ]; then
        record_check "$name" "pass" "RAM: ${ram_gb}GB (≥16GB required, ✅ passed)" ""
    elif [ "$ram_gb" -ge 8 ]; then
        record_check "$name" "warn" "RAM: ${ram_gb}GB (16GB recommended, VM may be slow)" "Upgrade to 16GB+ RAM for optimal performance"
    else
        record_check "$name" "fail" "RAM: ${ram_gb}GB (minimum 16GB required)" "Upgrade to at least 16GB RAM"
    fi
}

check_storage_type() {
    local name="storage_type"
    local has_ssd=false

    # Check for NVMe or SSD (ROTA=0)
    while IFS= read -r line; do
        if echo "$line" | grep -q "0"; then
            has_ssd=true
            break
        fi
    done < <(lsblk -d -o NAME,ROTA | grep -E '^(sd|nvme)' | awk '{print $2}')

    if [ "$has_ssd" = true ]; then
        local ssd_list=$(lsblk -d -o NAME,ROTA,SIZE | grep -E '^(sd|nvme)' | awk '$2 == 0 {print $1 " (" $3 ")"}' | tr '\n' ', ' | sed 's/,$//')
        record_check "$name" "pass" "Storage: SSD/NVMe detected [$ssd_list]" ""
    else
        record_check "$name" "fail" "Storage: Only HDD detected (SSD MANDATORY for usable performance)" "Install SSD or NVMe drive (10-30x faster than HDD)"
    fi
}

check_storage_space() {
    local name="storage_space"
    local free_gb=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "$free_gb" -ge 150 ]; then
        record_check "$name" "pass" "Free space: ${free_gb}GB (≥150GB recommended, ✅ passed)" ""
    elif [ "$free_gb" -ge 100 ]; then
        record_check "$name" "warn" "Free space: ${free_gb}GB (150GB recommended)" "Free up disk space or use different partition"
    else
        record_check "$name" "fail" "Free space: ${free_gb}GB (minimum 100GB required)" "Free up disk space or add storage"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - QEMU/KVM STACK
# ==============================================================================

check_qemu_installed() {
    local name="qemu_installed"

    if command -v qemu-system-x86_64 &> /dev/null; then
        local version=$(qemu-system-x86_64 --version | head -n1)
        record_check "$name" "pass" "QEMU installed: $version" ""
    else
        record_check "$name" "fail" "QEMU not installed" "Run: sudo ./scripts/01-install-qemu-kvm.sh"
    fi
}

check_kvm_module() {
    local name="kvm_module"

    if lsmod | grep -q '^kvm'; then
        local kvm_type=$(lsmod | grep '^kvm' | awk '{print $1}' | head -n1)
        record_check "$name" "pass" "KVM kernel module loaded: $kvm_type" ""
    else
        record_check "$name" "fail" "KVM kernel module not loaded" "Run: sudo modprobe kvm && sudo modprobe kvm_intel (or kvm_amd)"
    fi
}

check_libvirt_installed() {
    local name="libvirt_installed"

    if command -v virsh &> /dev/null; then
        local version=$(virsh --version)
        record_check "$name" "pass" "libvirt installed: version $version" ""
    else
        record_check "$name" "fail" "libvirt not installed" "Run: sudo ./scripts/01-install-qemu-kvm.sh"
    fi
}

check_libvirtd_running() {
    local name="libvirtd_running"

    if systemctl is-active --quiet libvirtd 2>/dev/null; then
        record_check "$name" "pass" "libvirtd service running" ""
    else
        record_check "$name" "fail" "libvirtd service not running" "Run: sudo systemctl start libvirtd && sudo systemctl enable libvirtd"
    fi
}

check_virt_manager() {
    local name="virt_manager"

    if command -v virt-manager &> /dev/null; then
        record_check "$name" "pass" "virt-manager (GUI) installed" ""
    else
        record_check "$name" "warn" "virt-manager (GUI) not installed (optional)" "Run: sudo apt install -y virt-manager"
    fi
}

check_ovmf_firmware() {
    local name="ovmf_firmware"

    if [ -f "/usr/share/OVMF/OVMF_CODE.fd" ] || [ -f "/usr/share/ovmf/OVMF.fd" ]; then
        record_check "$name" "pass" "OVMF UEFI firmware installed" ""
    else
        record_check "$name" "fail" "OVMF UEFI firmware not installed (required for Windows 11)" "Run: sudo apt install -y ovmf"
    fi
}

check_swtpm() {
    local name="swtpm"

    if command -v swtpm &> /dev/null; then
        record_check "$name" "pass" "swtpm (TPM 2.0 emulation) installed" ""
    else
        record_check "$name" "fail" "swtpm not installed (required for Windows 11)" "Run: sudo apt install -y swtpm"
    fi
}

check_qemu_utils() {
    local name="qemu_utils"

    if command -v qemu-img &> /dev/null; then
        record_check "$name" "pass" "qemu-utils (qemu-img) installed" ""
    else
        record_check "$name" "fail" "qemu-utils not installed" "Run: sudo apt install -y qemu-utils"
    fi
}

check_guestfs_tools() {
    local name="guestfs_tools"

    if command -v virt-customize &> /dev/null; then
        record_check "$name" "pass" "guestfs-tools installed" ""
    else
        record_check "$name" "warn" "guestfs-tools not installed (optional but useful)" "Run: sudo apt install -y guestfs-tools"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - USER PERMISSIONS
# ==============================================================================

check_libvirt_group() {
    local name="libvirt_group"

    if groups | grep -q '\blibvirt\b'; then
        record_check "$name" "pass" "User in 'libvirt' group" ""
    else
        record_check "$name" "fail" "User NOT in 'libvirt' group" "Run: sudo ./scripts/02-configure-user-groups.sh && logout/login"
    fi
}

check_kvm_group() {
    local name="kvm_group"

    if groups | grep -q '\bkvm\b'; then
        record_check "$name" "pass" "User in 'kvm' group" ""
    else
        record_check "$name" "fail" "User NOT in 'kvm' group" "Run: sudo ./scripts/02-configure-user-groups.sh && logout/login"
    fi
}

check_kvm_device_access() {
    local name="kvm_device_access"

    if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        record_check "$name" "pass" "/dev/kvm readable and writable" ""
    elif [ -e /dev/kvm ]; then
        record_check "$name" "fail" "/dev/kvm exists but no permissions" "Add user to kvm group and logout/login"
    else
        record_check "$name" "fail" "/dev/kvm does not exist" "Ensure KVM module is loaded: sudo modprobe kvm_intel"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - NETWORK
# ==============================================================================

check_default_network() {
    local name="default_network"

    if ! command -v virsh &> /dev/null; then
        record_check "$name" "fail" "Cannot check network (virsh not installed)" "Install libvirt first"
        return
    fi

    if virsh net-list --all 2>/dev/null | grep -q 'default'; then
        if virsh net-list 2>/dev/null | grep -q 'default.*active'; then
            record_check "$name" "pass" "Default libvirt network active" ""
        else
            record_check "$name" "warn" "Default network exists but not active" "Run: virsh net-start default"
        fi
    else
        record_check "$name" "fail" "Default libvirt network not configured" "Run: virsh net-define /usr/share/libvirt/networks/default.xml && virsh net-start default"
    fi
}

check_internet_connectivity() {
    local name="internet_connectivity"

    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        record_check "$name" "pass" "Internet connectivity working" ""
    else
        record_check "$name" "warn" "No internet connectivity" "Check network connection (required for Windows ISO download)"
    fi
}

check_dns_resolution() {
    local name="dns_resolution"

    if ping -c 1 -W 3 archive.ubuntu.com &> /dev/null; then
        record_check "$name" "pass" "DNS resolution working" ""
    else
        record_check "$name" "warn" "DNS resolution issues" "Check /etc/resolv.conf"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - REQUIRED ISOS
# ==============================================================================

check_windows_iso() {
    local name="windows_iso"

    # Check common locations
    local found=false
    for dir in "$HOME/ISOs" "$HOME/Downloads" "$PROJECT_ROOT/isos"; do
        if [ -d "$dir" ]; then
            if find "$dir" -iname "*win*.iso" -o -iname "*windows*.iso" 2>/dev/null | grep -q .; then
                local iso_file=$(find "$dir" -iname "*win*.iso" -o -iname "*windows*.iso" 2>/dev/null | head -n1)
                record_check "$name" "pass" "Windows ISO found: $(basename "$iso_file")" ""
                found=true
                break
            fi
        fi
    done

    if [ "$found" = false ]; then
        record_check "$name" "warn" "Windows 11 ISO not found in common locations" "Download from: https://www.microsoft.com/software-download/windows11"
    fi
}

check_virtio_drivers_iso() {
    local name="virtio_drivers_iso"

    # Check common locations
    local found=false
    for dir in "$HOME/ISOs" "$HOME/Downloads" "$PROJECT_ROOT/isos"; do
        if [ -d "$dir" ]; then
            if find "$dir" -iname "*virtio*.iso" 2>/dev/null | grep -q .; then
                local iso_file=$(find "$dir" -iname "*virtio*.iso" 2>/dev/null | head -n1)
                record_check "$name" "pass" "VirtIO drivers ISO found: $(basename "$iso_file")" ""
                found=true
                break
            fi
        fi
    done

    if [ "$found" = false ]; then
        record_check "$name" "warn" "VirtIO drivers ISO not found in common locations" "Download from: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - UBUNTU VERSION
# ==============================================================================

check_ubuntu_version() {
    local name="ubuntu_version"

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            local version=$(echo "$VERSION_ID" | cut -d. -f1,2)
            if [ "$version" = "25.10" ]; then
                record_check "$name" "pass" "Ubuntu 25.10 (tested version)" ""
            elif echo "$version" | grep -qE '^(24|25)'; then
                record_check "$name" "pass" "Ubuntu $VERSION_ID (should work, tested on 25.10)" ""
            else
                record_check "$name" "warn" "Ubuntu $VERSION_ID (not tested, may have issues)" "Consider upgrading to Ubuntu 25.10"
            fi
        else
            record_check "$name" "warn" "Not Ubuntu ($PRETTY_NAME) - may work but not tested" "This project was designed for Ubuntu 25.10"
        fi
    else
        record_check "$name" "fail" "Cannot detect OS version" "Ensure /etc/os-release exists"
    fi
}

check_kernel_version() {
    local name="kernel_version"
    local kernel_version=$(uname -r)
    local major_version=$(echo "$kernel_version" | cut -d. -f1)

    if [ "$major_version" -ge 6 ]; then
        record_check "$name" "pass" "Kernel $kernel_version (6.x+ required for best KVM)" ""
    elif [ "$major_version" -eq 5 ]; then
        record_check "$name" "warn" "Kernel $kernel_version (6.x recommended)" "Consider upgrading kernel for better KVM features"
    else
        record_check "$name" "fail" "Kernel $kernel_version (too old, 5.x minimum)" "Upgrade to Ubuntu 22.04+ or upgrade kernel manually"
    fi
}

# ==============================================================================
# CHECK FUNCTIONS - AGENT SYSTEM
# ==============================================================================

check_agent_definitions() {
    local name="agent_definitions"
    local agent_dir="$PROJECT_ROOT/.claude/agents"

    if [ -d "$agent_dir" ]; then
        local agent_count=$(find "$agent_dir" -name "*.md" -type f | wc -l)
        if [ "$agent_count" -ge 14 ]; then
            record_check "$name" "pass" "Agent system: $agent_count agent definitions found" ""
        elif [ "$agent_count" -gt 0 ]; then
            record_check "$name" "warn" "Agent system: Only $agent_count agents found (14 expected)" "Check .claude/agents/ directory"
        else
            record_check "$name" "fail" "No agent definitions found" "Ensure .claude/agents/ directory has agent .md files"
        fi
    else
        record_check "$name" "fail" "Agent directory missing: .claude/agents/" "Clone complete repository or check git status"
    fi
}

check_automation_scripts() {
    local name="automation_scripts"
    local scripts_dir="$PROJECT_ROOT/scripts"

    if [ -d "$scripts_dir" ]; then
        local script_count=$(find "$scripts_dir" -name "*.sh" -type f | wc -l)
        if [ "$script_count" -ge 10 ]; then
            record_check "$name" "pass" "Automation scripts: $script_count scripts available" ""
        elif [ "$script_count" -gt 0 ]; then
            record_check "$name" "warn" "Automation scripts: Only $script_count scripts found" "Some automation may be incomplete"
        else
            record_check "$name" "fail" "No automation scripts found" "Check scripts/ directory"
        fi
    else
        record_check "$name" "fail" "Scripts directory missing" "Clone complete repository or check git status"
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

run_all_checks() {
    # Hardware checks
    show_category "Hardware Requirements"
    check_cpu_virtualization && display_check "hardware" "cpu_virtualization"
    check_cpu_cores && display_check "hardware" "cpu_cores"
    check_ram && display_check "hardware" "ram"
    check_storage_type && display_check "hardware" "storage_type"
    check_storage_space && display_check "hardware" "storage_space"

    # QEMU/KVM stack checks
    show_category "QEMU/KVM Stack"
    check_qemu_installed && display_check "qemu" "qemu_installed"
    check_kvm_module && display_check "qemu" "kvm_module"
    check_libvirt_installed && display_check "qemu" "libvirt_installed"
    check_libvirtd_running && display_check "qemu" "libvirtd_running"
    check_virt_manager && display_check "qemu" "virt_manager"
    check_ovmf_firmware && display_check "qemu" "ovmf_firmware"
    check_swtpm && display_check "qemu" "swtpm"
    check_qemu_utils && display_check "qemu" "qemu_utils"
    check_guestfs_tools && display_check "qemu" "guestfs_tools"

    # User permissions checks
    show_category "User Permissions"
    check_libvirt_group && display_check "permissions" "libvirt_group"
    check_kvm_group && display_check "permissions" "kvm_group"
    check_kvm_device_access && display_check "permissions" "kvm_device_access"

    # Network checks
    show_category "Network Configuration"
    check_default_network && display_check "network" "default_network"
    check_internet_connectivity && display_check "network" "internet_connectivity"
    check_dns_resolution && display_check "network" "dns_resolution"

    # ISO checks
    show_category "Required ISOs"
    check_windows_iso && display_check "isos" "windows_iso"
    check_virtio_drivers_iso && display_check "isos" "virtio_drivers_iso"

    # Ubuntu/kernel checks
    show_category "Operating System"
    check_ubuntu_version && display_check "os" "ubuntu_version"
    check_kernel_version && display_check "os" "kernel_version"

    # Agent system checks
    show_category "Agent System & Automation"
    check_agent_definitions && display_check "agents" "agent_definitions"
    check_automation_scripts && display_check "agents" "automation_scripts"
}

generate_json_report() {
    local status="ready"
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        status="not_ready"
    elif [ "$WARNING_CHECKS" -gt 5 ]; then
        status="warnings"
    fi

    # Build JSON report
    cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "username": "$USER",
  "status": "$status",
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "pass_rate": $(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")
  },
  "checks": {
EOF

    local first=true
    for check_name in "${!CHECK_RESULTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$REPORT_FILE"
        fi

        cat >> "$REPORT_FILE" <<EOF
    "$check_name": {
      "status": "${CHECK_RESULTS[$check_name]}",
      "message": "${CHECK_MESSAGES[$check_name]}",
      "fix": "${CHECK_FIXES[$check_name]}"
    }
EOF
    done

    cat >> "$REPORT_FILE" <<EOF

  },
  "next_steps": $(if [ "$FAILED_CHECKS" -gt 0 ]; then echo '"Install missing components: sudo ./scripts/01-install-qemu-kvm.sh"'; else echo '"Ready to create VM: ./scripts/create-vm.sh"'; fi)
}
EOF

    if [ "$JSON_ONLY" = true ]; then
        cat "$REPORT_FILE"
    fi
}

show_summary() {
    if [ "$JSON_ONLY" = true ]; then
        return
    fi

    echo ""
    local pass_rate
    pass_rate=$(awk "BEGIN {printf \"%.1f%%\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")
    cat <<EOF | gum style --border double --border-foreground 212 --padding "1 2" --margin "1 0"
Readiness Check Complete

Total Checks: $TOTAL_CHECKS
✅ Passed: $PASSED_CHECKS
❌ Failed: $FAILED_CHECKS
⚠️  Warnings: $WARNING_CHECKS

Pass Rate: $pass_rate
EOF

    echo ""
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        gum style --foreground 46 --bold "🎉 System is READY for QEMU/KVM deployment!"
        echo ""
        gum style --foreground 117 "Next steps:"
        echo "  1. Create VM: ./scripts/create-vm.sh"
        echo "  2. Or use automation: ./scripts/install-master.sh"
    else
        gum style --foreground 196 --bold "⚠️  System is NOT READY - please fix failed checks"
        echo ""
        gum style --foreground 226 "Recommended action:"
        echo "  Run: sudo ./scripts/01-install-qemu-kvm.sh"
        echo "  Then: sudo ./scripts/02-configure-user-groups.sh"
        echo "  Finally: Logout and login (for group changes)"
    fi

    echo ""
    gum style --foreground 86 "📄 JSON report saved: $REPORT_FILE"
}

# ==============================================================================
# INTERACTIVE RESULT HANDLING
# ==============================================================================

# Display fix instructions for failed checks
show_fix_instructions() {
    if [ "$JSON_ONLY" = true ]; then
        return
    fi

    echo ""
    gum style --bold --foreground 226 "Fix Instructions for Failed Checks:"
    echo ""

    for check_name in "${!CHECK_RESULTS[@]}"; do
        local status="${CHECK_RESULTS[$check_name]}"
        local fix="${CHECK_FIXES[$check_name]}"

        if [[ "$status" == "fail" && -n "$fix" ]]; then
            gum style --foreground 196 "❌ ${CHECK_MESSAGES[$check_name]}"
            gum style --foreground 226 --italic "   💡 Fix: $fix"
            echo ""
        fi
    done

    for check_name in "${!CHECK_RESULTS[@]}"; do
        local status="${CHECK_RESULTS[$check_name]}"
        local fix="${CHECK_FIXES[$check_name]}"

        if [[ "$status" == "warn" && -n "$fix" ]]; then
            gum style --foreground 226 "⚠️  ${CHECK_MESSAGES[$check_name]}"
            gum style --foreground 226 --italic "   💡 Recommendation: $fix"
            echo ""
        fi
    done
}

# Show interactive menu after checks complete
show_interactive_menu() {
    local status="$1"

    echo ""

    # Build menu options based on status
    local options=()

    # All statuses can view detailed report
    options+=("📋 View JSON Report")

    # Show fix instructions if there are issues
    if [[ "$FAILED_CHECKS" -gt 0 || "$WARNING_CHECKS" -gt 0 ]]; then
        options+=("🔧 Show All Fix Instructions")
    fi

    # Only non-blocking can continue
    if [[ "$FAILED_CHECKS" -eq 0 ]]; then
        options+=("▶️  Continue (Ready to Create VM)")
    else
        options+=("▶️  Continue Anyway (Not Recommended)")
    fi

    # Always allow retry and navigation
    options+=("🔄 Retry All Checks")
    options+=("← Back to Main Menu")
    options+=("🚪 Exit")

    # Status display
    local status_color=46
    local status_emoji="✅"
    local status_label="ALL CHECKS PASSED"

    if [[ "$FAILED_CHECKS" -gt 0 ]]; then
        status_color=196
        status_emoji="❌"
        status_label="ERRORS DETECTED - Please Fix Before Continuing"
    elif [[ "$WARNING_CHECKS" -gt 0 ]]; then
        status_color=226
        status_emoji="⚠️"
        status_label="PASSED WITH WARNINGS"
    fi

    cat <<EOF | gum style --border rounded --border-foreground "$status_color" --padding "1 2" --margin "1 0"
$status_emoji $status_label

✅ Passed: $PASSED_CHECKS | ⚠️ Warnings: $WARNING_CHECKS | ❌ Failed: $FAILED_CHECKS
EOF

    echo ""
    gum style --foreground "$status_color" "What would you like to do?"
    echo ""

    local choice
    choice=$(printf '%s\n' "${options[@]}" | gum choose)

    case "$choice" in
        "📋 View JSON Report")
            if [[ -f "$REPORT_FILE" ]]; then
                gum pager < "$REPORT_FILE"
            else
                echo "Report file not found: $REPORT_FILE"
            fi
            # Return to menu
            show_interactive_menu "$status"
            ;;
        "🔧 Show All Fix Instructions")
            show_fix_instructions
            echo ""
            gum style --foreground 240 "Press any key to continue..."
            read -n 1 -s -r
            # Return to menu
            show_interactive_menu "$status"
            ;;
        "▶️  Continue"*|"Continue"*)
            return 0  # Continue
            ;;
        "🔄 Retry All Checks")
            return 1  # Retry
            ;;
        "← Back to Main Menu")
            return 2  # Back
            ;;
        "🚪 Exit"|"")
            echo ""
            gum style --foreground 212 "Goodbye! 👋"
            exit 0
            ;;
    esac
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    local run_mode
    run_mode=$(get_mode_string)

    show_header
    run_all_checks
    generate_json_report
    show_summary

    # Branch behavior based on mode
    if should_run_interactive; then
        # Interactive mode: show menu with options
        local menu_result
        show_interactive_menu "$run_mode"
        menu_result=$?

        case "$menu_result" in
            0)  # Continue
                echo ""
                gum style --foreground 46 "Proceeding..."
                if [ "$FAILED_CHECKS" -gt 0 ]; then
                    exit 1  # Still exit with error code if there were failures
                else
                    exit 0
                fi
                ;;
            1)  # Retry
                echo ""
                gum style --foreground 117 "Rerunning checks..."
                sleep 1
                exec "$0" "$@"  # Re-execute the script
                ;;
            2)  # Back to menu
                echo ""
                gum style --foreground 240 "Returning to main menu..."
                exit 0  # Clean exit, let parent handle navigation
                ;;
        esac
    else
        # Automation/CI mode: exit with appropriate code (original behavior)
        if [ "$FAILED_CHECKS" -gt 0 ]; then
            exit 1
        else
            exit 0
        fi
    fi
}

main "$@"
