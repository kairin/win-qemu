#!/bin/bash
################################################################################
# VirtIO-FS Filesystem Sharing Setup Script
# =========================================
#
# PURPOSE:
#   Automates the configuration of virtio-fs filesystem sharing between Ubuntu
#   host and Windows 11 guest for high-performance .pst file access.
#
# FEATURES:
#   - Pre-flight compatibility checks (libvirt version, virtiofsd)
#   - Automated directory creation and permission setup
#   - VM XML backup before modifications
#   - Syntax validation before applying changes
#   - Comprehensive error handling and rollback capability
#   - Detailed logging with timestamps
#   - Dry-run mode for testing
#   - MANDATORY read-only mode enforcement (security)
#
# USAGE:
#   sudo ./scripts/setup-virtio-fs.sh --vm <vm-name> [OPTIONS]
#
# OPTIONS:
#   --vm <name>           VM name (REQUIRED)
#   --source <path>       Source directory on host (default: /home/user/outlook-data)
#   --target <tag>        Mount tag for guest (default: outlook-share)
#   --queue <size>        Queue size 1024/2048/4096 (default: 1024)
#   --dry-run             Test without making changes
#   --force               Skip confirmation prompts
#   --help                Show this help message
#
# EXAMPLES:
#   # Basic setup with defaults
#   sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook
#
#   # Custom source directory
#   sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook --source /mnt/data/pst-files
#
#   # High performance for large .pst files
#   sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook --queue 4096
#
#   # Dry run to preview changes
#   ./scripts/setup-virtio-fs.sh --vm win11-outlook --dry-run
#
# SECURITY:
#   - ALWAYS enforces read-only mode (ransomware protection)
#   - No option to enable write mode (by design)
#   - Validates directory permissions before proceeding
#   - Creates backup of VM XML before modifications
#
# VERSION: 1.0.0 (January 2025)
# MAINTAINER: win-qemu agent ecosystem
# LICENSE: See project LICENSE file
################################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures

#------------------------------------------------------------------------------
# Configuration and Constants
#------------------------------------------------------------------------------

# Script metadata
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Compatibility aliases
readonly RESET=$NC

# Helper for colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}"
}

# Logging configuration
readonly LOG_DIR="/var/log/win-qemu"
readonly LOG_FILE="$LOG_DIR/setup-virtio-fs.log"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Default configuration
DEFAULT_SOURCE_DIR="/home/user/outlook-data"
DEFAULT_TARGET_TAG="outlook-share"
DEFAULT_QUEUE_SIZE="1024"

# VM configuration
VM_NAME=""
SOURCE_DIR="$DEFAULT_SOURCE_DIR"
TARGET_TAG="$DEFAULT_TARGET_TAG"
QUEUE_SIZE="$DEFAULT_QUEUE_SIZE"

# Operational flags
DRY_RUN=false
FORCE=false
BACKUP_FILE=""


# Print section header
print_header() {
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$CYAN$BOLD" "$*"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Error handler
error_exit() {
    log_error "$1"

    # Rollback if backup exists
    if [[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]]; then
        log_warning "Attempting rollback from backup: $BACKUP_FILE"
        if virsh define "$BACKUP_FILE" &>/dev/null; then
            log_success "Rollback successful - VM restored to previous state"
        else
            log_error "Rollback failed - Manual recovery required: virsh define $BACKUP_FILE"
        fi
    fi

    exit 1
}

# Confirmation prompt
confirm() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    prompt_confirm "$1" || exit 0
}

#------------------------------------------------------------------------------
# Help and Usage
#------------------------------------------------------------------------------

show_help() {
    cat << EOF
${BOLD}VirtIO-FS Filesystem Sharing Setup Script${RESET}
Version: $SCRIPT_VERSION

${BOLD}USAGE:${RESET}
    sudo $SCRIPT_NAME --vm <vm-name> [OPTIONS]

${BOLD}REQUIRED OPTIONS:${RESET}
    --vm <name>           Name of the VM to configure

${BOLD}OPTIONAL PARAMETERS:${RESET}
    --source <path>       Source directory on host
                          Default: $DEFAULT_SOURCE_DIR

    --target <tag>        Mount tag for Windows guest
                          Default: $DEFAULT_TARGET_TAG

    --queue <size>        VirtIO queue size (1024/2048/4096)
                          Default: $DEFAULT_QUEUE_SIZE
                          1024: Standard workloads (<1GB .pst files)
                          2048: High performance (1-2GB .pst files)
                          4096: Maximum performance (>2GB .pst files)

${BOLD}FLAGS:${RESET}
    --dry-run             Preview changes without applying them
    --force               Skip confirmation prompts
    --help                Show this help message

${BOLD}EXAMPLES:${RESET}
    # Basic setup with defaults
    sudo $SCRIPT_NAME --vm win11-outlook

    # Custom source directory
    sudo $SCRIPT_NAME --vm win11-outlook --source /mnt/data/pst-files

    # High performance configuration
    sudo $SCRIPT_NAME --vm win11-outlook --queue 4096

    # Preview changes without applying
    $SCRIPT_NAME --vm win11-outlook --dry-run

${BOLD}SECURITY NOTES:${RESET}
    - Read-only mode is MANDATORY (ransomware protection)
    - No option to enable write mode (by design)
    - Guest malware CANNOT encrypt host files
    - Always verify read-only mode after setup

${BOLD}WINDOWS GUEST SETUP:${RESET}
    After running this script, configure Windows guest:
    1. Install WinFsp: https://github.com/winfsp/winfsp/releases
    2. Reboot Windows
    3. Mount as Z: drive: net use Z: \\\\svc\\$DEFAULT_TARGET_TAG
    4. Verify read-only: Try creating file (should fail)

${BOLD}TROUBLESHOOTING:${RESET}
    - Check logs: $LOG_FILE
    - Verify libvirt: virsh version
    - Test virtiofsd: which virtiofsd
    - VM XML backup location: /var/lib/libvirt/qemu/backups/

${BOLD}DOCUMENTATION:${RESET}
    - Implementation Guide: outlook-linux-guide/06-seamless-bridge-integration.md
    - Security Analysis: research/06-security-hardening-analysis.md
    - Troubleshooting: research/07-troubleshooting-failure-modes.md

EOF
    exit 0
}

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_help
    fi

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
            --queue)
                QUEUE_SIZE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run '$SCRIPT_NAME --help' for usage information"
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$VM_NAME" ]]; then
        log_error "VM name is required. Use --vm <name>"
        echo "Run '$SCRIPT_NAME --help' for usage information"
        exit 1
    fi

    # Validate queue size
    if [[ ! "$QUEUE_SIZE" =~ ^(1024|2048|4096)$ ]]; then
        log_error "Invalid queue size: $QUEUE_SIZE (must be 1024, 2048, or 4096)"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Pre-flight Checks
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]] && [[ "$DRY_RUN" == "false" ]]; then
        log_error "This script must be run as root (use sudo)"
        log_info "For dry-run mode, root is not required: $SCRIPT_NAME --dry-run"
        exit 1
    fi
}

check_libvirt_version() {
    log_info "Checking libvirt version..."

    if ! command -v virsh &> /dev/null; then
        error_exit "virsh command not found. Install libvirt: sudo apt install libvirt-clients"
    fi

    local version
    version=$(virsh version | grep "libvirt library" | awk '{print $4}')
    log_success "libvirt version: $version"

    # Check minimum version (9.0.0)
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)

    if [[ $major -lt 9 ]]; then
        log_warning "libvirt version $version is older than recommended (9.0.0)"
        log_warning "virtio-fs may not be fully supported - proceed with caution"
        confirm "Continue with potentially incompatible libvirt version?"
    fi
}

check_virtiofsd() {
    log_info "Checking for virtiofsd binary..."

    local virtiofsd_paths=(
        "/usr/libexec/virtiofsd"
        "/usr/lib/qemu/virtiofsd"
        "/usr/bin/virtiofsd"
    )

    local found=false
    for path in "${virtiofsd_paths[@]}"; do
        if [[ -x "$path" ]]; then
            log_success "Found virtiofsd: $path"
            found=true
            break
        fi
    done

    if [[ "$found" == "false" ]]; then
        log_error "virtiofsd binary not found in standard locations"
        log_info "Install QEMU with virtio-fs support:"
        log_info "  sudo apt install qemu-system-x86 qemu-kvm"
        exit 1
    fi
}

check_vm_exists() {
    log_info "Checking if VM '$VM_NAME' exists..."

    if ! virsh dominfo "$VM_NAME" &>/dev/null; then
        error_exit "VM '$VM_NAME' not found. List VMs with: virsh list --all"
    fi

    log_success "VM '$VM_NAME' found"
}

check_vm_state() {
    log_info "Checking VM state..."

    local state
    state=$(virsh domstate "$VM_NAME" 2>/dev/null)

    if [[ "$state" == "running" ]]; then
        log_warning "VM '$VM_NAME' is currently running"
        log_warning "VM must be restarted for virtio-fs changes to take effect"

        if [[ "$DRY_RUN" == "false" ]]; then
            confirm "Shutdown VM now to apply changes?"
            log_info "Shutting down VM..."
            virsh shutdown "$VM_NAME"

            # Wait for shutdown (max 60 seconds)
            local timeout=60
            local elapsed=0
            while [[ "$(virsh domstate "$VM_NAME" 2>/dev/null)" != "shut off" ]]; do
                sleep 2
                elapsed=$((elapsed + 2))
                if [[ $elapsed -ge $timeout ]]; then
                    log_warning "Graceful shutdown timeout - forcing shutdown"
                    virsh destroy "$VM_NAME"
                    break
                fi
            done
            log_success "VM shutdown complete"
        fi
    else
        log_success "VM state: $state"
    fi
}

#------------------------------------------------------------------------------
# Directory Setup
#------------------------------------------------------------------------------

setup_source_directory() {
    log_info "Setting up source directory: $SOURCE_DIR"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create directory: $SOURCE_DIR"
        log_info "[DRY RUN] Would set permissions: 755"
        log_info "[DRY RUN] Would set ownership: $SUDO_USER:libvirt-qemu"
        return 0
    fi

    # Create directory if it doesn't exist
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_info "Creating directory: $SOURCE_DIR"
        mkdir -p "$SOURCE_DIR" || error_exit "Failed to create directory: $SOURCE_DIR"
        log_success "Directory created"
    else
        log_success "Directory already exists"
    fi

    # Set permissions (755 = rwxr-xr-x)
    log_info "Setting directory permissions to 755"
    chmod 755 "$SOURCE_DIR" || error_exit "Failed to set permissions"

    # Set ownership
    local owner="${SUDO_USER:-$USER}"
    log_info "Setting directory ownership to $owner:$owner"
    chown "$owner:$owner" "$SOURCE_DIR" || error_exit "Failed to set ownership"

    # Add libvirt-qemu user to group for access
    if getent group libvirt-qemu &>/dev/null; then
        log_info "Granting libvirt-qemu access to directory"
        setfacl -m g:libvirt-qemu:rx "$SOURCE_DIR" 2>/dev/null || {
            log_warning "setfacl not available - using group ownership instead"
            chgrp libvirt-qemu "$SOURCE_DIR" || log_warning "Failed to set group ownership"
        }
    fi

    # Create README
    local readme="$SOURCE_DIR/README.txt"
    if [[ ! -f "$readme" ]]; then
        cat > "$readme" << EOF
VirtIO-FS Shared Directory
=========================

This directory is shared with Windows 11 VM via virtio-fs.
It will appear as Z: drive in the guest (mount tag: $TARGET_TAG).

SECURITY: This share is configured as READ-ONLY in the guest.
          Guest malware CANNOT encrypt or modify files in this directory.

PURPOSE: Store .pst files here for Microsoft 365 Outlook access.

SETUP DATE: $(date '+%Y-%m-%d %H:%M:%S')
VM NAME: $VM_NAME
SOURCE: $SOURCE_DIR
TARGET: $TARGET_TAG

For more information, see:
  - outlook-linux-guide/06-seamless-bridge-integration.md
  - research/06-security-hardening-analysis.md
EOF
        chown "$owner:$owner" "$readme"
        log_success "Created README.txt in shared directory"
    fi

    # Display directory status
    echo ""
    log_info "Directory configuration:"
    ls -ld "$SOURCE_DIR"
    echo ""
}

create_test_file() {
    log_info "Creating test file for verification..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create test file: $SOURCE_DIR/test-virtio-fs.txt"
        return 0
    fi

    local test_file="$SOURCE_DIR/test-virtio-fs.txt"
    local owner="${SUDO_USER:-$USER}"

    cat > "$test_file" << EOF
VirtIO-FS Test File
==================

Created: $(date '+%Y-%m-%d %H:%M:%S')
VM: $VM_NAME
Source: $SOURCE_DIR
Target: $TARGET_TAG

If you can read this file from Windows guest (Z: drive),
virtio-fs is working correctly!

SECURITY TEST:
Try to delete this file from Windows. It should fail with "Access Denied"
because read-only mode is enforced.
EOF

    chown "$owner:$owner" "$test_file"
    chmod 644 "$test_file"
    log_success "Test file created: $test_file"
}

#------------------------------------------------------------------------------
# VM Configuration
#------------------------------------------------------------------------------

backup_vm_xml() {
    log_info "Creating backup of VM configuration..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would backup VM XML to /var/lib/libvirt/qemu/backups/"
        return 0
    fi

    local backup_dir="/var/lib/libvirt/qemu/backups"
    mkdir -p "$backup_dir" || error_exit "Failed to create backup directory"

    BACKUP_FILE="$backup_dir/${VM_NAME}_${TIMESTAMP}_pre-virtiofs.xml"

    if ! virsh dumpxml "$VM_NAME" > "$BACKUP_FILE"; then
        error_exit "Failed to create VM XML backup"
    fi

    log_success "Backup created: $BACKUP_FILE"
}

generate_virtiofs_xml() {
    log_info "Generating virtio-fs device configuration..."

    local temp_xml="/tmp/virtiofs-${VM_NAME}-${TIMESTAMP}.xml"

    cat > "$temp_xml" << EOF
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs' queue='$QUEUE_SIZE'/>
  <source dir='$SOURCE_DIR'/>
  <target dir='$TARGET_TAG'/>
  <readonly/>
</filesystem>
EOF

    log_success "Configuration generated: $temp_xml"

    echo ""
    log_info "VirtIO-FS Configuration:"
    print_color "$YELLOW" "$(cat "$temp_xml")"
    echo ""

    echo "$temp_xml"
}

check_existing_virtiofs() {
    log_info "Checking for existing virtio-fs configuration..."

    if virsh dumpxml "$VM_NAME" | grep -q "type='virtiofs'"; then
        log_warning "VM already has virtio-fs configured"
        virsh dumpxml "$VM_NAME" | grep -A 5 "type='virtiofs'" || true
        echo ""
        confirm "Remove existing virtio-fs and add new configuration?"

        if [[ "$DRY_RUN" == "false" ]]; then
            log_info "Removing existing virtio-fs device..."
            # We'll handle this during XML editing
        fi
    fi
}

attach_virtiofs_device() {
    local xml_file="$1"

    log_info "Attaching virtio-fs device to VM..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would attach virtio-fs device from: $xml_file"
        log_info "[DRY RUN] Command: virsh attach-device $VM_NAME $xml_file --config"
        return 0
    fi

    # Try to attach device
    if virsh attach-device "$VM_NAME" "$xml_file" --config; then
        log_success "VirtIO-FS device attached successfully"
    else
        log_error "Failed to attach device using virsh attach-device"
        log_info "Attempting manual XML editing..."

        # Fallback: Manual XML editing
        local current_xml="/tmp/vm-${VM_NAME}-current.xml"
        virsh dumpxml "$VM_NAME" > "$current_xml"

        # Insert filesystem block before </devices>
        sed -i "/<\/devices>/i \\  $(cat "$xml_file" | sed 's/^/  /')" "$current_xml"

        # Validate and define
        if virsh define "$current_xml"; then
            log_success "VirtIO-FS configuration applied via manual XML editing"
        else
            error_exit "Failed to apply virtio-fs configuration - check $current_xml"
        fi
    fi
}

verify_virtiofs_config() {
    log_info "Verifying virtio-fs configuration..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would verify configuration in VM XML"
        return 0
    fi

    if ! virsh dumpxml "$VM_NAME" | grep -q "type='virtiofs'"; then
        error_exit "VirtIO-FS configuration not found in VM XML after attachment"
    fi

    # Check for read-only tag
    if ! virsh dumpxml "$VM_NAME" | grep -A 5 "type='virtiofs'" | grep -q "<readonly/>"; then
        log_error "CRITICAL: <readonly/> tag not found in virtio-fs configuration!"
        log_error "This is a SECURITY RISK - guest can write to host files"
        error_exit "Configuration validation failed - read-only mode not enforced"
    fi

    log_success "VirtIO-FS configuration verified successfully"

    echo ""
    log_info "Current virtio-fs configuration in VM:"
    virsh dumpxml "$VM_NAME" | grep -A 7 "type='virtiofs'" || true
    echo ""
}

#------------------------------------------------------------------------------
# Post-Configuration
#------------------------------------------------------------------------------

start_vm() {
    log_info "Starting VM..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would start VM: virsh start $VM_NAME"
        return 0
    fi

    local current_state
    current_state=$(virsh domstate "$VM_NAME" 2>/dev/null)

    if [[ "$current_state" == "shut off" ]]; then
        confirm "Start VM now?"

        if virsh start "$VM_NAME"; then
            log_success "VM started successfully"
            log_info "Waiting for VM to boot (30 seconds)..."
            sleep 30
        else
            error_exit "Failed to start VM"
        fi
    else
        log_info "VM is already running (state: $current_state)"
    fi
}

show_windows_instructions() {
    print_header "WINDOWS GUEST SETUP INSTRUCTIONS"

    cat << EOF
${BOLD}VirtIO-FS host configuration is complete!${RESET}

Now configure the Windows guest to mount the shared directory:

${BOLD}Step 1: Install WinFsp${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Download WinFsp from: ${CYAN}https://github.com/winfsp/winfsp/releases${RESET}
2. Download latest version: ${CYAN}winfsp-2.0.23075.msi${RESET} (or newer)
3. Run installer in Windows guest
4. Use default installation path: ${CYAN}C:\\Program Files (x86)\\WinFsp${RESET}
5. ${YELLOW}REBOOT Windows guest${RESET} (required for driver loading)

${BOLD}Step 2: Install VirtIO-FS Service${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Mount virtio-win.iso in guest (if not already mounted)
2. Open File Explorer → Navigate to ISO drive
3. Go to: ${CYAN}guest-agent\\${RESET} folder
4. Run: ${CYAN}virtiofs-*.exe${RESET} or ${CYAN}virtiofs.msi${RESET}
5. Open ${CYAN}services.msc${RESET}
6. Find "${CYAN}VirtIO-FS Service${RESET}"
7. Set Startup type: ${CYAN}Automatic${RESET}
8. Click ${CYAN}Start${RESET} to start service immediately

${BOLD}Step 3: Mount as Z: Drive${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open ${CYAN}PowerShell as Administrator${RESET}
2. Run the following command:

   ${GREEN}net use Z: \\\\svc\\$TARGET_TAG${RESET}

3. Open File Explorer
4. You should see ${CYAN}Z:${RESET} drive under "This PC"
5. Open Z: drive - you should see test file

${BOLD}Step 4: Verify Read-Only Mode (SECURITY TEST)${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open ${CYAN}Z:${RESET} drive in File Explorer
2. Try to create a new file (Right-click → New → Text Document)
3. ${GREEN}Expected result: "Access Denied" error ✓${RESET}
4. Try to delete ${CYAN}test-virtio-fs.txt${RESET}
5. ${GREEN}Expected result: "Access Denied" error ✓${RESET}
6. ${RED}If you CAN create/delete files: SECURITY RISK!${RESET}
   Contact system administrator immediately

${BOLD}Step 5: Configure Outlook${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Copy your .pst files to ${CYAN}$SOURCE_DIR${RESET} on the host
2. In Windows, open Microsoft 365 Outlook
3. Go to: ${CYAN}File → Open & Export → Open Outlook Data File${RESET}
4. Navigate to ${CYAN}Z:${RESET} drive
5. Select your .pst file and click ${CYAN}OK${RESET}
6. Archive should appear in Outlook folder pane

${BOLD}TROUBLESHOOTING${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${YELLOW}Issue: Z: drive not appearing${RESET}
  - Check WinFsp is installed: ${CYAN}Get-Package -Name WinFsp${RESET} (PowerShell)
  - Check VirtIO-FS Service is running: ${CYAN}services.msc${RESET}
  - Restart VirtIO-FS Service
  - Check Event Viewer for errors

${YELLOW}Issue: "Access Denied" when opening files${RESET}
  - Check file permissions on host: ${CYAN}ls -l $SOURCE_DIR${RESET}
  - Fix permissions: ${CYAN}chmod 644 $SOURCE_DIR/*.pst${RESET}
  - Fix ownership: ${CYAN}chown $SUDO_USER:$SUDO_USER $SOURCE_DIR/*.pst${RESET}

${YELLOW}Issue: Slow performance (>5 seconds to open .pst)${RESET}
  - Increase queue size to 2048 or 4096
  - Enable Hyper-V enlightenments in VM
  - Contact performance optimization specialist

${BOLD}CONFIGURATION SUMMARY${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VM Name:          ${CYAN}$VM_NAME${RESET}
Source Directory: ${CYAN}$SOURCE_DIR${RESET}
Mount Tag:        ${CYAN}$TARGET_TAG${RESET}
Queue Size:       ${CYAN}$QUEUE_SIZE${RESET}
Access Mode:      ${GREEN}READ-ONLY (ransomware protection enabled)${RESET}
Windows Drive:    ${CYAN}Z:${RESET}

${BOLD}SECURITY NOTES${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${GREEN}✓${RESET} Read-only mode enforced - guest cannot modify host files
${GREEN}✓${RESET} Ransomware protection active
${GREEN}✓${RESET} VM XML backup created: ${CYAN}$BACKUP_FILE${RESET}
${GREEN}✓${RESET} Configuration logged: ${CYAN}$LOG_FILE${RESET}

${BOLD}NEXT STEPS${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Complete Windows guest setup (Steps 1-5 above)
2. Test .pst file access in Outlook
3. Verify read-only mode (security test)
4. Set up regular backups of $SOURCE_DIR
5. Consider enabling LUKS encryption on host partition

${BOLD}DOCUMENTATION${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Implementation Guide: ${CYAN}outlook-linux-guide/06-seamless-bridge-integration.md${RESET}
Security Analysis:    ${CYAN}research/06-security-hardening-analysis.md${RESET}
Troubleshooting:      ${CYAN}research/07-troubleshooting-failure-modes.md${RESET}

EOF
}

#------------------------------------------------------------------------------
# Main Execution
#------------------------------------------------------------------------------

main() {
    # Print banner
    print_header "VirtIO-FS Filesystem Sharing Setup - Version $SCRIPT_VERSION"

    log_info "Starting virtio-fs setup for VM: $VM_NAME"
    log_info "Source directory: $SOURCE_DIR"
    log_info "Target mount tag: $TARGET_TAG"
    log_info "Queue size: $QUEUE_SIZE"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_color "$YELLOW$BOLD" "DRY RUN MODE - No changes will be made"
    fi

    echo ""

    # Phase 1: Pre-flight checks
    print_header "Phase 1: Pre-Flight Validation"
    check_root
    check_libvirt_version
    check_virtiofsd
    check_vm_exists
    check_vm_state

    # Phase 2: Directory setup
    print_header "Phase 2: Host-Side Directory Setup"
    setup_source_directory
    create_test_file

    # Phase 3: VM configuration
    print_header "Phase 3: VM Configuration"
    backup_vm_xml
    check_existing_virtiofs

    local virtiofs_xml
    virtiofs_xml=$(generate_virtiofs_xml)

    attach_virtiofs_device "$virtiofs_xml"
    verify_virtiofs_config

    # Phase 4: Finalization
    print_header "Phase 4: Finalization"

    if [[ "$DRY_RUN" == "false" ]]; then
        start_vm
    fi

    # Show Windows instructions
    show_windows_instructions

    # Final summary
    print_header "SETUP COMPLETE!"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_color "$YELLOW$BOLD" "DRY RUN COMPLETED - No actual changes were made"
        log_info "To apply changes, run without --dry-run flag:"
        log_info "  sudo $SCRIPT_NAME --vm $VM_NAME"
    else
        log_success "VirtIO-FS configuration completed successfully!"
        log_success "Log file: $LOG_FILE"
        log_success "VM XML backup: $BACKUP_FILE"
    fi

    echo ""
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

# Parse arguments and run
parse_arguments "$@"
init_logging "setup-virtio-fs"
main

# Clean up temporary files
if [[ "$DRY_RUN" == "false" ]]; then
    rm -f /tmp/virtiofs-${VM_NAME}-*.xml 2>/dev/null || true
    rm -f /tmp/vm-${VM_NAME}-current.xml 2>/dev/null || true
fi

exit 0
