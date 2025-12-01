---
name: 031-hyperv-enlightenments
description: Enable all 14 Hyper-V enlightenments.
model: haiku
---

## Single Task
Apply complete Hyper-V enlightenment configuration.

## XML Configuration
```xml
<hyperv mode='custom'>
  <relaxed state='on'/>
  <vapic state='on'/>
  <spinlocks state='on' retries='8191'/>
  <vpindex state='on'/>
  <runtime state='on'/>
  <synic state='on'/>
  <stimer state='on'><direct state='on'/></stimer>
  <reset state='on'/>
  <frequencies state='on'/>
  <reenlightenment state='on'/>
  <tlbflush state='on'/>
  <ipi state='on'/>
  <evmcs state='on'/>
  <vendor_id state='on' value='randomid'/>
</hyperv>
```

## Input
- vm_name: Target VM name

## Output
```
status: success | error
enlightenments_applied: 14
expected_gain: 30-50%
```

## Reference
See: `.claude/instructions-for-agents/guides/hyperv-enlightenments.md`

## Parent: 003-performance
