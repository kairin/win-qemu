# Performance Benchmarks & Targets

[← Back to Index](../README.md)

---

## Target Metrics

| Metric | Target | Minimum | Measurement |
|--------|--------|---------|-------------|
| Overall Performance | 85-95% native | 80% | Composite score |
| Boot Time | <25 seconds | <45 seconds | Stopwatch |
| Outlook Launch | <5 seconds | <10 seconds | Stopwatch |
| PST Open (1GB) | <3 seconds | <5 seconds | Stopwatch |
| Disk IOPS (4K) | >30,000 | >20,000 | fio benchmark |
| Network Throughput | >900 Mbps | >500 Mbps | iperf3 |
| Memory Latency | <100ns | <200ns | mlc benchmark |

---

## Benchmark Commands

### Boot Time Measurement
```bash
# Host-side timing
time virsh start VM_NAME
# Stop timer when Windows login screen appears
```

### Disk I/O Benchmark
```bash
# Inside Windows guest (PowerShell)
winsat disk -drive C

# Or using fio from host
fio --name=test --ioengine=libaio --rw=randread \
    --bs=4k --direct=1 --size=1G --numjobs=4 \
    --runtime=60 --group_reporting
```

### Network Benchmark
```bash
# Host as server
iperf3 -s

# Guest as client (PowerShell)
iperf3.exe -c HOST_IP -t 30
```

### Memory Benchmark
```powershell
# Inside Windows guest
Get-Counter '\Memory\Available MBytes'
```

---

## Baseline vs Optimized Comparison

| Metric | Unoptimized | Optimized | Improvement |
|--------|-------------|-----------|-------------|
| Boot Time | 45s | 22s | **51%** |
| Outlook Launch | 8s | 3s | **62%** |
| Disk IOPS | 15,000 | 35,000 | **133%** |
| Network | 400 Mbps | 950 Mbps | **138%** |

---

## Optimization Checklist

| Optimization | Expected Gain | Status |
|--------------|---------------|--------|
| Hyper-V enlightenments (14) | 30-50% | [ ] |
| VirtIO-SCSI (not IDE) | 200-400% | [ ] |
| CPU host-passthrough | 10-15% | [ ] |
| CPU pinning | 5-10% | [ ] |
| Huge pages | 5-15% | [ ] |
| I/O threading | 10-20% | [ ] |
| Multi-queue VirtIO | 20-40% | [ ] |
| VirtIO-GPU 3D | 50-100% | [ ] |

---

## Performance Report Template

```json
{
  "timestamp": "2025-11-28T14:30:00Z",
  "vm_name": "win11-outlook",
  "phase": "post-optimization",
  "metrics": {
    "boot_time_seconds": 22,
    "outlook_launch_seconds": 3,
    "pst_open_seconds": 2,
    "disk_iops_4k": 35000,
    "network_mbps": 950
  },
  "optimizations": {
    "hyperv_enlightenments": 14,
    "virtio_drivers": "scsi,net,gpu",
    "cpu_mode": "host-passthrough",
    "cpu_pinning": true,
    "huge_pages": true
  },
  "score": "92% native",
  "status": "PASS"
}
```

---

## Troubleshooting Poor Performance

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Boot >45s | Missing enlightenments | Apply all 14 Hyper-V features |
| Slow disk | IDE emulation | Switch to VirtIO-SCSI |
| High latency | CPU stealing | Enable CPU pinning |
| Memory pressure | No huge pages | Configure huge pages |
| Graphics lag | No 3D accel | Enable VirtIO-GPU accel3d |

---

[← Back to Index](../README.md)
