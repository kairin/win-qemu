# QEMU/KVM Windows Virtualization - Native Outlook on Linux

> **Run Microsoft 365 Outlook desktop natively on Ubuntu with 85-95% native Windows performance using hardware-assisted virtualization**

[![Status](https://img.shields.io/badge/Status-Ready%20for%20Install-green)]()
[![Progress](https://img.shields.io/badge/Progress-40%25-blue)]()
[![License](https://img.shields.io/badge/License-MIT-blue)]()

---

## 📊 Project Status Dashboard

```
📊 PROJECT STATUS (2025-11-26)

✅ Repository Setup:        100% Complete
✅ Documentation:           100% Complete (Consolidated in docs-repo/)
✅ Hardware Verification:   100% Complete (Excellent)
❌ Software Installation:     0% Complete (NEXT STEP)
⏸️  VM Creation:            Pending (after software)
⏸️  Performance Tuning:     Pending
⏸️  Security Hardening:     Pending

Overall Progress: [████░░░░░░] 40% (Infrastructure Ready)
Next Milestone: Run ./start.sh
```

---

## 🎯 The Solution

**Problem**: Need native Outlook on Linux. Graph API blocked. No 3rd party clients allowed.
**Solution**: QEMU/KVM Virtualization + VirtIO + Hyper-V Enlightenments + virtio-fs.
**Result**: 85-95% native performance, direct PST access, full IT compliance capability.

---

## 🚀 Quick Start (New!)

**We have introduced a zero-command-memorization TUI.**

### 1. Launch the Wizard
```bash
./start.sh
```

### 2. Select "🚀 Quick Start"
The guided wizard will walk you through:
1.  **Hardware Check** (Automatic verification)
2.  **Software Install** (Installs QEMU/KVM stack)
3.  **User Groups** (Configures permissions)
4.  **ISO Setup** (Guides you to downloads)
5.  **VM Creation** (Sets up Windows 11)

> **Note**: You can still use individual scripts in `scripts/` if you prefer manual control, but `start.sh` is the recommended entry point.

---

## 📂 Documentation Structure

All documentation is centralized in `docs-repo/`.

### **[00-INDEX.md](docs-repo/00-INDEX.md)** (Start Here)

| Section | Content |
|---------|---------|
| **[01-concept/](docs-repo/01-concept/)** | **Prerequisites**: Hardware, Software, Legal, Network. |
| **[02-setup/](docs-repo/02-setup/)** | **Implementation**: Install Guides, Automation, Optimization. |
| **[03-ops/](docs-repo/03-ops/)** | **Maintenance**: Security, Performance Theory, Troubleshooting. |
| **[04-history/](docs-repo/04-history/)** | **Archives**: Project logs, validation reports, dry-run results. |
| **[05-agents/](docs-repo/05-agents/)** | **Internals**: Multi-agent system manuals. |
| **[06-constitutional/](docs-repo/06-constitutional/)** | **Rules**: Core mandates for this repository. |

---

## ⚠️ Outstanding Issues

**From Dry-Run Tests (2025-11-26):**
- **Software Stack**: QEMU/KVM is **not installed**.
- **Action**: Run `./start.sh` -> "Quick Start" to resolve.

---

## 💻 Key Technologies

- **Hypervisor**: KVM (Kernel-based Virtual Machine)
- **Emulation**: QEMU 8.2+
- **Management**: libvirt
- **Drivers**: VirtIO (Network, Block, Balloon, GPU)
- **Filesystem**: virtio-fs (High-performance sharing)
- **TPM**: swtpm (TPM 2.0 emulation)

---

## 🤖 Multi-Agent System

This project is maintained by a 14-agent system.
- **User Entry Point**: `start.sh`
- **Agent Entry Point**: `AGENTS.md` -> `docs-repo/06-constitutional/`

---

## 📄 License

MIT License - See LICENSE file for details