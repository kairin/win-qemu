# Multi-Agent System

## Overview
A 14-agent system automates workflows from VM creation to security hardening.

## Agent Categories
- **Infrastructure (8)**: Documentation, Git, Orchestration, Health, Compliance.
- **QEMU Specialized (6)**: VM Ops, Performance, Security, virtio-fs, Automation, Health-Check.

## Quick Reference
- **vm-operations-specialist**: Create/Manage VMs.
- **performance-optimization-specialist**: Hyper-V tuning.
- **security-hardening-specialist**: Security audits.
- **virtio-fs-specialist**: Filesystem sharing.
- **master-orchestrator**: Coordinates complex tasks.

## Invocation
- **Natural Language**: "Create a Windows 11 VM" (routes to Master Orchestrator).
- **Direct**: "Use vm-operations-specialist to..."

**Reference**: [`docs-repo/05-agents/00-overview.md`](../05-agents/00-overview.md)
