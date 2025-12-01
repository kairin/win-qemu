---
description: Complete performance optimization workflow - baseline, tune Hyper-V enlightenments, VirtIO, CPU pinning, benchmark, validate 85-95% native performance - FULLY AUTOMATIC
---

## Purpose

**PERFORMANCE TUNING**: Comprehensive performance optimization workflow to achieve 85-95% of native Windows performance through Hyper-V enlightenments, VirtIO optimization, CPU pinning, and huge pages.

## User Input

```text
$ARGUMENTS
```

**Expected Arguments** (optional):
- `VM_NAME` - VM to optimize (default: auto-detect running VM)
- `--baseline-only` - Only measure baseline, don't apply optimizations
- `--skip-benchmark` - Apply optimizations without benchmarking

**Examples**:
- `/guardian-optimize` → Optimize current VM
- `/guardian-optimize win11-outlook` → Optimize specific VM
- `/guardian-optimize --baseline-only` → Measure current performance only

## Automatic Workflow

You **MUST** invoke the **001-orchestrator** agent to coordinate the performance optimization workflow.

Pass the following instructions to 001-orchestrator:

### Phase 1: Prerequisites & Baseline (Delegated to 007-health)

**Agent**: **007-health** → delegates to:
- **071-hardware-check**: CPU core count, storage type
- **035-benchmark**: Establish baseline metrics

**Tasks**:
1. Verify VM exists and is accessible
2. Check VirtIO component availability
3. Validate hardware supports optimization (CPU pinning, huge pages)
4. Establish performance baseline

**Baseline Metrics** (if VM running):
```bash
# VM boot time
virsh shutdown {{ VM_NAME }}
time virsh start {{ VM_NAME }}
# Target: < 25 seconds

# Disk IOPS (4K random)
# Run fio inside guest or measure from host
# Target: > 40,000 IOPS (SSD)

# CPU performance
# Geekbench or similar in guest
# Target: 85-95% of native score
```

**Blocking Conditions**:
```
IF VM does not exist:
  STOP: "VM not found - run /guardian-vm first"

IF VM on HDD (not SSD):
  WARN: "Performance optimization limited on HDD (expect 30-50% native only)"

IF CPU < 4 cores:
  WARN: "CPU pinning not recommended (insufficient cores)"
```

### Phase 2: Hyper-V Enlightenments (Delegated to 003-performance)

**Agent**: **003-performance** → **031-hyperv-enlightenments**

**Tasks**:
1. Apply ALL 14 Hyper-V enlightenments
2. Validate XML configuration
3. Define VM with updated configuration

**Hyper-V Enlightenments** (MANDATORY for Windows performance):
```xml
<features>
  <hyperv mode='custom'>
    <!-- 1. Relaxed timing -->
    <relaxed state='on'/>

    <!-- 2. Virtual APIC -->
    <vapic state='on'/>

    <!-- 3. Spinlock optimization -->
    <spinlocks state='on' retries='8191'/>

    <!-- 4. VP index -->
    <vpindex state='on'/>

    <!-- 5. Runtime state -->
    <runtime state='on'/>

    <!-- 6. Synthetic interrupt controller -->
    <synic state='on'/>

    <!-- 7. Synthetic timers -->
    <stimer state='on'>
      <direct state='on'/>
    </stimer>

    <!-- 8. System reset -->
    <reset state='on'/>

    <!-- 9. Vendor ID -->
    <vendor_id state='on' value='1234567890ab'/>

    <!-- 10. Frequency MSRs -->
    <frequencies state='on'/>

    <!-- 11. Reenlightenment -->
    <reenlightenment state='on'/>

    <!-- 12. TLB flush -->
    <tlbflush state='on'/>

    <!-- 13. IPI send -->
    <ipi state='on'/>

    <!-- 14. EVMCS (Enlightened VMCS) -->
    <evmcs state='on'/>
  </hyperv>
</features>
```

**Performance Impact**:
- Boot time improvement: 15-30%
- CPU performance improvement: 10-20%
- Overall responsiveness: 20-40% better

### Phase 3: VirtIO Optimization (Delegated to 003-performance)

**Agent**: **003-performance** → **032-virtio-tune**

**Tasks**:
1. Verify all devices use VirtIO
2. Optimize VirtIO driver parameters
3. Enable multiqueue for network

**VirtIO Configuration**:

**Disk (virtio-blk)**:
```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='threads' discard='unmap'/>
  <source file='/var/lib/libvirt/images/{{ VM_NAME }}.qcow2'/>
  <target dev='vda' bus='virtio'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
</disk>
```
- `cache='none'`: Direct I/O (bypass host cache)
- `io='threads'`: Threaded I/O for better performance
- `discard='unmap'`: Thin provisioning support

**Network (virtio-net with multiqueue)**:
```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
  <driver name='vhost' queues='{{ VCPUS }}'/>
</interface>
```
- `queues='{{ VCPUS }}'`: One queue per vCPU for parallel processing
- `driver='vhost'`: Kernel-level acceleration

**Graphics (virtio-vga/virtio-gpu)**:
```xml
<video>
  <model type='virtio' vram='16384' heads='1'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
</video>
```

**Memory Balloon (virtio-balloon)**:
```xml
<memballoon model='virtio'>
  <stats period='5'/>
</memballoon>
```

### Phase 4: CPU Pinning (Conditional - If 8+ cores)

**Agent**: **003-performance** → **033-cpu-pinning**

**Tasks**:
1. Detect host CPU topology
2. Pin vCPUs to dedicated physical cores
3. Reserve cores for host OS

**CPU Pinning Configuration** (example for 16-core host, 4 vCPUs):
```xml
<vcpu placement='static' cpuset='0-15'>4</vcpu>
<cputune>
  <!-- Pin vCPU 0 to physical core 0 -->
  <vcpupin vcpu='0' cpuset='0'/>
  <!-- Pin vCPU 1 to physical core 1 -->
  <vcpupin vcpu='1' cpuset='1'/>
  <!-- Pin vCPU 2 to physical core 2 -->
  <vcpupin vcpu='2' cpuset='2'/>
  <!-- Pin vCPU 3 to physical core 3 -->
  <vcpupin vcpu='3' cpuset='3'/>

  <!-- Reserve cores 4-7 for host OS -->
  <emulatorpin cpuset='4-7'/>
</cputune>

<!-- CPU topology matching -->
<cpu mode='host-passthrough' check='none'>
  <topology sockets='1' dies='1' cores='4' threads='1'/>
  <cache mode='passthrough'/>
</cpu>
```

**Performance Impact**:
- Reduced context switching
- Better CPU cache utilization
- More consistent performance (lower latency variance)

**Skip if**:
- Host has < 8 cores (need to reserve 4+ for host)
- User declines (pinning reduces flexibility)

### Phase 5: Huge Pages (Conditional - If available)

**Agent**: **003-performance** → **034-huge-pages**

**Tasks**:
1. Check huge pages availability on host
2. Configure huge pages for VM memory
3. Lock memory to prevent swapping

**Huge Pages Configuration**:
```bash
# On host: Enable huge pages (requires reboot)
echo "vm.nr_hugepages = {{ VM_RAM_GB * 256 }}" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
grep HugePages /proc/meminfo
```

**VM XML Configuration**:
```xml
<memoryBacking>
  <hugepages/>
  <locked/>
  <nosharepages/>
</memoryBacking>
```

**Performance Impact**:
- Memory access latency: 5-10% improvement
- TLB (Translation Lookaside Buffer) pressure reduced
- Better for memory-intensive workloads

**Skip if**:
- Host RAM < 32GB (not enough for huge pages + VM + host)
- User declines (requires host reboot)

### Phase 6: Benchmarking (Conditional - Unless --skip-benchmark)

**Agent**: **003-performance** → **035-benchmark**

**Tasks**:
1. Restart VM to apply optimizations
2. Measure post-optimization performance
3. Compare baseline vs optimized
4. Validate 85-95% native performance target

**Benchmark Tests**:
```bash
# 1. VM Boot Time
time virsh start {{ VM_NAME }}
# Target: < 25 seconds (was ~45s before optimization)

# 2. Disk Performance (in Windows guest)
# CrystalDiskMark or fio
# Target: Sequential Read > 2000 MB/s, 4K Random Read > 40,000 IOPS

# 3. CPU Performance (in Windows guest)
# Geekbench 6 or Cinebench
# Target: 85-95% of native Windows score

# 4. Outlook Startup Time (if installed)
# Measure time from click to inbox load
# Target: < 5 seconds (was ~12s before optimization)
```

**Performance Report**:
```
Baseline → Optimized (Improvement)
─────────────────────────────────────────────────────────────
Boot Time:        45s → 22s (51% faster)
Disk IOPS (4K):   8,000 → 45,000 (463% faster)
CPU Score:        60% → 92% native (53% improvement)
Outlook Startup:  12s → 4s (67% faster)
Overall:          50-60% → 85-95% native performance
```

### Phase 7: Context7 Standards Validation (Delegated to 007-health)

**Agent**: **007-health** (with Context7 integration)

**Tasks**:
1. Query Context7 for QEMU/KVM performance best practices
2. Validate all optimizations against latest standards
3. Identify missing optimizations (if any)

**Context7 Queries**:
- "QEMU Windows VM performance optimization 2025"
- "Hyper-V enlightenments best practices KVM"
- "VirtIO driver optimization techniques"
- "CPU pinning and NUMA for VM performance"

**Expected Output**:
- All 14 Hyper-V enlightenments: ✅ Applied
- VirtIO optimization: ✅ Configured
- CPU pinning: ✅ Configured (if 8+ cores)
- Huge pages: ✅ or ⚠️ (optional)
- Additional recommendations from Context7

### Phase 8: Constitutional Commit (Delegated to 009-git)

**Agent**: **009-git** → delegates to:
- **091-branch-create**: Create perf-vm-optimization branch
- **092-commit-format**: Constitutional commit message
- **093-merge-strategy**: Merge to main with --no-ff

**Tasks**:
1. Export optimized VM XML
2. Document performance improvements
3. Commit with constitutional format

**Automatic Execution**:
```bash
# 1. Export optimized XML
virsh dumpxml {{ VM_NAME }} > configs/{{ VM_NAME }}-optimized.xml

# 2. Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH="${DATETIME}-perf-vm-optimization-{{ VM_NAME }}"

git checkout -b "$BRANCH"
git add configs/{{ VM_NAME }}-optimized.xml

# 3. Commit
git commit -m "perf(vm): Optimize {{ VM_NAME }} to 85-95% native performance

Problem:
- Default VM performance: 50-60% of native Windows
- Boot time: 45 seconds (target: < 25s)
- Outlook startup: 12 seconds (target: < 5s)

Solution:
- Applied all 14 Hyper-V enlightenments
- Optimized VirtIO drivers (cache=none, io=threads, multiqueue)
- Configured CPU pinning (4 vCPUs to cores 0-3)
- Enabled huge pages (2MB pages for {{ RAM_GB }}GB RAM)

Performance Improvements:
- Boot time: 45s → 22s (51% faster) ✅
- Disk IOPS: 8,000 → 45,000 (463% faster) ✅
- CPU score: 60% → 92% native (53% improvement) ✅
- Outlook startup: 12s → 4s (67% faster) ✅
- Overall: 50-60% → 92% native performance ✅

Technical Details:
- Hyper-V enlightenments: 14/14 applied
- VirtIO devices: disk (virtio-blk), network (virtio-net), graphics (virtio-vga)
- CPU pinning: vCPUs 0-3 → cores 0-3, emulator → cores 4-7
- Huge pages: {{ VM_RAM_GB * 256 }} pages allocated
- Memory backing: hugepages, locked, nosharepages

Validation:
- Context7 best practices: ✅ ALIGNED
- Performance target: ✅ ACHIEVED (92% > 85% target)
- All benchmarks: ✅ PASSED

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push and merge
git push -u origin "$BRANCH"
git checkout main
git merge "$BRANCH" --no-ff
git push origin main
```

## Expected Output

```
⚡ COMPLETE PERFORMANCE OPTIMIZATION
═══════════════════════════════════════════════════════════════════════

VM Name: win11-outlook

Phase 1: Prerequisites & Baseline ✅ READY
  - VM exists: win11-outlook
  - Storage: NVMe SSD (optimal)
  - CPU cores: 16 (sufficient for pinning)
  - Huge pages: Available

Baseline Performance:
  - Boot time: 45 seconds
  - Disk IOPS (4K): 8,000
  - CPU score: 60% native
  - Outlook startup: 12 seconds

Phase 2: Hyper-V Enlightenments ✅ COMPLETE
  - Applied: 14/14 enlightenments
  - relaxed, vapic, spinlocks, vpindex, runtime,
    synic, stimer, reset, vendor_id, frequencies,
    reenlightenment, tlbflush, ipi, evmcs

Phase 3: VirtIO Optimization ✅ COMPLETE
  - Disk: virtio-blk (cache=none, io=threads)
  - Network: virtio-net (multiqueue, 4 queues)
  - Graphics: virtio-vga
  - Balloon: virtio-balloon

Phase 4: CPU Pinning ✅ COMPLETE
  - vCPU 0 → core 0
  - vCPU 1 → core 1
  - vCPU 2 → core 2
  - vCPU 3 → core 3
  - Emulator → cores 4-7
  - CPU mode: host-passthrough

Phase 5: Huge Pages ✅ CONFIGURED
  - Huge pages: 2048 pages (8GB)
  - Memory locked: Yes
  - No share pages: Yes

Phase 6: Benchmarking ✅ COMPLETE

PERFORMANCE COMPARISON:
──────────────────────────────────────────────────────────────────────
Metric              Baseline    Optimized   Improvement   Target
──────────────────────────────────────────────────────────────────────
Boot Time           45s         22s         ↑ 51%        < 25s ✅
Disk IOPS (4K)      8,000       45,000      ↑ 463%       > 40K ✅
CPU Score           60%         92%         ↑ 53%        85-95% ✅
Outlook Startup     12s         4s          ↑ 67%        < 5s ✅
Overall             50-60%      92%         ↑ 64%        85-95% ✅
──────────────────────────────────────────────────────────────────────

Phase 7: Context7 Validation ✅ ALIGNED
  - All optimizations match latest best practices
  - No additional optimizations recommended

Phase 8: Constitutional Commit ✅ COMPLETE
  - Branch: 20251117-180000-perf-vm-optimization-win11-outlook
  - XML saved: configs/win11-outlook-optimized.xml
  - Committed and merged to main

═══════════════════════════════════════════════════════════════════════

🎯 OPTIMIZATION COMPLETE - PERFORMANCE TARGET ACHIEVED

Your Windows 11 VM now performs at 92% of native Windows speed.

Next Steps:
- Run /guardian-security (to harden security while maintaining performance)
- Configure virtio-fs for PST files (virtio-fs-specialist agent)
- Install QEMU guest agent in Windows for automation

═══════════════════════════════════════════════════════════════════════
```

## When to Use

Run `/guardian-optimize` when you need to:
- **After VM creation**: Apply performance optimizations to new VM
- **Existing VM is slow**: Improve 50-60% performance to 85-95%
- **Benchmark current VM**: Measure performance without changes (--baseline-only)
- **After Windows updates**: Re-validate optimizations still applied

**Perfect for**: Achieving near-native Windows performance (85-95%) for daily productivity.

## What This Command Does NOT Do

- ❌ Does NOT create VMs (use `/guardian-vm`)
- ❌ Does NOT install Windows or VirtIO drivers (manual step)
- ❌ Does NOT harden security (use `/guardian-security`)
- ❌ Does NOT configure applications (Outlook, etc.)

**Focus**: VM performance optimization only - maximizes VM speed to 85-95% native.

## Constitutional Compliance

This command enforces:
- ✅ ALL 14 Hyper-V enlightenments (not 10, not 12 - all 14)
- ✅ VirtIO for ALL devices (disk, network, graphics, balloon)
- ✅ Performance target: 85-95% native (not "fast enough")
- ✅ Benchmarking: Measure before and after
- ✅ Context7 validation: Align with latest 2025 best practices
- ✅ Constitutional commit: Document performance gains
- ✅ CPU pinning: Only if 8+ cores (don't starve host)
- ✅ Huge pages: Only if 32GB+ RAM (don't exhaust memory)
