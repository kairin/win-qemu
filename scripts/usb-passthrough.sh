#!/bin/bash
#
# usb-passthrough.sh - USB Device Passthrough Management
#
# Purpose: Attach host USB devices to running VMs
# Usage: sudo ./scripts/usb-passthrough.sh [OPTIONS]
#

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

show_help() {
    echo "Usage: sudo $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --list             List host USB devices"
    echo "  --attach VM_NAME   Attach a USB device to a VM"
    echo "  --detach VM_NAME   Detach a USB device from a VM"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 --list"
    echo "  sudo $0 --attach win11-vm"
}

list_usb_devices() {
    log_step "Host USB Devices:"
    lsusb | while read line; do
        bus=$(echo $line | awk '{print $2}')
        dev=$(echo $line | awk '{print $4}' | sed 's/://')
        id=$(echo $line | awk '{print $6}')
        name=$(echo $line | cut -d ' ' -f 7-)
        echo "  Bus $bus Device $dev: ID $id $name"
    done
}

select_usb_device() {
    local devices=()
    local i=0
    
    echo "Available USB Devices:"
    while read line; do
        devices+=("$line")
        echo "  [$i] $line"
        ((i++))
    done < <(lsusb)
    
    if [[ ${#devices[@]} -eq 0 ]]; then
        log_error "No USB devices found"
        exit 1
    fi
    
    read -p "Select device (0-$((i-1))): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -lt $i ]]; then
        local line="${devices[$selection]}"
        USB_VENDOR_ID=$(echo $line | awk '{print $6}' | cut -d: -f1)
        USB_PRODUCT_ID=$(echo $line | awk '{print $6}' | cut -d: -f2)
        USB_NAME=$(echo $line | cut -d ' ' -f 7-)
        log_info "Selected: $USB_NAME ($USB_VENDOR_ID:$USB_PRODUCT_ID)"
    else
        log_error "Invalid selection"
        exit 1
    fi
}

generate_usb_xml() {
    local vendor="$1"
    local product="$2"
    local outfile="$3"
    
    cat > "$outfile" <<EOF
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x$vendor'/>
    <product id='0x$product'/>
  </source>
</hostdev>
EOF
}

attach_usb() {
    local vm_name="$1"
    
    if ! check_vm_exists "$vm_name"; then
        log_error "VM '$vm_name' not found"
        exit 1
    fi
    
    select_usb_device
    
    local xml_file="/tmp/usb_${USB_VENDOR_ID}_${USB_PRODUCT_ID}.xml"
    generate_usb_xml "$USB_VENDOR_ID" "$USB_PRODUCT_ID" "$xml_file"
    
    log_step "Attaching device to $vm_name..."
    if virsh attach-device "$vm_name" "$xml_file" --live --persistent; then
        log_success "Device attached successfully"
    else
        log_error "Failed to attach device"
    fi
    
    rm -f "$xml_file"
}

detach_usb() {
    local vm_name="$1"
    
    if ! check_vm_exists "$vm_name"; then
        log_error "VM '$vm_name' not found"
        exit 1
    fi
    
    select_usb_device
    
    local xml_file="/tmp/usb_${USB_VENDOR_ID}_${USB_PRODUCT_ID}.xml"
    generate_usb_xml "$USB_VENDOR_ID" "$USB_PRODUCT_ID" "$xml_file"
    
    log_step "Detaching device from $vm_name..."
    if virsh detach-device "$vm_name" "$xml_file" --live --persistent; then
        log_success "Device detached successfully"
    else
        log_error "Failed to detach device (it might not be attached)"
    fi
    
    rm -f "$xml_file"
}

main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    init_logging "usb-passthrough"
    check_root
    check_libvirtd
    
    case "${1:-}" in
        --list)
            list_usb_devices
            ;;
        --attach)
            if [[ -z "${2:-}" ]]; then
                log_error "Missing VM name"
                show_help
                exit 1
            fi
            attach_usb "$2"
            ;;
        --detach)
            if [[ -z "${2:-}" ]]; then
                log_error "Missing VM name"
                show_help
                exit 1
            fi
            detach_usb "$2"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
