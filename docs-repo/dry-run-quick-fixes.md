# Dry-Run Mode: Quick Fix Guide

**Priority:** CRITICAL - Blocks user exploration before QEMU installation
**Estimated Fix Time:** 5 hours total

---

## Critical Issues (Fix First)

### 1. common.sh: check_root() - Line 192
**Problem:** Always requires sudo, even in dry-run
**Fix:**
```bash
check_root() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping root check (would require sudo)"
        return 0
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        exit 1
    fi
}
```

### 2. common.sh: check_libvirtd() - Line 199
**Problem:** Exits if libvirtd not running
**Fix:**
```bash
check_libvirtd() {
    log_step "Checking libvirtd service..."

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping libvirtd check"
        return 0
    fi

    if ! systemctl is-active --quiet libvirtd; then
        log_error "libvirtd service is not running"
        return 1
    fi
    log_success "libvirtd service is active"
}
```

### 3. configure-performance.sh: check_requirements() - Line 224
**Problem:** Exits if virsh/virt-xml missing
**Fix:**
```bash
check_requirements() {
    # ... existing missing_deps check ...

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY RUN] Missing: ${missing_deps[*]}"
            log_info "[DRY RUN] Install with: sudo apt install libvirt-clients"
            return 0  # Continue in dry-run
        else
            log_error "Missing: ${missing_deps[*]}"
            exit 1
        fi
    fi
}
```

---

## Test Validation

**Run after fixes:**
```bash
cd /home/kkk/Apps/win-qemu
./scripts/comprehensive-dry-run.sh
```

**Expected Result:**
```
✅ dryrun-create-vm: PASS
✅ dryrun-start-vm: PASS
✅ dryrun-stop-vm: PASS
✅ dryrun-config-perf: PASS
```

---

## Implementation Order

1. Fix `common.sh` (30 min) - Fixes all scripts at once
2. Test with `comprehensive-dry-run.sh` (15 min)
3. Fix `configure-performance.sh` (30 min) - Has unique checks
4. Enhance dry-run output (2 hours) - Better user experience
5. Final validation (30 min)

**Total: 5 hours**

---

## Files to Modify

1. `/home/kkk/Apps/win-qemu/scripts/lib/common.sh` - Lines 192, 199, 209
2. `/home/kkk/Apps/win-qemu/scripts/configure-performance.sh` - Lines 224-251
3. Optional enhancements: All 4 main scripts (better dry-run output)

---

## Success Criteria

- [ ] All 8 dry-run tests pass
- [ ] No sudo required for `--dry-run`
- [ ] No QEMU installation required for preview
- [ ] Detailed feedback shows what WOULD execute
- [ ] User can evaluate scripts BEFORE setup commitment
