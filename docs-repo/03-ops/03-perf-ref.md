# QEMU/KVM Performance Optimization - Quick Reference Card

## Critical Optimizations (Must-Have)

### 1. Hyper-V Enlightenments (30-50% performance gain)

```xml
<features>
  <hyperv mode='custom'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
    <vpindex state='on'/>
    <synic state='on'/>
    <stimer state='on'>
      <direct state='on'/>
    </stimer>
    <frequencies state='on'/>
    <tlbflush state='on'/>
    <ipi state='on'/>
  </hyperv>
  <kvm>
    <hidden state='on'/>
  </kvm>
</features>

<clock offset='localtime'>
  <timer name='hpet' present='no'/>
  <timer name='hypervclock' present='yes'/>
  <timer name='tsc' present='yes' mode='native'/>
</clock>
```

### 2. VirtIO Drivers (50-80% I/O performance gain)

**Disk (VirtIO-SCSI):**
```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap' queues='4'/>
  <target dev='sda' bus='scsi'/>
</disk>
<controller type='scsi' model='virtio-scsi'>
  <driver queues='4'/>
</controller>
```

**Network (VirtIO-net):**
```xml
<interface type='network'>
  <model type='virtio'/>
  <driver name='vhost' queues='4' rx_queue_size='1024' tx_queue_size='1024'/>
</interface>
```

**Video (VirtIO-GPU):**
```xml
<video>
  <model type='virtio' heads='2' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

### 3. CPU Configuration (10-20% latency reduction)

```xml
<vcpu placement='static'>8</vcpu>
<cpu mode='host-passthrough' check='none' migratable='off'>
  <topology sockets='1' dies='1' cores='4' threads='2'/>
  <cache mode='passthrough'/>
</cpu>
```

## Recommended Optimizations

### 4. Memory (15-30% throughput improvement)

**Huge Pages:**
```bash
# Host setup (for 8GB VM)
echo 4506 | sudo tee /proc/sys/vm/nr_hugepages
echo "vm.nr_hugepages = 4506" | sudo tee -a /etc/sysctl.conf
```

```xml
<memoryBacking>
  <hugepages>
    <page size='2048' unit='KiB'/>
  </hugepages>
  <source type='memfd'/>
  <access mode='shared'/>
  <allocation mode='immediate'/>
</memoryBacking>
```

### 5. CPU Pinning (Example: 16-thread host)

```xml
<cputune>
  <!-- Reserve CPUs 0-3 for host, pin VM to 4-15 -->
  <vcpupin vcpu='0' cpuset='4'/>
  <vcpupin vcpu='1' cpuset='5'/>
  <vcpupin vcpu='2' cpuset='6'/>
  <vcpupin vcpu='3' cpuset='7'/>
  <vcpupin vcpu='4' cpuset='12'/>
  <vcpupin vcpu='5' cpuset='13'/>
  <vcpupin vcpu='6' cpuset='14'/>
  <vcpupin vcpu='7' cpuset='15'/>
  <emulatorpin cpuset='0-3'/>
</cputune>
```

### 6. virtio-fs (10-30x faster than Samba)

```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs' queue='1024'/>
  <binary path='/usr/libexec/virtiofsd' xattr='on'>
    <cache mode='auto'/>
  </binary>
  <source dir='/home/username/OutlookArchives'/>
  <target dir='outlook-archives'/>
</filesystem>
```

## Performance Verification Commands

### Host Commands
```bash
# Overall VM stats
virsh domstats win11-outlook

# Real-time monitoring
virt-top

# Huge pages usage
grep -i huge /proc/meminfo

# CPU pinning verification
virsh vcpuinfo win11-outlook

# I/O statistics
virsh domblkstat win11-outlook sda --human
```

### Guest Commands (Windows PowerShell)
```powershell
# Verify Hyper-V enlightenments
Get-ComputerInfo | Select-Object HyperV*

# Check CPU topology
Get-WmiObject Win32_Processor | Select NumberOfCores,NumberOfLogicalProcessors

# Performance counters
Get-Counter "\Processor(_Total)\% Processor Time","\Memory\Available MBytes"
```

## Expected Performance Targets

| Metric | Target | Acceptable | Poor |
|--------|--------|-----------|------|
| Boot time | <25s | 25-40s | >40s |
| Outlook launch | <5s | 5-10s | >10s |
| .pst open (1GB) | <3s | 3-6s | >6s |
| UI scrolling | 60fps | 45-60fps | <45fps |
| Idle CPU usage | <5% | 5-10% | >10% |
| Disk IOPS (4K) | >30,000 | 15,000-30,000 | <15,000 |

## Common Issues and Solutions

| Symptom | Cause | Solution |
|---------|-------|----------|
| Slow boot | No enlightenments | Add Hyper-V features |
| Laggy UI | Software rendering | Enable VirtIO-GPU 3D |
| High idle CPU | Missing `<relaxed>` | Enable enlightenments |
| Slow disk | IDE/SATA | Switch to VirtIO-SCSI |
| .pst slow | Samba/network | Use virtio-fs |
| Network slow | e1000 | Switch to VirtIO-net |

## Resource Allocation Guidelines

| Host Config | Host Reserve | Guest Allocation |
|-------------|--------------|------------------|
| 8 cores (16T) | 2C/4T | 6C/12T |
| 12 cores (24T) | 2C/4T | 8-10C/16-20T |
| 16GB RAM | 6-8GB | 8-10GB |
| 32GB RAM | 8-12GB | 16-20GB |

## Quick Setup Checklist

- [ ] Install base packages: `qemu-kvm libvirt-daemon-system virt-manager ovmf swtpm`
- [ ] Download virtio-win ISO from Fedora repository
- [ ] Create VM with Q35 chipset + UEFI + TPM 2.0
- [ ] Set CPU mode to `host-passthrough`
- [ ] Install Windows with VirtIO drivers
- [ ] Apply Hyper-V enlightenments via `virsh edit`
- [ ] Enable VirtIO-GPU with 3D acceleration
- [ ] Configure huge pages
- [ ] Set up virtio-fs for .pst files
- [ ] Install QEMU guest agent
- [ ] Benchmark and verify performance

## Additional Resources

- Full playbook: `09-performance-optimization-playbook.md`
- Base setup: `05-qemu-kvm-reference-architecture.md`
- Complete XML template in Section 8.1 of performance playbook

---

**Quick Tip:** Start with enlightenments + VirtIO drivers for 70% native performance in 30 minutes. Add CPU pinning + huge pages for 85%+ performance with 1-2 hours additional setup.
