#!/usr/bin/env bash

################################################################################
# Win-QEMU Ultimate TUI - Zero Command Memorization Interface
#
# A beautiful, intelligent, guided workflow for Windows 11 VM setup on Ubuntu
# using QEMU/KVM with near-native performance.
#
# Features:
# - Wizard-style guided setup
# - Smart state management and resume capability
# - Beautiful gum-powered TUI
# - Contextual help at every step
# - Progress tracking
# - Zero commands to remember
################################################################################

set -euo pipefail

# Ensure proper Unicode/UTF-8 support for gum box drawing
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-}"
export CLICOLOR_FORCE=1

# Color codes for consistent styling
readonly COLOR_PRIMARY=212      # Pink/purple
readonly COLOR_SUCCESS=46       # Green
readonly COLOR_WARNING=226      # Yellow
readonly COLOR_ERROR=196        # Red
readonly COLOR_INFO=57          # Blue
readonly COLOR_MUTED=240        # Gray

# Directories - use absolute paths based on script location
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STATE_DIR="$PROJECT_ROOT/.installation-state"
readonly CONFIG_DIR="$PROJECT_ROOT/configs"
readonly SCRIPT_DIR="$PROJECT_ROOT/scripts"

# Get terminal width dynamically (with fallback)
get_term_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    # Cap at reasonable max, leave 4 chars margin for borders
    if [ "$width" -gt 80 ]; then
        echo 76
    elif [ "$width" -gt 40 ]; then
        echo $((width - 4))
    else
        echo 36
    fi
}

# Cache terminal width (recalculate on window resize)
TERM_WIDTH=$(get_term_width)

# State files
readonly STATE_FILE="$STATE_DIR/wizard-progress"
readonly HARDWARE_STATE="$STATE_DIR/hardware-check"
readonly SOFTWARE_STATE="$STATE_DIR/software-check"
readonly VM_STATE="$STATE_DIR/vm-info"

################################################################################
# Utility Functions
################################################################################

ensure_gum() {
    if ! command -v gum &> /dev/null; then
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  gum is not installed (required for TUI interface)           ║"
        echo "╠══════════════════════════════════════════════════════════════╣"
        echo "║  Installation options:                                       ║"
        echo "║    1. sudo apt install gum          (Ubuntu 23.04+)          ║"
        echo "║    2. brew install gum              (if Homebrew installed)  ║"
        echo "║    3. go install github.com/charmbracelet/gum@latest         ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""

        # Check if apt has gum available
        if apt-cache show gum &>/dev/null 2>&1; then
            read -p "gum is available via apt. Install now? [Y/n] " choice
            choice="${choice:-Y}"
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo "Installing gum via apt..."
                sudo apt install -y gum
                if command -v gum &> /dev/null; then
                    echo "✓ gum installed successfully!"
                    return 0
                fi
            fi
        elif command -v go &> /dev/null; then
            read -p "Go is installed. Install gum via 'go install'? [Y/n] " choice
            choice="${choice:-Y}"
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo "Installing gum via go..."
                go install github.com/charmbracelet/gum@latest
                # Add Go bin to PATH for this session
                export PATH="$PATH:$(go env GOPATH)/bin"
                if command -v gum &> /dev/null; then
                    echo "✓ gum installed successfully!"
                    echo "Note: Add $(go env GOPATH)/bin to your PATH permanently"
                    return 0
                fi
            fi
        fi

        echo "Please install gum manually and re-run this script."
        exit 1
    fi
}

init_state_dir() {
    mkdir -p "$STATE_DIR" "$CONFIG_DIR" "$SCRIPT_DIR"
}

show_header() {
    local title="$1"
    local subtitle="${2:-}"

    clear
    # Recalculate width in case terminal was resized
    TERM_WIDTH=$(get_term_width)

    gum style \
        --border double \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 2" \
        --margin "1 0" \
        --align center \
        --width "$TERM_WIDTH" \
        "$title"

    if [ -n "$subtitle" ]; then
        gum style \
            --foreground "$COLOR_INFO" \
            --padding "0 2" \
            --align center \
            --width "$TERM_WIDTH" \
            "$subtitle"
        echo ""
    fi
}

show_breadcrumb() {
    gum style \
        --foreground "$COLOR_MUTED" \
        --padding "0 1" \
        "📍 $1"
    echo ""
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" "✅ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" "❌ $1"
}

show_warning() {
    gum style --foreground "$COLOR_WARNING" "⚠️  $1"
}

show_info() {
    gum style --foreground "$COLOR_INFO" "ℹ️  $1"
}

show_section() {
    echo ""
    gum style \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 2" \
        --width "$TERM_WIDTH" \
        "$1"
    echo ""
}

pause_for_user() {
    echo ""
    gum style --foreground "$COLOR_MUTED" "Press any key to continue..."
    read -n 1 -s -r
}

# Wait for user acknowledgment before returning to parent menu
# Usage: wait_and_return "Parent Menu Name"
wait_and_return() {
    local parent_menu="${1:-Previous Menu}"
    echo ""
    gum style \
        --foreground "$COLOR_PRIMARY" \
        --bold \
        "← Press any key to return to $parent_menu..."
    read -n 1 -s -r
}

# Show a back button choice - returns true if user selected back
# Usage: if show_back_option "Parent Menu"; then break; fi
show_back_option() {
    local parent_menu="${1:-Main Menu}"
    echo ""
    if gum confirm --affirmative="← Back to $parent_menu" --negative="Stay here" "Return to previous menu?"; then
        return 0
    fi
    return 1
}

save_state() {
    local key="$1"
    local value="$2"

    # Create or update state file
    if [ -f "$STATE_FILE" ]; then
        # Remove existing key if present
        grep -v "^$key=" "$STATE_FILE" > "$STATE_FILE.tmp" 2>/dev/null || true
        mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi

    echo "$key=$value" >> "$STATE_FILE"
}

load_state() {
    local key="$1"
    local default="${2:-}"

    if [ -f "$STATE_FILE" ]; then
        grep "^$key=" "$STATE_FILE" | cut -d= -f2- || echo "$default"
    else
        echo "$default"
    fi
}

################################################################################
# Hardware Verification Functions
################################################################################

check_cpu_virtualization() {
    local count=$(egrep -c '(vmx|svm)' /proc/cpuinfo 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        local cpu_type=$(grep -o 'vmx\|svm' /proc/cpuinfo | head -1)
        local tech="Intel VT-x"
        [ "$cpu_type" = "svm" ] && tech="AMD-V"

        show_success "CPU Virtualization: Enabled ($tech, $count cores)"
        echo "cpu_virt=pass" >> "$HARDWARE_STATE"
        return 0
    else
        show_error "CPU Virtualization: Not enabled or not supported"
        echo "cpu_virt=fail" >> "$HARDWARE_STATE"
        return 1
    fi
}

check_memory() {
    local total_gb=$(free -g | awk '/^Mem:/{print $2}')
    local available_gb=$(free -g | awk '/^Mem:/{print $7}')

    if [ "$total_gb" -ge 16 ]; then
        show_success "RAM: ${total_gb}GB total, ${available_gb}GB available (16GB+ required)"
        echo "memory=pass" >> "$HARDWARE_STATE"
        return 0
    else
        show_error "RAM: ${total_gb}GB total (16GB minimum required)"
        echo "memory=fail" >> "$HARDWARE_STATE"
        return 1
    fi
}

check_storage() {
    local has_ssd=false
    local ssd_list=""

    while IFS= read -r line; do
        local device=$(echo "$line" | awk '{print $1}')
        local rota=$(echo "$line" | awk '{print $2}')

        if [ "$rota" = "0" ]; then
            has_ssd=true
            local size=$(lsblk -dno SIZE "/dev/$device" 2>/dev/null || echo "unknown")
            ssd_list="${ssd_list}${device} (${size}), "
        fi
    done < <(lsblk -dno NAME,ROTA | grep -v "^loop")

    ssd_list=${ssd_list%, }

    if $has_ssd; then
        show_success "Storage: SSD detected (${ssd_list})"
        echo "storage=pass" >> "$HARDWARE_STATE"
        return 0
    else
        show_error "Storage: No SSD detected (SSD required for usable performance)"
        echo "storage=fail" >> "$HARDWARE_STATE"
        return 1
    fi
}

check_cpu_cores() {
    local cores=$(nproc)

    if [ "$cores" -ge 8 ]; then
        show_success "CPU Cores: $cores cores (8+ recommended)"
        echo "cores=pass" >> "$HARDWARE_STATE"
        return 0
    else
        show_warning "CPU Cores: $cores cores (8+ recommended for best performance)"
        echo "cores=warning" >> "$HARDWARE_STATE"
        return 0  # Warning, not failure
    fi
}

run_hardware_check() {
    show_header "🔍 System Readiness Check" "Validating hardware requirements"
    show_breadcrumb "Main Menu > System Readiness Check"

    show_section "Hardware Requirements Validation"

    > "$HARDWARE_STATE"  # Clear previous state

    local all_pass=true

    check_cpu_virtualization || all_pass=false
    check_memory || all_pass=false
    check_storage || all_pass=false
    check_cpu_cores

    echo ""

    if $all_pass; then
        show_section "✅ All hardware requirements met!
Your system is ready for QEMU/KVM virtualization."
        save_state "hardware_check" "passed"
    else
        show_section "⚠️  Some hardware requirements not met
Review the failures above. You may continue, but performance may be poor."

        if gum confirm "Continue anyway?"; then
            save_state "hardware_check" "warning"
        else
            save_state "hardware_check" "failed"
            return 1
        fi
    fi

    pause_for_user
}

################################################################################
# Software Installation Functions
################################################################################

check_qemu_installed() {
    if command -v qemu-system-x86_64 &> /dev/null; then
        local version=$(qemu-system-x86_64 --version | head -1)
        show_success "QEMU: Installed ($version)"
        return 0
    else
        show_warning "QEMU: Not installed"
        return 1
    fi
}

check_libvirt_installed() {
    if command -v virsh &> /dev/null; then
        local version=$(virsh --version 2>/dev/null)
        show_success "libvirt: Installed (version $version)"
        return 0
    else
        show_warning "libvirt: Not installed"
        return 1
    fi
}

check_virt_manager_installed() {
    if command -v virt-manager &> /dev/null; then
        show_success "virt-manager: Installed"
        return 0
    else
        show_warning "virt-manager: Not installed"
        return 1
    fi
}

check_user_groups() {
    local user=$(whoami)
    local in_libvirt=false
    local in_kvm=false

    if groups | grep -q '\blibvirt\b'; then
        in_libvirt=true
    fi

    if groups | grep -q '\bkvm\b'; then
        in_kvm=true
    fi

    if $in_libvirt && $in_kvm; then
        show_success "User Groups: $user is in libvirt and kvm groups"
        return 0
    else
        show_warning "User Groups: $user needs to be added to libvirt and kvm groups"
        return 1
    fi
}

run_software_check() {
    show_header "📦 Software Installation Status" "Checking installed components"
    show_breadcrumb "Main Menu > Installation & Setup > Verify Installation"

    show_section "Checking QEMU/KVM Stack"

    local needs_install=false

    check_qemu_installed || needs_install=true
    check_libvirt_installed || needs_install=true
    check_virt_manager_installed || needs_install=true
    check_user_groups || needs_install=true

    echo ""

    if $needs_install; then
        return 1
    else
        show_section "✅ All software components installed!"
        save_state "software_check" "complete"
        return 0
    fi
}

install_qemu_stack() {
    show_header "📦 QEMU/KVM Installation" "Installing virtualization stack"
    show_breadcrumb "Main Menu > Installation & Setup > Install QEMU/KVM"

    show_section "The following packages will be installed:
• qemu-system-x86 (hardware emulation)
• qemu-kvm (KVM acceleration)
• libvirt-daemon-system (VM management)
• libvirt-clients (virsh CLI)
• bridge-utils (networking)
• virt-manager (GUI management)
• ovmf (UEFI firmware)
• swtpm (TPM 2.0 for Windows 11)
• qemu-utils (disk tools)
• guestfs-tools (filesystem tools)"

    if ! gum confirm "Proceed with installation?"; then
        return 1
    fi

    echo ""
    show_info "This will require sudo password and may take 5-10 minutes..."
    echo ""

    local packages=(
        qemu-system-x86
        qemu-kvm
        libvirt-daemon-system
        libvirt-clients
        bridge-utils
        virt-manager
        ovmf
        swtpm
        qemu-utils
        guestfs-tools
    )

    if gum spin --spinner dot --title "Installing QEMU/KVM stack..." -- \
        sudo apt update && sudo apt install -y "${packages[@]}"; then
        echo ""
        show_success "Installation completed successfully!"
        save_state "qemu_installed" "true"
        pause_for_user
        return 0
    else
        echo ""
        show_error "Installation failed! Check the error messages above."
        pause_for_user
        return 1
    fi
}

configure_user_groups() {
    show_header "👤 User Group Configuration" "Adding user to libvirt and kvm groups"
    show_breadcrumb "Main Menu > Installation & Setup > Configure User Groups"

    local user=$(whoami)

    show_section "Your user ($user) will be added to:
• libvirt group (VM management permissions)
• kvm group (KVM access)

⚠️  IMPORTANT: You will need to log out and log back in for changes to take effect!"

    if ! gum confirm "Add $user to libvirt and kvm groups?"; then
        return 1
    fi

    echo ""

    if sudo usermod -aG libvirt,kvm "$user"; then
        show_success "User groups configured!"
        echo ""
        show_warning "LOGOUT REQUIRED: Log out and back in for changes to take effect."
        save_state "groups_configured" "true"
        save_state "logout_required" "true"
        pause_for_user
        return 0
    else
        show_error "Failed to configure user groups!"
        pause_for_user
        return 1
    fi
}

################################################################################
# VM Operations Functions
################################################################################

list_vms() {
    show_header "💿 Virtual Machines" "Listing all VMs"
    show_breadcrumb "Main Menu > VM Operations > List VMs"

    echo ""

    if ! command -v virsh &> /dev/null; then
        show_error "libvirt not installed! Install QEMU/KVM stack first."
        wait_and_return "VM Operations Menu"
        return 0  # Don't fail, just return to menu
    fi

    local vms=$(virsh list --all --name 2>/dev/null)

    if [ -z "$vms" ]; then
        show_info "No VMs found. Create one using the 'Create New VM' option."
    else
        gum style \
            --border rounded \
            --border-foreground "$COLOR_INFO" \
            --padding "1 2" \
            --width "$TERM_WIDTH" \
            "$(virsh list --all)"
    fi

    echo ""
    wait_and_return "VM Operations Menu"
}

# Helper function to select a VM for an operation
select_vm_for_operation() {
    local operation="${1:-manage}"

    if ! command -v virsh &> /dev/null; then
        show_error "libvirt not installed!"
        return 1
    fi

    local vms=$(virsh -c qemu:///system list --all --name 2>/dev/null | grep -v '^$')

    if [ -z "$vms" ]; then
        show_error "No VMs found. Create one first."
        return 1
    fi

    local vm_name=$(echo "$vms" | gum choose --header "Select VM to $operation:")

    if [ -z "$vm_name" ]; then
        return 1
    fi

    echo "$vm_name"
}

create_vm_wizard() {
    show_header "🚀 Create New VM Wizard" "Step-by-step Windows 11 VM creation"
    show_breadcrumb "Main Menu > VM Operations > Create New VM"

    # Step 1: VM Name
    show_section "Step 1: VM Configuration"
    echo "VM Name:"
    local vm_name=$(gum input --placeholder "win11-outlook" --value "win11-outlook")

    if [ -z "$vm_name" ]; then
        show_error "VM name cannot be empty!"
        pause_for_user
        return 1
    fi

    # Check if VM already exists
    if virsh list --all --name 2>/dev/null | grep -q "^$vm_name$"; then
        show_error "VM '$vm_name' already exists!"
        pause_for_user
        return 1
    fi

    # Step 2: Resources
    echo ""
    echo "RAM (GB):"
    local total_ram=$(free -g | awk '/^Mem:/{print $2}')
    local default_ram=8
    [ "$total_ram" -ge 32 ] && default_ram=16

    local ram_gb=$(gum input --placeholder "$default_ram" --value "$default_ram")
    ram_gb=${ram_gb:-$default_ram}

    echo ""
    echo "CPU Cores:"
    local total_cores=$(nproc)
    local default_cores=4
    [ "$total_cores" -ge 16 ] && default_cores=8

    local cpus=$(gum input --placeholder "$default_cores" --value "$default_cores")
    cpus=${cpus:-$default_cores}

    echo ""
    echo "Disk Size (GB):"
    local disk_gb=$(gum input --placeholder "100" --value "100")
    disk_gb=${disk_gb:-100}

    # Step 3: ISO Paths
    echo ""
    show_section "Step 2: Installation Media"

    echo "Windows 11 ISO path:"
    local win11_iso=$(gum input --placeholder "/path/to/Win11.iso")

    if [ ! -f "$win11_iso" ]; then
        show_error "Windows 11 ISO not found: $win11_iso"
        echo ""
        show_info "Download from: https://www.microsoft.com/software-download/windows11"
        pause_for_user
        return 1
    fi

    echo ""
    echo "VirtIO drivers ISO path:"
    local virtio_iso=$(gum input --placeholder "/path/to/virtio-win.iso")

    if [ ! -f "$virtio_iso" ]; then
        show_error "VirtIO drivers ISO not found: $virtio_iso"
        echo ""
        show_info "Download from: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/"
        pause_for_user
        return 1
    fi

    # Step 4: Confirmation
    echo ""
    show_section "VM Configuration Summary:

Name:      $vm_name
RAM:       ${ram_gb}GB
CPUs:      $cpus cores
Disk:      ${disk_gb}GB
Win11 ISO: $win11_iso
VirtIO:    $virtio_iso

Machine:   Q35 chipset
Firmware:  UEFI (OVMF)
TPM:       2.0 (required for Windows 11)
Storage:   VirtIO (high performance)
Network:   VirtIO NAT"

    if ! gum confirm "Create VM with these settings?"; then
        show_info "VM creation cancelled."
        pause_for_user
        return 1
    fi

    # Step 5: Create VM
    echo ""
    show_info "Creating VM... This will open virt-manager for installation."
    echo ""

    local ram_mb=$((ram_gb * 1024))

    # Save VM info
    cat > "$VM_STATE" <<EOF
vm_name=$vm_name
ram_gb=$ram_gb
cpus=$cpus
disk_gb=$disk_gb
win11_iso=$win11_iso
virtio_iso=$virtio_iso
created_date=$(date +%Y-%m-%d)
EOF

    if virt-install \
        --name "$vm_name" \
        --ram "$ram_mb" \
        --vcpus "$cpus" \
        --disk size="$disk_gb",format=qcow2,bus=virtio \
        --cdrom "$win11_iso" \
        --disk "$virtio_iso",device=cdrom \
        --os-variant win11 \
        --machine q35 \
        --boot uefi \
        --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
        --network network=default,model=virtio \
        --video virtio \
        --graphics spice \
        --noautoconsole; then

        echo ""
        show_success "VM '$vm_name' created successfully!"
        save_state "vm_created" "true"
        save_state "vm_name" "$vm_name"

        echo ""
        show_info "Opening virt-manager for Windows installation..."
        show_info "During Windows installation, load VirtIO drivers from the second CD."

        sleep 2
        virt-manager --connect qemu:///system --show-domain-console "$vm_name" &

    else
        echo ""
        show_error "VM creation failed!"
    fi

    pause_for_user
}

start_vm() {
    show_header "▶️  Start Virtual Machine"
    show_breadcrumb "Main Menu > VM Operations > Start VM"

    local vms=$(virsh list --state-shutoff --name 2>/dev/null | grep -v '^$')

    if [ -z "$vms" ]; then
        show_info "No stopped VMs found."
        wait_and_return "VM Operations Menu"
        return 0
    fi

    echo "Select VM to start (or press Esc to cancel):"
    local vm_name=$(echo "$vms" | gum choose)

    if [ -z "$vm_name" ]; then
        return 0  # User cancelled, return to menu loop
    fi

    echo ""
    if gum spin --spinner dot --title "Starting $vm_name..." -- virsh start "$vm_name"; then
        show_success "VM '$vm_name' started!"

        if gum confirm "Open console?"; then
            virt-manager --connect qemu:///system --show-domain-console "$vm_name" &
        fi
    else
        show_error "Failed to start VM!"
    fi

    wait_and_return "VM Operations Menu"
}

stop_vm() {
    show_header "⏹️  Stop Virtual Machine"
    show_breadcrumb "Main Menu > VM Operations > Stop VM"

    local vms=$(virsh list --state-running --name 2>/dev/null | grep -v '^$')

    if [ -z "$vms" ]; then
        show_info "No running VMs found."
        wait_and_return "VM Operations Menu"
        return 0
    fi

    echo "Select VM to stop (or press Esc to cancel):"
    local vm_name=$(echo "$vms" | gum choose)

    if [ -z "$vm_name" ]; then
        return 0  # User cancelled, return to menu loop
    fi

    echo ""
    echo "Shutdown method:"
    local method=$(gum choose "Graceful shutdown (ACPI)" "Force stop (immediate)" "← Cancel")

    if [ -z "$method" ] || [ "$method" = "← Cancel" ]; then
        return 0  # User cancelled
    fi

    echo ""
    if [ "$method" = "Graceful shutdown (ACPI)" ]; then
        if gum spin --spinner dot --title "Shutting down $vm_name..." -- virsh shutdown "$vm_name"; then
            show_success "Shutdown signal sent to '$vm_name'"
            show_info "VM will shut down when guest OS responds to ACPI signal"
        else
            show_error "Failed to send shutdown signal!"
        fi
    else
        if gum confirm "Force stop '$vm_name'? (May cause data loss)"; then
            if virsh destroy "$vm_name"; then
                show_success "VM '$vm_name' force stopped"
            else
                show_error "Failed to force stop VM!"
            fi
        fi
    fi

    wait_and_return "VM Operations Menu"
}

delete_vm() {
    show_header "🗑️  Delete Virtual Machine"
    show_breadcrumb "Main Menu > VM Operations > Delete VM"

    local vms=$(virsh list --all --name 2>/dev/null | grep -v '^$')

    if [ -z "$vms" ]; then
        show_info "No VMs found."
        wait_and_return "VM Operations Menu"
        return 0
    fi

    echo "Select VM to delete (or press Esc to cancel):"
    local vm_name=$(echo "$vms" | gum choose)

    if [ -z "$vm_name" ]; then
        return 0  # User cancelled, return to menu loop
    fi

    echo ""
    show_warning "⚠️  WARNING: This will permanently delete the VM and its disk!"
    echo ""

    if ! gum confirm "Delete '$vm_name'? This cannot be undone!"; then
        return 0  # User cancelled
    fi

    echo ""

    # Stop if running
    if virsh list --name | grep -q "^$vm_name$"; then
        show_info "Stopping VM..."
        virsh destroy "$vm_name" 2>/dev/null || true
    fi

    # Undefine with storage
    if virsh undefine "$vm_name" --remove-all-storage; then
        show_success "VM '$vm_name' deleted successfully"
    else
        show_error "Failed to delete VM!"
    fi

    wait_and_return "VM Operations Menu"
}

################################################################################
# Quick Start Wizard
################################################################################

quick_start_wizard() {
    show_header "🚀 Quick Start Wizard" "Guided setup for Windows 11 VM"
    show_breadcrumb "Main Menu > Quick Start"

    # Check if we should resume
    local last_step=$(load_state "wizard_step" "0")

    if [ "$last_step" != "0" ]; then
        show_info "Previous wizard session detected at step $last_step"
        if gum confirm "Resume from step $last_step?"; then
            # Resume logic handled in step checks below
            :
        else
            save_state "wizard_step" "0"
            last_step=0
        fi
    fi

    # Step 1: Hardware Check
    if [ "$last_step" -le 1 ]; then
        save_state "wizard_step" "1"

        show_section "Step 1/6: Hardware Verification"
        echo ""

        # Run hardware check with retry loop
        while true; do
            if run_hardware_check; then
                break  # Passed, continue to next step
            else
                echo ""
                show_warning "Hardware check found issues."
                echo ""

                local choice=$(gum choose \
                    "🔄 Retry Hardware Check" \
                    "▶️  Continue Anyway (Not Recommended)" \
                    "← Back to Main Menu")

                case "$choice" in
                    "🔄 Retry Hardware Check")
                        continue
                        ;;
                    "▶️  Continue Anyway (Not Recommended)")
                        show_warning "Continuing despite hardware issues..."
                        break
                        ;;
                    "← Back to Main Menu"|"")
                        return 1
                        ;;
                esac
            fi
        done
    fi

    # Step 2: Software Installation
    if [ "$last_step" -le 2 ]; then
        save_state "wizard_step" "2"

        show_header "🚀 Quick Start Wizard - Step 2/6" "Software Installation"

        # Run software check with retry loop
        while true; do
            if run_software_check; then
                break  # All software installed
            else
                echo ""
                show_warning "Some software components are missing."
                echo ""

                local choice=$(gum choose \
                    "🔧 Install QEMU/KVM Stack Now" \
                    "🔄 Retry Software Check" \
                    "▶️  Continue Anyway (Not Recommended)" \
                    "← Back to Main Menu")

                case "$choice" in
                    "🔧 Install QEMU/KVM Stack Now")
                        if install_qemu_stack; then
                            continue  # Re-check after install
                        else
                            show_error "Installation failed. Please check errors above."
                        fi
                        ;;
                    "🔄 Retry Software Check")
                        continue
                        ;;
                    "▶️  Continue Anyway (Not Recommended)")
                        show_warning "Continuing without all software installed..."
                        break
                        ;;
                    "← Back to Main Menu"|"")
                        return 1
                        ;;
                esac
            fi
        done
    fi

    # Step 3: User Groups
    if [ "$last_step" -le 3 ]; then
        save_state "wizard_step" "3"

        show_header "🚀 Quick Start Wizard - Step 3/6" "User Configuration"

        # Check user groups with retry loop
        while true; do
            if check_user_groups; then
                break  # User groups are configured
            else
                echo ""
                show_warning "User groups need configuration."
                echo ""

                local choice=$(gum choose \
                    "🔧 Configure User Groups Now" \
                    "🔄 Retry Group Check" \
                    "▶️  Continue Anyway (May Cause Permission Errors)" \
                    "← Back to Main Menu")

                case "$choice" in
                    "🔧 Configure User Groups Now")
                        if configure_user_groups; then
                            if [ "$(load_state logout_required)" = "true" ]; then
                                show_section "⚠️  LOGOUT REQUIRED

You must log out and log back in for group changes to take effect.

After logging back in, run this wizard again to continue from Step 4."

                                local logout_choice=$(gum choose \
                                    "🚪 Exit Now (Recommended)" \
                                    "🔄 I've Logged Out - Retry Check" \
                                    "← Back to Main Menu")

                                case "$logout_choice" in
                                    "🚪 Exit Now (Recommended)")
                                        exit 0
                                        ;;
                                    "🔄 I've Logged Out - Retry Check")
                                        save_state "logout_required" "false"
                                        continue
                                        ;;
                                    "← Back to Main Menu"|"")
                                        return 1
                                        ;;
                                esac
                            fi
                        else
                            show_error "Group configuration failed."
                        fi
                        ;;
                    "🔄 Retry Group Check")
                        continue
                        ;;
                    "▶️  Continue Anyway (May Cause Permission Errors)")
                        show_warning "Continuing without proper groups..."
                        break
                        ;;
                    "← Back to Main Menu"|"")
                        return 1
                        ;;
                esac
            fi
        done
    fi

    # Step 4: Download ISOs
    if [ "$last_step" -le 4 ]; then
        save_state "wizard_step" "4"

        show_header "🚀 Quick Start Wizard - Step 4/6" "Download Installation Media"

        # ISO download step with retry loop
        while true; do
            show_section "You need two ISO files:

1. Windows 11 ISO
   Download: https://www.microsoft.com/software-download/windows11

2. VirtIO Drivers ISO
   Download: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

Download these files now, then return here to continue."

            local choice=$(gum choose \
                "✅ I Have Both ISOs - Continue" \
                "📥 Open Download URLs in Browser" \
                "⏭️  Skip for Now (Configure Later)" \
                "← Back to Main Menu")

            case "$choice" in
                "✅ I Have Both ISOs - Continue")
                    break
                    ;;
                "📥 Open Download URLs in Browser")
                    if command -v xdg-open &> /dev/null; then
                        xdg-open "https://www.microsoft.com/software-download/windows11" &
                        sleep 1
                        xdg-open "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/" &
                        show_info "Opened download URLs in your browser."
                    else
                        show_warning "Cannot open browser. Please open URLs manually."
                    fi
                    echo ""
                    gum style --foreground 240 "Press any key when downloads are complete..."
                    read -n 1 -s -r
                    continue
                    ;;
                "⏭️  Skip for Now (Configure Later)")
                    show_warning "Skipping ISO verification. You'll need to provide paths during VM creation."
                    break
                    ;;
                "← Back to Main Menu"|"")
                    return 1
                    ;;
            esac
        done
    fi

    # Step 5: Create VM
    if [ "$last_step" -le 5 ]; then
        save_state "wizard_step" "5"

        show_header "🚀 Quick Start Wizard - Step 5/6" "Create Virtual Machine"

        create_vm_wizard || return 1
    fi

    # Step 6: Next Steps
    save_state "wizard_step" "6"

    show_header "🚀 Quick Start Wizard - Complete!" "VM created successfully"

    show_section "✅ Wizard Complete!

Your Windows 11 VM has been created. Next steps:

1. Install Windows 11 in the VM
2. During installation, load VirtIO drivers from second CD
3. After Windows installation, return to this tool for:
   - Performance optimization (Hyper-V enlightenments)
   - Security hardening
   - File sharing setup (virtio-fs)

Recommended: Run 'Performance Optimization' from the main menu
             after Windows installation completes."

    save_state "wizard_step" "complete"
    pause_for_user
}

################################################################################
# Documentation & Help
################################################################################

show_documentation() {
    while true; do
        show_header "📚 Documentation & Help"
        show_breadcrumb "Main Menu > Documentation"

        local choice=$(gum choose \
            "Quick Start Guide" \
            "Implementation Guides" \
            "Research Documentation" \
            "Troubleshooting" \
            "Performance Tuning" \
            "Security Hardening" \
            "Agent System" \
            "← Back to Main Menu")

        case "$choice" in
            "Quick Start Guide")
                if [ -f "CLAUDE.md" ]; then
                    gum pager < CLAUDE.md
                else
                    show_error "CLAUDE.md not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Implementation Guides")
                if [ -d "outlook-linux-guide" ]; then
                    local guide=$(find outlook-linux-guide -name "*.md" | gum filter)
                    [ -n "$guide" ] && gum pager < "$guide"
                else
                    show_error "outlook-linux-guide directory not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Research Documentation")
                if [ -d "research" ]; then
                    local doc=$(find research -name "*.md" | gum filter)
                    [ -n "$doc" ] && gum pager < "$doc"
                else
                    show_error "research directory not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Troubleshooting")
                if [ -f "research/07-troubleshooting-failure-modes.md" ]; then
                    gum pager < "research/07-troubleshooting-failure-modes.md"
                else
                    show_error "Troubleshooting guide not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Performance Tuning")
                if [ -f "outlook-linux-guide/09-performance-optimization-playbook.md" ]; then
                    gum pager < "outlook-linux-guide/09-performance-optimization-playbook.md"
                else
                    show_error "Performance guide not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Security Hardening")
                if [ -f "research/06-security-hardening-analysis.md" ]; then
                    gum pager < "research/06-security-hardening-analysis.md"
                else
                    show_error "Security guide not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "Agent System")
                if [ -f ".claude/agents/README.md" ]; then
                    gum pager < ".claude/agents/README.md"
                else
                    show_error "Agent documentation not found!"
                    wait_and_return "Documentation Menu"
                fi
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

################################################################################
# Main Menu
################################################################################

run_demo_mode() {
    show_header "🎥 Demo Mode (VHS)" "Recording automated tour"

    if ! command -v vhs &> /dev/null; then
        show_error "vhs is not installed!"
        echo ""
        show_info "Install with: go install github.com/charmbracelet/vhs@latest"
        echo "or download from: https://github.com/charmbracelet/vhs"
        pause_for_user
        return
    fi

    show_section "This will record a demo navigating through menus.
Uses arrow keys and Enter to navigate (gum choose style).

Output file: demo.gif
Duration: ~60 seconds"

    if ! gum confirm "Start recording now?"; then
        return
    fi

    # Generate Tape - uses arrow keys to navigate gum choose menus
    cat > demo.tape <<'EOF'
Output demo.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Padding 20
Set FontFamily "JetBrainsMono Nerd Font"
Set Theme "catppuccin-mocha"
Set PlaybackSpeed 1.5

# Start the TUI
Hide
Type "./start.sh"
Enter
Sleep 3s
Show

# Main menu is now visible - first item "Quick Start" is highlighted
Sleep 1.5s

# Navigate to System Readiness Check (item 2)
Down
Sleep 0.5s
Enter
Sleep 3s
# Hardware check runs, press key to continue
Space
Sleep 1s

# Back at main menu - go to Installation & Setup (item 3)
Down
Down
Sleep 0.5s
Enter
Sleep 1s

# In Installation submenu - browse items
Down
Sleep 0.4s
Down
Sleep 0.4s
Down
Sleep 0.4s
Down
Sleep 0.4s
# Select "Back to Main Menu"
Down
Sleep 0.4s
Enter
Sleep 1s

# Back at main - go to VM Operations (item 4)
Down
Down
Down
Sleep 0.5s
Enter
Sleep 1s

# In VM Operations submenu - browse items
Down
Sleep 0.4s
Down
Sleep 0.4s
Down
Sleep 0.4s
Down
Sleep 0.4s
Down
Sleep 0.4s
# Select "Back to Main Menu"
Down
Sleep 0.4s
Enter
Sleep 1s

# Back at main - go to Performance (item 5)
Down
Down
Down
Down
Sleep 0.5s
Enter
Sleep 1s

# In Performance submenu - view guide then back
Enter
Sleep 2s
Space
Sleep 0.5s
# Select back
Down
Down
Down
Down
Down
Sleep 0.3s
Enter
Sleep 1s

# Back at main - go to Security (item 6)
Down
Down
Down
Down
Down
Sleep 0.5s
Enter
Sleep 1s

# In Security submenu - back immediately
Down
Down
Down
Down
Down
Sleep 0.3s
Enter
Sleep 1s

# Back at main - go to Health & Diagnostics (item 9)
Down
Down
Down
Down
Down
Down
Down
Down
Sleep 0.5s
Enter
Sleep 1s

# In Diagnostics submenu - back
Down
Down
Down
Down
Sleep 0.3s
Enter
Sleep 1s

# Back at main - go to Exit (last item)
Down
Down
Down
Down
Down
Down
Down
Down
Down
Down
Down
Down
Sleep 0.5s
Enter
Sleep 2s
EOF

    # Run VHS
    echo ""
    if gum spin --spinner dot --title "Recording demo (this takes about 2 minutes)..." -- vhs demo.tape; then
        rm demo.tape
        show_success "Demo recorded: demo.gif"
        echo ""
        show_info "View with: xdg-open demo.gif"
    else
        show_error "Recording failed! Check vhs output above."
        rm -f demo.tape
    fi

    pause_for_user
}

show_main_menu() {
    while true; do
        show_header "🖥️  Win-QEMU - Windows 11 on Ubuntu" "Zero-Command TUI Interface"
        show_breadcrumb "Main Menu"

        # Show system status
        local hw_status=$(load_state "hardware_check" "unknown")
        local sw_status=$(load_state "software_check" "unknown")
        local vm_status=$(load_state "vm_created" "false")

        gum style \
            --border rounded \
            --border-foreground "$COLOR_MUTED" \
            --padding "1 2" \
            --width "$TERM_WIDTH" \
            "System Status:
  Hardware Check: $([ "$hw_status" = "passed" ] && echo "✅ Passed" || echo "❓ Not checked")
  Software: $([ "$sw_status" = "complete" ] && echo "✅ Installed" || echo "❓ Not checked")
  VM Created: $([ "$vm_status" = "true" ] && echo "✅ Yes" || echo "❌ No")"

        echo ""

        local choice=$(gum choose \
            "🚀 Quick Start (Guided Setup Wizard)" \
            "📋 System Readiness Check" \
            "📦 Installation & Setup" \
            "💿 Virtual Machine Operations" \
            "⚡ Performance & Optimization" \
            "🔒 Security & Hardening" \
            "📁 File Sharing (virtio-fs)" \
            "💾 Backup & Recovery" \
            "🏥 Health & Diagnostics" \
            "📚 Documentation & Help" \
            "⚙️  Settings" \
            "🎥 Run Demo (Record VHS)" \
            "🚪 Exit")

        case "$choice" in
            "🚀 Quick Start (Guided Setup Wizard)")
                quick_start_wizard
                ;;
            "📋 System Readiness Check")
                run_hardware_check
                ;;
            "📦 Installation & Setup")
                show_installation_menu
                ;;
            "💿 Virtual Machine Operations")
                show_vm_menu
                ;;
            "⚡ Performance & Optimization")
                show_performance_menu
                ;;
            "🔒 Security & Hardening")
                show_security_menu
                ;;
            "📁 File Sharing (virtio-fs)")
                show_filesharing_menu
                ;;
            "💾 Backup & Recovery")
                show_backup_menu
                ;;
            "🏥 Health & Diagnostics")
                show_diagnostics_menu
                ;;
            "📚 Documentation & Help")
                show_documentation
                ;;
            "⚙️  Settings")
                show_settings_menu
                ;;
            "🎥 Run Demo (Record VHS)")
                run_demo_mode
                ;;
            "🚪 Exit")
                clear
                gum style \
                    --foreground "$COLOR_PRIMARY" \
                    --padding "1 2" \
                    "Thanks for using Win-QEMU! 👋"
                echo ""
                exit 0
                ;;
        esac
    done
}

show_installation_menu() {
    while true; do
        show_header "📦 Installation & Setup"
        show_breadcrumb "Main Menu > Installation & Setup"

        local choice=$(gum choose \
            "Install QEMU/KVM Stack" \
            "Configure User Groups" \
            "Download Windows 11 ISO (Instructions)" \
            "Download VirtIO Drivers (Instructions)" \
            "Verify Installation" \
            "← Back to Main Menu")

        case "$choice" in
            "Install QEMU/KVM Stack")
                install_qemu_stack
                ;;
            "Configure User Groups")
                configure_user_groups
                ;;
            "Download Windows 11 ISO (Instructions)")
                show_header "💿 Windows 11 ISO Download"
                show_section "Download Windows 11 ISO from Microsoft:

URL: https://www.microsoft.com/software-download/windows11

Steps:
1. Visit the URL above
2. Scroll to 'Download Windows 11 Disk Image (ISO)'
3. Select 'Windows 11 (multi-edition ISO)'
4. Click 'Download', choose language
5. Download 64-bit ISO (~5-6 GB)

Save the ISO to a known location (e.g., ~/Downloads/Win11.iso)"
                pause_for_user
                ;;
            "Download VirtIO Drivers (Instructions)")
                show_header "💿 VirtIO Drivers Download"
                show_section "Download VirtIO drivers for Windows:

URL: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

Recommended file: virtio-win-0.1.xxx.iso (latest stable)

These drivers enable high-performance storage and network
in your Windows 11 VM."
                pause_for_user
                ;;
            "Verify Installation")
                if ! run_software_check; then
                    echo ""
                    if gum confirm "Would you like to fix these issues now?"; then
                        # Check if packages need installation
                        if ! check_qemu_installed >/dev/null 2>&1 || \
                           ! check_libvirt_installed >/dev/null 2>&1 || \
                           ! check_virt_manager_installed >/dev/null 2>&1; then
                            install_qemu_stack
                        fi

                        # Check if groups need configuration
                        if ! check_user_groups >/dev/null 2>&1; then
                            configure_user_groups
                        fi

                        # Re-run verification
                        run_software_check
                    fi
                fi
                pause_for_user
                ;;
            "← Back to Main Menu")
                break
                ;;
        esac
    done
}

show_vm_menu() {
    while true; do
        show_header "💿 Virtual Machine Operations"
        show_breadcrumb "Main Menu > VM Operations"

        local choice=$(gum choose \
            "Create New VM (Wizard)" \
            "List All VMs" \
            "Start VM" \
            "Stop VM" \
            "Delete VM" \
            "VM Console (virt-manager)" \
            "← Back to Main Menu")

        case "$choice" in
            "Create New VM (Wizard)")
                create_vm_wizard
                ;;
            "List All VMs")
                list_vms
                ;;
            "Start VM")
                start_vm
                ;;
            "Stop VM")
                stop_vm
                ;;
            "Delete VM")
                delete_vm
                ;;
            "VM Console (virt-manager)")
                virt-manager &
                ;;
            "← Back to Main Menu")
                break
                ;;
        esac
    done
}

show_performance_menu() {
    while true; do
        show_header "⚡ Performance & Optimization"
        show_breadcrumb "Main Menu > Performance"

        local choice=$(gum choose \
            "View Performance Guide" \
            "Apply All Optimizations" \
            "CPU Pinning" \
            "Huge Pages" \
            "Hyper-V Enlightenments" \
            "VirtIO Tuning" \
            "← Back to Main Menu")

        case "$choice" in
            "View Performance Guide")
                show_section "Performance Optimization Guide

Available optimizations:
• Hyper-V enlightenments (14 features) - 10-15% improvement
• CPU pinning - 3-5% improvement
• Huge pages - 5-10% improvement
• VirtIO driver tuning - I/O optimization

Target: 85-95% native Windows performance

Script: $SCRIPT_DIR/configure-performance.sh"
                wait_and_return "Performance Menu"
                ;;
            "Apply All Optimizations")
                local vm_name=$(select_vm_for_operation "optimize")
                if [[ -n "$vm_name" ]]; then
                    show_header "Applying all optimizations to '$vm_name'..."
                    if [ -f "$SCRIPT_DIR/configure-performance.sh" ]; then
                        "$SCRIPT_DIR/configure-performance.sh" --vm "$vm_name" --all --yes || true
                    else
                        show_error "configure-performance.sh not found"
                    fi
                fi
                wait_and_return "Performance Menu"
                ;;
            "CPU Pinning")
                local vm_name=$(select_vm_for_operation "configure CPU pinning for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/configure-performance.sh" ]; then
                        "$SCRIPT_DIR/configure-performance.sh" --vm "$vm_name" --cpu-pinning || true
                    fi
                fi
                wait_and_return "Performance Menu"
                ;;
            "Huge Pages")
                local vm_name=$(select_vm_for_operation "configure huge pages for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/configure-performance.sh" ]; then
                        "$SCRIPT_DIR/configure-performance.sh" --vm "$vm_name" --huge-pages || true
                    fi
                fi
                wait_and_return "Performance Menu"
                ;;
            "Hyper-V Enlightenments")
                local vm_name=$(select_vm_for_operation "configure Hyper-V for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/configure-performance.sh" ]; then
                        "$SCRIPT_DIR/configure-performance.sh" --vm "$vm_name" --hyperv || true
                    fi
                fi
                wait_and_return "Performance Menu"
                ;;
            "VirtIO Tuning")
                local vm_name=$(select_vm_for_operation "tune VirtIO for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/configure-performance.sh" ]; then
                        "$SCRIPT_DIR/configure-performance.sh" --vm "$vm_name" --virtio || true
                    fi
                fi
                wait_and_return "Performance Menu"
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

show_security_menu() {
    while true; do
        show_header "🔒 Security & Hardening"
        show_breadcrumb "Main Menu > Security"

        local choice=$(gum choose \
            "Run Security Audit" \
            "Apply All Security Hardening" \
            "Configure Host Firewall" \
            "Enforce virtio-fs Read-Only" \
            "Configure AppArmor" \
            "View Security Guide" \
            "← Back to Main Menu")

        case "$choice" in
            "Run Security Audit")
                show_header "Running Security Audit..."
                if [ -f "$SCRIPT_DIR/configure-security.sh" ]; then
                    "$SCRIPT_DIR/configure-security.sh" --audit || true
                else
                    show_error "configure-security.sh not found"
                fi
                wait_and_return "Security Menu"
                ;;
            "Apply All Security Hardening")
                local vm_name=$(select_vm_for_operation "harden")
                if [[ -n "$vm_name" ]]; then
                    show_header "Applying security hardening to '$vm_name'..."
                    if [ -f "$SCRIPT_DIR/configure-security.sh" ]; then
                        sudo "$SCRIPT_DIR/configure-security.sh" --vm "$vm_name" --all || true
                    fi
                fi
                wait_and_return "Security Menu"
                ;;
            "Configure Host Firewall")
                show_header "Configuring UFW Firewall..."
                if [ -f "$SCRIPT_DIR/configure-security.sh" ]; then
                    sudo "$SCRIPT_DIR/configure-security.sh" --firewall || true
                fi
                wait_and_return "Security Menu"
                ;;
            "Enforce virtio-fs Read-Only")
                local vm_name=$(select_vm_for_operation "enforce read-only for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/configure-security.sh" ]; then
                        "$SCRIPT_DIR/configure-security.sh" --vm "$vm_name" --virtiofs-ro || true
                    fi
                fi
                wait_and_return "Security Menu"
                ;;
            "Configure AppArmor")
                show_header "Configuring AppArmor..."
                if [ -f "$SCRIPT_DIR/configure-security.sh" ]; then
                    sudo "$SCRIPT_DIR/configure-security.sh" --apparmor || true
                fi
                wait_and_return "Security Menu"
                ;;
            "View Security Guide")
                show_section "Security Hardening Guide

Available features:
• UFW Firewall - Block unnecessary network access
• virtio-fs Read-Only - Mandatory protection against ransomware
• AppArmor - Confine QEMU processes

Key security principle:
  Host filesystem sharing MUST be read-only!
  This protects against ransomware encrypting host files.

Script: $SCRIPT_DIR/configure-security.sh"
                wait_and_return "Security Menu"
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

show_filesharing_menu() {
    while true; do
        show_header "📁 File Sharing (virtio-fs)"
        show_breadcrumb "Main Menu > File Sharing"

        local choice=$(gum choose \
            "Setup virtio-fs Share" \
            "Test virtio-fs Connection" \
            "View File Sharing Guide" \
            "← Back to Main Menu")

        case "$choice" in
            "Setup virtio-fs Share")
                local vm_name=$(select_vm_for_operation "configure virtio-fs for")
                if [[ -n "$vm_name" ]]; then
                    show_header "Setting up virtio-fs for '$vm_name'..."

                    # Ask for source directory
                    local source_dir=$(gum input --placeholder "/home/$USER/shared-folder" --prompt "Source directory on host: ")
                    if [[ -z "$source_dir" ]]; then
                        source_dir="/home/$USER/shared-folder"
                    fi

                    if [ -f "$SCRIPT_DIR/setup-virtio-fs.sh" ]; then
                        "$SCRIPT_DIR/setup-virtio-fs.sh" --vm "$vm_name" --source "$source_dir" || true
                    else
                        show_error "setup-virtio-fs.sh not found"
                    fi
                fi
                wait_and_return "File Sharing Menu"
                ;;
            "Test virtio-fs Connection")
                local vm_name=$(select_vm_for_operation "test virtio-fs for")
                if [[ -n "$vm_name" ]]; then
                    if [ -f "$SCRIPT_DIR/test-virtio-fs.sh" ]; then
                        "$SCRIPT_DIR/test-virtio-fs.sh" --vm "$vm_name" --verbose || true
                    else
                        show_error "test-virtio-fs.sh not found"
                    fi
                fi
                wait_and_return "File Sharing Menu"
                ;;
            "View File Sharing Guide")
                show_section "virtio-fs File Sharing Guide

virtio-fs provides high-performance filesystem sharing between host and guest.

IMPORTANT: Read-only mode is MANDATORY for security!
This protects against ransomware encrypting host files.

Setup steps:
1. Configure share with setup-virtio-fs.sh
2. Install WinFsp in Windows guest
3. Mount share as drive letter (e.g., Z:)
4. Access host files from Windows

Scripts:
• $SCRIPT_DIR/setup-virtio-fs.sh
• $SCRIPT_DIR/test-virtio-fs.sh"
                wait_and_return "File Sharing Menu"
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

show_backup_menu() {
    while true; do
        show_header "💾 Backup & Recovery"
        show_breadcrumb "Main Menu > Backup"

        local choice=$(gum choose \
            "Create Backup (Live)" \
            "Create Backup (Offline)" \
            "Create Snapshot Only" \
            "List Snapshots" \
            "Restore Snapshot" \
            "View Backup Guide" \
            "← Back to Main Menu")

        case "$choice" in
            "Create Backup (Live)")
                local vm_name=$(select_vm_for_operation "backup")
                if [[ -n "$vm_name" ]]; then
                    show_header "Creating live backup of '$vm_name'..."
                    if [ -f "$SCRIPT_DIR/backup-vm.sh" ]; then
                        "$SCRIPT_DIR/backup-vm.sh" --vm "$vm_name" --live --yes || true
                    else
                        show_error "backup-vm.sh not found"
                    fi
                fi
                wait_and_return "Backup Menu"
                ;;
            "Create Backup (Offline)")
                local vm_name=$(select_vm_for_operation "backup")
                if [[ -n "$vm_name" ]]; then
                    show_header "Creating offline backup of '$vm_name'..."
                    if [ -f "$SCRIPT_DIR/backup-vm.sh" ]; then
                        "$SCRIPT_DIR/backup-vm.sh" --vm "$vm_name" --offline --yes || true
                    fi
                fi
                wait_and_return "Backup Menu"
                ;;
            "Create Snapshot Only")
                local vm_name=$(select_vm_for_operation "snapshot")
                if [[ -n "$vm_name" ]]; then
                    local snap_name=$(gum input --placeholder "snapshot-$(date +%Y%m%d)" --prompt "Snapshot name: ")
                    if [[ -z "$snap_name" ]]; then
                        snap_name="snapshot-$(date +%Y%m%d-%H%M%S)"
                    fi
                    show_header "Creating snapshot '$snap_name' for '$vm_name'..."
                    virsh -c qemu:///system snapshot-create-as "$vm_name" "$snap_name" --description "Created via start.sh" || true
                fi
                wait_and_return "Backup Menu"
                ;;
            "List Snapshots")
                local vm_name=$(select_vm_for_operation "list snapshots for")
                if [[ -n "$vm_name" ]]; then
                    show_header "Snapshots for '$vm_name'"
                    virsh -c qemu:///system snapshot-list "$vm_name" || true
                fi
                wait_and_return "Backup Menu"
                ;;
            "Restore Snapshot")
                local vm_name=$(select_vm_for_operation "restore snapshot for")
                if [[ -n "$vm_name" ]]; then
                    # Get list of snapshots
                    local snapshots=$(virsh -c qemu:///system snapshot-list "$vm_name" --name 2>/dev/null)
                    if [[ -z "$snapshots" ]]; then
                        show_error "No snapshots found for '$vm_name'"
                    else
                        local snap_name=$(echo "$snapshots" | gum choose --header "Select snapshot to restore:")
                        if [[ -n "$snap_name" ]]; then
                            if gum confirm "Restore '$vm_name' to snapshot '$snap_name'?"; then
                                show_header "Restoring snapshot..."
                                virsh -c qemu:///system snapshot-revert "$vm_name" "$snap_name" || true
                            fi
                        fi
                    fi
                fi
                wait_and_return "Backup Menu"
                ;;
            "View Backup Guide")
                show_section "Backup & Recovery Guide

Backup Types:
• Live Backup - Backup while VM is running
• Offline Backup - Stop VM, backup, restart
• Snapshot - Point-in-time state capture

Backup script: $SCRIPT_DIR/backup-vm.sh

Manual commands:
• Create snapshot: virsh snapshot-create-as <vm> <name>
• List snapshots: virsh snapshot-list <vm>
• Restore: virsh snapshot-revert <vm> <name>
• Delete: virsh snapshot-delete <vm> <name>"
                wait_and_return "Backup Menu"
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

show_diagnostics_menu() {
    while true; do
        show_header "🏥 Health & Diagnostics"
        show_breadcrumb "Main Menu > Diagnostics"

        local choice=$(gum choose \
            "Run Full System Check (42+ Checks)" \
            "Run Quick Hardware Check" \
            "Run Quick Software Check" \
            "Check VM Status" \
            "View Latest Report" \
            "← Back to Main Menu")

        case "$choice" in
            "Run Full System Check (42+ Checks)")
                # Run the comprehensive system readiness check with retry loop
                run_full_system_check_with_retry
                ;;
            "Run Quick Hardware Check")
                # Run quick hardware check with retry option
                run_hardware_check_with_retry
                ;;
            "Run Quick Software Check")
                # Run quick software check with retry option
                run_software_check_with_retry
                ;;
            "Check VM Status")
                list_vms
                # list_vms has its own wait_and_return, so just continue loop
                ;;
            "View Latest Report")
                view_latest_report
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

# Run full system check with retry loop
run_full_system_check_with_retry() {
    while true; do
        show_header "🔍 Full System Readiness Check" "Running 42+ prerequisite checks..."
        show_breadcrumb "Main Menu > Diagnostics > Full System Check"

        # Run the comprehensive check script
        local check_result=0
        if [ -f "$SCRIPT_DIR/system-readiness-check.sh" ]; then
            # Run with --interactive flag to ensure menu shows
            "$SCRIPT_DIR/system-readiness-check.sh" --interactive || check_result=$?
        else
            show_error "system-readiness-check.sh not found!"
            wait_and_return "Diagnostics Menu"
            return
        fi

        # The script handles its own menu now, so we just need to handle the return
        # If the script exits cleanly (0), return to this menu
        # The script's internal menu handles retry, continue, exit, etc.
        break
    done
}

# Run hardware check with retry option
run_hardware_check_with_retry() {
    while true; do
        run_hardware_check
        local hw_result=$?

        echo ""

        # Show retry menu
        local choice=$(gum choose \
            "🔄 Retry Hardware Check" \
            "▶️  Continue" \
            "← Back to Diagnostics Menu")

        case "$choice" in
            "🔄 Retry Hardware Check")
                continue  # Loop again
                ;;
            "▶️  Continue"|"← Back to Diagnostics Menu"|"")
                break
                ;;
        esac
    done
}

# Run software check with retry option
run_software_check_with_retry() {
    while true; do
        local needs_install=false

        if ! run_software_check; then
            needs_install=true
        fi

        echo ""

        # Build options based on result
        local options=()

        if $needs_install; then
            options+=("🔧 Install Missing Components")
        fi

        options+=("🔄 Retry Software Check")
        options+=("← Back to Diagnostics Menu")

        local choice=$(printf '%s\n' "${options[@]}" | gum choose)

        case "$choice" in
            "🔧 Install Missing Components")
                install_qemu_stack
                continue  # Re-check after install
                ;;
            "🔄 Retry Software Check")
                continue
                ;;
            "← Back to Diagnostics Menu"|"")
                break
                ;;
        esac
    done
}

# View the latest readiness check report
view_latest_report() {
    show_header "📄 Latest Readiness Report"
    show_breadcrumb "Main Menu > Diagnostics > View Report"

    local report_dir="$STATE_DIR"

    # Alternative location
    if [ ! -d "$report_dir" ] || [ -z "$(ls -A "$report_dir" 2>/dev/null)" ]; then
        report_dir=".installation-state"
    fi

    # Find the latest report
    local latest_report=$(find "$report_dir" -name "readiness-check-*.json" 2>/dev/null | sort -r | head -n1)

    if [ -n "$latest_report" ] && [ -f "$latest_report" ]; then
        show_info "Report: $latest_report"
        echo ""

        if command -v jq &> /dev/null; then
            # Pretty print JSON
            jq '.' "$latest_report" | gum pager
        else
            gum pager < "$latest_report"
        fi
    else
        show_warning "No readiness check reports found."
        echo ""
        show_info "Run 'Full System Check' to generate a report."
    fi

    wait_and_return "Diagnostics Menu"
}

show_settings_menu() {
    while true; do
        show_header "⚙️  Settings"
        show_breadcrumb "Main Menu > Settings"

        local choice=$(gum choose \
            "Reset Wizard Progress" \
            "Clear All State" \
            "View State Files" \
            "← Back to Main Menu")

        case "$choice" in
            "Reset Wizard Progress")
                if gum confirm "Reset wizard progress? You'll start from Step 1."; then
                    save_state "wizard_step" "0"
                    show_success "Wizard progress reset!"
                fi
                wait_and_return "Settings Menu"
                ;;
            "Clear All State")
                if gum confirm "Clear all state? This will reset everything."; then
                    rm -rf "$STATE_DIR"
                    init_state_dir
                    show_success "All state cleared!"
                fi
                wait_and_return "Settings Menu"
                ;;
            "View State Files")
                if [ -d "$STATE_DIR" ]; then
                    show_section "State Files:"
                    find "$STATE_DIR" -type f -exec sh -c 'echo ""; echo "=== {} ==="; cat "{}"' \;
                else
                    show_info "No state files found."
                fi
                wait_and_return "Settings Menu"
                ;;
            "← Back to Main Menu"|"")
                break
                ;;
        esac
    done
}

################################################################################
# Main Entry Point
################################################################################

main() {
    ensure_gum
    init_state_dir
    show_main_menu
}

main "$@"
