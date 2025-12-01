# Win-QEMU AI Agent System

> **Single Source of Truth**: [AGENTS.md](../AGENTS.md) → [docs-repo/06-constitutional/](../docs-repo/06-constitutional/)

## Project Goal

Run native Microsoft 365 Outlook on Ubuntu 25.10 with **85-95% native performance** using QEMU/KVM + VirtIO + Hyper-V enlightenments + virtio-fs.

---

## Quick Reference

| Need | Agent | Model | Invoke |
|------|-------|-------|--------|
| Strategic coordination | 001-orchestrator | Opus | `@agent-001-orchestrator` |
| VM operations | 002-vm-operations | Sonnet | Automatic via orchestrator |
| Performance tuning | 003-performance | Sonnet | Automatic via orchestrator |
| Security hardening | 004-security | Sonnet | Automatic via orchestrator |
| virtio-fs sharing | 005-virtiofs | Sonnet | Automatic via orchestrator |
| Guest automation | 006-automation | Sonnet | Automatic via orchestrator |
| Health checks | 007-health | Sonnet | Automatic via orchestrator |
| Prerequisites | 008-prerequisites | Sonnet | Automatic via orchestrator |
| Git operations | 009-git | Sonnet | Automatic via orchestrator |
| Documentation | 010-docs | Sonnet | Automatic via orchestrator |
| Cleanup | 011-cleanup | Sonnet | Automatic via orchestrator |
| **Astro/GitHub Pages** | **012-astro** | Sonnet | Automatic via orchestrator |

---

## Workflow Agents (Invoke via Task tool)

| Agent | Purpose |
|-------|---------|
| `000-health` | 42-point health check + device-specific setup guides |
| `000-vm` | Complete VM lifecycle (create → optimize → secure → test) |
| `000-optimize` | Performance tuning with Hyper-V enlightenments |
| `000-security` | 60+ security checklist enforcement |
| `000-commit` | Constitutional Git workflow automation |
| `000-backup` | VM backup, snapshots, integrity verification |
| `000-virtiofs` | virtio-fs host setup + VM config + read-only enforcement |
| `000-cleanup` | Repository hygiene with redundancy detection |
| `000-docs` | Doc verification, symlink restoration, SSoT validation |
| `000-deploy` | Astro build + GitHub Pages deployment + .nojekyll verification |

> **Note**: Slash commands archived to `docs-repo/04-history/09-slash-commands-archive/`

---

## Agent Hierarchy (84 agents)

```
Tier 0 Workflow Agents (10 Sonnet - Zero-Config Automation)
├── 000-backup     → VM backup and snapshot with integrity verification
├── 000-cleanup    → Repository hygiene with redundancy detection
├── 000-commit     → Constitutional Git commit with change analysis
├── 000-deploy     → Astro build + GitHub Pages deployment
├── 000-docs       → Documentation integrity and symlink management
├── 000-health     → 42-point QEMU/KVM health check
├── 000-optimize   → Performance tuning for 85-95% native
├── 000-security   → 60+ security checklist enforcement
├── 000-vm         → Complete VM lifecycle (create, optimize, secure, test)
└── 000-virtiofs   → virtio-fs filesystem sharing with read-only enforcement

001-orchestrator (Opus - Strategic Coordination)
│
├── Tier 2 Specialists (11 Sonnet agents)
│   ├── 002-vm-operations    → 021-025 (VM create, configure, lifecycle, XML, snapshot)
│   ├── 003-performance      → 031-035 (Hyper-V, CPU pin, hugepages, I/O, benchmark)
│   ├── 004-security         → 041-046 (LUKS, firewall, BitLocker, virtio-fs RO, audit, backup)
│   ├── 005-virtiofs         → 051-055 (setup, WinFsp, mount, PST, permissions)
│   ├── 006-automation       → 061-065 (guest agent, commands, file transfer, clipboard, display)
│   ├── 007-health           → 071-076 (hardware, QEMU stack, VirtIO, network, report, guide)
│   ├── 008-prerequisites    → 081-085 (packages, groups, libvirtd, VirtIO ISO, Windows ISO)
│   ├── 009-git              → 091-095 (branch, validate, commit, merge, push)
│   ├── 010-docs             → 101-105 (symlink verify, restore, merge, size, links)
│   ├── 011-cleanup          → 111-114 (redundancy, scripts, archive, metrics)
│   └── 012-astro            → 121-*, 122-* (precheck, build, validate, nojekyll, deploy)
│
└── Tier 4 Execution (60 Haiku atomic agents)
    └── Single-task specialists for parallel execution
```

---

## Constitutional Rules (NON-NEGOTIABLE)

### Git Workflow
1. **Branch Naming**: `YYYYMMDD-HHMMSS-type-description`
2. **Branch Preservation**: NEVER delete branches (historical audit trail)
3. **Merge Strategy**: Always `--no-ff` (preserve merge commits)

### Performance Targets
4. **Native Performance**: 85-95% of bare metal
5. **Boot Time**: < 25 seconds to Windows desktop
6. **App Launch**: < 5 seconds for Outlook

### Security Requirements
7. **virtio-fs**: MANDATORY read-only mode (ransomware protection)
8. **Security Checklist**: 60+ items must pass
9. **Host Isolation**: No guest-to-host write access

---

## Directory Structure

```
.claude/
├── README.md                    # This file (quick reference)
├── settings.local.json          # MCP permissions & configuration
├── agents/                      # 84 agent definitions
│   ├── 000-*.md                 # Tier 0 (10 Workflow orchestrators)
│   ├── 001-orchestrator.md      # Tier 1 (Opus)
│   ├── 002-012-*.md             # Tier 2 (Sonnet specialists)
│   └── 021-122-*.md             # Tier 4 (Haiku atomic)
├── rules-tailwindcss/           # Tailwind CSS v4 rules
│   └── tailwind.md
└── instructions-for-agents/     # Modular documentation
    ├── architecture/            # Agent registry, delegation
    ├── requirements/            # Constitutional rules, git workflow
    └── guides/                  # Security checklist, deployment, benchmarks
```

---

## Links

- **Constitutional Framework**: [docs-repo/06-constitutional/](../docs-repo/06-constitutional/)
- **Agent Registry**: [instructions-for-agents/architecture/agent-registry.md](instructions-for-agents/architecture/agent-registry.md)
- **Git Strategy**: [instructions-for-agents/requirements/git-workflow.md](instructions-for-agents/requirements/git-workflow.md)
- **Website**: https://kairin.github.io/win-qemu/
- **Repository**: https://github.com/kairin/win-qemu

---

## Version

- **Agents**: 84 total (10 Workflow + 1 Opus + 11 Sonnet + 62 Haiku)
- **Slash Commands**: Archived (invoke 000-* agents directly via Task tool)
- **Rules**: Tailwind CSS v4 + DaisyUI
- **Last Updated**: 2025-11-30
