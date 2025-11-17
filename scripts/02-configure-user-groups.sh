#!/bin/bash
#
# 02-configure-user-groups.sh - User Group Configuration for QEMU/KVM
#
# Purpose: Add user to libvirt and kvm groups for VM management
# Requirements: QEMU/KVM installed (01-install-qemu-kvm.sh completed)
# Duration: < 5 seconds
# Idempotent: Safe to run multiple times
#
# Usage:
#   sudo ./scripts/02-configure-user-groups.sh [username]
#
#   If no username provided, uses $SUDO_USER (the user who ran sudo)
#
# Output:
#   - Log: .installation-state/user-groups-YYYYMMDD-HHMMSS.log
#   - State: .installation-state/user-groups-configured.json
#
# IMPORTANT: After running this script, you MUST:
#   1. Log out and log back in OR
#   2. Reboot the system
#   Group membership changes only take effect after new login session.
#
# Author: AI-assisted (Claude Code)
# Created: 2025-11-17
# Version: 1.0
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_DIR="${PROJECT_ROOT}/.installation-state"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${STATE_DIR}/user-groups-${TIMESTAMP}.log"
STATE_FILE="${STATE_DIR}/user-groups-configured.json"

# Determine target user
if [[ $# -ge 1 ]]; then
    TARGET_USER="$1"
elif [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
else
    echo "ERROR: Could not determine target user"
    echo "Usage: sudo $0 [username]"
    exit 1
fi

# Groups to add user to
REQUIRED_GROUPS=(
    libvirt  # VM management permissions
    kvm      # Hardware virtualization access
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

init_logging() {
    mkdir -p "$STATE_DIR"

    echo "# User Group Configuration Log" > "$LOG_FILE"
    echo "# Started: $(date +'%Y-%m-%d %H:%M:%S %Z')" >> "$LOG_FILE"
    echo "# Hostname: $(hostname)" >> "$LOG_FILE"
    echo "# Target user: $TARGET_USER" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"

    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} ${message}" ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} ${message}" ;;
        CMD)     echo -e "${YELLOW}[CMD]${NC} ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

run_logged() {
    local cmd="$*"
    log CMD "$cmd"

    if output=$($cmd 2>&1); then
        echo "$output" >> "$LOG_FILE"
        return 0
    else
        local exit_code=$?
        echo "$output" >> "$LOG_FILE"
        log ERROR "Command failed with exit code $exit_code"
        return $exit_code
    fi
}

# ==============================================================================
# PRE-CHECKS
# ==============================================================================

preflight_checks() {
    log INFO "Starting pre-flight checks"

    # Check if running as root/sudo
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run with sudo"
        log ERROR "Usage: sudo $0 [username]"
        exit 1
    fi

    # Check if target user exists
    if ! id "$TARGET_USER" &>/dev/null; then
        log ERROR "User '$TARGET_USER' does not exist"
        exit 1
    fi
    log SUCCESS "User '$TARGET_USER' exists"

    # Check if libvirt group exists (indicates QEMU/KVM installed)
    if ! getent group libvirt &>/dev/null; then
        log ERROR "Group 'libvirt' does not exist"
        log ERROR "Please install QEMU/KVM first: ./scripts/01-install-qemu-kvm.sh"
        exit 1
    fi
    log SUCCESS "Group 'libvirt' exists"

    # Check if kvm group exists
    if ! getent group kvm &>/dev/null; then
        log ERROR "Group 'kvm' does not exist"
        log ERROR "Please install QEMU/KVM first: ./scripts/01-install-qemu-kvm.sh"
        exit 1
    fi
    log SUCCESS "Group 'kvm' exists"

    log SUCCESS "All pre-flight checks passed"
}

# ==============================================================================
# GROUP MEMBERSHIP CONFIGURATION
# ==============================================================================

check_current_groups() {
    log INFO "Checking current group membership for user '$TARGET_USER'"

    local user_groups=$(id -nG "$TARGET_USER")
    log INFO "Current groups: $user_groups"

    # Check if already in required groups
    local already_configured=true
    for group in "${REQUIRED_GROUPS[@]}"; do
        if echo "$user_groups" | grep -qw "$group"; then
            log SUCCESS "User already in group '$group'"
        else
            already_configured=false
        fi
    done

    if $already_configured; then
        log SUCCESS "User already in all required groups"
        log INFO "Skipping group addition (idempotent behavior)"

        # Still save state file
        save_configuration_state

        echo ""
        log SUCCESS "Group configuration verification complete"
        log WARN "If groups were recently added, you MUST log out and back in for changes to take effect"

        exit 0
    fi
}

add_user_to_groups() {
    log INFO "Adding user '$TARGET_USER' to required groups"

    local groups_added=()
    local groups_failed=()

    for group in "${REQUIRED_GROUPS[@]}"; do
        log INFO "Adding user to group '$group'"

        if run_logged usermod -aG "$group" "$TARGET_USER"; then
            log SUCCESS "Added user to group '$group'"
            groups_added+=("$group")
        else
            log ERROR "Failed to add user to group '$group'"
            groups_failed+=("$group")
        fi
    done

    # Report results
    if [[ ${#groups_failed[@]} -gt 0 ]]; then
        log ERROR "Failed to add user to some groups: ${groups_failed[*]}"
        exit 1
    fi

    log SUCCESS "User added to all required groups: ${groups_added[*]}"
}

verify_group_membership() {
    log INFO "Verifying group membership"

    local user_groups=$(id -nG "$TARGET_USER")
    local verification_failed=false

    for group in "${REQUIRED_GROUPS[@]}"; do
        if echo "$user_groups" | grep -qw "$group"; then
            log SUCCESS "Verified: User in group '$group'"
        else
            log ERROR "Verification failed: User NOT in group '$group'"
            verification_failed=true
        fi
    done

    if $verification_failed; then
        log ERROR "Group membership verification failed"
        exit 1
    fi

    log SUCCESS "All group memberships verified"
}

# ==============================================================================
# STATE MANAGEMENT
# ==============================================================================

save_configuration_state() {
    log INFO "Saving configuration state"

    local user_groups=$(id -nG "$TARGET_USER")

    cat > "$STATE_FILE" <<EOF
{
    "configuration_date": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "target_user": "$TARGET_USER",
    "groups_configured": [
        $(for group in "${REQUIRED_GROUPS[@]}"; do
            echo "\"$group\""
        done | paste -sd, -)
    ],
    "current_groups": [
        $(echo "$user_groups" | tr ' ' '\n' | awk '{print "\"" $0 "\""}' | paste -sd, -)
    ],
    "reboot_required": true,
    "log_file": "$LOG_FILE"
}
EOF

    log SUCCESS "Configuration state saved to: $STATE_FILE"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    echo "======================================================================"
    echo "  User Group Configuration for QEMU/KVM"
    echo "  Target User: $TARGET_USER"
    echo "======================================================================"
    echo ""

    init_logging

    log INFO "Configuring user group membership for QEMU/KVM access"
    log INFO "Log file: $LOG_FILE"
    echo ""

    preflight_checks
    echo ""

    check_current_groups
    echo ""

    add_user_to_groups
    echo ""

    verify_group_membership
    echo ""

    save_configuration_state
    echo ""

    echo "======================================================================"
    log SUCCESS "User group configuration complete!"
    echo "======================================================================"
    echo ""
    log INFO "Configuration summary:"
    log INFO "  - User: $TARGET_USER"
    log INFO "  - Groups added: ${REQUIRED_GROUPS[*]}"
    log INFO "  - Log file: $LOG_FILE"
    log INFO "  - State file: $STATE_FILE"
    echo ""
    log WARN "CRITICAL: Group membership changes require logout/login to take effect"
    echo ""
    log INFO "Next steps:"
    log INFO "  1. Log out and log back in OR reboot your system"
    log INFO "  2. Verify groups active: groups | grep libvirt"
    log INFO "  3. Run verification script: ./scripts/03-verify-installation.sh"
    log INFO "  4. Create Windows 11 VM: ./scripts/04-create-vm.sh"
    echo ""
    echo "======================================================================"
}

main "$@"
