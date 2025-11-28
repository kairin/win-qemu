# Instructions for Agents - Documentation Index

> **Token Optimization**: Shared instructions extracted from agents to eliminate duplication and reduce token usage by ~48%.

## Directory Structure

```
.claude/instructions-for-agents/
├── README.md                           (this file)
├── architecture/
│   ├── agent-delegation.md             (4-tier hierarchy, decision tree)
│   └── agent-registry.md               (60-agent reference)
├── requirements/
│   ├── constitutional-rules.md         (core mandates, non-negotiable)
│   ├── git-workflow.md                 (branch naming, commit format)
│   └── vm-standards.md                 (Q35, UEFI, TPM, VirtIO specs)
└── guides/
    ├── security-checklist.md           (60+ security items)
    ├── hyperv-enlightenments.md        (14 enlightenment features)
    └── performance-benchmarks.md       (target metrics)
```

## Quick Reference

| Need | Document |
|------|----------|
| Agent tier decision | `architecture/agent-delegation.md` |
| Find specific agent | `architecture/agent-registry.md` |
| Constitutional rules | `requirements/constitutional-rules.md` |
| Git branch/commit format | `requirements/git-workflow.md` |
| VM configuration specs | `requirements/vm-standards.md` |
| Security audit checklist | `guides/security-checklist.md` |
| Hyper-V enlightenments | `guides/hyperv-enlightenments.md` |
| Performance targets | `guides/performance-benchmarks.md` |

## Navigation Pattern

```
Agent file → References instruction file → Back to agent
Example: 003-performance.md → hyperv-enlightenments.md
```

**Last Updated**: 2025-11-28
**Token Savings**: ~48% reduction through shared instructions
