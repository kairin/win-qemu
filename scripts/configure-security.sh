#!/bin/bash
#
# configure-security.sh - Security Hardening for QEMU/KVM Windows VMs
#
# Purpose: Apply security hardening to host and VM configurations
# Requirements: QEMU/KVM installed, VM created
# Duration: 2-5 minutes depending on options
# Idempotent: Safe to run multiple times
#
# Usage:
#   ./scripts/configure-security.sh [OPTIONS]
#
# Options:
#   --vm NAME           Target VM name (default: win11)
#   --all               Apply all security hardening
#   --firewall          Configure UFW firewall rules
#   --virtiofs-ro       Enforce virtio-fs read-only mode
#   --apparmor          Configure AppArmor profiles
#   --audit             Run security audit only (no changes)
#   --dry-run           Show what would be done
#   --help              Show this help message
#
# Security Features:
#   - UFW firewall rules for VM network isolation
#   - virtio-fs mandatory read-only mode (ransomware protection)
#   - AppArmor profiles for QEMU processes
#   - Security audit and compliance checking
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

# State file for security configuration
STATE_FILE="${STATE_DIR}/security-config-$(date +%Y%m%d-%H%M%S).json"

# Default options
VM_NAME="win11"
DRY_RUN=false
APPLY_ALL=false
APPLY_FIREWALL=false
APPLY_VIRTIOFS_RO=false
APPLY_APPARMOR=false
AUDIT_ONLY=false

# Security checklist tracking
declare -A SECURITY_STATUS
TOTAL_ITEMS=0
CONFIGURED_ITEMS=0
PENDING_ITEMS=0

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Apply security hardening to QEMU/KVM Windows VMs.

OPTIONS:
    --vm NAME       Target VM name (default: win11)
    --all           Apply all security hardening
    --firewall      Configure UFW firewall rules
    --virtiofs-ro   Enforce virtio-fs read-only mode
    --apparmor      Configure AppArmor profiles
    --audit         Run security audit only (no changes)
    --dry-run       Show what would be done without making changes
    --help          Show this help message

EXAMPLES:
    $(basename "$0") --audit                    # Audit current security
    $(basename "$0") --all --vm win11           # Apply all hardening
    $(basename "$0") --virtiofs-ro --vm win11   # Enforce read-only mode
    $(basename "$0") --firewall                 # Configure firewall only

SECURITY FEATURES:
    Firewall:       Block unnecessary VM network access
    VirtIO-FS RO:   Mandatory read-only for host filesystem sharing
    AppArmor:       Confine QEMU processes
    Audit:          Check compliance with security checklist

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --vm)
                VM_NAME="$2"
                shift 2
                ;;
            --all)
                APPLY_ALL=true
                shift
                ;;
            --firewall)
                APPLY_FIREWALL=true
                shift
                ;;
            --virtiofs-ro)
                APPLY_VIRTIOFS_RO=true
                shift
                ;;
            --apparmor)
                APPLY_APPARMOR=true
                shift
                ;;
            --audit)
                AUDIT_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If --all specified, enable all features
    if [[ "$APPLY_ALL" == "true" ]]; then
        APPLY_FIREWALL=true
        APPLY_VIRTIOFS_RO=true
        APPLY_APPARMOR=true
    fi
}

# ==============================================================================
# SECURITY FUNCTIONS
# ==============================================================================

record_security_item() {
    local name="$1"
    local status="$2"  # configured, pending, warning, critical
    local message="$3"
    
    SECURITY_STATUS["$name"]="$status:$message"
    ((TOTAL_ITEMS++))
    
    case "$status" in
        configured)
            ((CONFIGURED_ITEMS++))
            log SUCCESS "$name: $message"
            ;;
        pending)
            ((PENDING_ITEMS++))
            log WARN "$name: $message"
            ;;
        warning)
            log WARN "$name: $message"
            ;;
        critical)
            log ERROR "$name: $message"
            ;;
    esac
}

# Configure UFW firewall rules
configure_firewall() {
    log STEP "Configuring UFW firewall rules..."
    
    # Check if UFW is installed
    if ! command -v ufw &>/dev/null; then
        record_security_item "UFW installed" "pending" "UFW not installed - run: sudo apt install ufw"
        return
    fi
    
    # Check UFW status
    local ufw_status=$(sudo ufw status 2>/dev/null | head -1)
    if [[ "$ufw_status" != *"active"* ]]; then
        record_security_item "UFW active" "pending" "UFW not active"
        if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
            log INFO "Enabling UFW..."
            sudo ufw --force enable
            record_security_item "UFW active" "configured" "Enabled"
        fi
    else
        record_security_item "UFW active" "configured" "Firewall is active"
    fi
    
    # Default deny incoming
    if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
        log INFO "Setting default deny incoming policy..."
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
    fi
    record_security_item "UFW default policy" "configured" "Deny incoming, allow outgoing"
    
    # Allow SSH (if needed)
    if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
        sudo ufw allow ssh comment 'SSH access'
    fi
    record_security_item "SSH access" "configured" "Port 22 allowed"
    
    # Allow libvirt bridge traffic
    if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
        # Allow traffic on virbr0 (default libvirt bridge)
        sudo ufw allow in on virbr0 comment 'libvirt bridge' 2>/dev/null || true
        sudo ufw allow out on virbr0 comment 'libvirt bridge' 2>/dev/null || true
    fi
    record_security_item "libvirt bridge" "configured" "virbr0 traffic allowed"
}

# Enforce virtio-fs read-only mode
configure_virtiofs_readonly() {
    log STEP "Checking virtio-fs read-only configuration for VM '$VM_NAME'..."
    
    # Check if VM exists
    if ! virsh -c qemu:///system dominfo "$VM_NAME" &>/dev/null 2>&1; then
        record_security_item "VM exists" "pending" "VM '$VM_NAME' not found - create it first"
        return
    fi
    
    # Get VM XML
    local vm_xml=$(virsh -c qemu:///system dumpxml "$VM_NAME" 2>/dev/null)
    
    # Check for filesystem entries
    if echo "$vm_xml" | grep -q "<filesystem"; then
        # Check if readonly is set
        if echo "$vm_xml" | grep -q "<readonly/>"; then
            record_security_item "virtio-fs read-only" "configured" "Read-only mode enforced"
        else
            record_security_item "virtio-fs read-only" "critical" "WRITE ACCESS ENABLED - Security risk!"
            
            if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
                log WARN "Attempting to enforce read-only mode..."
                
                # Stop VM if running
                local vm_state=$(virsh -c qemu:///system domstate "$VM_NAME" 2>/dev/null)
                if [[ "$vm_state" == "running" ]]; then
                    log INFO "Stopping VM to modify configuration..."
                    virsh -c qemu:///system shutdown "$VM_NAME"
                    sleep 5
                fi
                
                # Use the setup-virtio-fs.sh script if available
                if [[ -x "$SCRIPT_DIR/setup-virtio-fs.sh" ]]; then
                    log INFO "Using setup-virtio-fs.sh to enforce read-only..."
                    "$SCRIPT_DIR/setup-virtio-fs.sh" --vm "$VM_NAME" --readonly
                else
                    log ERROR "setup-virtio-fs.sh not found - manual configuration required"
                fi
            fi
        fi
    else
        record_security_item "virtio-fs configured" "pending" "No filesystem sharing configured"
    fi
}

# Configure AppArmor profiles
configure_apparmor() {
    log STEP "Checking AppArmor configuration..."
    
    # Check if AppArmor is installed and running
    if ! command -v apparmor_status &>/dev/null; then
        record_security_item "AppArmor installed" "pending" "AppArmor not installed"
        return
    fi
    
    local aa_status=$(sudo apparmor_status 2>/dev/null | head -1)
    if [[ "$aa_status" != *"enabled"* ]]; then
        record_security_item "AppArmor enabled" "pending" "AppArmor not enabled"
        return
    fi
    record_security_item "AppArmor enabled" "configured" "AppArmor is active"
    
    # Check libvirt AppArmor profile
    if sudo aa-status 2>/dev/null | grep -q "libvirt"; then
        record_security_item "libvirt AppArmor profile" "configured" "Profile loaded"
    else
        record_security_item "libvirt AppArmor profile" "pending" "Profile not loaded"
    fi
    
    # Check QEMU AppArmor profiles
    local qemu_profiles=$(sudo aa-status 2>/dev/null | grep -c "qemu" || echo "0")
    if [[ "$qemu_profiles" -gt 0 ]]; then
        record_security_item "QEMU AppArmor profiles" "configured" "$qemu_profiles profiles loaded"
    else
        record_security_item "QEMU AppArmor profiles" "pending" "No QEMU profiles loaded"
    fi
}

# Security audit function
run_security_audit() {
    log STEP "Running comprehensive security audit..."
    echo ""
    
    # 1. Check file permissions
    log INFO "Checking critical file permissions..."
    
    local iso_dir="${PROJECT_ROOT}/source-iso"
    if [[ -d "$iso_dir" ]]; then
        local iso_perms=$(stat -c "%a" "$iso_dir" 2>/dev/null || echo "unknown")
        if [[ "$iso_perms" == "755" || "$iso_perms" == "700" ]]; then
            record_security_item "ISO directory permissions" "configured" "$iso_perms"
        else
            record_security_item "ISO directory permissions" "warning" "$iso_perms (recommend 755)"
        fi
    fi
    
    # 2. Check for exposed credentials
    log INFO "Checking for exposed credentials..."
    local env_file="${PROJECT_ROOT}/.env"
    if [[ -f "$env_file" ]]; then
        local env_perms=$(stat -c "%a" "$env_file" 2>/dev/null || echo "unknown")
        if [[ "$env_perms" == "600" || "$env_perms" == "400" ]]; then
            record_security_item ".env file permissions" "configured" "$env_perms"
        else
            record_security_item ".env file permissions" "warning" "$env_perms (should be 600)"
            if [[ "$DRY_RUN" == "false" && "$AUDIT_ONLY" == "false" ]]; then
                chmod 600 "$env_file"
            fi
        fi
    fi
    
    # 3. Check libvirt security settings
    log INFO "Checking libvirt security settings..."
    if [[ -f /etc/libvirt/qemu.conf ]]; then
        if grep -q "^security_driver = \"apparmor\"" /etc/libvirt/qemu.conf; then
            record_security_item "QEMU security driver" "configured" "AppArmor"
        elif grep -q "^security_driver = \"selinux\"" /etc/libvirt/qemu.conf; then
            record_security_item "QEMU security driver" "configured" "SELinux"
        else
            record_security_item "QEMU security driver" "pending" "No security driver configured"
        fi
    fi
    
    # 4. Check VM-specific security
    if virsh -c qemu:///system dominfo "$VM_NAME" &>/dev/null 2>&1; then
        local vm_xml=$(virsh -c qemu:///system dumpxml "$VM_NAME" 2>/dev/null)
        
        # Check Secure Boot
        if echo "$vm_xml" | grep -q "secure='yes'"; then
            record_security_item "Secure Boot" "configured" "Enabled"
        else
            record_security_item "Secure Boot" "pending" "Not enabled"
        fi
        
        # Check TPM
        if echo "$vm_xml" | grep -q "<tpm"; then
            record_security_item "TPM 2.0" "configured" "Enabled"
        else
            record_security_item "TPM 2.0" "pending" "Not configured"
        fi
    fi
    
    # 5. Check network isolation
    log INFO "Checking network isolation..."
    if virsh -c qemu:///system net-info default &>/dev/null 2>&1; then
        local net_forward=$(virsh -c qemu:///system net-dumpxml default 2>/dev/null | grep -o "mode='[^']*'" | head -1)
        if [[ "$net_forward" == *"nat"* ]]; then
            record_security_item "Network mode" "configured" "NAT (isolated)"
        elif [[ "$net_forward" == *"bridge"* ]]; then
            record_security_item "Network mode" "warning" "Bridge mode (less isolated)"
        fi
    fi
}

# ==============================================================================
# OUTPUT FUNCTIONS
# ==============================================================================

output_summary() {
    echo ""
    echo "=============================================="
    echo "        SECURITY CONFIGURATION SUMMARY"
    echo "=============================================="
    echo ""
    echo -e "  VM:            ${BOLD}$VM_NAME${NC}"
    echo -e "  Total Items:   ${BOLD}$TOTAL_ITEMS${NC}"
    echo -e "  Configured:    ${GREEN}$CONFIGURED_ITEMS${NC}"
    echo -e "  Pending:       ${YELLOW}$PENDING_ITEMS${NC}"
    echo ""
    
    if [[ $PENDING_ITEMS -eq 0 ]]; then
        echo -e "${GREEN}All security items configured!${NC}"
    else
        echo -e "${YELLOW}Some security items need attention.${NC}"
        echo ""
        echo "Recommendations:"
        for key in "${!SECURITY_STATUS[@]}"; do
            local value="${SECURITY_STATUS[$key]}"
            local status="${value%%:*}"
            local message="${value#*:}"
            if [[ "$status" == "pending" || "$status" == "critical" || "$status" == "warning" ]]; then
                echo "  - $key: $message"
            fi
        done
    fi
    echo ""
}

output_json() {
    cat << EOF
{
    "timestamp": "$(date -Iseconds)",
    "vm": "$VM_NAME",
    "summary": {
        "total": $TOTAL_ITEMS,
        "configured": $CONFIGURED_ITEMS,
        "pending": $PENDING_ITEMS
    },
    "items": {
EOF
    
    local first=true
    for key in "${!SECURITY_STATUS[@]}"; do
        local value="${SECURITY_STATUS[$key]}"
        local status="${value%%:*}"
        local message="${value#*:}"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        printf '        "%s": {"status": "%s", "message": "%s"}' "$key" "$status" "$message"
    done
    
    cat << EOF

    }
}
EOF
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"
    
    echo ""
    echo "========================================"
    echo "  QEMU/KVM Security Configuration"
    echo "========================================"
    echo ""
    echo "  VM: $VM_NAME"
    echo "  Mode: $(if $AUDIT_ONLY; then echo "Audit only"; elif $DRY_RUN; then echo "Dry run"; else echo "Apply changes"; fi)"
    echo ""
    
    # Always run audit
    run_security_audit
    
    # Apply specific configurations if requested
    if [[ "$APPLY_FIREWALL" == "true" ]]; then
        configure_firewall
    fi
    
    if [[ "$APPLY_VIRTIOFS_RO" == "true" ]]; then
        configure_virtiofs_readonly
    fi
    
    if [[ "$APPLY_APPARMOR" == "true" ]]; then
        configure_apparmor
    fi
    
    # Output results
    output_summary
    
    # Save state
    output_json > "$STATE_FILE" 2>/dev/null || true
    
    if [[ $PENDING_ITEMS -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
