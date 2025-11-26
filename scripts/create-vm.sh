#!/bin/bash

################################################################################
# Windows 11 VM Creation Script for QEMU/KVM
#
# This script automates the creation of a Windows 11 virtual machine with:
# - Q35 chipset (modern PCI-Express support)
# - UEFI/OVMF firmware with Secure Boot
# - TPM 2.0 emulation (Windows 11 requirement)
# - 14 Hyper-V enlightenments (85-95% native performance)
# - VirtIO drivers for all devices (disk, network, graphics)
# - Comprehensive pre-flight validation
#
# USAGE:
#   sudo ./scripts/create-vm.sh [OPTIONS]
#
# OPTIONS:
#   --name NAME         VM name (default: win11-outlook)
#   --ram MB            RAM allocation in MB (default: 8192)
#   --vcpus COUNT       Number of vCPUs (default: 4)
#   --disk GB           Disk size in GB (default: 100)
#   --dry-run           Preview actions without executing
#   --help              Display this help message
#
# EXAMPLES:
#   # Default installation
#   sudo ./scripts/create-vm.sh
#
#   # Custom configuration
#   sudo ./scripts/create-vm.sh --name my-win11 --ram 16384 --vcpus 8 --disk 200
#
#   # Preview without creating
#   ./scripts/create-vm.sh --dry-run
#
# REQUIREMENTS:
#   - Ubuntu 25.10 or compatible Linux distribution
#   - QEMU/KVM installed (qemu-system-x86, libvirt, etc.)
#   - Hardware virtualization enabled (Intel VT-x or AMD-V)
#   - Minimum 16GB RAM, 8 CPU cores, SSD storage
#   - Windows 11 ISO and VirtIO drivers ISO in source-iso/ directory
#
# AUTHOR: win-qemu project
# VERSION: 1.0.0
# LAST UPDATED: 2025-01-19
################################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures

################################################################################
# CONFIGURATION
################################################################################

# Script directory (absolute# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
DEFAULT_VM_NAME="win11-vm"
DEFAULT_RAM_MB="8192"
DEFAULT_VCPUS="4"
DEFAULT_DISK_GB="100"

# Directories (using PROJECT_ROOT from common.sh)
CONFIG_TEMPLATE="${PROJECT_ROOT}/configs/win11-vm.xml"
SOURCE_ISO_DIR="${PROJECT_ROOT}/source-iso"
VM_IMAGES_DIR="/var/lib/libvirt/images"
NVRAM_DIR="/var/lib/libvirt/qemu/nvram"
TPM_DIR="/var/lib/libvirt/swtpm"

################################################################################
# HELP FUNCTION
################################################################################

show_help() {
    cat <<'EOF'
USAGE:
    create-vm.sh [OPTIONS]

DESCRIPTION:
    Creates a new Windows 11 virtual machine with QEMU/KVM, optimized for
    running Microsoft 365 Outlook with near-native performance (85-95%).

OPTIONS:
    --name NAME         VM name (default: win11-outlook)
    --ram MB           RAM in MB (default: 8192)
    --vcpus NUM        Number of vCPUs (default: 4)
    --disk GB          Disk size in GB (default: 100)
    --iso PATH         Windows ISO path (default: source-iso/Win11.iso)
    --virtio-iso PATH  VirtIO drivers ISO (default: source-iso/virtio-win.iso)
    --dry-run          Validate without creating VM
    --help             Show this help message

PREREQUISITES:
    1. QEMU/KVM installed: sudo ./scripts/install-master.sh

    2. User permissions:
       - Must be in 'libvirt' and 'kvm' groups
       - Run: sudo usermod -aG libvirt,kvm $USER
       - Then logout/login or reboot

    3. ISOs (place in source-iso/ directory):
       - Win11.iso: Windows 11 installation media
         Download: https://www.microsoft.com/software-download/windows11
       - virtio-win.iso: VirtIO drivers for Windows
         Download: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

    4. Permissions:
       - User must be in 'libvirt' and 'kvm' groups
       - Script must be run with sudo

PRE-FLIGHT CHECKS:
    This script performs comprehensive validation before VM creation:
    ✅ Hardware virtualization enabled (vmx/svm)
    ✅ Sufficient RAM available
    ✅ SSD storage detected
    ✅ Adequate CPU cores
    ✅ QEMU/KVM packages installed
    ✅ libvirtd service running
    ✅ User in libvirt/kvm groups
    ✅ Required ISOs present
    ✅ Sufficient disk space
    ✅ Template configuration file exists

WHAT THIS SCRIPT DOES:
    1. Validates system compatibility (hardware, software, resources)
    2. Prompts for VM configuration (or uses command-line arguments)
    3. Creates VM disk image (qcow2 format)
    4. Generates VM XML configuration from template
    5. Defines VM with libvirt (virsh define)
    6. Sets up TPM state directory
    7. Provides instructions for Windows installation

WHAT THIS SCRIPT DOES NOT DO:
    - Install Windows (manual step via virt-manager or virt-viewer)
    - Configure network beyond NAT default
    - Apply post-installation optimizations (use other scripts)
    - Install VirtIO drivers in Windows (manual during/after install)

POST-CREATION STEPS:
    1. Start VM: virsh start <vm-name>
       Or use virt-manager GUI

    2. Install Windows 11:
       - Boot from Windows 11 ISO
       - At "Where do you want to install Windows?" screen:
         * Click "Load driver"
         * Browse to virtio-win.iso → viostor\w11\amd64
         * Load VirtIO storage driver
         * Disk will appear, proceed with installation

    3. After Windows installation:
       - Install remaining VirtIO drivers from virtio-win.iso
       - Install QEMU Guest Agent (guest-agent/qemu-ga-x86_64.msi)
       - Run Windows Updates
       - Activate Windows with valid license key

    4. Optimization (see performance-optimization-playbook.md):
       - Verify Hyper-V enlightenments active
       - Configure CPU pinning (optional)
       - Enable huge pages (optional)
       - Benchmark performance (CrystalDiskMark)

    5. Security Hardening (see security-hardening-analysis.md):
       - Enable BitLocker encryption
       - Configure Windows Firewall
       - Setup virtio-fs for PST file sharing (read-only mode)
       - Create backup snapshots

PERFORMANCE EXPECTATIONS:
    With full optimization: 85-95% of native Windows performance
    - Boot time: <25 seconds
    - Outlook startup: <5 seconds
    - Disk IOPS: >40,000 (4K random reads)

TROUBLESHOOTING:
    - Permission denied: Ensure user in libvirt/kvm groups, run with sudo
    - ISOs not found: Place ISOs in source-iso/ directory with exact names
    - VM already exists: Use different --name or delete existing VM
    - libvirtd not running: sudo systemctl start libvirtd

FOR MORE INFORMATION:
    - Main guide: outlook-linux-guide/05-qemu-kvm-reference-architecture.md
    - Performance: outlook-linux-guide/09-performance-optimization-playbook.md
    - Security: research/06-security-hardening-analysis.md

EOF
}

################################################################################
# PRE-FLIGHT VALIDATION FUNCTIONS
################################################################################


check_hardware_virtualization() {
    log_step "Checking hardware virtualization support..."
    local virt_count
    virt_count=$(grep -c -E '(vmx|svm)' /proc/cpuinfo || true)

    if [[ $virt_count -eq 0 ]]; then
        log_error "Hardware virtualization not enabled"
        log_error "Enable Intel VT-x or AMD-V in BIOS/UEFI settings"
        log_error "Reboot and enter BIOS setup (usually F2, F10, or Del key)"
        return 1
    fi

    log_success "Hardware virtualization enabled ($virt_count cores with vmx/svm)"
}

check_ram() {
    log_step "Checking available RAM..."
    local total_ram_gb
    total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')

    if [[ $total_ram_gb -lt 16 ]]; then
        log_warning "RAM below recommended minimum (${total_ram_gb}GB detected, 16GB recommended)"
        log_warning "VM performance may be degraded with less than 16GB total RAM"
        log_warning "Consider upgrading RAM or reducing VM allocation"
    else
        log_success "Sufficient RAM available (${total_ram_gb}GB total)"
    fi
}

check_ssd() {
    log_step "Checking storage type..."
    local ssd_count
    ssd_count=$(lsblk -d -o name,rota | grep -c "0$" || true)

    if [[ $ssd_count -eq 0 ]]; then
        log_warning "No SSD detected (HDD storage)"
        log_warning "HDD will result in 50-60% performance (unusable for daily work)"
        log_warning "SSD is STRONGLY RECOMMENDED for acceptable performance"
    else
        log_success "SSD storage detected"
    fi
}

check_cpu_cores() {
    log_step "Checking CPU cores..."
    local core_count
    core_count=$(nproc)

    if [[ $core_count -lt 8 ]]; then
        log_warning "CPU cores below recommended minimum ($core_count cores, 8 recommended)"
        log_warning "Performance may be degraded with fewer cores"
    else
        log_success "Sufficient CPU cores ($core_count cores available)"
    fi
}

check_qemu_kvm_installed() {
    log_step "Checking QEMU/KVM installation..."

    # In dry-run mode, skip package check to allow preview without QEMU installed
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping QEMU/KVM package check"
        log_info "[DRY RUN] Would verify: qemu-system-x86, qemu-kvm, libvirt-daemon-system, libvirt-clients, ovmf, swtpm"
        return 0
    fi

    local missing_packages=()

    local required_packages=(
        "qemu-system-x86"
        "qemu-kvm"
        "libvirt-daemon-system"
        "libvirt-clients"
        "ovmf"
        "swtpm"
    )

    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*${package}"; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_error "Missing required packages: ${missing_packages[*]}"
        log_error "Install with: sudo apt install -y ${missing_packages[*]}"
        return 1
    fi

    log_success "All required QEMU/KVM packages installed"
}


check_user_groups() {
    log_step "Checking user group membership..."

    # In dry-run mode, skip group check to allow preview
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping user group check"
        log_info "[DRY RUN] Would verify user is in libvirt and kvm groups"
        return 0
    fi

    local actual_user="${SUDO_USER:-$USER}"
    local missing_groups=()

    if ! groups "$actual_user" | grep -q libvirt; then
        missing_groups+=("libvirt")
    fi

    if ! groups "$actual_user" | grep -q kvm; then
        missing_groups+=("kvm")
    fi

    if [[ ${#missing_groups[@]} -gt 0 ]]; then
        log_error "User '$actual_user' not in required groups: ${missing_groups[*]}"
        log_error "Add user to groups: sudo usermod -aG libvirt,kvm $actual_user"
        log_error "Then log out and back in for changes to take effect"
        return 1
    fi

    log_success "User '$actual_user' in libvirt and kvm groups"
}

check_isos_exist() {
    log_step "Checking for required ISO files..."

    # In dry-run mode, skip ISO check to allow preview
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping ISO file check"
        log_info "[DRY RUN] Would verify: Win11.iso, virtio-win.iso in ${SOURCE_ISO_DIR}"
        return 0
    fi

    local missing_isos=()
    local win11_iso="${SOURCE_ISO_DIR}/Win11.iso"
    local virtio_iso="${SOURCE_ISO_DIR}/virtio-win.iso"

    # 1. Check Windows 11 ISO
    if [[ ! -f "$win11_iso" ]]; then
        log_warning "Win11.iso not found in ${SOURCE_ISO_DIR}"
        
        # Search for potential candidates
        local candidates=($(find "$SOURCE_ISO_DIR" -maxdepth 1 -name "Win11*.iso" -o -name "Windows11*.iso"))
        
        if [[ ${#candidates[@]} -gt 0 ]]; then
            log_info "Found potential Windows 11 ISOs:"
            for i in "${!candidates[@]}"; do
                echo "  [$i] $(basename "${candidates[$i]}")"
            done
            
            if [[ "$DRY_RUN" == "false" ]]; then
                read -p "Select an ISO to rename to Win11.iso (0-${#candidates[@]-1}, or 'n' to skip): " selection
                if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -lt "${#candidates[@]}" ]]; then
                    local selected_iso="${candidates[$selection]}"
                    log_info "Renaming $(basename "$selected_iso") to Win11.iso..."
                    mv "$selected_iso" "$win11_iso"
                    log_success "Renamed successfully"
                else
                    missing_isos+=("Win11.iso")
                fi
            else
                log_info "[DRY RUN] Would prompt to rename candidate ISO"
                missing_isos+=("Win11.iso")
            fi
        else
            missing_isos+=("Win11.iso")
        fi
    fi

    # 2. Check VirtIO Drivers ISO
    if [[ ! -f "$virtio_iso" ]]; then
        log_warning "virtio-win.iso not found"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            read -p "Download latest VirtIO drivers now? (y/n): " download_confirm
            if [[ "$download_confirm" =~ ^[Yy]$ ]]; then
                log_info "Downloading virtio-win.iso..."
                if wget -O "$virtio_iso" --show-progress "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"; then
                    log_success "Download complete"
                else
                    log_error "Download failed"
                    missing_isos+=("virtio-win.iso")
                fi
            else
                missing_isos+=("virtio-win.iso")
            fi
        else
            log_info "[DRY RUN] Would prompt to download virtio-win.iso"
            missing_isos+=("virtio-win.iso")
        fi
    fi

    # Final Verification
    if [[ ${#missing_isos[@]} -gt 0 ]]; then
        log_error "Missing ISO files in ${SOURCE_ISO_DIR}:"
        for iso in "${missing_isos[@]}"; do
            log_error "  - $iso"
        done
        log_error ""
        log_error "Download locations:"
        log_error "  Windows 11: https://www.microsoft.com/software-download/windows11"
        log_error "  VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/"
        return 1
    fi

    log_success "Required ISOs found:"
    log_success "  - Win11.iso ($(du -h "$win11_iso" | cut -f1))"
    log_success "  - virtio-win.iso ($(du -h "$virtio_iso" | cut -f1))"
}

check_disk_space() {
    log_step "Checking available disk space..."

    # In dry-run mode, still check disk space but don't fail
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        local vm_images_avail
        vm_images_avail=$(df -BG "$VM_IMAGES_DIR" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
        log_warning "[DRY RUN] Disk space check: ${vm_images_avail}GB available (150GB minimum required)"
        return 0
    fi

    local vm_images_avail
    vm_images_avail=$(df -BG "$VM_IMAGES_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')

    if [[ $vm_images_avail -lt 150 ]]; then
        log_error "Insufficient disk space in $VM_IMAGES_DIR"
        log_error "Available: ${vm_images_avail}GB, Required: 150GB minimum"
        log_error "Free up space or use a different storage location"
        return 1
    fi

    log_success "Sufficient disk space (${vm_images_avail}GB available)"
}

check_template_exists() {
    log_step "Checking for VM template configuration..."

    # In dry-run mode, skip template check but show what would be verified
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping template check"
        log_info "[DRY RUN] Would verify: $CONFIG_TEMPLATE exists"
        return 0
    fi

    if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
        log_error "Template configuration not found: $CONFIG_TEMPLATE"
        log_error "Ensure configs/win11-vm.xml exists in the project directory"
        return 1
    fi

    log_success "Template configuration found: $CONFIG_TEMPLATE"
}

run_preflight_checks() {
    log_step "Running pre-flight validation checks..."
    echo ""

    local checks_failed=0

    # Critical checks (must pass)
    check_root || ((checks_failed++))
    check_hardware_virtualization || ((checks_failed++))
    check_qemu_kvm_installed || ((checks_failed++))
    check_libvirtd || ((checks_failed++))
    check_user_groups || ((checks_failed++))
    check_isos_exist || ((checks_failed++))
    check_disk_space || ((checks_failed++))
    check_template_exists || ((checks_failed++))

    # Warning checks (can proceed with warnings)
    check_ram  # Warning only
    check_ssd  # Warning only
    check_cpu_cores  # Warning only

    echo ""

    if [[ $checks_failed -gt 0 ]]; then
        log_error "Pre-flight checks failed ($checks_failed critical errors)"
        log_error "Fix the above issues before proceeding"
        return 1
    fi

    log_success "All pre-flight checks passed!"
    return 0
}

################################################################################
# VM CONFIGURATION FUNCTIONS
################################################################################

prompt_vm_config() {
    log_step "VM Configuration"
    echo ""

    # VM Name
    read -p "Enter VM name (default: $DEFAULT_VM_NAME): " VM_NAME
    VM_NAME="${VM_NAME:-$DEFAULT_VM_NAME}"

    # Check if VM already exists
    if virsh dominfo "$VM_NAME" &>/dev/null; then
        log_error "VM '$VM_NAME' already exists"
        read -p "Do you want to overwrite it? This will DELETE the existing VM! (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_error "VM creation cancelled"
            exit 1
        fi
        log_warning "Will delete existing VM '$VM_NAME' before creating new one"
        OVERWRITE_EXISTING=true
    fi

    # RAM
    read -p "Enter RAM in MB (default: $DEFAULT_RAM_MB, minimum: 4096): " RAM_MB
    RAM_MB="${RAM_MB:-$DEFAULT_RAM_MB}"

    if [[ $RAM_MB -lt 4096 ]]; then
        log_error "RAM must be at least 4096MB (4GB)"
        exit 1
    fi

    # vCPUs
    local max_vcpus
    max_vcpus=$(nproc)
    read -p "Enter number of vCPUs (default: $DEFAULT_VCPUS, maximum: $max_vcpus): " VCPUS
    VCPUS="${VCPUS:-$DEFAULT_VCPUS}"

    if [[ $VCPUS -gt $max_vcpus ]]; then
        log_error "vCPUs cannot exceed host CPU count ($max_vcpus)"
        exit 1
    fi

    # Disk Size
    read -p "Enter disk size in GB (default: $DEFAULT_DISK_GB, minimum: 60): " DISK_GB
    DISK_GB="${DISK_GB:-$DEFAULT_DISK_GB}"

    if [[ $DISK_GB -lt 60 ]]; then
        log_error "Disk size must be at least 60GB"
        exit 1
    fi

    echo ""
    log_info "VM Configuration Summary:"
    log_info "  Name: $VM_NAME"
    log_info "  RAM: ${RAM_MB}MB ($(awk "BEGIN {printf \"%.1f\", $RAM_MB/1024}")GB)"
    log_info "  vCPUs: $VCPUS"
    log_info "  Disk: ${DISK_GB}GB"
    echo ""

    read -p "Proceed with VM creation? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_error "VM creation cancelled by user"
        exit 1
    fi
}

################################################################################
# VM CREATION FUNCTIONS
################################################################################

delete_existing_vm() {
    local vm_name="$1"

    log_step "Deleting existing VM '$vm_name'..."

    # Stop VM if running
    if virsh domstate "$vm_name" 2>/dev/null | grep -q "running"; then
        log_info "Stopping VM..."
        virsh destroy "$vm_name" || true
    fi

    # Undefine VM (removes configuration)
    log_info "Removing VM definition..."
    virsh undefine "$vm_name" --nvram --remove-all-storage || true

    # Clean up TPM directory
    if [[ -d "${TPM_DIR}/${vm_name}" ]]; then
        log_info "Removing TPM state directory..."
        rm -rf "${TPM_DIR}/${vm_name}"
    fi

    log_success "Existing VM deleted"
}

create_vm_disk() {
    local vm_name="$1"
    local disk_size_gb="$2"
    local disk_path="${VM_IMAGES_DIR}/${vm_name}.qcow2"

    log_step "Creating VM disk image..."

    if [[ -f "$disk_path" ]]; then
        log_warning "Disk image already exists: $disk_path"
        log_warning "It will be overwritten"
        rm -f "$disk_path"
    fi

    qemu-img create -f qcow2 "$disk_path" "${disk_size_gb}G"

    # Set proper permissions
    chown libvirt-qemu:kvm "$disk_path"
    chmod 660 "$disk_path"

    log_success "VM disk created: $disk_path (${disk_size_gb}GB)"
}

generate_vm_xml() {
    local vm_name="$1"
    local ram_mb="$2"
    local vcpus="$3"
    local output_file="$4"

    log_step "Generating VM XML configuration..."

    # Generate UUID
    local vm_uuid
    vm_uuid=$(uuidgen)

    # Get actual user's home directory
    local user_home
    user_home=$(eval echo "~${SUDO_USER:-$USER}")

    # Copy template and replace placeholders
    cp "$CONFIG_TEMPLATE" "$output_file"

    sed -i "s/VM_NAME/$vm_name/g" "$output_file"
    sed -i "s/GENERATE_UUID/$vm_uuid/g" "$output_file"
    sed -i "s/RAM_MB/$ram_mb/g" "$output_file"
    sed -i "s/VCPU_COUNT/$vcpus/g" "$output_file"
    sed -i "s|USER_HOME|$user_home|g" "$output_file"

    # Update TPM encryption secret name
    sed -i "s/tpm-VM_NAME/tpm-${vm_name}/g" "$output_file"

    log_success "VM XML configuration generated: $output_file"
}

define_vm() {
    local xml_file="$1"

    log_step "Defining VM with libvirt..."

    virsh define "$xml_file"

    log_success "VM defined successfully"
}

setup_tpm_directory() {
    local vm_name="$1"
    local tpm_path="${TPM_DIR}/${vm_name}"

    log_step "Setting up TPM state directory..."

    mkdir -p "$tpm_path"
    chown tss:tss "$tpm_path"
    chmod 750 "$tpm_path"

    log_success "TPM directory created: $tpm_path"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    # Parse command-line arguments
    DRY_RUN=false
    OVERWRITE_EXISTING=false
    VM_NAME=""
    RAM_MB=""
    VCPUS=""
    DISK_GB=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --name)
                VM_NAME="$2"
                shift 2
                ;;
            --ram)
                RAM_MB="$2"
                shift 2
                ;;
            --vcpus)
                VCPUS="$2"
                shift 2
                ;;
            --disk)
                DISK_GB="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Initialize logging
    init_logging "create-vm"

    # Display banner
    echo ""
    echo "=================================================="
    echo "  Windows 11 VM Creation Script for QEMU/KVM"
    echo "  Version 1.0.0 | January 2025"
    echo "=================================================="
    echo ""

    # Run pre-flight checks
    if ! run_preflight_checks; then
        log_error "Pre-flight checks failed. Cannot proceed."
        exit 1
    fi

    # Get VM configuration (interactive or from arguments)
    if [[ -z "$VM_NAME" ]] || [[ -z "$RAM_MB" ]] || [[ -z "$VCPUS" ]] || [[ -z "$DISK_GB" ]]; then
        prompt_vm_config
    else
        # Validate provided arguments
        if [[ $RAM_MB -lt 4096 ]]; then
            log_error "RAM must be at least 4096MB"
            exit 1
        fi

        local max_vcpus
        max_vcpus=$(nproc)
        if [[ $VCPUS -gt $max_vcpus ]]; then
            log_error "vCPUs cannot exceed host CPU count ($max_vcpus)"
            exit 1
        fi

        if [[ $DISK_GB -lt 60 ]]; then
            log_error "Disk size must be at least 60GB"
            exit 1
        fi

        # Check if VM exists
        if virsh dominfo "$VM_NAME" &>/dev/null; then
            log_error "VM '$VM_NAME' already exists"
            log_error "Delete it first with: virsh undefine $VM_NAME --nvram --remove-all-storage"
            exit 1
        fi
    fi

    # Dry-run mode
    if [[ "$DRY_RUN" == true ]]; then
        log_step "DRY-RUN MODE - No changes will be made"
        echo ""
        log_info "Would create VM with:"
        log_info "  Name: $VM_NAME"
        log_info "  RAM: ${RAM_MB}MB"
        log_info "  vCPUs: $VCPUS"
        log_info "  Disk: ${DISK_GB}GB"
        log_info "  Disk path: ${VM_IMAGES_DIR}/${VM_NAME}.qcow2"
        log_info "  NVRAM path: ${NVRAM_DIR}/${VM_NAME}_VARS.fd"
        log_info "  TPM path: ${TPM_DIR}/${VM_NAME}/"
        echo ""
        log_success "Dry-run complete. Use without --dry-run to create VM."
        exit 0
    fi

    # Delete existing VM if overwriting
    if [[ "$OVERWRITE_EXISTING" == true ]]; then
        delete_existing_vm "$VM_NAME"
    fi

    # Create VM
    log_step "Creating Windows 11 VM: $VM_NAME"
    echo ""

    create_vm_disk "$VM_NAME" "$DISK_GB"

    local temp_xml="/tmp/${VM_NAME}.xml"
    generate_vm_xml "$VM_NAME" "$RAM_MB" "$VCPUS" "$temp_xml"

    define_vm "$temp_xml"

    setup_tpm_directory "$VM_NAME"

    # Clean up temporary XML
    rm -f "$temp_xml"

    # Display VM info
    echo ""
    log_step "VM Creation Complete!"
    echo ""

    virsh dominfo "$VM_NAME"

    echo ""
    log_success "VM '$VM_NAME' created successfully!"
    echo ""

    # Next steps
    log_step "Next Steps:"
    echo ""
    log_info "1. Start the VM:"
    log_info "   virsh start $VM_NAME"
    log_info "   OR"
    log_info "   virt-manager  (GUI - double-click VM to open console)"
    echo ""
    log_info "2. Install Windows 11:"
    log_info "   - Boot from Windows 11 ISO"
    log_info "   - At 'Where do you want to install Windows?' screen:"
    log_info "     a. Click 'Load driver'"
    log_info "     b. Browse to virtio-win.iso → viostor\\w11\\amd64"
    log_info "     c. Load VirtIO storage driver"
    log_info "     d. Disk will appear, proceed with installation"
    echo ""
    log_info "3. After Windows installation:"
    log_info "   - Install all VirtIO drivers from virtio-win.iso"
    log_info "   - Install QEMU Guest Agent (guest-agent/qemu-ga-x86_64.msi)"
    log_info "   - Run Windows Updates"
    log_info "   - Activate Windows with valid license key"
    echo ""
    log_info "4. Verify performance (after optimization):"
    log_info "   virsh dumpxml $VM_NAME | grep -c hyperv"
    log_info "   (Should return >0, indicating Hyper-V enlightenments active)"
    echo ""
    log_info "5. Create baseline snapshot:"
    log_info "   virsh snapshot-create-as $VM_NAME baseline 'Fresh Windows install'"
    echo ""
    log_info "For detailed guides, see:"
    log_info "  - outlook-linux-guide/05-qemu-kvm-reference-architecture.md"
    log_info "  - outlook-linux-guide/09-performance-optimization-playbook.md"
    echo ""
    log_success "Log file: $LOG_FILE"
    echo ""
}

# Execute main function
main "$@"
