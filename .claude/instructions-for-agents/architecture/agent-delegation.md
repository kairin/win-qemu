# Agent Delegation Guide

[← Back to Index](../README.md) | [Agent Registry](./agent-registry.md)

---

## 4-Tier Hierarchy

```
001-orchestrator (Opus) ─ Strategic coordination
    │
    ├─ Tier 2 (Sonnet Core)
    │   ├─ 002-vm-operations ──→ 021-025 (5 Haiku)
    │   ├─ 003-performance ────→ 031-035 (5 Haiku)
    │   ├─ 004-security ───────→ 041-046 (6 Haiku)
    │   ├─ 005-virtiofs ───────→ 051-055 (5 Haiku)
    │   ├─ 006-automation ─────→ 061-065 (5 Haiku)
    │   ├─ 007-health ─────────→ 071-076 (6 Haiku)
    │   ├─ 008-prerequisites ──→ 081-085 (5 Haiku)
    │   ├─ 009-git ────────────→ 091-095 (5 Haiku)
    │   ├─ 010-docs ───────────→ 101-105 (5 Haiku)
    │   └─ 011-cleanup ────────→ 111-114 (4 Haiku)
```

---

## Delegation Decision Tree

```
Task Received
    │
    ├─ Simple/direct? → Execute directly (no agent)
    │   Examples: Read file, answer question, run single command
    │
    └─ Needs agent?
        │
        ├─ ATOMIC (single op, deterministic)
        │   → Haiku tier (02X-11X)
        │   Examples: Validate branch name, check file exists
        │
        ├─ MODERATE (2-5 steps, focused domain)
        │   → Sonnet tier (002-011)
        │   Examples: Git commit flow, VM creation
        │
        └─ COMPLEX (multi-domain, parallel, judgment)
            → Opus (001-orchestrator)
            Examples: Full audit with fixes, multi-agent workflow
```

---

## Cost/Complexity Matrix

| Tier | Model | Cost | Token Budget | When to Use |
|------|-------|------|--------------|-------------|
| 4 | Haiku | $ | ~500 tokens | Single atomic task, no judgment |
| 2 | Sonnet | $$ | ~2K tokens | Domain operations, sequenced workflow |
| 1 | Opus | $$$ | ~8K tokens | Multi-agent orchestration |

**Token Optimization**: ~40% reduction by delegating atomic tasks to Haiku.

---

## When to Delegate to Haiku

**DO delegate**:
- Single atomic operation needed
- Task is repeatable and deterministic
- No complex decision-making required
- Speed/cost optimization desired

**DO NOT delegate**:
- Complex multi-step reasoning needed
- User judgment required
- Context7 queries (requires parent MCP access)
- Error handling with multiple options

---

## Execution Mode Decision Tree

```
STATE-MUTATING? (git commit, file delete, push, write)
  └─ YES → SEQUENTIAL execution only
  └─ NO  → Check dependencies...

HAS DEPENDENCY on another task?
  └─ YES → SEQUENTIAL (run after dependency completes)
  └─ NO  → PARALLEL eligible
```

### Parallel-Safety Reference

| Category | Agents | Mode |
|----------|--------|------|
| Analysis/Validation | 007-health, 010-docs, 011-cleanup | PARALLEL |
| Performance/Security | 003-performance, 004-security | PARALLEL |
| Git Operations | 009-git, 091-095 | SEQUENTIAL |
| VM Operations | 002-vm-operations, 021-025 | SEQUENTIAL |

---

## Delegation Examples

### Good Delegation
```
Task: "Check if branch name is valid"
Agent: 092-branch-validate (Haiku)
Why: Single atomic validation, no reasoning needed

Task: "Commit and push my changes"
Agent: 009-git (Sonnet) → delegates to 091, 093, 094, 095
Why: Multi-step workflow with sequencing

Task: "Create VM, optimize, harden security"
Agent: 001-orchestrator (Opus) → coordinates 002, 003, 004
Why: Complex multi-domain task
```

### Anti-Patterns (What NOT to Do)
```
WRONG: Using Opus for "validate branch name"
Why: 70x cost waste - Haiku can do this

WRONG: Using Haiku for "full security audit with fixes"
Why: Haiku cannot reason about multi-system coordination
```

---

## Routing Table (001-orchestrator)

| User Intent | Target Agent |
|-------------|--------------|
| Create/manage VM | 002-vm-operations |
| Optimize performance | 003-performance |
| Harden security | 004-security |
| Configure file sharing | 005-virtiofs |
| Automate guest tasks | 006-automation |
| Check system health | 007-health |
| First-time setup | 008-prerequisites |
| Git commit/push | 009-git |
| Fix documentation | 010-docs |
| Clean up repository | 011-cleanup |

---

[← Back to Index](../README.md) | [Agent Registry](./agent-registry.md)
