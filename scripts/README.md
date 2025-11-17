# Scripts Directory

## Purpose
This directory contains automation scripts for QEMU/KVM Windows virtualization management.

## Planned Scripts

### VM Lifecycle Management
- **create-vm.sh** - Automated Windows 11 VM creation with Q35, UEFI, TPM 2.0
- **start-vm.sh** - Start VM with health checks
- **stop-vm.sh** - Graceful VM shutdown
- **destroy-vm.sh** - Remove VM and associated resources

### Configuration & Optimization
- **configure-performance.sh** - Apply Hyper-V enlightenments and performance tuning
- **setup-virtio-fs.sh** - Configure VirtIO filesystem sharing for PST files
- **install-virtio-drivers.sh** - Automated VirtIO driver installation helpers

### Monitoring & Maintenance
- **health-check.sh** - System and VM health validation
- **backup-vm.sh** - Create VM snapshots and backups
- **monitor-performance.sh** - Real-time performance monitoring

## Usage Guidelines

**Before Running Scripts**:
1. Review script content and understand what it does
2. Check script permissions (`chmod +x script-name.sh`)
3. Run with appropriate privileges (some require sudo)
4. Test in development environment first

**Safety Practices**:
- Scripts include error checking and validation
- Provide rollback/recovery procedures
- Log all operations for audit trail
- Never run untested scripts on production VMs

## Beginner Notes

**What are shell scripts?**
Shell scripts (.sh files) are text files containing commands that automate tasks. Instead of typing commands one-by-one, scripts execute them automatically in sequence.

**How to run a script:**
```bash
# Make script executable (first time only)
chmod +x script-name.sh

# Run the script
./script-name.sh
```

**Understanding sudo:**
Some scripts require `sudo` (superuser privileges) to perform system-level operations like installing packages or modifying network settings. You'll be prompted for your password.

## Documentation
- Main guide: `/outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- Performance tuning: `/outlook-linux-guide/09-performance-optimization-playbook.md`
- Security hardening: `/research/06-security-hardening-analysis.md`

---

*Created: 2025-11-17*
*Status: Initial setup - scripts to be added during implementation*
