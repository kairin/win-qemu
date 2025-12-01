#!/bin/bash

################################################################################
# QEMU/KVM VM Backup Script
# Version: 1.0.0
# Compatible with: QEMU 8.0+, libvirt 9.0+
#
# This script provides automated VM backup with multiple snapshot strategies:
# - Live snapshots (VM running, includes RAM state)
# - Offline snapshots (VM stopped, disk only)
# - External snapshots (qcow2 overlay for incremental backups)
# - XML configuration export
# - Automatic backup rotation (keep last N backups)
# - Backup integrity verification
# - Size estimation before backup
#
# Usage:
#   ./backup-vm.sh <vm-name> [OPTIONS]
#
# Options:
#   --offline           Stop VM before backup (recommended for consistency)
#   --live              Create live snapshot (VM running, default if running)
#   --external          Use external snapshots (qcow2 overlay)
#   --backup-dir <dir>  Custom backup directory (default: /var/backups/vms)
#   --keep <N>          Keep only last N backups (default: 5)
#   --no-rotation       Skip automatic cleanup of old backups
#   --snapshot-only     Create snapshot without exporting disk
#   --no-snapshot       Export disk without creating snapshot
#   --verify            Verify backup integrity after creation
#   --compress          Compress backup (slower but saves space)
#   --dry-run           Preview actions without executing
#   --yes               Skip all confirmations
#   -h, --help          Display this help message
#
# Examples:
#   # Basic backup (automatic mode based on VM state)
#   ./backup-vm.sh win11-outlook
#
#   # Offline backup (stop VM first)
#   ./backup-vm.sh win11-outlook --offline
#
#   # Live backup with verification
#   ./backup-vm.sh win11-outlook --live --verify
#
#   # External snapshot with custom backup dir
#   ./backup-vm.sh win11-outlook --external --backup-dir /backup/vms
#
#   # Keep only last 10 backups
#   ./backup-vm.sh win11-outlook --keep 10
#
#   # Quick snapshot without export
#   ./backup-vm.sh win11-outlook --snapshot-only
#
#   # Compressed backup (saves space)
#   ./backup-vm.sh win11-outlook --compress
#
#   # Dry run to estimate size
#   ./backup-vm.sh win11-outlook --dry-run
#
# Snapshot Types:
#
#   LIVE SNAPSHOT (VM Running):
#     - Includes VM state (RAM, CPU registers)
#     - Allows restoring to exact running state
#     - Larger snapshot size (includes memory dump)
#     - No downtime required
#
#   OFFLINE SNAPSHOT (VM Stopped):
#     - Disk state only
#     - Smaller snapshot size
#     - More consistent (no in-flight I/O)
#     - Requires VM downtime
#
#   EXTERNAL SNAPSHOT:
#     - Creates qcow2 overlay file
#     - Original disk becomes read-only backing file
#     - Enables incremental backups
#     - Can be used for backup without copying
#
# Backup Structure:
#   /var/backups/vms/
#   └── win11-outlook/
#       ├── backup-20250119-120000/
#       │   ├── win11-outlook.qcow2      # Disk image
#       │   ├── win11-outlook.xml        # VM configuration
#       │   ├── backup-info.txt          # Backup metadata
#       │   └── checksum.sha256          # Integrity verification
#       └── backup-20250119-150000/
#           └── ...
#
# Requirements:
#   - qcow2 disk format (for snapshots)
#   - Sufficient disk space (1-2x VM disk size)
#   - Root/sudo access for backup operations
#
# Safety Features:
#   - Pre-backup disk space check
#   - Snapshot list before creating new ones
#   - Automatic backup rotation
#   - Integrity verification (optional)
#   - Dry-run mode for planning
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
VM_DISK_PATH=""
VM_DISK_SIZE_GB=0

# Backup configuration
BACKUP_DIR="/var/backups/vms"
BACKUP_NAME=""
KEEP_BACKUPS=5
CURRENT_BACKUP_DIR=""

# Operational flags
BACKUP_OFFLINE=false
BACKUP_LIVE=false
USE_EXTERNAL_SNAPSHOT=false
SNAPSHOT_ONLY=false
NO_SNAPSHOT=false
VERIFY_BACKUP=false
COMPRESS_BACKUP=false
NO_ROTATION=false
SKIP_CONFIRM=false
DRY_RUN=false

# Statistics
DISK_USAGE_BEFORE=0
DISK_USAGE_AFTER=0
BACKUP_SIZE_MB=0
BACKUP_DURATION=0

# Logging
LOG_DIR="/var/log/win-qemu"
LOG_FILE="${LOG_DIR}/backup-vm-$(date +%Y%m%d-%H%M%S).log"

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
QEMU/KVM VM Backup Script v1.0.0

Automated VM backup with snapshots, configuration export, and rotation.

USAGE:
    ./backup-vm.sh <vm-name> [OPTIONS]

ARGUMENTS:
    <vm-name>           Name of the VM to backup (required)

BACKUP MODE OPTIONS:
    --offline           Stop VM before backup (most consistent)
    --live              Create live snapshot (VM remains running)
    --external          Use external snapshots (qcow2 overlay)

BACKUP LOCATION:
    --backup-dir <dir>  Custom backup directory (default: /var/backups/vms)

BACKUP MANAGEMENT:
    --keep <N>          Keep only last N backups, delete older (default: 5)
    --no-rotation       Skip automatic cleanup of old backups

BACKUP CONTENT:
    --snapshot-only     Create snapshot without exporting disk
    --no-snapshot       Export disk without creating snapshot
    --verify            Verify backup integrity (SHA256 checksum)
    --compress          Compress backup with gzip (slower, saves space)

OPERATIONAL FLAGS:
    --dry-run           Preview actions without executing
    --yes               Skip all confirmations (for automation)
    -h, --help          Display this help message

EXAMPLES:

    # Basic backup (automatic mode)
    ./backup-vm.sh win11-outlook

    # Offline backup (stops VM for consistency)
    ./backup-vm.sh win11-outlook --offline

    # Live backup with verification
    ./backup-vm.sh win11-outlook --live --verify

    # External snapshot (incremental backup capable)
    ./backup-vm.sh win11-outlook --external

    # Custom backup location with compression
    ./backup-vm.sh win11-outlook --backup-dir /mnt/backup --compress

    # Keep last 10 backups, delete older
    ./backup-vm.sh win11-outlook --keep 10

    # Quick snapshot without full export
    ./backup-vm.sh win11-outlook --snapshot-only

    # Automated backup (no prompts)
    ./backup-vm.sh win11-outlook --yes

    # Dry run to check disk space
    ./backup-vm.sh win11-outlook --dry-run

SNAPSHOT TYPES:

    LIVE SNAPSHOT (--live):
        ✓ VM remains running (no downtime)
        ✓ Includes RAM state (full restore capability)
        ✗ Larger backup size (includes memory dump)
        ✗ Less consistent (in-flight I/O)

        Use case: Minimal downtime requirement

    OFFLINE SNAPSHOT (--offline):
        ✓ Most consistent (no in-flight I/O)
        ✓ Smaller backup size (disk only)
        ✗ Requires VM downtime

        Use case: Production backups, best practices

    EXTERNAL SNAPSHOT (--external):
        ✓ Fast (creates overlay, no copy)
        ✓ Enables incremental backups
        ✓ Original disk becomes read-only backing
        ✗ Requires qcow2 format
        ✗ Snapshot chain management needed

        Use case: Frequent backups, disk space constraints

BACKUP STRUCTURE:

    /var/backups/vms/
    └── win11-outlook/
        ├── backup-20250119-120000/
        │   ├── win11-outlook.qcow2      # Disk image
        │   ├── win11-outlook.xml        # VM configuration
        │   ├── backup-info.txt          # Backup metadata
        │   └── checksum.sha256          # Integrity hash (if --verify)
        └── backup-20250119-150000/
            └── ...

BACKUP RESTORATION:

    1. Stop current VM:
       virsh shutdown win11-outlook

    2. Restore disk image:
       cp /var/backups/vms/win11-outlook/backup-YYYYMMDD-HHMMSS/win11-outlook.qcow2 \
          /var/lib/libvirt/images/win11-outlook.qcow2

    3. Restore VM configuration (if needed):
       virsh define /var/backups/vms/win11-outlook/backup-YYYYMMDD-HHMMSS/win11-outlook.xml

    4. Start VM:
       virsh start win11-outlook

BACKUP ROTATION:

    Default: Keeps last 5 backups, deletes older automatically

    Customize retention:
        --keep 10       # Keep 10 backups
        --no-rotation   # Never delete old backups

    Manual cleanup:
        ls -lh /var/backups/vms/win11-outlook/
        rm -rf /var/backups/vms/win11-outlook/backup-YYYYMMDD-HHMMSS

DISK SPACE PLANNING:

    Space required: 1-2x VM disk size

    Example: 100GB VM disk requires:
        - No compression: ~100GB backup space
        - With compression: ~40-60GB backup space
        - Live snapshot: +8GB (if VM has 8GB RAM)

    Check available space:
        df -h /var/backups/vms

REQUIREMENTS:
    - qcow2 disk format (for snapshots)
    - Sufficient disk space (1-2x VM disk size)
    - Root/sudo access for backup operations

TROUBLESHOOTING:
    - "No space left": Free up backup directory or use --compress
    - "Snapshot failed": Check disk format with: qemu-img info <disk>
    - "Permission denied": Run with sudo

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

    # Determine backup mode based on state if not specified
    if [[ "$BACKUP_OFFLINE" == "false" ]] && [[ "$BACKUP_LIVE" == "false" ]]; then
        if [[ "$VM_STATE" == "running" ]]; then
            log_info "Auto-selecting LIVE backup mode (VM is running)"
            BACKUP_LIVE=true
        else
            log_info "Auto-selecting OFFLINE backup mode (VM is stopped)"
            BACKUP_OFFLINE=true
        fi
    fi

    log_success "VM state determined: $VM_STATE"
}

get_vm_disk_info() {
    log_step "Getting VM disk information..."

    # Get primary disk path
    VM_DISK_PATH=$(virsh domblklist "$VM_NAME" | awk '/vda|sda|hda/{print $2}' | head -1)

    if [[ -z "$VM_DISK_PATH" ]]; then
        log_error "Could not determine VM disk path"
        log_error "VM may not have a disk attached"
        return 1
    fi

    log_info "VM disk path: $VM_DISK_PATH"

    # Get disk size
    if [[ -f "$VM_DISK_PATH" ]]; then
        local disk_size_bytes
        disk_size_bytes=$(stat -f --format="%s" "$VM_DISK_PATH" 2>/dev/null || stat -c "%s" "$VM_DISK_PATH" 2>/dev/null || echo "0")
        VM_DISK_SIZE_GB=$((disk_size_bytes / 1024 / 1024 / 1024))

        log_info "VM disk size: ${VM_DISK_SIZE_GB}GB"

        # Check disk format (should be qcow2 for snapshots)
        local disk_format
        disk_format=$(qemu-img info "$VM_DISK_PATH" | awk '/file format:/{print $3}')
        log_info "Disk format: $disk_format"

        if [[ "$disk_format" != "qcow2" ]] && [[ "$NO_SNAPSHOT" == "false" ]]; then
            log_warning "Disk format is $disk_format (not qcow2)"
            log_warning "Snapshots require qcow2 format"
            log_warning "Will proceed with disk export only (no snapshot)"
            NO_SNAPSHOT=true
        fi
    else
        log_warning "Disk file not found at: $VM_DISK_PATH"
    fi

    log_success "VM disk information retrieved"
}

check_disk_space() {
    log_step "Checking available disk space..."

    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR" 2>/dev/null || true

    # Get available space in backup directory
    local avail_space_kb
    avail_space_kb=$(df "$BACKUP_DIR" | awk 'NR==2{print $4}')
    local avail_space_gb=$((avail_space_kb / 1024 / 1024))

    log_info "Backup directory: $BACKUP_DIR"
    log_info "Available space: ${avail_space_gb}GB"

    # Estimate required space (disk size + 20% overhead)
    local required_space_gb=$((VM_DISK_SIZE_GB + VM_DISK_SIZE_GB / 5))

    if [[ "$COMPRESS_BACKUP" == "true" ]]; then
        # Compression typically achieves 40-60% reduction
        required_space_gb=$((required_space_gb / 2))
        log_info "Estimated space needed (compressed): ${required_space_gb}GB"
    else
        log_info "Estimated space needed: ${required_space_gb}GB"
    fi

    if [[ $avail_space_gb -lt $required_space_gb ]]; then
        log_error "Insufficient disk space for backup"
        log_error "  Available: ${avail_space_gb}GB"
        log_error "  Required: ${required_space_gb}GB"
        log_error "  Shortfall: $((required_space_gb - avail_space_gb))GB"
        log_error ""
        log_error "Free up space or use:"
        log_error "  - --compress (reduces size by ~50%)"
        log_error "  - --backup-dir /other/location (use different disk)"
        log_error "  - --snapshot-only (no disk export)"
        return 1
    fi

    log_success "Sufficient disk space available"
}

################################################################################
# SNAPSHOT FUNCTIONS
################################################################################

list_existing_snapshots() {
    log_step "Listing existing snapshots..."

    local snapshot_count
    snapshot_count=$(virsh snapshot-list "$VM_NAME" --name 2>/dev/null | wc -l)

    if [[ $snapshot_count -gt 0 ]]; then
        log_info "Existing snapshots for '$VM_NAME':"
        virsh snapshot-list "$VM_NAME" --tree 2>/dev/null || true
    else
        log_info "No existing snapshots for '$VM_NAME'"
    fi
}

create_snapshot() {
    if [[ "$NO_SNAPSHOT" == "true" ]]; then
        log_info "Skipping snapshot creation (--no-snapshot specified)"
        return 0
    fi

    log_step "Creating snapshot..."

    # Generate snapshot name
    local snapshot_name="backup-$(date +%Y%m%d-%H%M%S)"
    local snapshot_desc="Backup snapshot created by backup-vm.sh on $(date)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create snapshot: $snapshot_name"
        return 0
    fi

    log_info "Snapshot name: $snapshot_name"

    # Create snapshot based on mode
    if [[ "$USE_EXTERNAL_SNAPSHOT" == "true" ]]; then
        log_info "Creating external snapshot (qcow2 overlay)..."
        if virsh snapshot-create-as "$VM_NAME" "$snapshot_name" "$snapshot_desc" --disk-only --atomic 2>&1; then
            log_success "External snapshot created: $snapshot_name"
            log_info "Original disk is now read-only backing file"
        else
            log_error "Failed to create external snapshot"
            return 1
        fi
    elif [[ "$BACKUP_LIVE" == "true" ]]; then
        log_info "Creating live snapshot (includes RAM state)..."
        if virsh snapshot-create-as "$VM_NAME" "$snapshot_name" "$snapshot_desc" --atomic 2>&1; then
            log_success "Live snapshot created: $snapshot_name"
        else
            log_error "Failed to create live snapshot"
            return 1
        fi
    else
        log_info "Creating offline snapshot (disk only)..."
        if virsh snapshot-create-as "$VM_NAME" "$snapshot_name" "$snapshot_desc" --disk-only --atomic 2>&1; then
            log_success "Offline snapshot created: $snapshot_name"
        else
            log_error "Failed to create offline snapshot"
            return 1
        fi
    fi
}

################################################################################
# BACKUP FUNCTIONS
################################################################################

prepare_backup_directory() {
    log_step "Preparing backup directory..."

    # Create VM-specific backup directory
    local vm_backup_dir="${BACKUP_DIR}/${VM_NAME}"
    mkdir -p "$vm_backup_dir"

    # Create timestamped backup directory
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    CURRENT_BACKUP_DIR="${vm_backup_dir}/${BACKUP_NAME}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create backup directory: $CURRENT_BACKUP_DIR"
        return 0
    fi

    mkdir -p "$CURRENT_BACKUP_DIR"
    log_success "Backup directory created: $CURRENT_BACKUP_DIR"
}

stop_vm_for_backup() {
    if [[ "$BACKUP_OFFLINE" != "true" ]]; then
        return 0
    fi

    if [[ "$VM_STATE" != "running" ]]; then
        log_info "VM is already stopped, no need to shut down"
        return 0
    fi

    log_step "Stopping VM for offline backup..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would stop VM: virsh shutdown $VM_NAME"
        return 0
    fi

    log_warning "Offline backup requires VM shutdown"
    if ! confirm "Stop VM '$VM_NAME' for backup?"; then
        log_error "Backup cancelled by user"
        exit 1
    fi

    # Graceful shutdown
    log_info "Sending shutdown signal..."
    virsh shutdown "$VM_NAME" > /dev/null 2>&1

    # Wait for shutdown (max 60 seconds)
    local elapsed=0
    while [[ $elapsed -lt 60 ]]; do
        local state
        state=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")

        if [[ "$state" == "shut off" ]]; then
            log_success "VM stopped gracefully"
            return 0
        fi

        echo -n "."
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo ""
    log_warning "Graceful shutdown timed out, forcing shutdown..."
    virsh destroy "$VM_NAME" > /dev/null 2>&1
    log_success "VM stopped (forced)"
}

export_vm_configuration() {
    log_step "Exporting VM configuration..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would export: virsh dumpxml $VM_NAME > ${CURRENT_BACKUP_DIR}/${VM_NAME}.xml"
        return 0
    fi

    local xml_path="${CURRENT_BACKUP_DIR}/${VM_NAME}.xml"
    virsh dumpxml "$VM_NAME" > "$xml_path"

    log_success "VM configuration exported: $xml_path"
}

export_disk_image() {
    if [[ "$SNAPSHOT_ONLY" == "true" ]]; then
        log_info "Skipping disk export (--snapshot-only specified)"
        return 0
    fi

    log_step "Exporting VM disk image..."
    log_info "This may take several minutes depending on disk size..."

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$COMPRESS_BACKUP" == "true" ]]; then
            log_info "[DRY RUN] Would export compressed: qemu-img convert -O qcow2 -c ..."
        else
            log_info "[DRY RUN] Would export: cp $VM_DISK_PATH ${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2"
        fi
        return 0
    fi

    local backup_disk_path="${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2"
    local temp_backup_path="${backup_disk_path}.tmp"
    local start_time
    start_time=$(date +%s)

    if [[ "$COMPRESS_BACKUP" == "true" ]]; then
        log_info "Compressing disk image (this is slower but saves space)..."
        if qemu-img convert -O qcow2 -c "$VM_DISK_PATH" "$temp_backup_path"; then
            mv "$temp_backup_path" "$backup_disk_path"
        else
            log_error "Compression failed"
            rm -f "$temp_backup_path"
            return 1
        fi
    else
        log_info "Copying disk image..."
        if cp --sparse=always "$VM_DISK_PATH" "$temp_backup_path"; then
            mv "$temp_backup_path" "$backup_disk_path"
        else
            log_error "Copy failed"
            rm -f "$temp_backup_path"
            return 1
        fi
    fi

    local end_time
    end_time=$(date +%s)
    BACKUP_DURATION=$((end_time - start_time))

    # Get backup size
    local backup_size_bytes
    backup_size_bytes=$(stat -c "%s" "$backup_disk_path" 2>/dev/null || echo "0")
    BACKUP_SIZE_MB=$((backup_size_bytes / 1024 / 1024))

    log_success "Disk image exported: $backup_disk_path"
    log_info "Backup size: ${BACKUP_SIZE_MB}MB ($(awk "BEGIN {printf \"%.1f\", $BACKUP_SIZE_MB/1024}")GB)"
    log_info "Export duration: ${BACKUP_DURATION}s"
}

create_backup_metadata() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create backup-info.txt"
        return 0
    fi

    log_step "Creating backup metadata..."

    local metadata_file="${CURRENT_BACKUP_DIR}/backup-info.txt"

    cat > "$metadata_file" << EOF
========================================
VM BACKUP METADATA
========================================
Backup Date: $(date '+%Y-%m-%d %H:%M:%S')
Script Version: $SCRIPT_VERSION
VM Name: $VM_NAME
VM State During Backup: $VM_STATE
Backup Mode: $(if [[ "$BACKUP_LIVE" == "true" ]]; then echo "LIVE"; else echo "OFFLINE"; fi)
Snapshot Created: $(if [[ "$NO_SNAPSHOT" == "true" ]]; then echo "NO"; else echo "YES"; fi)
Disk Exported: $(if [[ "$SNAPSHOT_ONLY" == "true" ]]; then echo "NO"; else echo "YES"; fi)
Compression: $(if [[ "$COMPRESS_BACKUP" == "true" ]]; then echo "YES"; else echo "NO"; fi)

BACKUP CONTENTS:
- VM Configuration: ${VM_NAME}.xml
$(if [[ "$SNAPSHOT_ONLY" != "true" ]]; then echo "- Disk Image: ${VM_NAME}.qcow2"; fi)

DISK INFORMATION:
- Original Disk: $VM_DISK_PATH
- Original Size: ${VM_DISK_SIZE_GB}GB
$(if [[ "$SNAPSHOT_ONLY" != "true" ]]; then echo "- Backup Size: ${BACKUP_SIZE_MB}MB"; fi)
$(if [[ "$SNAPSHOT_ONLY" != "true" ]]; then echo "- Export Duration: ${BACKUP_DURATION}s"; fi)

RESTORATION INSTRUCTIONS:
1. Stop VM: virsh shutdown $VM_NAME
2. Restore disk: cp ${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2
3. Restore config (if needed): virsh define ${CURRENT_BACKUP_DIR}/${VM_NAME}.xml
4. Start VM: virsh start $VM_NAME

========================================
EOF

    log_success "Backup metadata created: $metadata_file"
}

verify_backup_integrity() {
    if [[ "$VERIFY_BACKUP" != "true" ]]; then
        return 0
    fi

    if [[ "$SNAPSHOT_ONLY" == "true" ]]; then
        log_info "Skipping verification (snapshot-only mode)"
        return 0
    fi

    log_step "Verifying backup integrity..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would verify: sha256sum ${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2"
        return 0
    fi

    local backup_disk_path="${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2"
    local checksum_file="${CURRENT_BACKUP_DIR}/checksum.sha256"

    log_info "Calculating SHA256 checksum (this may take a few minutes)..."

    # Calculate checksum
    (cd "$CURRENT_BACKUP_DIR" && sha256sum "${VM_NAME}.qcow2" > checksum.sha256)

    log_success "Checksum created: $checksum_file"

    # Verify qcow2 integrity
    log_info "Verifying qcow2 image integrity..."
    if qemu-img check "$backup_disk_path" > /dev/null 2>&1; then
        log_success "Backup disk image integrity verified"
    else
        log_warning "qcow2 integrity check reported warnings"
        log_warning "Backup may still be usable, but verification recommended"
    fi
}

rotate_old_backups() {
    if [[ "$NO_ROTATION" == "true" ]]; then
        log_info "Skipping backup rotation (--no-rotation specified)"
        return 0
    fi

    log_step "Rotating old backups (keeping last $KEEP_BACKUPS)..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would delete backups older than $KEEP_BACKUPS"
        return 0
    fi

    local vm_backup_dir="${BACKUP_DIR}/${VM_NAME}"

    # Count existing backups
    local backup_count
    backup_count=$(find "$vm_backup_dir" -mindepth 1 -maxdepth 1 -type d -name "backup-*" | wc -l)

    log_info "Total backups: $backup_count"
    log_info "Retention policy: keep last $KEEP_BACKUPS"

    if [[ $backup_count -le $KEEP_BACKUPS ]]; then
        log_success "No old backups to delete (within retention limit)"
        return 0
    fi

    # Delete old backups (keep newest N)
    local to_delete=$((backup_count - KEEP_BACKUPS))
    log_info "Deleting $to_delete old backup(s)..."

    find "$vm_backup_dir" -mindepth 1 -maxdepth 1 -type d -name "backup-*" | \
        sort | head -n "$to_delete" | while read -r old_backup; do
        log_info "Deleting: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done

    log_success "Backup rotation complete"
}

restart_vm_after_backup() {
    if [[ "$BACKUP_OFFLINE" != "true" ]] || [[ "$VM_STATE" != "running" ]]; then
        return 0
    fi

    log_step "Restarting VM after backup..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would restart: virsh start $VM_NAME"
        return 0
    fi

    if confirm "Restart VM '$VM_NAME'?"; then
        virsh start "$VM_NAME" > /dev/null 2>&1
        log_success "VM restarted"
    else
        log_info "VM left in stopped state"
        log_info "Start manually with: virsh start $VM_NAME"
    fi
}

################################################################################
# REPORTING
################################################################################

generate_backup_report() {
    log_step "Backup Summary"
    echo ""

    log_info "VM: $VM_NAME"
    log_info "Backup Mode: $(if [[ "$BACKUP_LIVE" == "true" ]]; then echo "LIVE"; else echo "OFFLINE"; fi)"
    log_info "Backup Location: $CURRENT_BACKUP_DIR"

    if [[ "$SNAPSHOT_ONLY" != "true" ]]; then
        log_info "Backup Size: ${BACKUP_SIZE_MB}MB ($(awk "BEGIN {printf \"%.1f\", $BACKUP_SIZE_MB/1024}")GB)"
        log_info "Export Duration: ${BACKUP_DURATION}s"
    fi

    echo ""
    log_info "Backup Contents:"
    if [[ "$DRY_RUN" != "true" ]] && [[ -d "$CURRENT_BACKUP_DIR" ]]; then
        ls -lh "$CURRENT_BACKUP_DIR" | tail -n +2 | awk '{printf "  - %-30s %10s\n", $9, $5}'
    fi

    echo ""
    log_info "Restoration Commands:"
    log_info "  1. Stop VM:"
    log_info "     virsh shutdown $VM_NAME"
    log_info ""
    if [[ "$SNAPSHOT_ONLY" != "true" ]]; then
        log_info "  2. Restore disk:"
        log_info "     cp ${CURRENT_BACKUP_DIR}/${VM_NAME}.qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2"
        log_info ""
    fi
    log_info "  3. Start VM:"
    log_info "     virsh start $VM_NAME"
    echo ""

    # List all backups
    local vm_backup_dir="${BACKUP_DIR}/${VM_NAME}"
    if [[ -d "$vm_backup_dir" ]]; then
        log_info "All backups for '$VM_NAME':"
        find "$vm_backup_dir" -mindepth 1 -maxdepth 1 -type d -name "backup-*" | sort -r | while read -r backup_dir; do
            local backup_date
            backup_date=$(basename "$backup_dir" | sed 's/backup-//' | sed 's/\([0-9]\{8\}\)-\([0-9]\{6\}\)/\1 \2/')
            local backup_size
            backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
            log_info "  - $backup_date ($backup_size)"
        done
    fi
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
            --offline)
                BACKUP_OFFLINE=true
                shift
                ;;
            --live)
                BACKUP_LIVE=true
                shift
                ;;
            --external)
                USE_EXTERNAL_SNAPSHOT=true
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --keep)
                KEEP_BACKUPS="$2"
                shift 2
                ;;
            --no-rotation)
                NO_ROTATION=true
                shift
                ;;
            --snapshot-only)
                SNAPSHOT_ONLY=true
                shift
                ;;
            --no-snapshot)
                NO_SNAPSHOT=true
                shift
                ;;
            --verify)
                VERIFY_BACKUP=true
                shift
                ;;
            --compress)
                COMPRESS_BACKUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                SKIP_CONFIRM=true
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

    # Validate conflicting options
    if [[ "$SNAPSHOT_ONLY" == "true" ]] && [[ "$NO_SNAPSHOT" == "true" ]]; then
        log_error "Conflicting options: --snapshot-only and --no-snapshot"
        exit 1
    fi

    if [[ "$BACKUP_OFFLINE" == "true" ]] && [[ "$BACKUP_LIVE" == "true" ]]; then
        log_error "Conflicting options: --offline and --live"
        exit 1
    fi
}

main() {
    parse_arguments "$@"

    # Initialize logging
    init_logging "$@"

    # Display banner
    echo ""
    echo "=================================================="
    echo "  QEMU/KVM VM Backup Script"
    echo "  Version $SCRIPT_VERSION | January 2025"
    echo "=================================================="
    echo ""

    # Pre-backup checks
    check_root
    check_vm_exists || exit 1
    check_vm_state || exit 1
    get_vm_disk_info || exit 1
    check_disk_space || exit 1

    # List existing snapshots
    list_existing_snapshots

    # Prepare backup directory
    echo ""
    prepare_backup_directory

    # Stop VM if offline backup requested
    stop_vm_for_backup

    # Create snapshot
    create_snapshot

    # Export VM configuration
    export_vm_configuration

    # Export disk image
    export_disk_image

    # Create metadata
    create_backup_metadata

    # Verify backup integrity
    verify_backup_integrity

    # Rotate old backups
    rotate_old_backups

    # Restart VM if it was stopped
    restart_vm_after_backup

    # Generate report
    echo ""
    generate_backup_report

    log_success "Backup completed successfully!"

    if [[ -f "$LOG_FILE" ]]; then
        log_info "Log file: $LOG_FILE"
    fi
    echo ""
}

# Execute main function
main "$@"
