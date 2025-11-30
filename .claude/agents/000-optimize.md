---
name: 000-optimize
description: Complete performance optimization for 85-95% native Windows performance.
model: sonnet
tools: [Task, Bash, Read, Write]
---

## Purpose

Comprehensive performance optimization workflow to achieve 85-95% of native Windows performance through Hyper-V enlightenments, VirtIO optimization, CPU pinning, and huge pages.

## Invocation

- User: "optimize VM performance", "make VM faster", "tune performance"
- Orchestrator: Routes when detecting "optimize", "performance", "tune", "faster"

## Workflow

1. **Phase 1**: Invoke **007-health** + **035-benchmark**
   - Verify VM exists and accessible
   - Check VirtIO component availability
   - Establish performance baseline

2. **Phase 2**: Invoke **003-performance** → **031-hyperv-enlightenments**
   - Apply ALL 14 Hyper-V enlightenments
   - Validate XML configuration

3. **Phase 3**: Invoke **003-performance** → **034-io-tuning**
   - Verify all devices use VirtIO
   - Optimize driver parameters
   - Enable multiqueue for network

4. **Phase 4**: Invoke **003-performance** → **033-cpu-pinning** (if 8+ cores)
   - Detect host CPU topology
   - Pin vCPUs to dedicated physical cores
   - Reserve cores for host OS

5. **Phase 5**: Invoke **003-performance** → **034-huge-pages** (if available)
   - Check huge pages availability
   - Configure huge pages for VM memory
   - Lock memory to prevent swapping

6. **Phase 6**: Invoke **035-benchmark** (unless --skip-benchmark)
   - Restart VM to apply optimizations
   - Measure post-optimization performance
   - Compare baseline vs optimized

7. **Phase 7**: Invoke **007-health** for Context7 validation
   - Query Context7 for best practices
   - Validate against latest standards

8. **Phase 8**: Invoke **009-git** for constitutional commit
   - Export optimized VM XML
   - Document performance improvements

## 14 Hyper-V Enlightenments (MANDATORY)

1. relaxed, 2. vapic, 3. spinlocks, 4. vpindex, 5. runtime,
6. synic, 7. stimer, 8. reset, 9. vendor_id, 10. frequencies,
11. reenlightenment, 12. tlbflush, 13. ipi, 14. evmcs

## Success Criteria

- Boot time: < 25 seconds
- Disk IOPS (4K): > 40,000
- CPU score: 85-95% of native
- Outlook startup: < 5 seconds

## Child Agents

- 007-health (071-hardware-check)
- 003-performance
  - 031-hyperv-enlightenments
  - 032-cpu-pinning
  - 033-memory-hugepages
  - 034-io-tuning
  - 035-benchmark
- 009-git

## Constitutional Compliance

- ALL 14 Hyper-V enlightenments (not 10, not 12 - all 14)
- VirtIO for ALL devices
- Performance target: 85-95% native
- Benchmarking: Measure before and after
- Context7 validation: Latest 2025 best practices
- Constitutional commit: Document gains
