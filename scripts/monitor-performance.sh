#!/bin/bash
#
# monitor-performance.sh - Real-time VM Performance Monitoring
#
# Purpose: Monitor CPU, RAM, and Disk I/O of running VMs
# Usage: sudo ./scripts/monitor-performance.sh [VM_NAME]
#

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
DEFAULT_VM_NAME="win11-vm"

show_help() {
    echo "Usage: sudo $0 [VM_NAME]"
    echo ""
    echo "Arguments:"
    echo "  VM_NAME        Name of the VM to monitor (optional, default: interactive selection)"
    echo ""
    echo "Options:"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0"
    echo "  sudo $0 win11-pro"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v virt-top &>/dev/null; then
        missing_deps+=("virt-top")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_deps[*]}"
        log_error "Install with: sudo apt install -y ${missing_deps[*]}"
        exit 1
    fi
}

# Select VM if not provided
select_vm() {
    local vms=($(virsh list --name --state-running))
    
    if [[ ${#vms[@]} -eq 0 ]]; then
        log_error "No running VMs found."
        exit 1
    fi
    
    if [[ ${#vms[@]} -eq 1 ]]; then
        VM_NAME="${vms[0]}"
        log_info "Auto-selected only running VM: $VM_NAME"
        return
    fi
    
    echo "Running VMs:"
    for i in "${!vms[@]}"; do
        echo "  [$i] ${vms[$i]}"
    done
    
    read -p "Select VM to monitor (0-${#vms[@]-1}): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -lt "${#vms[@]}" ]]; then
        VM_NAME="${vms[$selection]}"
    else
        log_error "Invalid selection"
        exit 1
    fi
}

main() {
    # Parse args
    if [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    VM_NAME="${1:-}"
    
    init_logging "monitor-performance"
    check_root
    check_libvirtd
    check_dependencies
    
    if [[ -z "$VM_NAME" ]]; then
        select_vm
    fi
    
    if ! check_vm_exists "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found"
        exit 1
    fi
    
    # Check if VM is running
    if ! virsh domstate "$VM_NAME" | grep -q "running"; then
        log_error "VM '$VM_NAME' is not running"
        exit 1
    fi
    
    log_info "Starting performance monitor for '$VM_NAME'..."
    log_info "Press 'q' to quit virt-top"
    sleep 2
    
    # Run virt-top
    virt-top --connect qemu:///system --domain "$VM_NAME"
}

main "$@"
