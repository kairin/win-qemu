# Context7 Library Quick Reference

**Purpose**: Quick lookup for Context7 library IDs used in QEMU/KVM verification workflow
**Created**: 2025-11-21
**Status**: Pending Context7 Lookups

---

## 🌐 Core Virtualization Libraries

### QEMU (Hardware Emulation)

**Technology**: QEMU
**Context7 Query**: "QEMU hardware emulation virtualization"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: All scripts, all configs
**Topics to Query**:
- "VM creation best practices"
- "QEMU command-line options"
- "Q35 chipset configuration"
- "UEFI firmware setup"
- "Performance optimization"

---

### KVM (Kernel Virtual Machine)

**Technology**: KVM
**Context7 Query**: "KVM kernel virtual machine Linux"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: All VM-related scripts
**Topics to Query**:
- "KVM hardware requirements"
- "CPU virtualization features"
- "KVM kernel module configuration"

---

### libvirt (Virtualization Management)

**Technology**: libvirt
**Context7 Query**: "libvirt virtualization management API XML"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: All scripts, all configs
**Topics to Query**:
- "XML domain configuration"
- "virsh command reference"
- "virt-install VM creation"
- "libvirt networking"
- "storage pool management"

---

## 🚀 VirtIO Paravirtualization Libraries

### VirtIO Drivers (General)

**Technology**: VirtIO
**Context7 Query**: "VirtIO paravirtualized drivers QEMU KVM"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: create-vm.sh, configure-performance.sh, win11-vm.xml
**Topics to Query**:
- "virtio-blk storage driver"
- "virtio-scsi vs virtio-blk comparison"
- "virtio-net network driver"
- "virtio-vga graphics driver"
- "VirtIO driver installation Windows"

---

### virtio-fs (Filesystem Sharing)

**Technology**: virtio-fs
**Context7 Query**: "virtio-fs filesystem sharing QEMU KVM"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: setup-virtio-fs.sh, test-virtio-fs.sh, virtio-fs-share.xml
**Topics to Query**:
- "virtio-fs configuration"
- "virtio-fs vs 9p performance"
- "virtio-fs read-only mode"
- "WinFsp Windows integration"
- "virtio-fs security best practices"

---

## 🔧 Firmware & Emulation Libraries

### OVMF/EDK2 (UEFI Firmware)

**Technology**: OVMF/EDK2
**Context7 Query**: "OVMF EDK2 UEFI firmware QEMU"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: create-vm.sh, win11-vm.xml
**Topics to Query**:
- "OVMF Secure Boot configuration"
- "UEFI firmware paths"
- "EDK2 QEMU integration"
- "OVMF variables storage"

---

### swtpm (TPM Emulator)

**Technology**: swtpm
**Context7 Query**: "swtpm TPM emulator QEMU"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: create-vm.sh, win11-vm.xml
**Topics to Query**:
- "swtpm TPM 2.0 configuration"
- "Windows 11 TPM requirements"
- "swtpm libvirt integration"

---

## ⚡ Performance Optimization Libraries

### Hyper-V Enlightenments

**Technology**: Hyper-V Enlightenments
**Context7 Query**: "Hyper-V enlightenments QEMU KVM Windows performance"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: configure-performance.sh, win11-vm.xml
**Topics to Query**:
- "Hyper-V enlightenments list"
- "relaxed timer configuration"
- "VAPIC optimization"
- "spinlocks configuration"
- "Enlightened VMCS (evmcs)"
- "stimer direct mode"
- "Performance impact benchmarks"

---

### CPU Pinning

**Technology**: CPU Pinning
**Context7 Query**: "CPU pinning libvirt QEMU performance tuning"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: configure-performance.sh, win11-vm.xml (commented)
**Topics to Query**:
- "CPU pinning best practices"
- "vcpupin configuration"
- "NUMA topology considerations"
- "CPU isolation"

---

### Huge Pages

**Technology**: Huge Pages
**Context7 Query**: "huge pages memory libvirt QEMU performance"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: configure-performance.sh, win11-vm.xml (commented)
**Topics to Query**:
- "huge pages configuration Linux"
- "transparent huge pages vs static"
- "libvirt huge pages XML"
- "huge pages performance benchmarks"

---

## 🔌 Guest Integration Libraries

### QEMU Guest Agent

**Technology**: QEMU Guest Agent
**Context7 Query**: "QEMU guest agent communication"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: stop-vm.sh (graceful shutdown)
**Topics to Query**:
- "QEMU guest agent installation"
- "guest agent commands"
- "graceful shutdown implementation"
- "host-guest communication"

---

### WinFsp (Windows Filesystem)

**Technology**: WinFsp
**Context7 Query**: "WinFsp Windows filesystem userspace"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: setup-virtio-fs.sh (Windows guest requirement)
**Topics to Query**:
- "WinFsp installation"
- "WinFsp virtio-fs integration"
- "WinFsp mounting drives"
- "WinFsp security considerations"

---

## 🛠️ System Administration Libraries

### systemd (Service Management)

**Technology**: systemd
**Context7 Query**: "systemd service management Linux"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: 01-install-qemu-kvm.sh
**Topics to Query**:
- "systemctl enable service"
- "systemctl start service"
- "systemd service validation"

---

### virt-install (VM Creation Tool)

**Technology**: virt-install
**Context7 Query**: "virt-install VM creation libvirt"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: create-vm.sh
**Topics to Query**:
- "virt-install command-line options"
- "virt-install vs virsh define"
- "virt-install best practices"
- "Windows VM creation with virt-install"

---

### virsh (Libvirt CLI)

**Technology**: virsh
**Context7 Query**: "virsh libvirt command-line interface"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: All operational scripts (start, stop, backup, configure)
**Topics to Query**:
- "virsh define vs virsh create"
- "virsh snapshot commands"
- "virsh dumpxml usage"
- "virsh qemu-agent-command"
- "virsh shutdown graceful vs destroy"

---

### qemu-img (Disk Image Tool)

**Technology**: qemu-img
**Context7 Query**: "qemu-img disk image management"
**Library ID**: [PENDING - use mcp__context7__resolve-library-id]
**Confidence**: [High | Medium | Low]
**Used In**: backup-vm.sh
**Topics to Query**:
- "qemu-img create options"
- "qcow2 format best practices"
- "qemu-img snapshot management"
- "disk image conversion"

---

## 📊 Usage Statistics

**Total Technologies**: 15
**Critical Priority**: 7 (QEMU, KVM, libvirt, VirtIO, virtio-fs, Hyper-V, virt-install)
**High Priority**: 5 (OVMF, swtpm, virsh, qemu-img, WinFsp)
**Medium Priority**: 3 (QEMU guest agent, CPU pinning, huge pages)

---

## 🚀 Quick Start Workflow

### Step 1: Resolve All Library IDs

For each technology above:
```
Use: mcp__context7__resolve-library-id
Input: Context7 Query from above
Output: Library ID (e.g., /qemu/qemu or /libvirt/libvirt)
Update: This document with resolved library ID
```

### Step 2: Cache Library Documentation

For critical/high priority libraries:
```
Use: mcp__context7__get-library-docs
Input: Library ID from Step 1, Topic from above
Output: Best practices documentation
Save: To docs-repo/context7-libraries/[technology]-docs.md
```

### Step 3: Use in Script Verification

When verifying a script:
1. Identify technologies used
2. Look up library IDs in this document
3. Fetch relevant documentation with topics from above
4. Compare script implementation against Context7 recommendations
5. Document findings in per-script verification document

---

## 📝 Update Log

**2025-11-21**: Initial creation with 15 technology entries
**[PENDING]**: Context7 library ID resolution
**[PENDING]**: Library documentation caching

---

**Document Version**: 1.0
**Status**: Pending Context7 Lookups
**Next Action**: Resolve library IDs for all 15 technologies
