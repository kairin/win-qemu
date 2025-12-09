# Multi-Agent System

## Overview
An 85-agent 5-tier hierarchical system optimized for QEMU/KVM workflows with ~48% token cost reduction vs flat architecture.

## 5-Tier Hierarchy

### Tier 0: Workflow Agents (Sonnet) - 10 Agents
Zero-config automation for common workflows.

| ID | Name | Role | Child Agents |
|----|------|------|--------------|
| 000 | backup | VM backup and snapshot with integrity verification | 002, 007, 046 |
| 000 | cleanup | Repository hygiene with redundancy detection | 009, 011 |
| 000 | commit | Constitutional Git commit with change analysis | 009 |
| 000 | deploy | Astro build + GitHub Pages deployment | 012 |
| 000 | docs | Documentation integrity and symlink management | 010 |
| 000 | health | 42-point QEMU/KVM health check | 007 |
| 000 | optimize | Performance tuning for 85-95% native | 003 |
| 000 | security | 60+ security checklist enforcement | 004 |
| 000 | vm | Complete VM lifecycle (create, optimize, secure, test) | 002, 003, 004, 007 |
| 000 | virtiofs | virtio-fs filesystem sharing with read-only enforcement | 005, 004 |

### Tier 1: Strategic (Opus) - 1 Agent
| ID | Name | Role |
|----|------|------|
| 001 | orchestrator | Strategic coordination, complex task decomposition |

### Tier 2: Domain Experts (Sonnet) - 11 Agents
| ID | Name | Role | Children |
|----|------|------|----------|
| 002 | vm-operations | VM lifecycle management | 021-025 |
| 003 | performance | Hyper-V, VirtIO tuning | 031-035 |
| 004 | security | 60+ checklist enforcement | 041-046 |
| 005 | virtiofs | Filesystem sharing | 051-055 |
| 006 | automation | QEMU guest agent | 061-065 |
| 007 | health | System readiness | 071-076 |
| 008 | prerequisites | Package installation | 081-085 |
| 009 | git | Constitutional commits | 091-095 |
| 010 | docs | Documentation sync | 101-105 |
| 011 | cleanup | Redundant file removal | 111-114 |
| 012 | astro | Astro/GitHub Pages | 121-*, 122-* |

### Tier 4: Task Executors (Haiku) - 63 Agents
Specialized single-task agents invoked by parent Sonnet agents:

- **02X VM Operations**: 021-025 (create, configure, lifecycle, validate, snapshot)
- **03X Performance**: 031-035 (Hyper-V, CPU pin, hugepages, I/O, benchmark)
- **04X Security**: 041-046 (LUKS, firewall, BitLocker, virtio-fs RO, audit, backup)
- **05X VirtIO-FS**: 051-055 (setup, WinFsp, mount, PST test, troubleshoot)
- **06X Automation**: 061-066 (GA install, virsh commands, file transfer, clipboard, display, VirtIO GPU)
- **07X Health**: 071-076 (hardware, QEMU stack, VirtIO, network, report, setup guide)
- **08X Prerequisites**: 081-085 (packages, groups, libvirtd, VirtIO ISO, Win ISO)
- **09X Git**: 091-095 (branch, commit, merge, conflict, sync)
- **10X Docs**: 101-105 (symlink verify, restore, index, README, changelog)
- **11X Cleanup**: 111-114 (scan, consolidate, delete, reference update)
- **12X Astro**: 121-* (precheck, build, validate, nojekyll, metrics, config), 122-* (git-sync, deploy-verify, asset-check, url-test, rollback)

## Workflow Agents (Invoke via Task tool)

| Agent | Entry Point | Description |
|-------|-------------|-------------|
| `000-health` | 000→007→07X | System readiness validation (42 prerequisites) |
| `000-vm` | 000→002,003,004→0XX | Complete VM creation workflow |
| `000-optimize` | 000→003→03X | Performance optimization (85-95% native) |
| `000-security` | 000→004→04X | 60+ security hardening checklist |
| `000-commit` | 000→009→09X | Constitutional Git workflow |
| `000-backup` | 000→002,007,046 | Backup with integrity verification |
| `000-cleanup` | 000→011→11X | Repository hygiene and redundancy removal |
| `000-docs` | 000→010→10X | Documentation sync and validation |
| `000-virtiofs` | 000→005,004→05X | virtio-fs setup with read-only protection |
| `000-deploy` | 000→012→12X | Astro build + GitHub Pages deployment |

> **Note**: Slash commands archived to `docs-repo/04-history/09-slash-commands-archive/`

## Agent Delegation Flow
```
User Request / Task tool invocation
    ↓
000-workflow (Sonnet) - Zero-config automation
    ↓
001-orchestrator (Opus) - Strategic decomposition (if needed)
    ↓
00X-domain-expert (Sonnet) - Domain coordination
    ↓
0XX-task-executor (Haiku) - Single task execution
    ↓
Result aggregation → User
```

## Cost Optimization
- Opus: Complex planning only
- Sonnet: Workflow + Domain coordination
- Haiku: 80%+ of execution tasks
- **Result**: ~48% token cost reduction vs all-Sonnet

## Shared Instructions
Modular documentation in `.claude/instructions-for-agents/`:
- `requirements/`: constitutional-rules, git-workflow, vm-standards
- `architecture/`: agent-registry, agent-delegation
- `guides/`: security-checklist, hyperv-enlightenments, performance-benchmarks, deployment-checklist

**Reference**: [Agent Registry](../../.claude/instructions-for-agents/architecture/agent-registry.md)
