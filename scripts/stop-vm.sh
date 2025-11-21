#!/bin/bash

################################################################################
# QEMU/KVM VM Stop Script
# Version: 1.0.0
# Compatible with: QEMU 8.0+, libvirt 9.0+
#
# This script provides graceful VM shutdown with safety features:
# - Attempt graceful shutdown via ACPI signal (like pressing power button)
# - Fallback to force shutdown after configurable timeout
# - Optional: Create snapshot before shutdown
# - Safety checks to prevent accidental data loss
# - Post-shutdown verification
#
# Usage:
#   ./stop-vm.sh <vm-name> [OPTIONS]
#
# Options:
#   --force             Force immediate shutdown (no graceful attempt)
#   --timeout <sec>     Graceful shutdown timeout (default: 60)
#   --snapshot          Create snapshot before shutdown
#   --snapshot-name <n> Custom snapshot name (default: pre-shutdown-TIMESTAMP)
#   --no-confirm        Skip confirmation prompts
#   --dry-run           Preview actions without executing
#   -h, --help          Display this help message
#
# Examples:
#   # Graceful shutdown (60s timeout)
#   ./stop-vm.sh win11-outlook
#
#   # Graceful shutdown with 120s timeout
#   ./stop-vm.sh win11-outlook --timeout 120
#
#   # Force immediate shutdown
#   ./stop-vm.sh win11-outlook --force
#
#   # Snapshot before shutdown
#   ./stop-vm.sh win11-outlook --snapshot
#
#   # Automated shutdown (no prompts)
#   ./stop-vm.sh win11-outlook --no-confirm
#
#   # Dry run
#   ./stop-vm.sh win11-outlook --dry-run
#
# Requirements:
#   - VM must exist in libvirt
#   - VM must be running or paused
#   - QEMU guest agent (recommended for graceful shutdown)
#
# Safety Features:
#   - Graceful shutdown attempt before forcing
#   - Configurable timeout for shutdown
#   - Optional snapshot before shutdown
#   - Verification of shutdown completion
#   - Warning about unsaved work
#
# Shutdown Methods:
#   1. GRACEFUL: Sends ACPI power signal (like pressing power button)
#      - Windows will save work and shut down cleanly
#      - Recommended method to prevent data corruption
#      - Requires guest OS to respond to ACPI signals
#
#   2. FORCE: Immediate power-off (like unplugging power cord)
#      - Use only if graceful shutdown fails
#      - Risk of data corruption and file system damage
#      - Last resort option
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

# Operational flags
FORCE_SHUTDOWN=false
CREATE_SNAPSHOT=false
SNAPSHOT_NAME=""
SKIP_CONFIRM=false
DRY_RUN=false
SHUTDOWN_TIMEOUT=60  # seconds

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
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️ "
ICON_INFO="ℹ️ "
ICON_ROCKET="🚀"


confirm() {
    if [[ "$SKIP_CONFIRM" == "true" ]]; then
        return 0
    fi

    local prompt="$1"
    local response
    read -r -p "$(echo -e "${COLOR_YELLOW}[CONFIRM]${COLOR_RESET} ${prompt} (y/N): ")" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

################################################################################
# HELP FUNCTION
################################################################################

show_help() {
    cat << 'EOF'
QEMU/KVM VM Stop Script v1.0.0

Graceful VM shutdown with safety features and optional snapshot creation.

USAGE:
    ./stop-vm.sh <vm-name> [OPTIONS]

ARGUMENTS:
    <vm-name>           Name of the VM to stop (required)

OPTIONS:
    --force             Force immediate shutdown (skip graceful attempt)
    --timeout <sec>     Graceful shutdown timeout in seconds (default: 60)
    --snapshot          Create snapshot before shutdown
    --snapshot-name <n> Custom snapshot name (auto-generated if not specified)
    --no-confirm        Skip confirmation prompts (for automation)
    --dry-run           Preview actions without executing
    -h, --help          Display this help message

EXAMPLES:
    # Graceful shutdown (recommended)
    ./stop-vm.sh win11-outlook

    # Graceful with extended timeout (120 seconds)
    ./stop-vm.sh win11-outlook --timeout 120

    # Force immediate shutdown (use with caution)
    ./stop-vm.sh win11-outlook --force

    # Create snapshot before shutdown
    ./stop-vm.sh win11-outlook --snapshot

    # Automated shutdown with custom snapshot
    ./stop-vm.sh win11-outlook --snapshot --snapshot-name backup-before-update --no-confirm

    # Preview without executing
    ./stop-vm.sh win11-outlook --dry-run

SHUTDOWN METHODS:

    GRACEFUL SHUTDOWN (Default):
        - Sends ACPI power button signal to guest OS
        - Windows saves all work and shuts down cleanly
        - Recommended to prevent data corruption
        - Waits up to timeout seconds for clean shutdown
        - Falls back to force shutdown if timeout exceeded

    FORCE SHUTDOWN (--force):
        - Immediate power-off (equivalent to pulling the plug)
        - Risk of data corruption and file system damage
        - Use only when graceful shutdown fails
        - Windows may detect improper shutdown on next boot

PRE-SHUTDOWN CHECKS:
    ✅ VM exists in libvirt
    ✅ VM is running or paused
    ✅ Optional: Create snapshot for easy rollback

WHAT THIS SCRIPT DOES:
    1. Validates VM exists and is running
    2. Optional: Creates snapshot before shutdown
    3. Attempts graceful shutdown (ACPI signal)
    4. Monitors shutdown progress
    5. Falls back to force shutdown if timeout exceeded
    6. Verifies VM is fully stopped
    7. Displays post-shutdown information

SNAPSHOT BEHAVIOR:
    When --snapshot is specified:
    - Snapshot is created BEFORE shutdown
    - Snapshot name: pre-shutdown-YYYYMMDD-HHMMSS
    - Can be customized with --snapshot-name
    - Allows easy rollback if needed
    - Snapshot includes VM state (if running)

REQUIREMENTS:
    - VM defined in libvirt
    - VM must be running or paused
    - For graceful shutdown: ACPI support in guest OS
    - For snapshots: qcow2 disk format (not raw)

TROUBLESHOOTING:
    - "Graceful shutdown failed": Guest OS not responding to ACPI
      Solution: Check if guest agent is running, use --force
    - "Snapshot creation failed": Disk format may be raw (not qcow2)
      Solution: Convert to qcow2 or skip snapshot
    - "VM not running": VM is already stopped
      Solution: Check VM state with: virsh domstate <vm-name>

SAFETY WARNINGS:
    - Always save work in guest OS before stopping
    - Use --force only when necessary
    - Force shutdown may cause file system corruption
    - Create snapshots before risky operations

FOR MORE INFORMATION:
    - Main guide: outlook-linux-guide/05-qemu-kvm-reference-architecture.md
    - VM operations: AGENTS.md (VM Operations Reference)
    - Snapshot management: ./backup-vm.sh --help

EOF
}

################################################################################
# VALIDATION FUNCTIONS
################################################################################

check_vm_exists() {
    log_step "Checking if VM '$VM_NAME' exists..."

    if ! virsh list --all | grep -qw "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found"
        log_error ""
        log_error "Available VMs:"
        virsh list --all --name | sed 's/^/  - /'
        return 1
    fi

    log_success "VM '$VM_NAME' exists"
}

check_vm_state() {
    log_step "Checking VM state..."

    VM_STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
    log_info "Current state: $VM_STATE"

    if [[ "$VM_STATE" == "shut off" ]]; then
        log_warning "VM '$VM_NAME' is already stopped"
        log_info "VM state: $VM_STATE"
        log_info ""
        log_info "To start VM: ./scripts/start-vm.sh $VM_NAME"
        exit 0
    elif [[ "$VM_STATE" == "paused" ]]; then
        log_info "VM is paused, will resume and shut down"
    elif [[ "$VM_STATE" != "running" ]] && [[ "$VM_STATE" != "paused" ]]; then
        log_warning "VM is in unexpected state: $VM_STATE"
        if ! confirm "Proceed with shutdown anyway?"; then
            log_error "Shutdown cancelled by user"
            exit 1
        fi
    fi

    log_success "VM is active and can be stopped"
}

################################################################################
# SNAPSHOT FUNCTIONS
################################################################################

create_pre_shutdown_snapshot() {
    if [[ "$CREATE_SNAPSHOT" != "true" ]]; then
        return 0
    fi

    log_step "Creating pre-shutdown snapshot..."

    # Generate snapshot name if not specified
    if [[ -z "$SNAPSHOT_NAME" ]]; then
        SNAPSHOT_NAME="pre-shutdown-$(date +%Y%m%d-%H%M%S)"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create snapshot: $SNAPSHOT_NAME"
        return 0
    fi

    log_info "Snapshot name: $SNAPSHOT_NAME"
    log_info "Creating snapshot (this may take a few moments)..."

    # Create snapshot with description
    local description="Pre-shutdown snapshot created by stop-vm.sh on $(date)"

    if virsh snapshot-create-as "$VM_NAME" "$SNAPSHOT_NAME" "$description" --atomic 2>&1; then
        log_success "Snapshot created: $SNAPSHOT_NAME"
        log_info "Restore with: virsh snapshot-revert $VM_NAME $SNAPSHOT_NAME"
    else
        log_error "Failed to create snapshot"
        log_warning "This may occur if disk format is raw (snapshots require qcow2)"

        if confirm "Continue shutdown without snapshot?"; then
            log_warning "Proceeding without snapshot"
            CREATE_SNAPSHOT=false
        else
            log_error "Shutdown cancelled by user"
            exit 1
        fi
    fi
}

################################################################################
# SHUTDOWN FUNCTIONS
################################################################################

attempt_graceful_shutdown() {
    if [[ "$FORCE_SHUTDOWN" == "true" ]]; then
        log_warning "Skipping graceful shutdown (--force specified)"
        return 1
    fi

    log_step "Attempting graceful shutdown..."
    log_info "Sending ACPI power button signal to guest OS"
    log_info "This is equivalent to pressing the power button in Windows"
    log_info "Windows will save work and shut down cleanly"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: virsh shutdown $VM_NAME"
        return 0
    fi

    # Send ACPI shutdown signal
    if ! virsh shutdown "$VM_NAME" > /dev/null 2>&1; then
        log_error "Failed to send shutdown signal"
        return 1
    fi

    log_success "Shutdown signal sent to guest OS"
}

monitor_graceful_shutdown() {
    if [[ "$FORCE_SHUTDOWN" == "true" ]] || [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    log_step "Monitoring shutdown progress..."
    log_info "Waiting up to ${SHUTDOWN_TIMEOUT}s for graceful shutdown..."

    local elapsed=0
    local state=""

    while [[ $elapsed -lt $SHUTDOWN_TIMEOUT ]]; do
        state=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")

        if [[ "$state" == "shut off" ]]; then
            echo ""
            log_success "Graceful shutdown completed (${elapsed}s)"
            return 0
        fi

        # Progress indicator
        echo -n "."
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo ""
    log_warning "Graceful shutdown timeout reached (${SHUTDOWN_TIMEOUT}s)"
    log_warning "Guest OS did not shut down in time"
    return 1
}

force_shutdown() {
    log_step "Forcing VM shutdown..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: virsh destroy $VM_NAME"
        return 0
    fi

    log_warning "⚠️  FORCE SHUTDOWN WARNING ⚠️"
    log_warning "This is equivalent to pulling the power plug!"
    log_warning "Risk of data corruption and file system damage"
    log_warning ""

    if [[ "$SKIP_CONFIRM" != "true" ]]; then
        if ! confirm "Force shutdown VM '$VM_NAME'?"; then
            log_error "Force shutdown cancelled by user"
            log_info "VM is still running. Manual intervention required."
            log_info "Try: virsh shutdown $VM_NAME (graceful)"
            log_info "Or check guest OS from console"
            exit 1
        fi
    fi

    # Force shutdown (destroy)
    if virsh destroy "$VM_NAME" > /dev/null 2>&1; then
        log_success "Force shutdown completed"
    else
        log_error "Failed to force shutdown VM"
        log_error "Manual intervention required"
        log_error "Check VM state with: virsh domstate $VM_NAME"
        exit 1
    fi
}

verify_shutdown() {
    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    log_step "Verifying shutdown..."

    local state
    state=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")

    if [[ "$state" == "shut off" ]]; then
        log_success "VM is fully stopped"
        log_info "VM state: $state"
    else
        log_error "VM did not shut down properly"
        log_error "Current state: $state"
        log_error "Manual intervention required"
        return 1
    fi
}

################################################################################
# POST-SHUTDOWN INFORMATION
################################################################################

display_post_shutdown_info() {
    log_step "Post-Shutdown Information"
    echo ""

    log_info "VM '$VM_NAME' has been stopped"
    log_info ""
    log_info "Next Steps:"
    log_info "  - Start VM: ./scripts/start-vm.sh $VM_NAME"
    log_info "  - Edit configuration: virsh edit $VM_NAME"
    log_info "  - View VM info: virsh dominfo $VM_NAME"

    if [[ "$CREATE_SNAPSHOT" == "true" ]] && [[ -n "$SNAPSHOT_NAME" ]]; then
        log_info ""
        log_info "Snapshot Information:"
        log_info "  - Snapshot name: $SNAPSHOT_NAME"
        log_info "  - Restore with: virsh snapshot-revert $VM_NAME $SNAPSHOT_NAME"
        log_info "  - List snapshots: virsh snapshot-list $VM_NAME"
        log_info "  - Delete snapshot: virsh snapshot-delete $VM_NAME $SNAPSHOT_NAME"
    fi

    echo ""
    log_info "VM Management:"
    log_info "  - Backup VM: ./scripts/backup-vm.sh $VM_NAME"
    log_info "  - List all VMs: virsh list --all"
    log_info "  - VM disk usage: du -h /var/lib/libvirt/images/${VM_NAME}.qcow2"
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
            --force)
                FORCE_SHUTDOWN=true
                shift
                ;;
            --timeout)
                SHUTDOWN_TIMEOUT="$2"
                shift 2
                ;;
            --snapshot)
                CREATE_SNAPSHOT=true
                shift
                ;;
            --snapshot-name)
                SNAPSHOT_NAME="$2"
                CREATE_SNAPSHOT=true
                shift 2
                ;;
            --no-confirm)
                SKIP_CONFIRM=true
                shift
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
    init_logging "stop-vm"

    # Display banner
    echo ""
    echo "=================================================="
    echo "  QEMU/KVM VM Stop Script"
    echo "  Version $SCRIPT_VERSION | January 2025"
    echo "=================================================="
    echo ""

    # Pre-shutdown checks
    check_vm_exists || exit 1
    check_vm_state

    # Create snapshot if requested
    create_pre_shutdown_snapshot

    # Shutdown workflow
    echo ""
    if [[ "$FORCE_SHUTDOWN" == "true" ]]; then
        # Direct force shutdown
        force_shutdown || exit 1
    else
        # Try graceful, fallback to force
        if attempt_graceful_shutdown; then
            if monitor_graceful_shutdown; then
                # Graceful shutdown succeeded
                :
            else
                # Graceful shutdown timed out
                log_warning "Graceful shutdown failed, falling back to force shutdown"
                force_shutdown || exit 1
            fi
        else
            # Graceful shutdown signal failed
            log_warning "Graceful shutdown signal failed, using force shutdown"
            force_shutdown || exit 1
        fi
    fi

    # Verify shutdown completed
    verify_shutdown || exit 1

    # Display post-shutdown information
    echo ""
    display_post_shutdown_info

    log_success "VM '$VM_NAME' stopped successfully!"

    if [[ -f "$LOG_FILE" ]]; then
        log_info "Log file: $LOG_FILE"
    fi
    echo ""
}

# Execute main function
main "$@"
