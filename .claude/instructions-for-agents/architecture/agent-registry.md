# Agent Registry (60 Agents)

[← Back to Index](../README.md) | [Delegation Guide](./agent-delegation.md)

---

## 4-Tier Overview

| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 10 | Domain operations |
| 4 | Haiku | 49 | Atomic execution |

---

## Tier 1: Orchestrator (Opus)

| Agent | Purpose | Parallel-Safe |
|-------|---------|---------------|
| **001-orchestrator** | Complex task coordination, multi-agent dispatch | No |

---

## Tier 2: Domain Specialists (Sonnet)

| Agent | Purpose | Children | Parallel-Safe |
|-------|---------|----------|---------------|
| **002-vm-operations** | VM lifecycle | 021-025 (5) | No |
| **003-performance** | Hyper-V tuning | 031-035 (5) | Yes |
| **004-security** | Security hardening | 041-046 (6) | Yes |
| **005-virtiofs** | Filesystem sharing | 051-055 (5) | Yes |
| **006-automation** | QEMU guest agent | 061-065 (5) | Yes |
| **007-health** | System readiness | 071-076 (6) | Yes |
| **008-prerequisites** | First-time setup | 081-085 (5) | Yes |
| **009-git** | Git operations | 091-095 (5) | No |
| **010-docs** | Documentation | 101-105 (5) | Yes |
| **011-cleanup** | Repository hygiene | 111-114 (4) | Yes |

---

## Tier 4: Haiku Execution Agents (49 total)

### 02X VM Operations (Parent: 002-vm-operations)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 021-vm-create | Create VM with Q35/UEFI/TPM | No |
| 022-vm-configure | Update VM configuration | No |
| 023-vm-lifecycle | Start/stop/pause operations | No |
| 024-vm-xml-validator | Validate libvirt XML | Yes |
| 025-vm-snapshot | Snapshot management | No |

### 03X Performance (Parent: 003-performance)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 031-hyperv-enlightenments | Enable 14 enlightenments | No |
| 032-cpu-pinning | CPU affinity configuration | No |
| 033-memory-hugepages | Huge pages setup | No |
| 034-io-tuning | Disk I/O optimization | No |
| 035-benchmark | Performance benchmarking | Yes |

### 04X Security (Parent: 004-security)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 041-luks-encryption | Host disk encryption | No |
| 042-firewall-rules | UFW/iptables configuration | No |
| 043-bitlocker-guest | Guest BitLocker setup | No |
| 044-virtiofs-readonly | Read-only mount config | No |
| 045-security-audit | Run security checklist | Yes |
| 046-backup-encryption | Encrypted backup management | No |

### 05X VirtIO-FS (Parent: 005-virtiofs)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 051-virtiofs-setup | Host virtiofs daemon | No |
| 052-winfsp-install | Guest WinFsp installation | No |
| 053-share-mount | Mount/unmount directories | No |
| 054-pst-access | Outlook PST file config | Yes |
| 055-permission-fix | Fix permission issues | No |

### 06X Automation (Parent: 006-automation)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 061-guest-agent-install | Guest agent installation | No |
| 062-guest-agent-commands | Execute commands via agent | No |
| 063-file-transfer | Host-guest file transfer | No |
| 064-clipboard-sync | Clipboard synchronization | No |
| 065-display-resize | Automatic display resize | No |

### 07X Health (Parent: 007-health)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 071-hardware-check | CPU/RAM/SSD validation | Yes |
| 072-qemu-stack-check | QEMU/KVM/libvirt validation | Yes |
| 073-virtio-check | VirtIO drivers validation | Yes |
| 074-network-check | Network configuration check | Yes |
| 075-report-generator | JSON report generation | Yes |
| 076-setup-guide-generator | Generate device-specific guides | Yes |

### 08X Prerequisites (Parent: 008-prerequisites)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 081-package-install | Install QEMU/KVM packages | No |
| 082-group-membership | Add user to libvirt/kvm groups | No |
| 083-libvirtd-setup | Enable/start libvirtd | No |
| 084-virtio-iso-download | Download VirtIO drivers ISO | Yes |
| 085-windows-iso-verify | Verify Windows ISO | Yes |

### 09X Git Operations (Parent: 009-git)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 091-branch-create | Create timestamped branches | No |
| 092-branch-validate | Validate branch naming | Yes |
| 093-commit-format | Constitutional commit messages | Yes |
| 094-merge-noff | No-fast-forward merge | No |
| 095-push-remote | Push with upstream tracking | No |

### 10X Documentation (Parent: 010-docs)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 101-symlink-verify | Verify CLAUDE.md/GEMINI.md | Yes |
| 102-symlink-restore | Restore broken symlinks | No |
| 103-content-merge | Merge diverged content | No |
| 104-size-check | AGENTS.md size management | Yes |
| 105-link-integrity | Cross-reference validation | Yes |

### 11X Cleanup (Parent: 011-cleanup)
| Agent | Task | Parallel-Safe |
|-------|------|---------------|
| 111-redundancy-detect | Detect duplicate files | Yes |
| 112-script-cleanup | Remove one-off scripts | No |
| 113-archive-obsolete | Archive obsolete docs | No |
| 114-metrics-report | Cleanup impact metrics | Yes |

---

## Parent-Child Summary

```
001-orchestrator (Opus)
├── 002-vm-operations ────→ 021-025 (5 Haiku)
├── 003-performance ──────→ 031-035 (5 Haiku)
├── 004-security ─────────→ 041-046 (6 Haiku)
├── 005-virtiofs ─────────→ 051-055 (5 Haiku)
├── 006-automation ───────→ 061-065 (5 Haiku)
├── 007-health ───────────→ 071-076 (6 Haiku)
├── 008-prerequisites ────→ 081-085 (5 Haiku)
├── 009-git ──────────────→ 091-095 (5 Haiku)
├── 010-docs ─────────────→ 101-105 (5 Haiku)
└── 011-cleanup ──────────→ 111-114 (4 Haiku)
```

**Total**: 1 Opus + 10 Sonnet + 49 Haiku = **60 agents**

---

[← Back to Index](../README.md) | [Delegation Guide](./agent-delegation.md)
