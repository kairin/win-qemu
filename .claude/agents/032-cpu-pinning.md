---
name: 032-cpu-pinning
description: Configure CPU affinity and pinning.
model: haiku
---

## Single Task
Pin VM vCPUs to physical CPU cores.

## Execution
```bash
# Get host CPU topology
lscpu | grep -E "Core|Socket|Thread"

# Pin vCPU 0 to physical CPU 2
virsh vcpupin $VM_NAME 0 2 --config

# Pin vCPU 1 to physical CPU 3
virsh vcpupin $VM_NAME 1 3 --config

# Verify pinning
virsh vcpupin $VM_NAME
```

## XML Configuration
```xml
<cputune>
  <vcpupin vcpu='0' cpuset='2'/>
  <vcpupin vcpu='1' cpuset='3'/>
  <vcpupin vcpu='2' cpuset='4'/>
  <vcpupin vcpu='3' cpuset='5'/>
</cputune>
```

## Input
- vm_name: Target VM name
- vcpu_count: Number of vCPUs
- start_cpu: First physical CPU to use

## Output
```
status: success | error
vcpus_pinned: count
cpu_mapping: {vcpu: physical_cpu}
```

## Parent: 003-performance
