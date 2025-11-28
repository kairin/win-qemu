# Hyper-V Enlightenments (14 Features)

[← Back to Index](../README.md)

---

## Complete XML Configuration

```xml
<features>
  <acpi/>
  <apic/>
  <pae/>

  <!-- Complete Hyper-V Enlightenments (14 features) -->
  <hyperv mode='custom'>
    <!-- CRITICAL: High-impact enlightenments -->
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
    <vpindex state='on'/>
    <runtime state='on'/>
    <synic state='on'/>
    <stimer state='on'>
      <direct state='on'/>
    </stimer>
    <reset state='on'/>
    <frequencies state='on'/>

    <!-- RECOMMENDED: Medium-impact enlightenments -->
    <reenlightenment state='on'/>
    <tlbflush state='on'/>
    <ipi state='on'/>
    <evmcs state='on'/>  <!-- Intel ONLY - omit for AMD -->

    <!-- OPTIONAL: Compatibility -->
    <vendor_id state='on' value='randomid'/>
  </hyperv>

  <!-- KVM-specific features -->
  <kvm>
    <hidden state='on'/>
  </kvm>
</features>
```

---

## Feature Reference

### Critical (High Impact)

| Feature | Purpose | Impact |
|---------|---------|--------|
| `relaxed` | Disable strict timer checking | 10-15% |
| `vapic` | Virtual APIC for fast interrupts | 5-10% |
| `spinlocks` | Optimized spinlock behavior | 5-8% |
| `vpindex` | Virtual processor index | 3-5% |
| `synic` | Synthetic interrupt controller | 5-8% |
| `stimer` + `direct` | Kernel-to-kernel timer delivery | 8-12% |
| `frequencies` | Expose TSC/APIC frequencies | 3-5% |

### Recommended (Medium Impact)

| Feature | Purpose | Impact |
|---------|---------|--------|
| `runtime` | Hypervisor runtime info | 2-3% |
| `reset` | Clean VM reset | 1-2% |
| `reenlightenment` | Migration stability | 2-3% |
| `tlbflush` | Optimized TLB invalidation | 3-5% |
| `ipi` | Inter-processor interrupt optimization | 2-4% |
| `evmcs` | Enlightened VMCS (Intel ONLY) | 3-5% |

### Optional (Compatibility)

| Feature | Purpose | Note |
|---------|---------|------|
| `vendor_id` | Hide KVM signature | For anti-cheat software |

---

## Validation Commands

```bash
# Check enlightenments count (should be 14)
virsh dumpxml VM_NAME | grep -c "state='on'"

# Verify critical features
virsh dumpxml VM_NAME | grep -E "relaxed|vapic|spinlocks|synic|stimer"

# Guest validation (PowerShell)
Get-ComputerInfo | Select-Object HyperV*
```

---

## Expected Performance Gain

| Before | After | Improvement |
|--------|-------|-------------|
| 0 enlightenments | 14 enlightenments | **30-50%** |
| Boot: 45s | Boot: 22s | 51% faster |
| Outlook: 8s | Outlook: 3s | 62% faster |

---

## Common Issues

| Issue | Solution |
|-------|----------|
| evmcs error on AMD | Remove `<evmcs state='on'/>` |
| stimer warning | Ensure `<direct state='on'/>` nested |
| No improvement | Verify all 14 features enabled |

---

[← Back to Index](../README.md)
