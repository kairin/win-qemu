# Multi-Agent System

## Overview
A 62-agent 4-tier hierarchical system optimized for QEMU/KVM workflows with ~48% token cost reduction vs flat architecture.

## 4-Tier Hierarchy

### Tier 1: Strategic (Opus) - 1 Agent
| ID | Name | Role |
|----|------|------|
| 001 | orchestrator | Strategic coordination, complex task decomposition |

### Tier 2: Domain Experts (Sonnet) - 10 Agents
| ID | Name | Role | Children |
|----|------|------|----------|
| 002 | vm-operations | VM lifecycle management | 02X |
| 003 | performance | Hyper-V, VirtIO tuning | 03X |
| 004 | security | 60+ checklist enforcement | 04X |
| 005 | virtiofs | Filesystem sharing | 05X |
| 006 | automation | QEMU guest agent | 06X |
| 007 | health | System readiness | 07X |
| 008 | prerequisites | Package installation | 08X |
| 009 | git | Constitutional commits | 09X |
| 010 | docs | Documentation sync | 10X |
| 011 | cleanup | Redundant file removal | 11X |

### Tier 4: Task Executors (Haiku) - 51 Agents
Specialized single-task agents invoked by parent Sonnet agents:

- **02X VM Operations**: 021-025 (create, configure, lifecycle, validate, snapshot)
- **03X Performance**: 031-035 (Hyper-V, CPU pin, hugepages, I/O, benchmark)
- **04X Security**: 041-046 (LUKS, firewall, BitLocker, virtio-fs RO, audit, backup)
- **05X VirtIO-FS**: 051-055 (setup, WinFsp, mount, PST test, troubleshoot)
- **06X Automation**: 061-065 (GA install, virsh commands, polling, host-guest, scripts)
- **07X Health**: 071-076 (hardware, QEMU stack, VirtIO, network, report, setup guide)
- **08X Prerequisites**: 081-085 (packages, groups, libvirtd, VirtIO ISO, Win ISO)
- **09X Git**: 091-095 (branch, commit, merge, conflict, sync)
- **10X Docs**: 101-105 (symlink verify, restore, index, README, changelog)
- **11X Cleanup**: 111-114 (scan, consolidate, delete, reference update)

## Slash Commands
| Command | Entry Point | Description |
|---------|-------------|-------------|
| `/guardian-health` | 001→007→07X | System readiness validation (42 prerequisites) |
| `/guardian-vm` | 001→002→02X | Complete VM creation workflow |
| `/guardian-optimize` | 001→003→03X | Performance optimization (85-95% native) |
| `/guardian-security` | 001→004→04X | 60+ security hardening checklist |
| `/guardian-commit` | 001→009→09X | Constitutional Git workflow |
| `/guardian-backup` | 001→004→046 | Encrypted backup creation |
| `/guardian-cleanup` | 001→011→11X | Repository hygiene and redundancy removal |
| `/guardian-documentation` | 001→010→10X | Documentation sync and validation |
| `/guardian-virtiofs` | 001→005→05X | virtio-fs setup with read-only protection |

## Agent Delegation Flow
```
User Request
    ↓
001-orchestrator (Opus) - Strategic decomposition
    ↓
00X-domain-expert (Sonnet) - Domain coordination
    ↓
0XX-task-executor (Haiku) - Single task execution
    ↓
Result aggregation → User
```

## Cost Optimization
- Opus: Complex planning only
- Sonnet: Domain coordination
- Haiku: 80%+ of execution tasks
- **Result**: ~48% token cost reduction vs all-Sonnet

## Shared Instructions
Modular documentation in `.claude/instructions-for-agents/`:
- `requirements/`: constitutional-rules, git-workflow, vm-standards
- `architecture/`: agent-registry, agent-delegation
- `guides/`: security-checklist, hyperv-enlightenments, performance-benchmarks

**Reference**: [Agent Registry](../../.claude/instructions-for-agents/architecture/agent-registry.md)
