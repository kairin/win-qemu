# VM Configuration Standards

[← Back to Index](../README.md)

---

## Machine Type (MANDATORY)

```xml
<!-- Q35 chipset with UEFI -->
<os>
  <type arch='x86_64' machine='pc-q35-8.0'>hvm</type>
  <loader readonly='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE_4M.fd</loader>
  <nvram template='/usr/share/OVMF/OVMF_VARS_4M.fd'>/var/lib/libvirt/qemu/nvram/VM_VARS.fd</nvram>
  <boot dev='hd'/>
</os>
```

---

## TPM 2.0 (MANDATORY for Windows 11)

```xml
<tpm model='tpm-crb'>
  <backend type='emulator' version='2.0'>
    <encryption secret='UUID-HERE'/>
  </backend>
</tpm>
```

**Setup**:
```bash
# Start swtpm service
sudo systemctl enable --now swtpm
```

---

## CPU Configuration (MANDATORY)

```xml
<cpu mode='host-passthrough' check='none' migratable='off'>
  <topology sockets='1' dies='1' cores='4' threads='2'/>
  <cache mode='passthrough'/>
  <feature policy='require' name='topoext'/>
</cpu>
```

**Rules**:
- MUST use `host-passthrough` (NOT host-model)
- MUST configure correct topology
- MUST enable cache passthrough

---

## Memory Configuration

```xml
<memory unit='GiB'>16</memory>
<currentMemory unit='GiB'>16</currentMemory>

<!-- For huge pages (recommended >8GB) -->
<memoryBacking>
  <hugepages>
    <page size='2048' unit='KiB'/>
  </hugepages>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

**Huge Pages Calculation**:
```bash
# Pages needed = RAM_MB / 2
# Add 10% overhead
# Example: 16GB = 8,192 + 820 = 9,012 pages
echo 9012 | sudo tee /proc/sys/vm/nr_hugepages
```

---

## VirtIO Devices (MANDATORY)

### VirtIO-SCSI (Storage)
```xml
<controller type='scsi' model='virtio-scsi'>
  <driver queues='4' iothread='1'/>
</controller>

<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
  <source file='/path/to/disk.qcow2'/>
  <target dev='sda' bus='scsi'/>
</disk>
```

### VirtIO-Net (Network)
```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
  <driver name='vhost' queues='4'/>
</interface>
```

### VirtIO-GPU (Graphics)
```xml
<video>
  <model type='virtio' heads='2' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

---

## virtio-fs (File Sharing)

```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs' queue='1024'/>
  <source dir='/host/path'/>
  <target dir='share-name'/>
  <readonly/>  <!-- MANDATORY: Ransomware protection -->
</filesystem>
```

**Guest Mount (Windows)**:
```powershell
# After WinFsp installation
net use Z: \\.\virtiofs\share-name
```

---

## Minimum Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | VT-x/AMD-V, 4 cores | 8+ cores |
| RAM | 8 GB | 16+ GB |
| Storage | 100 GB SSD | 256+ GB NVMe |
| GPU | Integrated | VirtIO-GPU 3D |

---

[← Back to Index](../README.md)
