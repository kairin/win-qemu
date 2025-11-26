# Core Mandates

> 🔧 **CRITICAL**: These are NON-NEGOTIABLE requirements for all work on this repository.

## 🚨 Hardware Requirements (MANDATORY)

**Minimum System Requirements**:
- **CPU**: Hardware virtualization (VT-x/AMD-V) enabled.
- **RAM**: Minimum 16GB (8GB guest / 8GB host).
- **Storage**: **SSD MANDATORY**. HDD is unsupported.
- **Cores**: Minimum 8 cores.

**Reference**: [`docs-repo/01-concept/01-hardware.md`](../01-concept/01-hardware.md)

## 🚨 Software Dependencies (MANDATORY)

**Host Packages**:
- QEMU/KVM Stack: `qemu-system-x86`, `libvirt-daemon-system`, `ovmf`, `swtpm`, `virt-manager`.

**Guest Requirements**:
- Windows 11 Pro Retail ISO
- VirtIO Drivers ISO
- WinFsp (for virtio-fs)
- QEMU Guest Agent

**Installation Sequence**:
1. Host packages & Groups
2. Windows 11 VM (Q35, UEFI, TPM 2.0)
3. VirtIO Drivers
4. WinFsp & Guest Agent
5. Hyper-V Optimization

**Reference**: [`docs-repo/01-concept/02-software.md`](../01-concept/02-software.md)

## 🚨 Licensing & Compliance (HIGH RISK)

**Mandatory Compliance**:
- **Windows**: Windows 11 Pro **Retail** License required. No OEM.
- **M365**: Personal account OR written IT approval for corporate use.
- **Prohibited**: Corporate access without approval (Shadow IT), Regulated industries (HIPAA/SOX) without approval.

**Reference**: [`docs-repo/01-concept/03-legal.md`](../01-concept/03-legal.md)

## 🚨 Network & Connectivity (MANDATORY)

- **Mode**: NAT (Default/Recommended) or Bridged (Specific use cases).
- **Connectivity**: Outbound HTTPS (443) to `*.office365.com`.
- **SSL**: Import corporate root CA if SSL inspection is active.

**Reference**: [`docs-repo/01-concept/04-network.md`](../01-concept/04-network.md)

## 🚨 Performance Optimization (MANDATORY)

**Hyper-V Enlightenments** (Must enable all 14):
- `relaxed`, `vapic`, `spinlocks`, `vpindex`, `runtime`, `synic`, `stimer`, `reset`, `vendor_id`, `frequencies`, `reenlightenment`, `tlbflush`, `ipi`, `evmcs`.

**VirtIO**: All devices (Disk, Net, GPU, FS) must use VirtIO.
**Memory**: Huge pages enabled.

**Reference**: [`docs-repo/02-setup/04-optimization.md`](../02-setup/04-optimization.md)

## 🚨 Security Hardening (MANDATORY)

**Host**:
- LUKS Encryption for storage.
- **virtio-fs Read-Only Mode** (Critical Ransomware Protection).
- Egress Firewall (M365 Whitelist).

**Guest**:
- BitLocker enabled.
- Windows Defender active.
- No admin privileges for daily use.

**Reference**: [`docs-repo/03-ops/01-security.md`](../03-ops/01-security.md)
