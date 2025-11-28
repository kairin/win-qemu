---
name: 071-hardware-check
description: Validate CPU/RAM/SSD requirements.
model: haiku
---

## Single Task
Check hardware meets QEMU/KVM requirements.

## Execution
```bash
# CPU virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo

# CPU cores
nproc

# RAM
free -h | grep Mem | awk '{print $2}'

# SSD check
lsblk -d -o name,rota | grep "0$"
```

## Requirements
- CPU: VT-x/AMD-V support
- Cores: 4 minimum, 8+ recommended
- RAM: 8GB minimum, 16GB+ recommended
- Storage: SSD (not HDD)

## Input
None required

## Output
```json
{
  "status": "pass | fail",
  "cpu_virt": true,
  "cpu_cores": 8,
  "ram_gb": 16,
  "ssd_detected": true,
  "issues": []
}
```

## Parallel-Safe: Yes

## Parent: 007-health
