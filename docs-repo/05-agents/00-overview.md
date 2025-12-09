# Win-QEMU Agent System

**Version**: 1.1.0 | **Status**: Production Ready | **Agents**: 85

---

## Quick Navigation

| Need | Document |
|------|----------|
| **Getting Started** | This file |
| **Agent System Architecture** | [../06-constitutional/04-agent-system.md](../06-constitutional/04-agent-system.md) |
| **Complete Reference** | [01-agents-reference.md](01-agents-reference.md) |
| **Workflow Patterns** | [02-workflows.md](02-workflows.md) |

---

## Overview

The win-qemu agent system automates QEMU/KVM Windows virtualization on Ubuntu with near-native performance (85-95%). It consists of **85 specialized agents** in a 5-tier hierarchy handling everything from VM lifecycle to security hardening.

**Key Benefits**:
- 87.7% time savings through parallel execution
- 60-75% faster VM setup (2-3 hrs vs 8-11 hrs manual)
- 100% constitutional compliance enforcement

---

## Agent Inventory

### Core Infrastructure (8 agents)

| Agent | Purpose |
|-------|---------|
| symlink-guardian | CLAUDE.md/GEMINI.md symlink integrity |
| documentation-guardian | AGENTS.md single source of truth |
| constitutional-compliance-agent | AGENTS.md size management (<40KB) |
| git-operations-specialist | ALL Git operations |
| constitutional-workflow-orchestrator | Shared workflow templates |
| master-orchestrator | Multi-agent coordination |
| project-health-auditor | Health checks, Context7 MCP |
| repository-cleanup-specialist | Redundancy detection |

### QEMU/KVM Specialized (7 agents)

| Agent | Purpose |
|-------|---------|
| vm-operations-specialist | VM lifecycle (Q35/UEFI/TPM) |
| performance-optimization-specialist | Hyper-V enlightenments, tuning |
| security-hardening-specialist | 60+ security checklist |
| virtio-fs-specialist | Filesystem sharing, PST access |
| qemu-automation-specialist | QEMU guest agent automation |
| qemu-health-checker | System readiness validation |
| **virtio-gpu-install** | **VirtIO GPU driver installation (NEW)** |

---

## Quick Start

### 1. Check System Readiness
```
User: "Check if my system is ready for QEMU/KVM"
→ qemu-health-checker validates 42 prerequisites
```

### 2. Create Your First VM
```
User: "Create a new Windows 11 VM"
→ vm-operations-specialist creates VM with Q35/UEFI/TPM
```

### 3. Optimize Performance
```
User: "Optimize my VM for best performance"
→ performance-optimization-specialist applies 14 Hyper-V enlightenments
```

### 4. Harden Security
```
User: "Run security checklist on my VM"
→ security-hardening-specialist runs 60+ checks
```

---

## Agent Selection Guide

| Need | Recommended Agent |
|------|-------------------|
| Create new VM | vm-operations-specialist |
| Optimize performance | performance-optimization-specialist |
| Harden security | security-hardening-specialist |
| Share PST files | virtio-fs-specialist |
| Automate tasks | qemu-automation-specialist |
| Git operations | git-operations-specialist |
| Multi-step workflow | master-orchestrator |
| System health check | qemu-health-checker |
| Standards compliance | project-health-auditor |
| Cleanup repository | repository-cleanup-specialist |

---

## Prerequisites

**Hardware**:
- CPU with VT-x/AMD-V (12+ cores recommended)
- 16GB+ RAM (32GB recommended)
- SSD storage (NVMe recommended)

**Software**:
```bash
# Install QEMU/KVM stack
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system \
    libvirt-clients ovmf swtpm qemu-utils guestfs-tools

# Add user to groups
sudo usermod -aG libvirt,kvm $USER

# Start libvirtd
sudo systemctl enable --now libvirtd
```

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Overall Performance | 85-95% native |
| Boot time | <25s |
| Outlook launch | <5s |
| PST open (1GB) | <3s |
| Disk IOPS (4K) | >30,000 |

---

## Security Standards

**Mandatory Measures**:
1. LUKS encryption for VM images
2. virtio-fs read-only mode (ransomware protection)
3. UFW firewall with M365 whitelist
4. BitLocker in guest
5. Regular encrypted backups

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Permission denied" | Add user to libvirt/kvm groups, re-login |
| "libvirtd not running" | `sudo systemctl start libvirtd` |
| "No hardware virtualization" | Enable VT-x/AMD-V in BIOS |
| "VM won't boot" | Check OVMF installed |

**For detailed troubleshooting**: See [AGENTS-REFERENCE.md](AGENTS-REFERENCE.md)

---

## Documentation References

- **Constitutional Requirements**: `CLAUDE.md` (AGENTS.md symlink)
- **VM Setup Guide**: `docs-repo/02-setup/01-core-install.md`
- **Performance Tuning**: See [Performance page](../../docs-astro/src/pages/performance.astro)
- **Security Checklist**: `docs-repo/03-ops/01-security.md`
- **Agent System Architecture**: `docs-repo/06-constitutional/04-agent-system.md`

---

**Created**: 2025-11-17 | **Updated**: 2025-12-09 | **Maintainer**: AI Assistants + User
