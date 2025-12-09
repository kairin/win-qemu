# QEMU/KVM Windows Virtualization

> **Run Microsoft 365 Outlook on Ubuntu with 85-95% native Windows performance using hardware-assisted virtualization**

[![Status](https://img.shields.io/badge/Status-Production%20Ready-green)]()
[![Progress](https://img.shields.io/badge/Progress-85%25-brightgreen)]()
[![Agents](https://img.shields.io/badge/AI%20Agents-85-purple)]()
[![Docs](https://img.shields.io/badge/Docs-Live-blue)](https://kairin.github.io/win-qemu/)
[![License](https://img.shields.io/badge/License-MIT-blue)]()

---

## Project Status (2025-12-09)

```
✅ Repository Setup         100%   Infrastructure complete
✅ Documentation            100%   Website + guides deployed
✅ TUI Wizard               100%   Zero-config installation
✅ VM Creation              100%   Windows 11 with TPM 2.0
✅ Performance Tuning       100%   14 Hyper-V enlightenments
✅ GPU Driver Guide         100%   VirtIO GPU + 4K support
✅ Post-Install Checklist   100%   Automated guidance
✅ Branch Compliance        100%   28/28 constitutional format
⏸️  VFIO GPU Passthrough    Planned (Intel iGPU)

Overall Progress: ████████░░ 85%
```

---

## Quick Start

```bash
# Clone and launch the TUI wizard
git clone https://github.com/kairin/win-qemu.git
cd win-qemu
./start.sh
```

The guided wizard handles:
1. Hardware verification (CPU, RAM, IOMMU)
2. Software installation (QEMU/KVM stack)
3. ISO setup (Windows 11 + VirtIO drivers)
4. VM creation (Q35/UEFI/TPM 2.0)
5. Post-install checklist (GPU driver, SPICE tools)

---

## Documentation

### Online Documentation
**[https://kairin.github.io/win-qemu/](https://kairin.github.io/win-qemu/)**

### Repository Guides

| Section | Content |
|---------|---------|
| **[00-INDEX.md](docs-repo/00-INDEX.md)** | Master documentation index |
| **[01-concept/](docs-repo/01-concept/)** | Hardware, software, legal requirements |
| **[02-setup/](docs-repo/02-setup/)** | Installation, optimization, automation |
| **[03-ops/](docs-repo/03-ops/)** | Security, performance, troubleshooting |
| **[05-agents/](docs-repo/05-agents/)** | 85-agent AI system reference |
| **[06-constitutional/](docs-repo/06-constitutional/)** | Project rules and standards |

---

## Key Features

| Feature | Description |
|---------|-------------|
| **85-Agent AI System** | 5-tier hierarchical automation (Opus → Sonnet → Haiku) |
| **Zero-Config TUI** | Guided wizard via `./start.sh` |
| **VirtIO GPU** | High-resolution display up to 4K |
| **14 Hyper-V Enlightenments** | Near-native Windows performance |
| **virtio-fs** | Secure host filesystem sharing |
| **Post-Install Checklist** | Automated driver installation guidance |

---

## Technologies

| Component | Technology |
|-----------|------------|
| Hypervisor | KVM (Kernel-based Virtual Machine) |
| Emulation | QEMU 8.2+ |
| Management | libvirt |
| Drivers | VirtIO (disk, network, GPU, balloon) |
| Filesystem | virtio-fs (high-performance sharing) |
| Security | TPM 2.0 (swtpm), Secure Boot, LUKS |
| TUI | gum (charmbracelet) |

---

## Multi-Agent System

This project is maintained by an **85-agent 5-tier hierarchical system**:

| Tier | Model | Count | Role |
|------|-------|-------|------|
| 0 | Sonnet | 10 | Workflow automation (`000-*`) |
| 1 | Opus | 1 | Strategic orchestration |
| 2 | Sonnet | 11 | Domain expertise |
| 4 | Haiku | 63 | Task execution |

**Entry Points:**
- **User**: `./start.sh` (TUI wizard)
- **Agent**: `AGENTS.md` → Constitutional rules

**Key Workflows:**
- `000-health` - System readiness validation
- `000-vm` - Complete VM lifecycle
- `000-security` - 60+ security checklist
- `000-deploy` - Documentation deployment

---

## Recent Updates (December 2025)

- **VirtIO GPU Driver Guide** - Resolved 1280x800 resolution limitation
- **VRAM Configuration** - TUI now supports custom VRAM allocation
- **Post-Install Checklist** - Automatic guidance after VM creation
- **Agent 066** - New `virtio-gpu-install` agent
- **100% Branch Compliance** - All 28 branches follow constitutional format
- **Documentation Website** - Live at kairin.github.io/win-qemu

---

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Overall Performance | 85-95% native | ✅ Achievable |
| Boot Time | < 25 seconds | ✅ Documented |
| Outlook Launch | < 5 seconds | ✅ Documented |
| Disk IOPS (4K) | > 30,000 | ✅ VirtIO enabled |
| Display Resolution | Up to 4K | ✅ GPU driver guide |

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Contributing

1. Follow the [constitutional rules](docs-repo/06-constitutional/)
2. Use branch naming: `YYYYMMDD-HHMMSS-type-description`
3. Run `./start.sh` to verify changes
4. All 85 agents enforce standards automatically
