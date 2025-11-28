---
name: 081-package-install
description: Install required QEMU/KVM packages.
model: haiku
---

## Single Task
Install all required packages for QEMU/KVM virtualization.

## Execution
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
  qemu-system-x86 \
  qemu-utils \
  libvirt-daemon-system \
  libvirt-clients \
  virtinst \
  virt-manager \
  ovmf \
  swtpm \
  swtpm-tools

# Verify installation
dpkg -l | grep -E "qemu|libvirt|ovmf|swtpm"
```

## Requirements
- qemu-system-x86: VM execution
- libvirt-daemon-system: VM management
- ovmf: UEFI firmware
- swtpm: TPM 2.0 emulation

## Output
```json
{
  "status": "pass | fail",
  "packages_installed": ["qemu-system-x86", "libvirt-daemon-system", "ovmf", "swtpm"],
  "missing_packages": []
}
```

## Parallel-Safe: Yes

## Parent: 008-prerequisites
