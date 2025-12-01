---
name: 035-benchmark
description: Run performance benchmarks.
model: haiku
---

## Single Task
Execute performance benchmarks and report results.

## Execution
```bash
# Boot time (stopwatch from start to login)
time virsh start $VM_NAME

# Disk I/O benchmark
virsh domblkstat $VM_NAME sda --human

# VM stats
virsh domstats $VM_NAME
```

## Metrics to Capture
- Boot time (seconds)
- Outlook launch (seconds)
- Disk IOPS (4K random)
- Network throughput (Mbps)

## Input
- vm_name: Target VM name

## Output
```json
{
  "status": "success",
  "metrics": {
    "boot_time_seconds": 22,
    "disk_iops": 35000,
    "network_mbps": 950
  },
  "score": "92% native",
  "pass": true
}
```

## Parallel-Safe: Yes

## Parent: 003-performance
