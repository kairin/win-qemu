# VM Script UX Analysis - Executive Summary

**Date**: 2025-11-27
**Analysis**: VM-SCRIPT-UX-ANALYSIS.md (complete 500+ line report)
**Quick Reference**: Top 3 improvements for immediate impact

---

## TL;DR - The Core Problem

**Scripts are technically perfect, but users hit walls because:**

1. **No upfront prerequisite checklist** - users discover missing items ONE AT A TIME through repeated script failures
2. **No workflow sequence guide** - users don't know the correct order (install → configure → create → start)
3. **Error messages lack "what next"** - errors say WHAT'S wrong but not HOW TO PROCEED

**Result**: Frustrating trial-and-error experience for first-time users.

---

## Top 3 Recommendations (Quick Wins)

### 1. Add `--check` Flag (1 hour, CRITICAL impact)

**What**: Pre-flight checklist that shows ALL prerequisites BEFORE running script

**Example**:
```bash
$ sudo ./scripts/create-vm.sh --check

VM CREATION PREREQUISITE CHECKLIST
===================================
[✗] QEMU/KVM packages NOT installed → Run: sudo ./scripts/install-master.sh
[✗] User not in groups → Run: sudo usermod -aG libvirt,kvm $USER + LOGOUT
[✗] ISOs missing → Download and place in source-iso/

WORKFLOW:
  1. Run install-master.sh (15 min)
  2. Fix groups + LOGOUT/login
  3. Download ISOs (30 min)
  4. Re-run with --check to verify

STATUS: ❌ NOT READY (3 issues)
```

**Impact**: Users see ALL problems at once, no more trial-and-error

### 2. Create Workflow Guide (30 minutes, HIGH impact)

**What**: `docs-repo/GETTING-STARTED-WORKFLOW.md` with step-by-step sequence

**Content** (skeleton):
```markdown
# Getting Started: VM Creation Workflow

## Phase 1: System Preparation (15 min)
1. Run: sudo ./scripts/install-master.sh
2. Run: sudo usermod -aG libvirt,kvm $USER
3. LOGOUT and login

## Phase 2: ISO Preparation (30-60 min)
4. Download Win11.iso
5. Download virtio-win.iso
6. Move to source-iso/

## Phase 3: VM Creation (5 min)
7. Run: sudo ./scripts/create-vm.sh --check
8. Run: sudo ./scripts/create-vm.sh

## Phase 4: Windows Installation (45-60 min)
9. Run: ./scripts/start-vm.sh --console
10. Install Windows + drivers
```

**Impact**: Users know the complete sequence upfront, no surprises

### 3. Enhance Error Messages (2 hours, MEDIUM impact)

**What**: Rewrite critical errors with 3-part structure

**Before**:
```bash
[✗] Missing required packages: qemu-system-x86
[✗] Install with: sudo apt install -y qemu-system-x86
```

**After**:
```bash
[✗] Missing required packages: qemu-system-x86

WHAT THIS MEANS:
  QEMU/KVM virtualization software is not installed.

HOW TO FIX:
  Option 1 (Recommended): sudo ./scripts/install-master.sh
  Option 2 (Manual): sudo apt install -y qemu-system-x86

NEXT STEPS:
  After installing, re-run: sudo ./scripts/create-vm.sh

Guide: docs-repo/GETTING-STARTED-WORKFLOW.md
```

**Impact**: Users understand WHY error occurred and WHAT TO DO NEXT

---

## Implementation Effort

| Task | Time | Impact | Priority |
|------|------|--------|----------|
| Add --check flag | 1 hour | Critical | 1 |
| Create workflow guide | 30 min | High | 2 |
| Enhanced error messages | 2 hours | Medium | 3 |
| **Total** | **3.5 hours** | **High ROI** | - |

**ROI**: ~4 hours investment → 90% reduction in "script won't run" user confusion

---

## Key Insights from Context7 Research

**Libvirt Best Practice**:
> "Do not report an error to the user when you're also returning an error for somebody else to handle."

**Application**: Aggregate ALL prerequisite failures, report together with fix plan.

**QEMU Error Handling**:
> "It is recommended that the user checks and removes the symlink after QEMU terminates to account for this."

**Application**: Provide cleanup guidance for interrupted operations.

---

## Current vs Improved UX (One Example)

### Current: Trial-and-Error Loop
```
Run script → Missing packages error → Exit
Install packages → Run script → Missing groups error → Exit
Fix groups → Run script → Missing ISOs error → Exit
Download ISOs → Run script → FINALLY WORKS (after 3 failures)
```

**User frustration**: "Why didn't it tell me about ALL the problems at once?"

### Improved: Upfront Validation
```
Run script --check → Shows ALL 3 problems + fix sequence
Follow checklist (install → groups → ISOs)
Run script → Works on first try
```

**User satisfaction**: "I knew exactly what was needed before starting."

---

## Files to Create/Update

**New Files** (create):
1. `docs-repo/GETTING-STARTED-WORKFLOW.md` - Step-by-step workflow
2. `docs-repo/VM-SCRIPT-UX-ANALYSIS.md` - Complete analysis (already created)

**Update Existing**:
1. `scripts/lib/common.sh` - Add `check_all_prerequisites()` function
2. `scripts/create-vm.sh` - Add --check flag, enhance errors
3. `scripts/start-vm.sh` - Add --check flag, enhance errors
4. `scripts/stop-vm.sh` - Enhance errors
5. `scripts/backup-vm.sh` - Enhance errors
6. `CLAUDE.md` - Link to new workflow guide

---

## Next Steps

1. **Review** this summary + full analysis (VM-SCRIPT-UX-ANALYSIS.md)
2. **Prioritize** which improvements to implement first
3. **Create** GitHub issues for tracking
4. **Implement** in priority order (--check → workflow → errors)
5. **Test** with fresh Ubuntu 25.10 VM (first-time user experience)

---

**Full Analysis**: See `docs-repo/VM-SCRIPT-UX-ANALYSIS.md` for detailed examples, code snippets, and implementation guide.
