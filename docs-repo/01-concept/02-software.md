# Comprehensive Dependency Analysis
## QEMU/KVM Outlook Virtualization Project

**Last Updated:** November 14, 2025
**Target Platform:** Ubuntu 25.10
**Guest OS:** Windows 11
**Application:** Microsoft 365 Outlook (Classic Desktop Client)

---

## Table of Contents

1. [Ubuntu Host Packages](#1-ubuntu-host-packages)
2. [Windows Guest Software](#2-windows-guest-software)
3. [Installation Order & Sequencing](#3-installation-order--sequencing)
4. [Driver Loading Process](#4-driver-loading-process)
5. [Verification & Testing](#5-verification--testing)
6. [Common Pitfalls & Troubleshooting](#6-common-pitfalls--troubleshooting)

---

## 1. Ubuntu Host Packages

### 1.1 Core Virtualization Stack

#### Mandatory Packages

| Package | Purpose | Compatibility Notes |
|---------|---------|---------------------|
| `qemu-kvm` | KVM hypervisor core | Hardware virtualization required (Intel VT-x / AMD-V) |
| `qemu-system-x86` | x86_64 system emulation | Required for Windows 11 guest |
| `libvirt-daemon-system` | Virtualization management daemon | Core management layer |
| `libvirt-clients` | Command-line tools (virsh) | Required for automation scripts |
| `bridge-utils` | Network bridge configuration | Enables VM networking |
| `virt-manager` | GUI management interface | Recommended for initial setup |
| `libosinfo-bin` | OS information database | Helps detect Windows 11 requirements |
| `ovmf` | UEFI firmware for VMs | **CRITICAL**: Windows 11 requires UEFI |
| `swtpm` | Software TPM emulator | **CRITICAL**: Windows 11 requires TPM 2.0 |
| `swtpm-tools` | TPM management utilities | Required for TPM configuration |

#### Installation Command

```bash
sudo apt update
sudo apt install qemu-kvm qemu-system-x86 libvirt-daemon-system \
                 libvirt-clients bridge-utils virt-manager \
                 libosinfo-bin ovmf swtpm swtpm-tools
```

### 1.2 Optional but Recommended Packages

| Package | Purpose | Use Case |
|---------|---------|----------|
| `freerdp2-x11` | RDP client for RemoteApp integration | Enables "seamless window" mode (optional) |
| `python3` | Host-side automation scripts | For custom .pst file automation |
| `virtiofsd` | virtio-fs daemon (usually included) | High-performance filesystem sharing |

#### Installation Command

```bash
sudo apt install freerdp2-x11 python3
```

### 1.3 User Configuration

**MANDATORY**: Add user to required groups

```bash
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
```

**NOTE:** Requires logout/login or `newgrp libvirt` to take effect.

### 1.4 Service Configuration

```bash
# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Verify service status
sudo systemctl status libvirtd
```

**Expected Output:** `active (running)`

---

## 2. Windows Guest Software

### 2.1 Windows 11 Installation Media

**Source:** Official Microsoft Media Creation Tool
**URL:** https://www.microsoft.com/software-download/windows11

**Requirements:**
- Windows 11 Pro or Enterprise (for RemoteApp support)
- Windows 11 Home (if RemoteApp not needed)
- ISO file size: ~5-6 GB

### 2.2 VirtIO Drivers (CRITICAL)

**Source:** Fedora Project (Official Upstream)
**URL:** https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

**Download:** `virtio-win-X.X.X.iso` (latest stable)

#### Driver Components Included

| Driver | Purpose | Install Phase | Mandatory |
|--------|---------|---------------|-----------|
| `viostor` | VirtIO SCSI storage driver | **During Windows install** | YES |
| `NetKVM` | VirtIO network adapter | Post-install | YES |
| `vioserial` | Serial port driver | Post-install | YES (for guest agent) |
| `qxldod` / `viogpudo` | Display drivers | Post-install | Recommended |
| `Balloon` | Memory ballooning | Post-install | Optional |
| `pvpanic` | Panic notification | Post-install | Optional |
| `viofs` | VirtIO filesystem driver | Post-install | **YES (for .pst access)** |

**Version Compatibility:** Use latest stable ISO (tested with virtio-win-0.1.240+)

### 2.3 WinFsp (Windows File System Proxy)

**Purpose:** Required framework for virtio-fs to function on Windows
**Source:** WinFsp Official Project
**URL:** https://winfsp.dev/ or https://github.com/winfsp/winfsp/releases

**Download:** `winfsp-X.X.XXXXX.msi` (latest stable release)

**Installation Requirements:**
- Must be installed BEFORE virtio-fs driver
- Requires Administrator privileges
- Service must be running

**Version Compatibility:** WinFsp 2.0 or later recommended

### 2.4 QEMU Guest Agent

**Purpose:** Host-to-guest automation control plane
**Source:** Included on virtio-win ISO
**Installer:** `qemu-ga-x86_64.msi`

**Capabilities:**
- Clean shutdown/reboot from host
- Execute commands in guest OS
- File system information queries
- Password management
- Time synchronization

**Installation:**
1. Mount virtio-win.iso in guest
2. Run `qemu-ga-x86_64.msi`
3. Service installs automatically
4. Verify service is "Running" and set to "Automatic"

### 2.5 Microsoft 365 Installation

**Source:** Microsoft 365 Portal
**URL:** https://www.office.com/

**Requirements:**
- Active Microsoft 365 subscription
- Internet connection for activation
- Microsoft account credentials

**Installation Method:**
1. Download from Microsoft 365 portal
2. Run installer in guest VM
3. Sign in with Microsoft account
4. Select "Classic Outlook" (not "New Outlook")

**CRITICAL NOTE:** The "New Outlook" web-based client does NOT support local .pst file access. You MUST use the classic desktop client.

---

## 3. Installation Order & Sequencing

### Phase 1: Host Environment Setup

```
1. Install Ubuntu 25.10 host packages
   └─> Install core virtualization stack (apt install ...)
   └─> Add user to libvirt/kvm groups
   └─> Enable and start libvirtd service
   └─> VERIFY: Check virtualization support

2. Download required ISO files
   └─> Windows 11 installation ISO
   └─> virtio-win driver ISO (latest stable)
```

**Verification:**
```bash
# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Check KVM module loaded
lsmod | grep kvm
# Should show kvm_intel or kvm_amd

# Test libvirt connection
virsh list --all
# Should connect without errors
```

### Phase 2: VM Creation & Configuration

```
3. Create Windows 11 VM using virt-manager
   └─> Set Chipset to Q35
   └─> Set Firmware to OVMF (UEFI)
   └─> Enable Secure Boot in XML
   └─> Add TPM 2.0 device (TIS model)
   └─> Set CPU model to "host-passthrough"
   └─> Set disk bus to VirtIO
   └─> Set network model to VirtIO
   └─> Attach Windows 11 ISO to CDROM1
   └─> Attach virtio-win ISO to CDROM2

4. CRITICAL: Configure before first boot
   └─> Add Hyper-V enlightenments (virsh edit)
   └─> Add memory backing for virtio-fs (virsh edit)
   └─> Allocate resources (4+ vCPUs, 8+ GB RAM)
```

**CRITICAL DEPENDENCY:** Hyper-V enlightenments MUST be added before Windows installation for best stability.

### Phase 3: Windows Installation & Driver Loading

```
5. Boot VM and start Windows 11 installation
   └─> Proceed until "Where do you want to install Windows?" screen
   └─> **CRITICAL**: Click "Load Driver"
   └─> Browse to virtio-win ISO (E:)
   └─> Navigate to viostor\w11\amd64
   └─> Load driver
   └─> Continue Windows installation

6. Complete Windows 11 OOBE (Out-of-Box Experience)
   └─> Create local user or sign in with Microsoft account
   └─> Complete setup
```

**CRITICAL NOTE:** Windows installer will NOT see any disks until viostor driver is loaded.

### Phase 4: Post-Installation Driver Setup

```
7. Install remaining VirtIO drivers
   └─> Open Device Manager
   └─> For each "Unknown device":
       └─> Right-click > Update driver
       └─> Browse my computer for drivers
       └─> Point to virtio-win ISO root
       └─> Let Windows auto-detect and install
   └─> Reboot guest

8. Install WinFsp framework
   └─> Download winfsp-X.X.XXXXX.msi
   └─> Run installer as Administrator
   └─> Verify "WinFsp" services are running
```

**DEPENDENCY:** WinFsp MUST be installed BEFORE virtio-fs driver configuration.

### Phase 5: Filesystem Sharing Setup

```
9. Configure virtio-fs on host
   └─> Shut down VM
   └─> Add Filesystem hardware in virt-manager:
       - Driver: virtiofs
       - Source: /home/username/OutlookArchives
       - Target: linux-archives (mount tag)
   └─> Start VM

10. Configure virtio-fs in guest
    └─> Install/update "Mass storage controller" driver from virtio-win ISO
    └─> Install VirtIO-FS Service from ISO
    └─> Start "VirtIO-FS Service" in services.msc
    └─> Set to Automatic startup
    └─> Verify Z: drive appears in "This PC"
```

### Phase 6: Guest Agent & Automation

```
11. Install QEMU Guest Agent
    └─> Mount virtio-win ISO
    └─> Run qemu-ga-x86_64.msi
    └─> Verify service is running in services.msc
    └─> Set to Automatic startup

12. Verify host-to-guest communication
    └─> On host: virsh qemu-agent-command <vm_name> '{"execute":"guest-ping"}'
    └─> Should receive successful response
```

### Phase 7: Application Installation

```
13. Install Microsoft 365 in guest
    └─> Download from office.com
    └─> Run installer
    └─> Sign in with Microsoft account
    └─> Select "Classic Outlook" during setup
    └─> DO NOT use "New Outlook"

14. Configure Outlook for .pst access
    └─> Launch Outlook
    └─> File > Open & Export > Open Outlook Data File
    └─> Navigate to Z:\ (virtio-fs share)
    └─> Open .pst file
```

### Phase 8: Optional RemoteApp Integration

```
15. Configure RemoteApp (Windows 11 Pro/Enterprise only)
    └─> Enable Remote Desktop in Windows settings
    └─> Add registry keys for Outlook RemoteApp
    └─> Configure firewall rules

16. Configure FreeRDP on host
    └─> Install freerdp2-x11
    └─> Create launch script with xfreerdp command
    └─> Test seamless window mode
```

**NOTE:** RemoteApp is optional. Full desktop mode via virt-manager is more stable.

---

## 4. Driver Loading Process

### 4.1 During Windows Installation (Pre-OS)

**CRITICAL PHASE:** Storage driver must be loaded manually.

#### Step-by-Step Process

1. **Boot VM with two ISOs attached:**
   - CDROM1: Windows 11 installation ISO
   - CDROM2: virtio-win.iso

2. **Proceed through installer until disk selection:**
   - Language selection
   - "Install now"
   - Product key (skip if using digital license)
   - License terms
   - "Custom: Install Windows only (advanced)"

3. **CRITICAL STEP - Load Storage Driver:**
   ```
   Screen: "Where do you want to install Windows?"
   Visible: Empty disk list or "No drives were found"

   Actions:
   a. Click "Load driver" button (bottom left)
   b. Click "Browse" button
   c. Navigate to "D:" or "E:" (virtio-win CD)
   d. Navigate to: \viostor\w11\amd64\
   e. Click "OK"
   f. Select "Red Hat VirtIO SCSI controller"
   g. Click "Next"

   Result: Virtual disk now appears in list
   ```

4. **Complete installation:**
   - Select the now-visible disk
   - Click "Next"
   - Installation proceeds normally

**FAILURE MODE:** If you skip this step, Windows will show "We couldn't find any drives" error.

### 4.2 Post-Installation Driver Setup

**PHASE:** After Windows 11 is installed and booted.

#### Initial State

Device Manager will show multiple "Unknown devices" under "Other devices":
- Ethernet Controller (virtio-net)
- PCI Simple Communications Controller (virtio-serial)
- Mass Storage Controller (virtio-fs, if configured)
- Other PCI devices

#### Driver Installation Process

**Method 1: Automatic (Recommended)**

1. Open Device Manager (devmgmt.msc)
2. Right-click any "Unknown device"
3. Select "Update driver"
4. Choose "Browse my computer for drivers"
5. Click "Browse" and select the virtio-win CD-ROM drive root (E:)
6. Check "Include subfolders"
7. Click "Next"
8. Windows will automatically find and install correct driver
9. Repeat for each unknown device

**Method 2: Bulk Installation**

1. Mount virtio-win.iso
2. Run `virtio-win-guest-tools.exe` installer
3. This installs all drivers and guest agent in one step
4. Reboot after installation

**RECOMMENDED:** Use Method 1 for more control and troubleshooting visibility.

#### Critical Drivers and Their Purposes

| Device Manager Entry | Required Driver | Purpose | Priority |
|---------------------|-----------------|---------|----------|
| SCSI Controller (already installed) | viostor | Storage access | MANDATORY |
| Ethernet Controller | NetKVM | Network access | MANDATORY |
| PCI Simple Communications Controller | vioserial | Guest agent communication | HIGH |
| Mass Storage Controller | viofs | Filesystem sharing | HIGH |
| Display Adapter | viogpudo/QXL | Graphics performance | MEDIUM |
| Balloon | Balloon | Dynamic memory | LOW |

### 4.3 VirtIO-FS Specific Setup

**DEPENDENCY CHAIN:**
```
WinFsp Framework (installed first)
    ↓
VirtIO-FS Driver (from virtio-win.iso)
    ↓
VirtIO-FS Service (virtiofs.exe)
    ↓
Z: Drive appears in Windows
```

**Installation Steps:**

1. **Install WinFsp (prerequisite):**
   ```
   Download: winfsp-X.X.XXXXX.msi
   Run as Administrator
   Verify: services.msc shows WinFsp services
   ```

2. **Install VirtIO-FS driver:**
   ```
   Device Manager > Mass Storage Controller
   Update driver > Browse > virtio-win.iso
   Driver will auto-install from viofs\w11\amd64
   ```

3. **Install and start VirtIO-FS service:**
   ```
   Method A: Run virtiofs.exe from ISO manually
   Method B: Service may auto-install with driver

   Verify:
   - services.msc shows "VirtIO-FS Service"
   - Status: Running
   - Startup type: Automatic
   ```

4. **Verify mount:**
   ```
   Open "This PC"
   Should see network drive labeled with mount tag
   Default: Z:\ linux-archives (or your configured tag)
   ```

### 4.4 Device Manager Verification

**After all drivers installed, Device Manager should show:**

- Display adapters
  - Red Hat VirtIO GPU DOD controller (or QXL)
- Network adapters
  - Red Hat VirtIO Ethernet Adapter
- Storage controllers
  - Red Hat VirtIO SCSI controller
- System devices
  - VirtIO Balloon Driver
  - VirtIO Serial Driver
  - PCI standard RAM Controller

**NO "Unknown devices" should remain.**

---

## 5. Verification & Testing

### 5.1 Host Environment Verification

#### Test 1: CPU Virtualization Support

```bash
# Check for virtualization extensions
egrep -c '(vmx|svm)' /proc/cpuinfo
```

**Expected:** Number > 0 (typically equals CPU thread count)
**Failure:** If 0, virtualization is disabled in BIOS or not supported

#### Test 2: KVM Module

```bash
# Check KVM kernel module loaded
lsmod | grep kvm
```

**Expected Output:**
```
kvm_intel    (Intel CPUs)
or
kvm_amd      (AMD CPUs)
kvm          (always present)
```

#### Test 3: libvirt Connection

```bash
# Test libvirt daemon
virsh version
```

**Expected:** Version information for libvirt, QEMU, and kernel
**Failure:** Connection errors indicate service issues

#### Test 4: User Permissions

```bash
# Verify group membership
groups $USER | grep -E 'libvirt|kvm'
```

**Expected:** Both "libvirt" and "kvm" appear
**Failure:** Run usermod commands and re-login

#### Test 5: Network Bridge

```bash
# Check default network
virsh net-list --all
```

**Expected:**
```
 Name      State    Autostart
----------------------------------
 default   active   yes
```

**Fix if needed:**
```bash
virsh net-start default
virsh net-autostart default
```

### 5.2 VM Configuration Verification

#### Test 6: VM XML Validation

```bash
# Dump VM configuration
sudo virsh dumpxml <vm_name> > vm-config.xml

# Check critical elements
grep -A 5 "<hyperv" vm-config.xml    # Hyper-V enlightenments
grep -A 3 "<memoryBacking" vm-config.xml  # virtio-fs requirement
grep "host-passthrough" vm-config.xml     # CPU passthrough
grep "OVMF" vm-config.xml                  # UEFI firmware
grep "tpm" vm-config.xml                   # TPM device
```

**Expected:** All elements present and properly configured

#### Test 7: VM Boot Test

```bash
# Start VM
virsh start <vm_name>

# Monitor for errors
virsh dominfo <vm_name>
```

**Expected:** State shows "running"
**Check logs if failed:**
```bash
journalctl -u libvirtd -f
```

### 5.3 Windows Guest Verification

#### Test 8: Driver Installation Check

**In Windows Guest:**

1. Open Device Manager (devmgmt.msc)
2. Verify NO "Unknown devices" in "Other devices"
3. Expand "Storage controllers"
   - Should see "Red Hat VirtIO SCSI controller"
4. Expand "Network adapters"
   - Should see "Red Hat VirtIO Ethernet Adapter"

**Command-Line Verification:**
```powershell
# In Windows PowerShell
Get-PnpDevice | Where-Object {$_.Status -eq "Error" -or $_.Status -eq "Unknown"}
```

**Expected:** No output (no problematic devices)

#### Test 9: Network Connectivity

**In Windows Guest:**

```cmd
# Test external connectivity
ping 8.8.8.8

# Test DNS resolution
ping google.com

# Check IP configuration
ipconfig /all
```

**Expected:** Successful pings and valid IP from libvirt network (usually 192.168.122.x)

#### Test 10: VirtIO-FS Mount Verification

**In Windows Guest:**

1. Open "This PC"
2. Verify network drive with your mount tag name (e.g., Z:)
3. Open the drive
4. Create test file

**Command-Line Test:**
```cmd
# Check drive exists
net use

# Test read/write
echo test > Z:\testfile.txt
type Z:\testfile.txt
del Z:\testfile.txt
```

**On Host (verify same file):**
```bash
# Should see the same operations in your shared folder
ls -l /home/username/OutlookArchives/
```

### 5.4 Guest Agent Verification

#### Test 11: Guest Agent Communication

```bash
# Test basic ping
virsh qemu-agent-command <vm_name> '{"execute":"guest-ping"}'
```

**Expected Output:**
```json
{"return":{}}
```

#### Test 12: Guest Agent Commands

```bash
# Get guest OS info
virsh qemu-agent-command <vm_name> '{"execute":"guest-get-osinfo"}' --pretty

# List filesystems
virsh domfsinfo <vm_name>

# Get time
virsh qemu-agent-command <vm_name> '{"execute":"guest-get-time"}' --pretty
```

**Expected:** JSON responses with guest information

#### Test 13: Remote Command Execution

```bash
# Execute command in guest
virsh qemu-agent-command <vm_name> \
  '{"execute":"guest-exec","arguments":{"path":"cmd.exe","arg":["/c","echo","hello"]}}'
```

**Expected:** Returns PID of executed process
**Failure:** Check guest agent service is running in Windows

### 5.5 Performance Verification

#### Test 14: CPU Performance

**In Windows Guest:**

```powershell
# Check CPU model
Get-WmiObject Win32_Processor | Select-Object Name
```

**Expected:** Should show your HOST CPU model (due to host-passthrough)
**Poor Performance Indicator:** Shows generic QEMU CPU

#### Test 15: Storage Performance

**In Windows Guest:**

```powershell
# Quick disk benchmark (requires admin)
winsat disk -drive c
```

**Expected:** Sequential read/write > 500 MB/s with VirtIO
**Poor Performance:** < 100 MB/s indicates non-VirtIO driver

#### Test 16: Graphics Performance

**In Windows Guest:**

1. Open Outlook or any Office app
2. Scroll through emails/documents
3. Resize windows

**Expected:** Smooth, responsive GUI
**Poor Performance Indicators:**
- Choppy scrolling
- Slow window redraws
- High CPU usage during GUI operations

**Fix:** Verify VirtIO GPU driver installed and 3D acceleration enabled

### 5.6 Microsoft 365 Outlook Verification

#### Test 17: Outlook Installation

**In Windows Guest:**

1. Launch Outlook
2. Sign in with Microsoft 365 account
3. Verify mailbox sync

**Command-Line Check:**
```powershell
# Find Outlook executable
Get-ChildItem "C:\Program Files\Microsoft Office" -Recurse -Filter "OUTLOOK.EXE"
```

**Expected:** Should find OUTLOOK.EXE in Office16 or Office17 folder

#### Test 18: PST File Access

**In Windows Guest:**

1. Launch Outlook
2. File > Open & Export > Open Outlook Data File
3. Navigate to Z:\ (virtio-fs share)
4. Create or open .pst file

**Expected:** File opens successfully and appears in Outlook sidebar

**Test Read/Write:**
1. Create test folder in .pst
2. Move email to test folder
3. Verify on host:
   ```bash
   # PST file should show updated timestamp
   ls -l /home/username/OutlookArchives/*.pst
   ```

### 5.7 Automation Verification

#### Test 19: VM Lifecycle Automation

```bash
# Test shutdown
virsh shutdown <vm_name> --mode=agent

# Wait and check
sleep 10
virsh domstate <vm_name>
```

**Expected:** Shows "shut off"

```bash
# Test start
virsh start <vm_name>

# Test reboot
virsh reboot <vm_name> --mode=agent
```

#### Test 20: Script-Based Automation

**Create test script:**

```bash
#!/bin/bash
VM_NAME="win11-outlook"

# Start VM
virsh start "$VM_NAME"

# Wait for agent
echo "Waiting for guest agent..."
until virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-ping"}' 2>/dev/null; do
  sleep 2
done

# Execute command
echo "Launching Outlook..."
virsh qemu-agent-command "$VM_NAME" \
  '{"execute":"guest-exec","arguments":{"path":"C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"}}'

echo "Automation complete"
```

**Test:**
```bash
chmod +x test-automation.sh
./test-automation.sh
```

**Expected:** VM starts, agent responds, Outlook launches in guest

---

## 6. Common Pitfalls & Troubleshooting

### 6.1 Installation Phase Issues

#### Issue 1: "We couldn't find any drives"

**Symptom:** Windows installer shows no disks available

**Cause:** VirtIO storage driver not loaded

**Solution:**
1. Click "Load driver"
2. Browse to virtio-win ISO
3. Navigate to viostor\w11\amd64
4. Load Red Hat VirtIO SCSI controller driver

#### Issue 2: "This PC can't run Windows 11"

**Symptom:** Windows installer refuses to proceed

**Cause:** Missing TPM 2.0 or Secure Boot configuration

**Solution:**
```bash
# Verify VM has TPM
sudo virsh dumpxml <vm_name> | grep -A 5 tpm

# Should show TPM 2.0 TIS device
# If missing, add via virt-manager:
# Add Hardware > TPM > Model: TIS, Version: 2.0
```

#### Issue 3: VM won't boot (black screen)

**Symptom:** VM starts but shows black screen or UEFI shell

**Cause:** OVMF firmware not properly configured

**Solution:**
```bash
# Check firmware setting
sudo virsh dumpxml <vm_name> | grep loader

# Should show OVMF_CODE path
# Fix in virt-manager: Overview > Firmware > Select UEFI
```

### 6.2 Performance Issues

#### Issue 4: High CPU usage / slow GUI

**Symptom:** VM uses 100% CPU, Office apps are laggy

**Causes & Solutions:**

**Cause A:** Missing Hyper-V enlightenments
```bash
# Add enlightenments via virsh edit
# See Section 4.4 of guide for full XML block
```

**Cause B:** Over-provisioned resources
```bash
# Check host CPU count
nproc

# VM should use LESS than total cores
# Recommended: 4 vCPUs for guest, rest for host
```

**Cause C:** QXL graphics instead of VirtIO
```bash
# Change video model in virt-manager:
# Video > Model > VirtIO
# Enable 3D acceleration
```

#### Issue 5: Network is slow

**Symptom:** Downloads are slow, web browsing lags

**Cause:** Not using VirtIO network driver

**Solution:**
```bash
# Check network model
sudo virsh dumpxml <vm_name> | grep -A 3 "interface type"

# Should show: <model type='virtio'/>
# If not, change in virt-manager: NIC > Device model > virtio
```

### 6.3 Filesystem Sharing Issues

#### Issue 6: Z: drive doesn't appear

**Symptom:** No virtio-fs drive visible in Windows

**Checklist:**

1. **Check WinFsp installed:**
   ```powershell
   # In Windows
   Get-Service | Where-Object {$_.Name -like "*winfsp*"}
   ```
   Should show WinFsp services running

2. **Check memory backing on host:**
   ```bash
   sudo virsh dumpxml <vm_name> | grep -A 2 memoryBacking
   ```
   Should show shared memory configuration

3. **Check filesystem device added:**
   ```bash
   sudo virsh dumpxml <vm_name> | grep -A 5 filesystem
   ```
   Should show virtiofs with source and target paths

4. **Check VirtIO-FS service in guest:**
   ```powershell
   # In Windows
   Get-Service "VirtIO-FS Service"
   ```
   Should show "Running"

**Solution:** Restart VirtIO-FS service:
```powershell
Restart-Service "VirtIO-FS Service"
```

#### Issue 7: "Access denied" on virtio-fs share

**Symptom:** Can see Z: drive but can't access files

**Cause:** Permission mismatch between host and guest

**Solution on host:**
```bash
# Make shared folder world-readable (or set specific permissions)
chmod 755 /home/username/OutlookArchives
chmod 644 /home/username/OutlookArchives/*.pst
```

### 6.4 Guest Agent Issues

#### Issue 8: Guest agent commands fail

**Symptom:** `virsh qemu-agent-command` returns errors

**Checklist:**

1. **Verify channel in VM XML:**
   ```bash
   sudo virsh dumpxml <vm_name> | grep -A 5 "channel type"
   ```
   Should show org.qemu.guest_agent.0

2. **Check service in Windows:**
   ```powershell
   Get-Service "QEMU Guest Agent"
   ```
   Should show "Running"

3. **Restart agent service:**
   ```powershell
   Restart-Service "QEMU Guest Agent"
   ```

4. **Check socket on host:**
   ```bash
   ls -la /var/lib/libvirt/qemu/channel/target/domain-*/
   ```
   Should show socket file

#### Issue 9: guest-exec commands don't work

**Symptom:** Commands return PID but nothing executes

**Cause:** Path escaping issues in JSON

**Solution:** Use double backslashes in Windows paths:
```bash
# WRONG:
'{"execute":"guest-exec","arguments":{"path":"C:\Windows\System32\cmd.exe"}}'

# CORRECT:
'{"execute":"guest-exec","arguments":{"path":"C:\\Windows\\System32\\cmd.exe"}}'
```

### 6.5 Microsoft 365 Outlook Issues

#### Issue 10: Can't open .pst files

**Symptom:** Outlook can't open .pst on Z: drive

**Causes & Solutions:**

**Cause A:** Using "New Outlook"
```
Solution: Switch to "Classic Outlook"
Settings > General > About Outlook > "Revert" button
```

**Cause B:** File permissions
```bash
# On host, ensure .pst is readable
chmod 644 /path/to/archive.pst
```

**Cause C:** Network drive limitation
```
Some Outlook versions restrict .pst on network drives
Workaround: Copy .pst to C:\ temporarily for initial setup
Then move back to Z: after Outlook recognizes it
```

#### Issue 11: Outlook won't sign in

**Symptom:** Microsoft 365 authentication fails

**Cause:** Network/firewall issues or date/time mismatch

**Solution:**
```powershell
# In Windows, sync time
w32tm /resync

# Check internet connectivity
Test-NetConnection outlook.office365.com -Port 443

# Disable firewall temporarily to test
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

### 6.6 RemoteApp Issues (Optional)

#### Issue 12: RemoteApp windows crash on second monitor

**Symptom:** Seamless windows bug out when dragged to second screen

**Cause:** Known RDP RemoteApp multi-monitor bug

**Solutions:**

**Option A:** Use single monitor for RDP session
```bash
xfreerdp /v:<vm_ip> /app:"||outlook" /monitors:0
```

**Option B:** Abandon RemoteApp, use full desktop
```
Simply use virt-manager window for VM
More stable and predictable
```

**Option C:** Use VM on separate virtual desktop
```
Leverage Ubuntu's workspace/virtual desktop feature
Swipe to dedicated Windows VM desktop
```

---

## Summary Checklist

### Pre-Installation Downloads

- [ ] Ubuntu 25.10 ISO (if fresh install needed)
- [ ] Windows 11 ISO from Microsoft
- [ ] virtio-win.iso (latest stable from Fedora)
- [ ] WinFsp installer (winfsp-X.X.XXXXX.msi)

### Host Setup

- [ ] Install virtualization packages
- [ ] Add user to libvirt/kvm groups
- [ ] Enable libvirtd service
- [ ] Verify CPU virtualization support
- [ ] Test virsh connectivity

### VM Creation

- [ ] Create VM with Q35 chipset
- [ ] Set OVMF UEFI firmware
- [ ] Add TPM 2.0 device
- [ ] Set CPU to host-passthrough
- [ ] Configure VirtIO disk and network
- [ ] Add Hyper-V enlightenments (virsh edit)
- [ ] Add memory backing (virsh edit)
- [ ] Attach Windows 11 and virtio-win ISOs

### Windows Installation

- [ ] Boot VM
- [ ] Load viostor driver at disk selection
- [ ] Complete Windows installation
- [ ] Install all VirtIO drivers (Device Manager)
- [ ] Verify no "Unknown devices" remain

### Filesystem Sharing

- [ ] Install WinFsp in Windows guest
- [ ] Add virtio-fs filesystem in virt-manager
- [ ] Install virtio-fs driver in guest
- [ ] Start VirtIO-FS service
- [ ] Verify Z: drive appears
- [ ] Test read/write to share

### Guest Agent

- [ ] Install qemu-ga-x86_64.msi in guest
- [ ] Verify service running and automatic
- [ ] Test guest-ping from host
- [ ] Test guest-exec command

### Microsoft 365

- [ ] Install Microsoft 365 in guest
- [ ] Sign in with account
- [ ] Launch Classic Outlook (not New Outlook)
- [ ] Open .pst file from Z: drive
- [ ] Verify email sync working

### Optional RemoteApp

- [ ] Enable Remote Desktop (Windows Pro/Enterprise)
- [ ] Add registry keys for RemoteApp
- [ ] Install freerdp2-x11 on host
- [ ] Test seamless window launch
- [ ] OR: Skip and use full desktop mode

### Verification

- [ ] All drivers installed and working
- [ ] Network connectivity functional
- [ ] virtio-fs share accessible
- [ ] Guest agent responding
- [ ] Outlook can access .pst files
- [ ] Performance acceptable (smooth GUI)
- [ ] Automation scripts working

---

## Quick Reference Commands

### Host Management

```bash
# List all VMs
virsh list --all

# Start VM
virsh start <vm_name>

# Shutdown VM gracefully
virsh shutdown <vm_name> --mode=agent

# Force stop VM
virsh destroy <vm_name>

# Edit VM configuration
sudo virsh edit <vm_name>

# View VM details
virsh dominfo <vm_name>

# Test guest agent
virsh qemu-agent-command <vm_name> '{"execute":"guest-ping"}'

# List guest filesystems
virsh domfsinfo <vm_name>

# Execute command in guest
virsh qemu-agent-command <vm_name> \
  '{"execute":"guest-exec","arguments":{"path":"C:\\Windows\\System32\\cmd.exe","arg":["/c","echo","test"]}}'
```

### Windows Guest Verification

```powershell
# Check drivers
Get-PnpDevice | Where-Object {$_.Status -eq "Error"}

# Check services
Get-Service | Where-Object {$_.Name -like "*virtio*" -or $_.Name -like "*qemu*" -or $_.Name -like "*winfsp*"}

# Test virtio-fs mount
Test-Path Z:\

# Check Outlook installation
Get-ChildItem "C:\Program Files\Microsoft Office" -Recurse -Filter "OUTLOOK.EXE"

# Check network
Test-NetConnection google.com
```

---

## Additional Resources

- **QEMU Documentation:** https://www.qemu.org/docs/master/
- **libvirt Documentation:** https://libvirt.org/docs.html
- **VirtIO Drivers:** https://fedoraproject.org/wiki/Windows_Virtio_Drivers
- **WinFsp Project:** https://winfsp.dev/
- **virt-manager Guide:** https://virt-manager.org/
- **QEMU Guest Agent Protocol:** https://wiki.qemu.org/Features/GuestAgent

---

**Document Version:** 1.0
**Last Updated:** November 14, 2025
**Based on:** outlook-linux-guide documentation (sections 01-08)
