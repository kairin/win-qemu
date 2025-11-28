---
name: 075-report-generator
description: Generate JSON health report.
model: haiku
---

## Single Task
Compile health check results into JSON report.

## Output Format
```json
{
  "timestamp": "2025-11-28T14:30:00Z",
  "hostname": "ubuntu-host",
  "overall_status": "pass | fail",
  "checks": {
    "hardware": {"status": "pass", "details": {}},
    "qemu_stack": {"status": "pass", "details": {}},
    "virtio": {"status": "pass", "details": {}},
    "network": {"status": "pass", "details": {}}
  },
  "issues": [],
  "recommendations": []
}
```

## Input
- hardware_result: From 071-hardware-check
- qemu_result: From 072-qemu-stack-check
- virtio_result: From 073-virtio-check
- network_result: From 074-network-check

## Output
- JSON report file saved to docs-repo/
- Summary printed to console

## Parallel-Safe: Yes

## Parent: 007-health
