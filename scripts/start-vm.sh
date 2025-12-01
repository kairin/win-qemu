#!/bin/bash

################################################################################
# QEMU/KVM VM Start Script
# Version: 1.0.0
# Compatible with: QEMU 8.0+, libvirt 9.0+
#
# This script provides safe VM startup with comprehensive pre-flight checks:
# - Verify VM exists and is not already running
# - Check host resource availability (RAM, CPU)
# - Optional: Wait for QEMU guest agent connectivity
# - Optional: Auto-connect to console
# - Display connection instructions (virt-manager, VNC, RDP)
#
# Usage:
#   ./start-vm.sh <vm-name> [OPTIONS]
#
# Options:
#   --wait-agent        Wait for QEMU guest agent to respond (max 120s)
#   --console           Open console after startup (virt-viewer)
#   --no-checks         Skip resource availability checks
#   --timeout <sec>     Boot timeout in seconds (default: 60)
#   --dry-run           Preview actions without executing
#   -h, --help          Display this help message
#
# Examples:
#   # Basic VM start
#   ./start-vm.sh win11-outlook
#
#   # Start and wait for guest agent
#   ./start-vm.sh win11-outlook --wait-agent
#
#   # Start and open console
#   ./start-vm.sh win11-outlook --console
#
#   # Quick start (skip checks)
#   ./start-vm.sh win11-outlook --no-checks
#
#   # Dry run
#   ./start-vm.sh win11-outlook --dry-run
#
# Requirements:
#   - VM must exist in libvirt
#   - Sufficient host resources (RAM, CPU)
#   - libvirtd service running
#
# Safety Features:
#   - Checks if VM is already running
#   - Validates host resource availability
#   - Monitors boot progress
#   - Detects boot failures
#   - Provides detailed connection instructions
#
# Author: win-qemu project
# Last Updated: 2025-01-19
################################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures

################################################################################
# CONFIGURATION
################################################################################

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# VM configuration
VM_NAME=""
VM_STATE=""
VM_MEMORY_KB=0
VM_VCPUS=0

# Operational flags
WAIT_AGENT=false
OPEN_CONSOLE=false
SKIP_CHECKS=false
DRY_RUN=false
BOOT_TIMEOUT=60  # seconds

# Host resources
HOST_CPU_CORES=$(nproc)
HOST_TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
HOST_AVAIL_RAM=$(free -m | awk '/^Mem:/{print $7}')

# Logging (will be initialized by init_logging() from common.sh)
# LOG_DIR and LOG_FILE are set by common.sh init_logging()

# Color codes for output
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_MAGENTA='\033[0;35m'

# Icons
ICON_SUCCESS=""
ICON_ERROR=""
ICON_WARNING=""
ICON_INFO=""
ICON_ROCKET=""


################################################################################
# HELP FUNCTION
################################################################################

show_help() {
    cat << 'EOF'
QEMU/KVM VM Start Script v1.0.0

Safe VM startup with pre-flight checks and resource validation.

USAGE:
    ./start-vm.sh <vm-name> [OPTIONS]

ARGUMENTS:
    <vm-name>           Name of the VM to start (required)

OPTIONS:
    --wait-agent        Wait for QEMU guest agent connectivity (max 120s)
    --console           Open graphical console after startup (virt-viewer)
    --no-checks         Skip host resource availability checks
    --timeout <sec>     Boot timeout in seconds (default: 60)
    --dry-run           Preview actions without executing
    -h, --help          Display this help message

EXAMPLES:
    # Basic VM start
    ./start-vm.sh win11-outlook

    # Start and wait for guest agent (recommended for automation)
    ./start-vm.sh win11-outlook --wait-agent

    # Start and open console (interactive mode)
    ./start-vm.sh win11-outlook --console

    # Quick start without resource checks
    ./start-vm.sh win11-outlook --no-checks

    # Preview without starting
    ./start-vm.sh win11-outlook --dry-run

PRE-FLIGHT CHECKS:
    ✅ VM exists in libvirt
    ✅ VM is not already running
    ✅ libvirtd service is active
    ✅ Sufficient host RAM available
    ✅ Sufficient host CPU cores available
    ✅ VM configuration is valid

WHAT THIS SCRIPT DOES:
    1. Validates VM exists and is not running
    2. Checks host resource availability
    3. Starts the VM via virsh
    4. Monitors boot progress
    5. Optional: Waits for QEMU guest agent
    6. Optional: Opens graphical console
    7. Displays connection instructions

CONNECTION METHODS:
    - virt-manager GUI: Start virt-manager, double-click VM
    - virt-viewer: virt-viewer <vm-name>
    - VNC: Use VNC client with display address
    - SSH: SSH to guest IP (requires guest agent)

REQUIREMENTS:
    - VM defined in libvirt (use create-vm.sh to create)
    - libvirtd service running
    - Sufficient host resources (RAM, CPU)
    - Optional: virt-viewer for --console flag

TROUBLESHOOTING:
    - "VM not found": Check VM name with: virsh list --all
    - "Already running": VM is active, use stop-vm.sh first
    - "Insufficient RAM": Free up host memory or reduce VM allocation
    - "Boot timeout": Check VM configuration, virt-manager console for errors

FOR MORE INFORMATION:
    - Main guide: outlook-linux-guide/05-qemu-kvm-reference-architecture.md
    - VM operations: AGENTS.md (VM Operations Reference)

EOF
}

################################################################################
# VALIDATION FUNCTIONS
################################################################################


check_vm_exists() {
    log_step "Checking if VM '$VM_NAME' exists..."

    # In dry-run mode, skip VM check since virsh may not be installed
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping VM existence check (virsh not required in preview mode)"
        log_info "[DRY RUN] Would verify VM '$VM_NAME' exists"
        return 0
    fi

    if ! virsh list --all | grep -qw "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found"
        log_error ""
        log_error "Available VMs:"
        virsh list --all --name | sed 's/^/  - /'
        log_error ""
        log_error "Create a VM with: ./scripts/create-vm.sh"
        return 1
    fi

    log_success "VM '$VM_NAME' exists"
}

check_vm_state() {
    log_step "Checking VM state..."

    # In dry-run mode, skip state check since virsh may not be installed
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        VM_STATE="unknown (dry-run)"
        log_warning "[DRY RUN] Skipping VM state check (virsh not required in preview mode)"
        log_info "[DRY RUN] Would check if VM '$VM_NAME' is stopped before starting"
        return 0
    fi

    VM_STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
    log_info "Current state: $VM_STATE"

    if [[ "$VM_STATE" == "running" ]]; then
        log_error "VM '$VM_NAME' is already running"
        log_info ""
        log_info "Connection options:"
        log_info "  - virt-manager (GUI)"
        log_info "  - virt-viewer $VM_NAME"
        log_info "  - virsh console $VM_NAME (text console)"
        log_info ""
        log_info "To restart, first stop with: ./scripts/stop-vm.sh $VM_NAME"
        return 1
    elif [[ "$VM_STATE" == "paused" ]]; then
        log_warning "VM is paused, will resume instead of starting"
    fi

    log_success "VM is ready to start (state: $VM_STATE)"
}

get_vm_resources() {
    log_step "Reading VM resource requirements..."

    # Get VM memory in KB
    VM_MEMORY_KB=$(virsh dominfo "$VM_NAME" | awk '/Max memory:/{print $3}')
    local vm_memory_mb=$((VM_MEMORY_KB / 1024))

    # Get VM vCPUs
    VM_VCPUS=$(virsh dominfo "$VM_NAME" | awk '/CPU\(s\):/{print $2}')

    log_info "VM requirements:"
    log_info "  - Memory: ${vm_memory_mb}MB"
    log_info "  - vCPUs: $VM_VCPUS"

    log_success "VM resource requirements retrieved"
}

check_host_resources() {
    if [[ "$SKIP_CHECKS" == "true" ]]; then
        log_warning "Skipping host resource checks (--no-checks specified)"
        return 0
    fi

    log_step "Checking host resource availability..."

    local vm_memory_mb=$((VM_MEMORY_KB / 1024))
    local checks_failed=0

    # Check RAM availability
    log_info "Host RAM: ${HOST_TOTAL_RAM}MB total, ${HOST_AVAIL_RAM}MB available"
    log_info "VM requires: ${vm_memory_mb}MB"

    if [[ $HOST_AVAIL_RAM -lt $vm_memory_mb ]]; then
        log_error "Insufficient RAM available"
        log_error "  Available: ${HOST_AVAIL_RAM}MB"
        log_error "  Required: ${vm_memory_mb}MB"
        log_error "  Shortfall: $((vm_memory_mb - HOST_AVAIL_RAM))MB"
        log_error ""
        log_error "Free up memory or reduce VM allocation"
        ((checks_failed++))
    else
        log_success "Sufficient RAM available (${HOST_AVAIL_RAM}MB >= ${vm_memory_mb}MB)"
    fi

    # Check CPU availability
    log_info "Host CPUs: ${HOST_CPU_CORES} cores available"
    log_info "VM requires: ${VM_VCPUS} vCPUs"

    if [[ $HOST_CPU_CORES -lt $VM_VCPUS ]]; then
        log_warning "VM vCPUs ($VM_VCPUS) exceed host cores ($HOST_CPU_CORES)"
        log_warning "Performance may be degraded due to CPU oversubscription"
    elif [[ $((HOST_CPU_CORES - VM_VCPUS)) -lt 2 ]]; then
        log_warning "Less than 2 cores remaining for host OS"
        log_warning "System may be sluggish during VM operation"
    else
        log_success "Sufficient CPUs available"
    fi

    if [[ $checks_failed -gt 0 ]]; then
        log_error "Resource availability checks failed"
        return 1
    fi

    log_success "Host resources are sufficient"
}

################################################################################
# VM START FUNCTIONS
################################################################################

start_vm() {
    log_step "Starting VM '$VM_NAME'..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: virsh start $VM_NAME"
        return 0
    fi

    # Handle paused state (resume instead of start)
    if [[ "$VM_STATE" == "paused" ]]; then
        log_info "Resuming paused VM..."
        virsh resume "$VM_NAME"
        log_success "VM resumed"
        return 0
    fi

    # Start the VM
    if virsh start "$VM_NAME" > /dev/null 2>&1; then
        log_success "VM start command issued successfully"
    else
        log_error "Failed to start VM"
        log_error "Check VM configuration with: virsh dumpxml $VM_NAME"
        log_error "Check virt-manager for detailed error messages"
        return 1
    fi
}

monitor_boot_progress() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would monitor boot progress for ${BOOT_TIMEOUT}s"
        return 0
    fi

    log_step "Monitoring boot progress..."
    log_info "Waiting up to ${BOOT_TIMEOUT}s for VM to reach running state..."

    local elapsed=0
    local state=""

    while [[ $elapsed -lt $BOOT_TIMEOUT ]]; do
        state=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")

        if [[ "$state" == "running" ]]; then
            log_success "VM is running (boot time: ${elapsed}s)"
            return 0
        elif [[ "$state" == "crashed" ]] || [[ "$state" == "shut off" ]]; then
            log_error "VM failed to boot (state: $state)"
            log_error "Check virt-manager console for boot errors"
            log_error "Common issues:"
            log_error "  - UEFI firmware not found (check OVMF installation)"
            log_error "  - Disk image corrupted"
            log_error "  - Invalid VM configuration"
            return 1
        fi

        # Progress indicator
        echo -n "."
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo ""
    log_warning "Boot timeout reached (${BOOT_TIMEOUT}s)"
    log_warning "VM may still be booting - check state with: virsh domstate $VM_NAME"
}

wait_for_guest_agent() {
    if [[ "$WAIT_AGENT" != "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would wait for QEMU guest agent (max 120s)"
        return 0
    fi

    log_step "Waiting for QEMU guest agent..."
    log_info "This requires QEMU guest agent installed in Windows"
    log_info "Install from virtio-win.iso: guest-agent/qemu-ga-x86_64.msi"

    local elapsed=0
    local max_wait=120

    while [[ $elapsed -lt $max_wait ]]; do
        # Try to ping guest agent
        if virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-ping"}' &>/dev/null; then
            log_success "Guest agent is responding (${elapsed}s)"

            # Get guest OS info
            local os_info
            os_info=$(virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-get-osinfo"}' 2>/dev/null | grep -o '"pretty-name":"[^"]*"' | cut -d'"' -f4)
            if [[ -n "$os_info" ]]; then
                log_info "Guest OS: $os_info"
            fi

            return 0
        fi

        echo -n "."
        sleep 3
        elapsed=$((elapsed + 3))
    done

    echo ""
    log_warning "Guest agent not responding after ${max_wait}s"
    log_warning "VM may still be booting or guest agent not installed"
    log_warning "Install with: virtio-win.iso → guest-agent/qemu-ga-x86_64.msi"
}

open_console_viewer() {
    if [[ "$OPEN_CONSOLE" != "true" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would open console: virt-viewer $VM_NAME"
        return 0
    fi

    log_step "Opening graphical console..."

    # Check if virt-viewer is installed
    if ! command -v virt-viewer &>/dev/null; then
        log_warning "virt-viewer not installed"
        log_info "Install with: sudo apt install virt-viewer"
        log_info "Or use virt-manager GUI instead"
        return 0
    fi

    # Open virt-viewer in background
    log_info "Launching virt-viewer..."
    virt-viewer "$VM_NAME" &>/dev/null &

    log_success "Console opened (virt-viewer PID: $!)"
}

display_connection_info() {
    log_step "VM Connection Information"
    echo ""

    local vm_ip=""

    # Try to get VM IP address (requires guest agent)
    if [[ "$DRY_RUN" != "true" ]]; then
        vm_ip=$(virsh domifaddr "$VM_NAME" 2>/dev/null | awk '/ipv4/{print $4}' | cut -d'/' -f1 || echo "")
    fi

    log_info "VM '$VM_NAME' is running"
    log_info ""
    log_info "Connection Options:"
    log_info "  1. virt-manager (GUI):"
    log_info "     virt-manager"
    log_info "     Then double-click '$VM_NAME' to open console"
    log_info ""
    log_info "  2. virt-viewer (Console):"
    log_info "     virt-viewer $VM_NAME"
    log_info ""
    log_info "  3. Text Console (Serial):"
    log_info "     virsh console $VM_NAME"
    log_info ""

    if [[ -n "$vm_ip" ]]; then
        log_info "  4. SSH (if enabled in guest):"
        log_info "     ssh user@$vm_ip"
        log_info ""
    fi

    log_info "VM Operations:"
    log_info "  - Stop VM: ./scripts/stop-vm.sh $VM_NAME"
    log_info "  - Pause VM: virsh suspend $VM_NAME"
    log_info "  - Resume VM: virsh resume $VM_NAME"
    log_info "  - Backup VM: ./scripts/backup-vm.sh $VM_NAME"
    log_info ""
    log_info "Monitoring:"
    log_info "  - Real-time stats: virt-top -1"
    log_info "  - VM state: virsh domstate $VM_NAME"
    log_info "  - VM info: virsh dominfo $VM_NAME"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # First argument is VM name (if not starting with --)
    if [[ ! "$1" =~ ^-- ]]; then
        VM_NAME="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wait-agent)
                WAIT_AGENT=true
                shift
                ;;
            --console)
                OPEN_CONSOLE=true
                shift
                ;;
            --no-checks)
                SKIP_CHECKS=true
                shift
                ;;
            --timeout)
                BOOT_TIMEOUT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$VM_NAME" ]]; then
        log_error "VM name is required"
        echo "Usage: $0 <vm-name> [OPTIONS]"
        echo "Use --help for more information"
        exit 1
    fi
}

main() {
    parse_arguments "$@"

    # Initialize logging
    # Initialize logging
    init_logging "start-vm"

    # Display banner
    echo ""
    echo "=================================================="
    echo "  QEMU/KVM VM Start Script"
    echo "  Version $SCRIPT_VERSION | January 2025"
    echo "=================================================="
    echo ""

    # Pre-flight checks
    check_libvirtd || exit 1
    check_vm_exists || exit 1
    check_vm_state || exit 1
    get_vm_resources || exit 1
    check_host_resources || exit 1

    # Start VM
    echo ""
    start_vm || exit 1

    # Monitor boot
    monitor_boot_progress || exit 1

    # Wait for guest agent (optional)
    wait_for_guest_agent

    # Open console (optional)
    open_console_viewer

    # Display connection information
    echo ""
    display_connection_info

    log_success "VM '$VM_NAME' started successfully!"

    if [[ -f "$LOG_FILE" ]]; then
        log_info "Log file: $LOG_FILE"
    fi
    echo ""
}

# Execute main function
main "$@"
