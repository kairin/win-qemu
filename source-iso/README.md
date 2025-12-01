# Source ISO Files

This directory is a **staging area** for downloading installation media. After download, ISOs must be moved to `/var/lib/libvirt/images/iso/` for libvirt access.

**Files in this directory are excluded from Git** due to size and licensing restrictions.

## Required Files

Download the following files:

### 1. Windows 11 ISO (Required)
- **File**: `Win11_25H2_English_x64.iso` (or latest version)
- **Size**: ~7.7 GB
- **Source**: [Microsoft Windows 11 Download](https://www.microsoft.com/software-download/windows11)
- **Purpose**: Windows 11 installation media for VM creation
- **License**: Requires valid Windows 11 Pro **Retail** license (NOT OEM)

### 2. VirtIO Drivers for Windows (Required)
- **File**: `virtio-win-*.iso` (e.g., `virtio-win-0.1.240.iso`)
- **Size**: ~500 MB
- **Source**: [Fedora VirtIO Drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/)
- **Purpose**: High-performance VirtIO drivers (storage, network, graphics)
- **License**: Open source (GPL/LGPL)

### 3. Microsoft Office Setup (Optional)
- **File**: `OfficeSetup.exe`
- **Size**: ~7.5 MB
- **Source**: [Microsoft 365 Downloads](https://www.office.com/download)
- **Purpose**: Install Microsoft 365 Outlook in Windows guest
- **License**: Requires valid Microsoft 365 subscription

### 4. CrossOver (Optional - Linux Alternative)
- **File**: `crossover_*.deb`
- **Size**: ~197 MB
- **Source**: [CodeWeavers CrossOver](https://www.codeweavers.com/crossover)
- **Purpose**: Alternative approach - run Windows apps on Linux without VM
- **License**: Commercial license required (trial available)
- **Note**: Not the primary solution; QEMU/KVM is recommended

## Current Directory Contents

```bash
# Check what's downloaded
ls -lh /home/kkk/Apps/win-qemu/source-iso
```

## Git Exclusion

These files are automatically excluded via `.gitignore`:
- `*.iso` - Windows and VirtIO ISOs
- `*.exe` - Microsoft Office setup
- `*.deb` - CrossOver package

## Setup: Move ISOs to libvirt Location

After downloading, move ISOs to the runtime location for libvirt/QEMU access:

```bash
# Create directory (one-time)
sudo mkdir -p /var/lib/libvirt/images/iso

# Move ISOs with standardized names
sudo mv source-iso/Win11_25H2_English_x64.iso /var/lib/libvirt/images/iso/Win11.iso
sudo mv source-iso/virtio-win-*.iso /var/lib/libvirt/images/iso/virtio-win.iso

# Set permissions
sudo chown root:kvm /var/lib/libvirt/images/iso/*.iso
sudo chmod 640 /var/lib/libvirt/images/iso/*.iso
```

**Why?** The `libvirt-qemu` user cannot access files in your home directory for security reasons. Moving ISOs to `/var/lib/libvirt/images/iso/` provides proper isolation.

## Usage

Refer to the main implementation guide for how to use these files:
- **VM Creation**: `outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- **Driver Installation**: Phase 2-3 of implementation checklist
- **Performance Optimization**: `outlook-linux-guide/09-performance-optimization-playbook.md`

## Security Notes

- **Never commit these files to Git** (licensing violations + bandwidth costs)
- Verify checksums after download (see official sources for SHA256)
- Store on encrypted partition (LUKS) if containing sensitive data
- Delete after VM setup to save disk space (keep backups elsewhere)

## File Integrity Verification

After downloading, verify file integrity:

```bash
# Windows 11 ISO (example - get hash from Microsoft)
sha256sum Win11_25H2_English_x64.iso

# VirtIO drivers (example - get hash from Fedora)
sha256sum virtio-win-*.iso
```

---

**Last Updated**: 2025-11-17
