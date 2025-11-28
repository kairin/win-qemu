---
name: 033-memory-hugepages
description: Configure huge pages for memory performance.
model: haiku
---

## Single Task
Enable and configure huge pages for VM.

## Execution
```bash
# Calculate pages needed (RAM_MB / 2MB) + 10% overhead
PAGES=$((RAM_MB / 2 + RAM_MB / 20))

# Allocate huge pages
echo $PAGES | sudo tee /proc/sys/vm/nr_hugepages

# Verify allocation
grep HugePages /proc/meminfo
```

## XML Configuration
```xml
<memoryBacking>
  <hugepages>
    <page size='2048' unit='KiB'/>
  </hugepages>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

## Input
- vm_name: Target VM name
- ram_mb: VM memory in MB

## Output
```
status: success | error
pages_allocated: count
total_mb: huge pages memory
```

## Parent: 003-performance
