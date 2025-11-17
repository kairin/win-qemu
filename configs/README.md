# Configs Directory

## Purpose
This directory contains XML configuration templates for libvirt virtual machines and networks.

## Planned Configuration Templates

### VM Definitions
- **win11-vm.xml** - Complete Windows 11 VM configuration with:
  - Q35 chipset (modern PCI-Express support)
  - UEFI firmware (OVMF)
  - TPM 2.0 emulation (required for Windows 11)
  - VirtIO storage, network, and graphics drivers
  - Hyper-V enlightenments (14 performance features)

### Network Configurations
- **network-nat.xml** - NAT network configuration (recommended)
  - Provides VM internet access while isolating from host network
  - Suitable for most use cases

- **network-bridge.xml** - Bridged network configuration (alternative)
  - Direct network access for RemoteApp scenarios
  - Use only if seamless window integration needed

### Filesystem Sharing
- **virtio-fs-share.xml** - VirtIO filesystem configuration
  - Read-only PST file sharing (ransomware protection)
  - Maps host directory to VM drive (Z:)

## Using XML Templates

### Basic Workflow
```bash
# 1. Copy template and customize
cp configs/win11-vm.xml configs/my-vm.xml

# 2. Edit configuration (adjust paths, resources)
nano configs/my-vm.xml

# 3. Validate XML syntax
virsh define --validate configs/my-vm.xml

# 4. Define VM in libvirt
virsh define configs/my-vm.xml

# 5. Start VM
virsh start my-vm
```

### Key Configuration Sections

**CPU and Memory** - Adjust based on your system:
```xml
<memory unit='GiB'>8</memory>  <!-- 8GB RAM for guest -->
<vcpu placement='static'>4</vcpu>  <!-- 4 virtual CPUs -->
```

**Storage** - VM disk location:
```xml
<source file='/var/lib/libvirt/images/win11.qcow2'/>
```

**Network** - Connection mode:
```xml
<interface type='network'>
  <source network='default'/>  <!-- Uses NAT -->
</interface>
```

## Beginner Notes

**What is XML?**
XML (eXtensible Markup Language) is a text format for structured data. Libvirt uses XML to define virtual machine configurations - think of it as a blueprint for your VM.

**What is libvirt?**
Libvirt is a management layer that sits on top of QEMU/KVM. Instead of typing complex QEMU commands, you define a VM once in XML and manage it with simple commands like `virsh start vm-name`.

**Important Tags:**
- `<domain>` - Root element, defines the entire VM
- `<os>` - Operating system and boot settings
- `<devices>` - Hardware devices (disk, network, graphics)
- `<features>` - Special features like Hyper-V enlightenments

**Safe Editing:**
- Always validate XML before using: `virsh define --validate file.xml`
- Keep backups of working configurations
- Test changes in development VMs first

## Documentation References
- Libvirt XML format: https://libvirt.org/formatdomain.html
- QEMU reference architecture: `/outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- Performance optimization: `/outlook-linux-guide/09-performance-optimization-playbook.md`

## Validation

Before using any XML configuration:
1. Check syntax with `virsh define --validate config-file.xml`
2. Verify paths exist (disk images, ISOs, directories)
3. Ensure resource allocation doesn't exceed host capacity
4. Review security settings (firewall, read-only mounts)

---

*Created: 2025-11-17*
*Status: Initial setup - templates to be added during implementation*
