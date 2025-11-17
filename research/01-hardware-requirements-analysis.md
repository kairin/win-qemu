# Hardware and System Requirements Analysis
## Windows 11 VM with Microsoft 365 Outlook on Ubuntu 25.10 using QEMU/KVM

**Research Agent:** Hardware Requirements Specialist
**Analysis Date:** November 14, 2025
**Source Architecture:** `/home/kkk/Apps/win-qemu/outlook-linux-guide/`

---

## Executive Summary

This comprehensive analysis evaluates hardware and system requirements for running a Windows 11 virtual machine with Microsoft 365 Outlook on Ubuntu 25.10 using QEMU/KVM virtualization. The solution uses self-managed virtualization to achieve 100% application compatibility while maintaining enterprise policy compliance.

**Critical Finding:** Minimum viable configuration requires 8+ CPU cores, 16GB RAM, and SSD storage. Under-provisioning resources leads to system instability and crashes.

---

## 1. CPU Requirements

### 1.1 Virtualization Technology Requirements

**Critical Requirement:** The host CPU must support hardware-assisted virtualization:
- **Intel CPUs:** Intel VT-x (Virtual Technology Extensions)
- **AMD CPUs:** AMD-V (AMD Virtualization)

These technologies are mandatory for KVM to function. Without them, QEMU will fall back to software emulation, resulting in unusable performance.

### 1.2 Why host-passthrough is Critical

The architecture mandates using **host-passthrough** CPU mode for the Windows 11 guest. This configuration:

1. **Satisfies Windows 11 Requirements:** Passes the host CPU's exact model and features to the guest, allowing Windows 11 to recognize a modern CPU generation and pass its hardware compatibility checks
2. **Enables Hyper-V Enlightenments:** Allows the guest to detect and use KVM-specific optimizations through Hyper-V enlightenments, dramatically improving performance and stability
3. **Provides Maximum Performance:** Eliminates CPU feature emulation overhead by exposing the real CPU capabilities directly to the guest
4. **Prevents Compatibility Issues:** Avoids Windows 11 installation failures due to "unsupported CPU" errors

### 1.3 Recommended CPU Cores and Allocation Strategy

**Minimum Configuration:**
- **Total Host Cores:** 8+ physical cores
- **Guest Allocation:** 4 vCPUs
- **Host Reserved:** 4+ cores

**Critical Principle:** Never over-provision CPU cores. The host OS **is** the hypervisor and must have dedicated resources.

**Why This Matters:**
According to the guide's Section 4.4, community reports of "100% CPU usage" or full system crashes are directly caused by:
- Over-provisioning (assigning all or most host cores to the guest)
- Resource starvation of the host OS
- Insufficient cores left for the hypervisor's management overhead

**Allocation Strategy:**
```
Example for 8-core system:
├── Guest VM: 4 vCPUs (50%)
└── Host OS + Hypervisor: 4 cores (50%)

Example for 12-core system:
├── Guest VM: 6 vCPUs
└── Host OS + Hypervisor: 6 cores
```

### 1.4 Verification Commands

**Check if virtualization is supported:**
```bash
# Check CPU virtualization capabilities
egrep -c '(vmx|svm)' /proc/cpuinfo
```
- If output is **0**: Virtualization not supported or not enabled in BIOS
- If output is **>0**: Number of cores with virtualization support

**Detailed CPU information:**
```bash
# Check for Intel VT-x
lscpu | grep -i virtualization
# Expected output: "Virtualization: VT-x" (Intel) or "Virtualization: AMD-V" (AMD)

# Alternative detailed check
LC_ALL=C lscpu | grep Virtualization
```

**Check if KVM modules are loaded:**
```bash
# Verify KVM kernel modules
lsmod | grep kvm

# Expected output should show:
# kvm_intel (for Intel) or kvm_amd (for AMD)
# kvm (base module)
```

**Verify KVM is accessible:**
```bash
# Check if /dev/kvm exists and is accessible
ls -l /dev/kvm

# Check if your user is in the kvm group
groups | grep kvm
```

### 1.5 How to Verify Virtualization is Enabled in BIOS

If `egrep -c '(vmx|svm)' /proc/cpuinfo` returns **0**, virtualization is disabled in BIOS:

**Intel Systems (VT-x):**
1. Reboot and enter BIOS/UEFI (typically Del, F2, F10, or F12 during boot)
2. Navigate to: Advanced → CPU Configuration (location varies by motherboard)
3. Look for: "Intel Virtualization Technology", "Intel VT-x", or "Virtualization Extensions"
4. Set to: **Enabled**
5. Also enable "VT-d" if available (for device passthrough support)
6. Save and exit

**AMD Systems (AMD-V):**
1. Reboot and enter BIOS/UEFI
2. Navigate to: Advanced → CPU Configuration
3. Look for: "SVM Mode", "AMD-V", or "Secure Virtual Machine"
4. Set to: **Enabled**
5. Also enable "IOMMU" if available
6. Save and exit

**Verification After BIOS Change:**
```bash
# Should now return a number > 0
egrep -c '(vmx|svm)' /proc/cpuinfo

# Should show virtualization type
lscpu | grep Virtualization
```

---

## 2. Memory Requirements

### 2.1 Minimum vs Recommended RAM

**Absolute Minimum Configuration:**
- **Total Host RAM:** 16 GB
- **Guest Allocation:** 8 GB
- **Host Reserved:** 8 GB

**Recommended Configuration:**
- **Total Host RAM:** 24-32 GB
- **Guest Allocation:** 12-16 GB
- **Host Reserved:** 12-16 GB

### 2.2 Memory Allocation Strategy (Guest vs Host)

**Golden Rule:** Maintain a 50/50 split or favor the host slightly.

**Rationale:**
```
Host Memory Responsibilities:
├── Ubuntu OS base system (2-3 GB)
├── Desktop environment (1-2 GB)
├── QEMU/KVM hypervisor overhead (1-2 GB)
├── Disk caching for VM images (important for performance)
├── virtio-fs shared memory (required)
└── Browser and other applications (2-4 GB)

Guest Memory Usage:
├── Windows 11 OS (4-5 GB)
├── Microsoft 365 Outlook (2-4 GB)
├── Office updates and services (1-2 GB)
└── Windows background services (1-2 GB)
```

**Bad Configuration Example** (causes system instability):
```
Total: 16 GB
├── Guest: 14 GB ❌ (leaves only 2GB for host)
└── Host: 2 GB remaining ❌
Result: System becomes unresponsive, frequent OOM kills
```

### 2.3 Why Shared Memory is Required for virtio-fs

**Critical Architecture Component:** The virtio-fs filesystem sharing mechanism (used for .pst file access) requires **shared memory backing**.

**Technical Implementation:**
```xml
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

**Why This is Mandatory:**
1. **virtio-fs Architecture:** Unlike traditional network shares (Samba), virtio-fs is a FUSE-based filesystem that operates through direct memory mapping between host and guest
2. **Zero-Copy Performance:** Shared memory enables zero-copy data transfers, providing near-native filesystem performance for .pst file access
3. **Memory Efficiency:** Allows the same physical memory pages to be mapped into both host and guest address spaces without duplication
4. **Prerequisites for virtiofs Driver:** The virtiofs driver cannot initialize without shared memory backing enabled in the VM configuration

**Without Shared Memory:**
- virtio-fs filesystem will fail to mount
- .pst files cannot be accessed from the host
- The core use case (Constraint #3 in the guide) fails completely

### 2.4 Potential Issues with Insufficient RAM

**Symptom:** Less than 16 GB total RAM

**Impacts:**
1. **Guest Swap Thrashing:** Windows 11 with Office suite will constantly page to disk
2. **Host OOM (Out of Memory) Killer:** Linux kernel may kill critical processes including the VM itself
3. **Degraded Performance:** Constant disk I/O from swapping makes the system unusable
4. **Unstable VM:** Random crashes, freezes, or corruption of the Windows VM
5. **Failed virtio-fs:** Insufficient memory for shared memory backing may cause filesystem share to become unresponsive

**Symptom:** Over-provisioned guest memory (e.g., 14 GB out of 16 GB)

**Impacts:**
1. **Host System Becomes Unresponsive:** Desktop environment freezes or crashes
2. **Hypervisor Cannot Function:** QEMU/libvirt services may be killed by OOM killer
3. **Complete System Hang:** May require hard reset
4. **Data Corruption Risk:** Sudden crashes can corrupt VM disk images

### 2.5 Memory Verification Commands

**Check total system RAM:**
```bash
# Total RAM in human-readable format
free -h

# Detailed memory info
cat /proc/meminfo | grep MemTotal
```

**Monitor memory usage in real-time:**
```bash
# Interactive memory monitor
htop

# Or traditional top
top

# VM-specific memory usage
virsh dommemstat <vm_name>
```

**Check VM memory allocation:**
```bash
# Show VM memory configuration
virsh dominfo <vm_name> | grep memory

# Current memory usage of running VM
virsh dommemstat <vm_name>
```

---

## 3. Storage Requirements

### 3.1 Disk Space Needed for Windows 11 VM

**Base Windows 11 Installation:**
- **Minimum Disk Image Size:** 64 GB (Windows 11 requirement)
- **Recommended Initial Size:** 80-100 GB
- **Typical Usage After Setup:** 40-50 GB (OS + drivers + updates)

**With Microsoft 365 Outlook Installed:**
- **Windows 11 Base:** ~45 GB
- **Microsoft 365 Apps Suite:** ~10-15 GB
- **Windows Updates (over time):** +10-20 GB
- **Temporary files and cache:** +5-10 GB
- **Recommended Total:** **120-150 GB** for comfortable long-term use

**Important:** This does NOT include .pst file storage (see next section).

### 3.2 Storage for .pst Files

**Strategy:** .pst files should be stored on the Ubuntu host, NOT inside the VM.

**Architecture:**
```
Ubuntu Host Filesystem
└── /home/username/OutlookArchives/
    ├── archive_2023.pst (5-50 GB per file typical)
    ├── archive_2024.pst
    └── current_work.pst

    ↓ (virtio-fs mapping)

Windows Guest
└── Z:\ (virtual drive mapped to host folder)
    ├── archive_2023.pst ← Direct access to host files
    ├── archive_2024.pst
    └── current_work.pst
```

**Typical .pst File Sizes:**
- Small archive (1-2 years): 2-10 GB
- Medium archive (3-5 years): 10-30 GB
- Large archive (5+ years): 30-100 GB
- Multiple archives: 50-200+ GB total

**Recommended Host Storage Allocation:**
- **For .pst files:** 100-300 GB (depending on archive size)
- **Separate from VM disk image:** Yes, use dedicated directory

### 3.3 Performance Implications of Storage Type (SSD vs HDD)

**Critical Performance Factor:** Storage type has MASSIVE impact on VM usability.

#### SSD (Solid State Drive) - STRONGLY RECOMMENDED

**Performance Characteristics:**
- **VM Boot Time:** 15-30 seconds
- **Windows Responsiveness:** Near-native feel
- **Office Application Startup:** 2-5 seconds
- **Outlook .pst File Access:** Instant (with virtio-fs)
- **IOPS (Input/Output Operations Per Second):** 10,000-100,000+

**Why SSD is Critical:**
1. **Random I/O Performance:** VMs generate massive amounts of random disk access (not sequential)
2. **Guest OS Responsiveness:** Windows constantly reads/writes to disk for page file, cache, and system files
3. **VirtIO Driver Performance:** VirtIO storage benefits enormously from low-latency storage
4. **Multi-tasking:** Running Office + Windows updates + antivirus requires high IOPS
5. **.pst File Operations:** Large .pst files require fast random access for email indexing and search

**Recommended:** NVMe SSD > SATA SSD > Any HDD

#### HDD (Hard Disk Drive) - NOT RECOMMENDED

**Performance Characteristics:**
- **VM Boot Time:** 2-5 minutes
- **Windows Responsiveness:** Sluggish, constant lag
- **Office Application Startup:** 15-60 seconds
- **Outlook .pst File Access:** Slow, delays when opening emails
- **IOPS:** 100-200 (100x slower than SSD)

**Critical Problems with HDD:**
1. **Unusable Desktop Experience:** Constant stuttering and freezing
2. **High CPU Usage:** CPU waits for disk I/O, appears as "CPU-bound"
3. **Increased Crashes:** I/O timeouts can cause application hangs
4. **Poor .pst Performance:** Opening large .pst files can take minutes
5. **Compounding Effect:** Both VM disk image AND .pst files compete for limited HDD IOPS

**Verdict:** HDD storage makes the solution impractical for daily use.

### 3.4 qcow2 Format Considerations

**qcow2** (QEMU Copy-On-Write version 2) is the recommended disk image format.

**Advantages:**
1. **Thin Provisioning:** Only uses actual disk space for written data
   - Create 150 GB image, only uses ~40 GB initially
   - Grows dynamically as Windows writes data
2. **Snapshot Support:** Create VM snapshots before updates/changes
3. **Compression:** Supports transparent compression (at cost of CPU)
4. **Encryption:** Built-in encryption support if needed

**Performance Considerations:**
```bash
# When creating disk image, use these optimal settings:
qemu-img create -f qcow2 -o preallocation=metadata,cluster_size=2M disk.qcow2 150G

# preallocation=metadata: Pre-allocate metadata for better performance
# cluster_size=2M: Larger clusters reduce overhead for large files
```

**Performance Impact:**
- **qcow2 on SSD:** Negligible overhead (2-5% vs raw)
- **qcow2 on HDD:** Adds additional overhead (5-15% vs raw)
- **With VirtIO drivers:** Overhead is minimal on modern systems

**Alternative - Raw Format:**
```bash
# Maximum performance but no features
qemu-img create -f raw disk.raw 150G
```
- Slightly better performance (especially on HDD)
- No thin provisioning (uses full 150 GB immediately)
- No snapshot support
- Generally NOT worth losing qcow2 features

**Disk Location Recommendation:**
```bash
# Default libvirt storage pool
/var/lib/libvirt/images/win11-outlook.qcow2

# Or custom location (ensure proper permissions)
/home/username/VirtualMachines/win11-outlook.qcow2
```

### 3.5 Storage Verification Commands

**Check available disk space:**
```bash
# Show disk space for filesystem
df -h /var/lib/libvirt/images

# Show disk space for home directory (for .pst files)
df -h /home
```

**Check VM disk image info:**
```bash
# Show qcow2 image details
qemu-img info /var/lib/libvirt/images/win11-outlook.qcow2

# Shows:
# - Virtual size (guest sees this)
# - Actual disk usage (host uses this)
# - Format and compression
```

**Monitor VM disk I/O:**
```bash
# Show VM disk statistics
virsh domblkstat <vm_name> vda

# Real-time I/O monitoring
iostat -x 2
```

**Check SSD vs HDD:**
```bash
# Check if device is rotational (HDD=1, SSD=0)
cat /sys/block/sda/queue/rotational

# Or use lsblk
lsblk -d -o name,rota
# ROTA=1 means HDD, ROTA=0 means SSD
```

---

## 4. GPU/Graphics Requirements

### 4.1 VirtIO vs QXL Video Adapters

The guide is explicit about graphics adapter choice: **VirtIO is mandatory for acceptable performance**.

#### QXL (Default - NOT RECOMMENDED)

**Characteristics:**
- Legacy SPICE display protocol adapter
- Software-based rendering only
- Dated design from early 2010s

**Performance Issues:**
- High CPU usage for GUI rendering
- Laggy window movement and animations
- Poor Office application performance (PowerPoint animations, Excel charts)
- No modern graphics acceleration

**Quote from Guide** (Section 4.4):
> "The default 'QXL' video adapter is old. In virt-manager, change the 'Video' device model to **VirtIO**. Ensure '3D acceleration' is checked."

#### VirtIO (REQUIRED)

**Characteristics:**
- Modern, performant graphics driver
- Supports 3D acceleration via Venus
- Designed for KVM optimization

**Configuration in virt-manager:**
1. Open VM settings
2. Go to "Video" device
3. Set Model to: **VirtIO**
4. Check: **3D acceleration** ✓

**Performance Benefits:**
- Dramatically reduced CPU usage for GUI operations
- Smooth window management and animations
- Proper Office application rendering (Excel, PowerPoint)
- Near-native desktop responsiveness

**Technical Details:**
- Uses virtio-gpu driver in guest
- Leverages Venus (Vulkan-to-OpenGL translation) for 3D
- Integrates with QEMU's graphics stack efficiently

### 4.2 3D Acceleration Support

**Status:** Supported and **required** with VirtIO adapter.

**Configuration:**
```xml
<!-- In VM XML configuration -->
<video>
  <model type='virtio' heads='1' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

**What 3D Acceleration Provides:**
1. **Hardware-accelerated OpenGL:** Office applications use OpenGL for charts, transitions, effects
2. **Better Windows Desktop Composition:** Windows Aero/Desktop Window Manager runs smoothly
3. **Reduced CPU Load:** GPU operations offloaded from CPU
4. **Modern Application Support:** Many modern apps expect basic 3D capabilities

**Limitations:**
- Not equivalent to GPU passthrough (no gaming-level performance)
- Uses software-accelerated Venus driver (not bare-metal GPU)
- Sufficient for Office productivity, not for CAD/gaming

### 4.3 Multi-Monitor Considerations

**Configuration:**
```xml
<video>
  <model type='virtio' heads='2' primary='yes'>
    <!-- heads='2' for dual monitors, '3' for triple, etc. -->
    <acceleration accel3d='yes'/>
  </model>
</video>
```

**Known Issues from Guide:**

**1. RDP RemoteApp Multi-Monitor Instability:**
From the guide's analysis of Winboat (Section 3):
> "Community reports document 'multi-monitor issues' as a persistent problem with Winboat's RDP integration, with windows not appearing on the correct screen or disappearing entirely."

**Impact:** If using optional FreeRDP + RemoteApp for "seamless windows", multi-monitor setups are unstable.

**2. Recommended Alternative:**
From Section 5.2:
> "Given the known instability of RDP RemoteApp with multi-monitor setups, a simpler and often more robust solution is to forgo the 'seamless' integration. The user can simply run the full Windows desktop in a standard virt-manager window, minimized or on a separate virtual desktop."

**Multi-Monitor Strategy:**
```
Option A (Unstable): FreeRDP + RemoteApp + Multi-Monitor
├── Pros: Seamless window integration
└── Cons: Known stability issues, windows disappear or misplace

Option B (Stable - RECOMMENDED): Full Desktop in virt-manager
├── Single virt-manager window on host
├── Windows guest configured for multi-monitor internally
├── Host: Use virtual desktops to switch between Linux and VM
└── 100% stable, no RDP-related bugs
```

**Best Practice:**
- Use VirtIO with 3D acceleration
- Configure multiple heads in VM if needed
- Run full desktop in virt-manager window (not RemoteApp)
- Use Linux virtual desktops to manage workspace

### 4.4 Known Issues with Graphics Performance

**Issue #1: Default QXL Adapter**

**Symptoms:**
- High CPU usage even when Windows is idle
- Sluggish GUI responsiveness
- Office applications (especially PowerPoint) feel slow
- Window dragging/resizing is choppy

**Solution:**
- Switch to VirtIO video adapter
- Enable 3D acceleration
- Apply Hyper-V enlightenments (see CPU section)

**Issue #2: Missing Hyper-V Enlightenments**

**Symptoms:**
- Poor overall VM performance despite good hardware
- Windows reports high CPU usage in Task Manager
- Inconsistent performance spikes

**Solution** (from Section 4.4):
```xml
<hyperv mode='custom'>
  <relaxed state='on'/>
  <vapic state='on'/>
  <spinlocks state='on' retries='8191'/>
  <vpindex state='on'/>
  <runtime state='on'/>
  <synic state='on'/>
  <stimer state='on'>
    <direct state='on'/>
  </stimer>
  <reset state='on'/>
  <vendor_id state='on' value='KVM Hv'/>
  <frequencies state='on'/>
  <reenlightenment state='on'/>
  <tlbflush state='on'/>
  <ipi state='on'/>
</hyperv>
```

**Impact:** Makes Windows "KVM-aware", dramatically improving graphics and overall performance.

**Issue #3: No GPU Passthrough in Current Architecture**

**Limitation:** The reference architecture does NOT use GPU passthrough (PCIe device assignment).

**Implications:**
- Graphics performance is good for Office productivity
- NOT suitable for CAD, 3D modeling, or gaming
- No access to host GPU's full capabilities
- Sufficient for the Outlook use case

**Why GPU Passthrough is Not Used:**
1. Requires second GPU or hybrid graphics setup
2. Adds significant configuration complexity
3. Can break host display
4. Not necessary for Office productivity workload
5. VirtIO + 3D acceleration is sufficient for Outlook/Office

### 4.5 Graphics Verification Commands

**Check video adapter in use:**
```bash
# Show VM video configuration
virsh dumpxml <vm_name> | grep -A 5 "<video>"

# Expected output with VirtIO:
# <video>
#   <model type='virtio' heads='1' primary='yes'>
#     <acceleration accel3d='yes'/>
#   </model>
# </video>
```

**Monitor graphics performance:**
```bash
# Check if GPU is being used (host-side)
nvidia-smi  # For NVIDIA GPUs
radeontop   # For AMD GPUs

# Check CPU usage during VM graphics operations
htop  # Look for QEMU process CPU usage
```

**Inside Windows guest:**
```powershell
# Check graphics adapter
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion

# Should show: "Red Hat VirtIO GPU" or similar
```

---

## 5. Summary of Critical Requirements

### Absolute Minimums (Barely Usable)
- **CPU:** 8 cores with VT-x/AMD-V, host-passthrough enabled
- **RAM:** 16 GB (8 GB guest / 8 GB host)
- **Storage:** 150 GB on SSD (100 GB for VM + 50 GB for .pst)
- **GPU:** VirtIO adapter with 3D acceleration enabled

### Recommended Configuration (Comfortable Daily Use)
- **CPU:** 12+ cores with VT-x/AMD-V, host-passthrough enabled
- **RAM:** 32 GB (16 GB guest / 16 GB host)
- **Storage:** 300+ GB on NVMe SSD (150 GB for VM + 150-200 GB for .pst)
- **GPU:** VirtIO adapter with 3D acceleration enabled
- **Multiple monitors:** Use full desktop in virt-manager (not RemoteApp)

### Deal Breakers (Will Not Work)
- ✗ No CPU virtualization support (VT-x/AMD-V)
- ✗ Less than 16 GB total RAM
- ✗ HDD storage (technically works but unusable performance)
- ✗ Using QXL video adapter (poor Office performance)
- ✗ Over-provisioning resources (guest gets >75% of host resources)
- ✗ Missing shared memory backing (virtio-fs will fail)

---

## 6. Complete Verification Script

```bash
#!/bin/bash
# Complete system verification script

echo "=== Hardware Requirements Verification ==="
echo

echo "1. CPU Virtualization Check"
if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    CORES=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
    echo "   ✓ CPU supports virtualization"
    echo "   Available cores: $CORES"
    if [ "$CORES" -ge 8 ]; then
        echo "   ✓ Core count sufficient (8+ required)"
    else
        echo "   ✗ Insufficient cores (need 8+, have $CORES)"
    fi
else
    echo "   ✗ CPU does NOT support virtualization or it's disabled in BIOS"
    exit 1
fi

echo
echo "2. Virtualization Type"
lscpu | grep Virtualization

echo
echo "3. KVM Module Check"
if lsmod | grep -q kvm; then
    echo "   ✓ KVM modules loaded"
    lsmod | grep kvm
else
    echo "   ✗ KVM modules NOT loaded"
fi

echo
echo "4. Memory Check"
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
echo "   Total RAM: ${TOTAL_RAM} GB"
if [ "$TOTAL_RAM" -ge 16 ]; then
    echo "   ✓ RAM sufficient (16GB+ required)"
else
    echo "   ✗ RAM insufficient (need 16GB+, have ${TOTAL_RAM}GB)"
fi

echo
echo "5. Storage Check"
echo "   Storage type (0=SSD, 1=HDD):"
lsblk -d -o name,rota | grep -v "loop"

echo
echo "6. Available disk space:"
df -h / /var/lib/libvirt/images 2>/dev/null || df -h /

echo
echo "7. /dev/kvm Access"
if [ -e /dev/kvm ]; then
    ls -l /dev/kvm
    if groups | grep -q kvm; then
        echo "   ✓ User is in kvm group"
    else
        echo "   ⚠ User NOT in kvm group (run: sudo usermod -aG kvm \$USER)"
    fi
else
    echo "   ✗ /dev/kvm does not exist"
fi

echo
echo "=== Verification Complete ==="
```

---

## Conclusion

This hardware requirements analysis establishes that a functional Microsoft 365 Outlook virtualization solution on Ubuntu 25.10 requires:

1. **Modern CPU** with hardware virtualization (8+ cores minimum)
2. **Adequate RAM** with proper allocation strategy (16GB minimum, 32GB recommended)
3. **Fast storage** on SSD (150GB+ for VM, additional space for .pst files)
4. **Proper graphics** configuration (VirtIO + 3D acceleration)
5. **Correct resource allocation** avoiding over-provisioning

The most common failures stem from insufficient hardware or improper resource allocation, not software configuration issues. Verifying these requirements before beginning installation will prevent most deployment problems.
