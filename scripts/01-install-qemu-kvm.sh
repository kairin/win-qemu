#!/bin/bash
#
# 01-install-qemu-kvm.sh - QEMU/KVM Installation with Comprehensive Logging
#
# Purpose: Install QEMU/KVM virtualization stack on Ubuntu 25.10
# Requirements: Ubuntu 25.10, sudo privileges, internet connection
# Duration: 5-10 minutes (depending on internet speed)
# Idempotent: Safe to run multiple times (skips if already installed)
#
# Usage:
#   sudo ./scripts/01-install-qemu-kvm.sh
#
# Output:
#   - Human-readable log: .installation-state/installation-YYYYMMDD-HHMMSS.log
#   - Machine-readable state: .installation-state/packages-installed.json
#
# Author: AI-assisted (Claude Code)
# Created: 2025-11-17
# Version: 1.0
#

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_DIR="${PROJECT_ROOT}/.installation-state"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${STATE_DIR}/installation-${TIMESTAMP}.log"
STATE_FILE="${STATE_DIR}/packages-installed.json"

# Packages to install (10 core packages)
PACKAGES=(
    qemu-kvm                  # Core QEMU/KVM virtualization
    libvirt-daemon-system     # Libvirt daemon (background service)
    libvirt-clients           # Virsh command-line tools
    bridge-utils              # Network bridge utilities
    virt-manager              # GUI management interface
    ovmf                      # UEFI firmware for VMs
    swtpm                     # Software TPM 2.0 emulator
    qemu-utils                # QEMU disk image tools
    guestfs-tools             # Guest filesystem tools
    virt-top                  # VM performance monitoring
)

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

# Initialize logging
init_logging() {
    mkdir -p "$STATE_DIR"

    echo "# QEMU/KVM Installation Log" > "$LOG_FILE"
    echo "# Started: $(date +'%Y-%m-%d %H:%M:%S %Z')" >> "$LOG_FILE"
    echo "# Hostname: $(hostname)" >> "$LOG_FILE"
    echo "# User: $SUDO_USER (running as: $USER)" >> "$LOG_FILE"
    echo "# Ubuntu version: $(lsb_release -ds)" >> "$LOG_FILE"
    echo "# Script: $0" >> "$LOG_FILE"
    echo "#" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Log message to file and console
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Log to file
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"

    # Log to console with color
    case "$level" in
        INFO)
            echo -e "${BLUE}[INFO]${NC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${message}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${message}"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${message}"
            ;;
        CMD)
            echo -e "${YELLOW}[CMD]${NC} ${message}"
            ;;
        *)
            echo "[${level}] ${message}"
            ;;
    esac
}

# Log command execution with output capture
run_logged() {
    local cmd="$*"
    log CMD "$cmd"

    # Execute command and capture output
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
# PRE-FLIGHT CHECKS
# ==============================================================================

preflight_checks() {
    log INFO "Starting pre-flight checks"

    # Check if running as root/sudo
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run with sudo"
        log ERROR "Usage: sudo $0"
        exit 1
    fi

    # Check Ubuntu version
    local ubuntu_version=$(lsb_release -rs)
    if [[ "$ubuntu_version" != "25.10" ]]; then
        log WARN "This script was tested on Ubuntu 25.10"
        log WARN "You are running Ubuntu $ubuntu_version"
        log WARN "Installation may work but is not guaranteed"

        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log INFO "Installation aborted by user"
            exit 0
        fi
    fi

    # Check CPU virtualization support
    if ! grep -qE '(vmx|svm)' /proc/cpuinfo; then
        log ERROR "CPU virtualization not supported or not enabled in BIOS"
        log ERROR "Please enable Intel VT-x or AMD-V in BIOS settings"
        exit 1
    fi
    local virt_count=$(grep -cE '(vmx|svm)' /proc/cpuinfo)
    log SUCCESS "CPU virtualization supported ($virt_count cores)"

    # Check available RAM
    local ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    if [[ $ram_gb -lt 16 ]]; then
        log WARN "Only ${ram_gb}GB RAM available (16GB recommended)"
    else
        log SUCCESS "RAM check passed (${ram_gb}GB available)"
    fi

    # Check disk space (need 2GB minimum for packages)
    local free_space_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $free_space_gb -lt 2 ]]; then
        log ERROR "Insufficient disk space (${free_space_gb}GB free, need 2GB minimum)"
        exit 1
    fi
    log SUCCESS "Disk space check passed (${free_space_gb}GB free)"

    # Check internet connectivity
    if ! ping -c 1 -W 3 archive.ubuntu.com &> /dev/null; then
        log ERROR "No internet connectivity (cannot reach archive.ubuntu.com)"
        log ERROR "Please check your network connection"
        exit 1
    fi
    log SUCCESS "Internet connectivity verified"

    log SUCCESS "All pre-flight checks passed"
}

# ==============================================================================
# CHECK IF ALREADY INSTALLED
# ==============================================================================

check_existing_installation() {
    log INFO "Checking for existing QEMU/KVM installation"

    local virsh_installed=false
    local libvirtd_running=false

    # Check if virsh is installed
    if command -v virsh &> /dev/null; then
        virsh_installed=true
        local virsh_version=$(virsh --version)
        log INFO "virsh already installed (version: $virsh_version)"
    fi

    # Check if libvirtd is running
    if systemctl is-active --quiet libvirtd; then
        libvirtd_running=true
        log INFO "libvirtd service already running"
    fi

    # If both are present, consider it already installed
    if $virsh_installed && $libvirtd_running; then
        log SUCCESS "QEMU/KVM already installed and running"
        log INFO "Skipping installation (idempotent behavior)"
        log INFO "To force reinstallation, stop libvirtd and remove packages first"

        # Still log this as a successful installation run
        save_installation_state

        echo ""
        log SUCCESS "Installation verification complete"
        log INFO "Next steps:"
        log INFO "  1. Verify installation: ./scripts/03-verify-installation.sh"
        log INFO "  2. Configure user groups: ./scripts/02-configure-user-groups.sh"
        log INFO "  3. Create Windows 11 VM: ./scripts/04-create-vm.sh"

        exit 0
    fi
}

# ==============================================================================
# PACKAGE INSTALLATION
# ==============================================================================

update_package_cache() {
    log INFO "Updating package cache"

    if run_logged apt update; then
        log SUCCESS "Package cache updated"
    else
        log ERROR "Failed to update package cache"
        exit 1
    fi
}

install_packages() {
    log INFO "Installing QEMU/KVM packages (this may take 5-10 minutes)"
    log INFO "Packages to install: ${PACKAGES[*]}"

    # Install packages with progress indication
    if run_logged apt install -y "${PACKAGES[@]}"; then
        log SUCCESS "All packages installed successfully"
    else
        log ERROR "Package installation failed"
        exit 1
    fi

    # Verify each package was installed
    log INFO "Verifying package installation"
    local failed_packages=()

    for package in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            local version=$(dpkg -l | grep "^ii  $package " | awk '{print $3}')
            log SUCCESS "$package installed (version: $version)"
        else
            log ERROR "$package installation failed"
            failed_packages+=("$package")
        fi
    done

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log ERROR "Failed packages: ${failed_packages[*]}"
        exit 1
    fi
}

# ==============================================================================
# POST-INSTALLATION CONFIGURATION
# ==============================================================================

configure_libvirtd() {
    log INFO "Configuring libvirtd service"

    # Enable libvirtd to start on boot
    if systemctl enable libvirtd; then
        log SUCCESS "libvirtd enabled (will start on boot)"
    else
        log WARN "Failed to enable libvirtd"
    fi

    # Start libvirtd service
    if systemctl start libvirtd; then
        log SUCCESS "libvirtd service started"
    else
        log ERROR "Failed to start libvirtd service"
        exit 1
    fi

    # Verify service is running
    if systemctl is-active --quiet libvirtd; then
        log SUCCESS "libvirtd service is active and running"
    else
        log ERROR "libvirtd service is not running"
        exit 1
    fi
}

configure_default_network() {
    log INFO "Configuring default libvirt network"

    # Check if default network exists
    if ! virsh net-list --all | grep -q default; then
        log WARN "Default network not found (may not be created yet)"
        return
    fi

    # Start default network if not active
    if ! virsh net-list | grep -q "default.*active"; then
        if run_logged virsh net-start default; then
            log SUCCESS "Default network started"
        else
            log WARN "Could not start default network (may already be active)"
        fi
    else
        log INFO "Default network already active"
    fi

    # Enable autostart for default network
    if run_logged virsh net-autostart default; then
        log SUCCESS "Default network autostart enabled"
    else
        log WARN "Could not enable default network autostart"
    fi
}

# ==============================================================================
# STATE MANAGEMENT
# ==============================================================================

save_installation_state() {
    log INFO "Saving installation state"

    # Get installed package versions
    local packages_json="["
    local first=true

    for package in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            local version=$(dpkg -l | grep "^ii  $package " | awk '{print $3}')
            local install_time=$(stat -c %y "/var/lib/dpkg/info/${package}.list" | cut -d'.' -f1)

            if ! $first; then
                packages_json+=","
            fi
            first=false

            packages_json+=$(cat <<EOF

    {
        "name": "$package",
        "version": "$version",
        "installed_at": "$install_time"
    }
EOF
)
        fi
    done

    packages_json+=$'\n]'

    # Create state file
    cat > "$STATE_FILE" <<EOF
{
    "installation_date": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "username": "$SUDO_USER",
    "ubuntu_version": "$(lsb_release -rs)",
    "ubuntu_codename": "$(lsb_release -cs)",
    "kernel_version": "$(uname -r)",
    "cpu_vendor": "$(lscpu | grep 'Vendor ID' | awk '{print $3}')",
    "cpu_model": "$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')",
    "ram_gb": $(free -g | awk '/^Mem:/ {print $2}'),
    "virtualization_support": "$(grep -qE '(vmx|svm)' /proc/cpuinfo && echo 'true' || echo 'false')",
    "packages_installed": $packages_json,
    "log_file": "$LOG_FILE"
}
EOF

    log SUCCESS "Installation state saved to: $STATE_FILE"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    echo "======================================================================"
    echo "  QEMU/KVM Installation Script"
    echo "  Ubuntu 25.10 - Comprehensive Installation with Logging"
    echo "======================================================================"
    echo ""

    # Initialize logging
    init_logging

    log INFO "Starting QEMU/KVM installation"
    log INFO "Log file: $LOG_FILE"
    echo ""

    # Run installation steps
    preflight_checks
    echo ""

    check_existing_installation
    echo ""

    update_package_cache
    echo ""

    install_packages
    echo ""

    configure_libvirtd
    echo ""

    configure_default_network
    echo ""

    save_installation_state
    echo ""

    # Final summary
    echo "======================================================================"
    log SUCCESS "QEMU/KVM installation complete!"
    echo "======================================================================"
    echo ""
    log INFO "Installation summary:"
    log INFO "  - Packages installed: ${#PACKAGES[@]}"
    log INFO "  - libvirtd service: running"
    log INFO "  - Default network: configured"
    log INFO "  - Log file: $LOG_FILE"
    log INFO "  - State file: $STATE_FILE"
    echo ""
    log INFO "Next steps:"
    log INFO "  1. Configure user groups: sudo ./scripts/02-configure-user-groups.sh"
    log INFO "  2. REBOOT SYSTEM (required for group changes to take effect)"
    log INFO "  3. Verify installation: ./scripts/03-verify-installation.sh"
    log INFO "  4. Create Windows 11 VM: ./scripts/04-create-vm.sh"
    echo ""
    log WARN "IMPORTANT: You MUST reboot for group membership changes to take effect"
    echo "======================================================================"
}

# Run main function
main "$@"
