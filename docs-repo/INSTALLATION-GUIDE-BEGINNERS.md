# QEMU/KVM Installation Guide for Complete Beginners

## What You're About to Install (Plain English)

### The Big Picture
You're installing **virtualization software** that lets you run Windows 11 as a "guest" inside your Ubuntu Linux system (the "host"). Think of it like running Windows in a secure, isolated container.

**Why QEMU/KVM?**
- **Free and open-source** (no licensing costs)
- **Near-native performance** (85-95% of native Windows speed when optimized)
- **Secure isolation** (Windows runs in a sandbox, can't harm your Ubuntu system)
- **Professional-grade** (used by cloud providers like AWS, Google Cloud)

### What Each Package Does

| Package Name | What It Does (Beginner-Friendly) | Why You Need It |
|--------------|----------------------------------|-----------------|
| **qemu-kvm** | The core virtualization engine | Creates and runs the virtual Windows computer |
| **libvirt-daemon-system** | Management service that runs in background | Controls VMs automatically, handles startup/shutdown |
| **libvirt-clients** | Command-line tools (virsh) | Lets you control VMs from terminal |
| **bridge-utils** | Network bridge tools | Connects VM to internet (NAT or bridged mode) |
| **virt-manager** | Graphical management interface | User-friendly GUI to manage VMs (like VirtualBox UI) |
| **ovmf** | UEFI firmware for VMs | Modern boot system (required for Windows 11) |
| **swtpm** | Software TPM 2.0 emulator | Security chip emulation (Windows 11 requirement) |
| **qemu-utils** | QEMU utility tools | Disk image management (create, resize, convert) |
| **guestfs-tools** | Guest filesystem tools | Access VM files from host for maintenance |
| **virt-top** | VM performance monitor | Like 'top' but for virtual machines |

### Installation Size & Time
- **Download size**: ~250-300 MB
- **Installed size**: ~800 MB
- **Installation time**: 5-10 minutes (depending on internet speed)
- **Disk space required**: Minimum 2GB free (recommended 5GB for safety)

---

## Installation Process Explained

### Phase 1: Pre-Installation Checks ✅

**What happens**: Verify your system meets requirements
**Duration**: 2 minutes
**What to expect**: Commands will output hardware info
**Potential issues**: If virtualization not enabled, you'll need to enable it in BIOS

```bash
# Check CPU virtualization support (must be > 0)
egrep -c '(vmx|svm)' /proc/cpuinfo
# Expected output: A number > 0 (e.g., 16 for 16-core CPU)
# If 0: Virtualization disabled in BIOS - reboot and enable VT-x/AMD-V

# Check available RAM (minimum 16GB recommended)
free -h
# Look for "total" column in "Mem:" row
# Example output: "Mem:  76Gi" means 76GB total RAM

# Check disk is SSD (rota=0 means SSD, rota=1 means HDD)
lsblk -d -o name,rota
# Expected output: nvme0n1  0 (SSD)
# If HDD (rota=1): Installation will work but VM performance will be poor

# Check available disk space (minimum 150GB free)
df -h /home
# Look for "Avail" column
# Example output: "Avail: 1.4T" means 1.4 terabytes free
```

**What success looks like**:
- ✅ CPU virtualization: 16 (or any number > 0)
- ✅ RAM: 76Gi total (or 16Gi minimum)
- ✅ Storage: SSD with 1.4T available
- ✅ All requirements met - proceed to installation

---

### Phase 2: Update Package Cache 🔄

**What happens**: Ubuntu downloads latest package information
**Duration**: 30-60 seconds
**What to expect**: You'll see "Reading package lists..." and download progress
**Why necessary**: Ensures you get the latest stable versions of packages

```bash
sudo apt update
```

**What you'll see**:
```
Hit:1 http://archive.ubuntu.com/ubuntu oracular InRelease
Get:2 http://security.ubuntu.com/ubuntu oracular-security InRelease [126 kB]
...
Reading package lists... Done
Building dependency tree... Done
```

**What success looks like**:
- ✅ No error messages
- ✅ Ends with "Reading package lists... Done"
- ✅ Ready to proceed to package installation

**Potential issues**:
- ❌ "Could not resolve host" - Check internet connection
- ❌ "Failed to fetch" - Try again, might be temporary server issue

---

### Phase 3: Install QEMU/KVM Packages 📦

**What happens**: Ubuntu downloads and installs 10 virtualization packages
**Duration**: 5-10 minutes
**What to expect**: Download progress bars, installation output, configuration messages
**Disk space used**: ~800 MB after installation

```bash
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    ovmf \
    swtpm \
    qemu-utils \
    guestfs-tools \
    virt-top
```

**Breaking down this command**:
- `sudo` - Run as administrator (will prompt for password)
- `apt install` - Ubuntu's package installer
- `-y` - Automatically answer "yes" to prompts (non-interactive)
- `\` - Line continuation (makes long command readable)

**What you'll see** (normal output):
```
Reading package lists... Done
Building dependency tree... Done
The following additional packages will be installed:
  ... (long list of dependencies)
The following NEW packages will be installed:
  qemu-kvm libvirt-daemon-system ... (10 packages)
0 upgraded, 85 newly installed, 0 to remove
Need to get 250 MB of archives.
After this operation, 800 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu oracular/main amd64 qemu-kvm ...
...
Setting up qemu-kvm ...
Setting up libvirt-daemon-system ...
Created symlink /etc/systemd/system/multi-user.target.wants/libvirtd.service
```

**What success looks like**:
- ✅ All packages download successfully (100% progress)
- ✅ "Setting up [package-name]..." for each package
- ✅ No error messages (warnings are usually OK)
- ✅ Returns to command prompt

**Potential issues**:
- ❌ "Unable to locate package" - Run `sudo apt update` again
- ❌ "Could not get lock" - Another apt process running, wait and retry
- ❌ "Insufficient space" - Free up disk space (need 2GB minimum)

---

### Phase 4: Configure User Permissions 👤

**What happens**: Add your user account to 'libvirt' and 'kvm' groups
**Duration**: 5 seconds
**What to expect**: Commands execute silently (no output = success)
**Why necessary**: Without this, you'd need `sudo` for every VM operation

```bash
# Add user 'kkk' to libvirt group (VM management permissions)
sudo usermod -aG libvirt kkk

# Add user 'kkk' to kvm group (hardware virtualization access)
sudo usermod -aG kvm kkk
```

**Breaking down this command**:
- `sudo` - Run as administrator (modifying user permissions requires root)
- `usermod` - Modify user account settings
- `-aG` - **a**ppend to **G**roup (adds group without removing existing ones)
- `libvirt` / `kvm` - Group names to add user to
- `kkk` - Your username (replace with yours if different)

**What you'll see**:
- (No output is normal - success!)

**Verify it worked** (PRE-REBOOT - groups may not show yet):
```bash
# Check user groups (new groups won't show until you log out/in)
groups kkk
# Output: kkk adm cdrom sudo dip plugdev users lpadmin
# Note: libvirt and kvm NOT shown yet - this is NORMAL before reboot
```

**What success looks like**:
- ✅ Commands execute without errors
- ✅ No output (silent success)
- ✅ Groups will be active after logout/reboot

**Important**:
- ⚠️ Group membership changes require **logout and login** (or reboot) to take effect
- ⚠️ Don't worry if `groups` command doesn't show libvirt/kvm yet - this is normal
- ⚠️ Verification happens in Phase 6 (after reboot)

---

### Phase 5: System Reboot (REQUIRED) 🔄

**What happens**: Restart your computer to activate group membership changes
**Duration**: 2-3 minutes (normal reboot time)
**Why necessary**: Linux only applies group changes after new login session
**What to expect**: Normal system reboot, save your work first

```bash
# Save all open documents and applications first!
sudo reboot
```

**Before rebooting**:
- ✅ Save all open documents
- ✅ Close applications
- ✅ Note this guide's location to continue after reboot
- ✅ Bookmark this page or remember path: `/home/kkk/Apps/win-qemu/docs-repo/INSTALLATION-GUIDE-BEGINNERS.md`

**What you'll see**:
- Ubuntu logout screen
- System restart
- Login prompt
- Normal desktop after login

**After reboot**:
- ✅ Log back in with your password
- ✅ Open terminal
- ✅ Continue to Phase 6 (Verification)

---

### Phase 6: Post-Reboot Verification ✅

**What happens**: Verify QEMU/KVM installed correctly and services are running
**Duration**: 2 minutes
**What to expect**: Each command shows status/version information
**Why necessary**: Confirm everything works before creating VMs

#### Test 1: Check virsh version
```bash
virsh --version
# Expected output: 10.0.0 (or similar version number)
# ✅ Success: Version number displayed
# ❌ Failure: "command not found" - libvirt-clients not installed
```

#### Test 2: Verify libvirtd service is running
```bash
systemctl status libvirtd
# Expected output:
# ● libvirtd.service - Virtualization daemon
#    Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; ...)
#    Active: active (running) since Sun 2025-11-17 18:30:00 UTC; 5min ago
#
# ✅ Success: "Active: active (running)" in green
# ❌ Failure: "Active: inactive (dead)" - service not started
```

**What this means**:
- **Loaded: loaded** - Service installed correctly
- **Active: active (running)** - Service is currently running
- **enabled** - Service starts automatically on boot

**If service not running**, start it:
```bash
sudo systemctl start libvirtd
sudo systemctl enable libvirtd  # Start on boot
```

#### Test 3: Confirm group membership (POST-REBOOT)
```bash
groups
# Expected output: kkk adm cdrom sudo dip plugdev users lpadmin libvirt kvm
#                                                                    ^^^^^^^ ^^^
# ✅ Success: Both 'libvirt' and 'kvm' appear in the list
# ❌ Failure: Missing groups - re-run usermod commands from Phase 4
```

#### Test 4: Test basic virsh functionality
```bash
virsh list --all
# Expected output:
#  Id   Name   State
# --------------------
# (Empty table is normal - no VMs created yet)
#
# ✅ Success: Table displays (even if empty)
# ❌ Failure: Permission denied - group membership issue
```

#### Test 5: Verify KVM kernel module loaded
```bash
lsmod | grep kvm
# Expected output (for Intel):
# kvm_intel         114688  0
# kvm              1249280  1 kvm_intel
#
# Expected output (for AMD):
# kvm_amd           114688  0
# kvm              1249280  1 kvm_amd
#
# ✅ Success: kvm_intel or kvm_amd shown
# ❌ Failure: No output - virtualization disabled in BIOS
```

#### Test 6: Check QEMU can access virtualization
```bash
kvm-ok
# Expected output:
# INFO: /dev/kvm exists
# KVM acceleration can be used
#
# ✅ Success: "KVM acceleration can be used"
# ❌ Failure: "KVM acceleration cannot be used" - BIOS virtualization disabled
```

**If kvm-ok not found**:
```bash
sudo apt install cpu-checker
kvm-ok
```

#### Test 7: Verify default network exists
```bash
virsh net-list --all
# Expected output:
#  Name      State    Autostart   Persistent
# ---------------------------------------------
#  default   active   yes         yes
#
# ✅ Success: 'default' network shows as 'active'
# ❌ Failure: Network not active - need to start it
```

**If default network not active**:
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## Verification Checklist

### ✅ Installation Success Criteria

After completing all phases, you should have:

- [x] **virsh version** displays successfully (e.g., 10.0.0)
- [x] **libvirtd service** active and running
- [x] **User groups** include both 'libvirt' and 'kvm'
- [x] **virsh list --all** executes without permission errors
- [x] **KVM module** loaded (kvm_intel or kvm_amd shown)
- [x] **kvm-ok** confirms acceleration available
- [x] **Default network** active and autostart enabled

### 🎯 What Success Looks Like (Summary)

```bash
# Quick validation script (run all tests at once)
echo "=== QEMU/KVM Installation Verification ===" && \
echo "" && \
echo "1. virsh version:" && \
virsh --version && \
echo "" && \
echo "2. libvirtd service:" && \
systemctl is-active libvirtd && \
echo "" && \
echo "3. User groups:" && \
groups | grep -E 'libvirt|kvm' && \
echo "" && \
echo "4. KVM module:" && \
lsmod | grep kvm && \
echo "" && \
echo "5. Default network:" && \
virsh net-list --all && \
echo "" && \
echo "=== Verification Complete ==="
```

**Expected output** (all ✅):
```
=== QEMU/KVM Installation Verification ===

1. virsh version:
10.0.0

2. libvirtd service:
active

3. User groups:
kkk adm cdrom sudo dip plugdev users lpadmin libvirt kvm

4. KVM module:
kvm_intel         114688  0
kvm              1249280  1 kvm_intel

5. Default network:
 Name      State    Autostart   Persistent
---------------------------------------------
 default   active   yes         yes

=== Verification Complete ===
```

---

## Troubleshooting Common Issues

### Issue 1: "virsh: command not found"

**Cause**: libvirt-clients package not installed

**Solution**:
```bash
sudo apt install libvirt-clients
virsh --version  # Verify installation
```

---

### Issue 2: "Permission denied" when running virsh

**Cause**: User not in libvirt/kvm groups OR haven't logged out/in after adding groups

**Solution**:
```bash
# Check if in groups
groups | grep libvirt

# If NOT in groups, add user:
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# MUST log out and back in (or reboot)
# Then verify:
groups | grep libvirt  # Should now show: libvirt kvm
```

---

### Issue 3: "KVM acceleration cannot be used"

**Cause**: Virtualization disabled in BIOS/UEFI

**Solution**:
1. Reboot computer
2. Enter BIOS/UEFI setup (usually F2, F10, Del, or Esc during boot)
3. Navigate to CPU or Advanced settings
4. Enable Intel VT-x (Intel) or AMD-V (AMD)
5. Save and exit BIOS
6. Boot Ubuntu and test: `kvm-ok`

---

### Issue 4: libvirtd service not running

**Cause**: Service failed to start or not enabled

**Solution**:
```bash
# Check detailed status
sudo systemctl status libvirtd

# Start service manually
sudo systemctl start libvirtd

# Enable automatic startup
sudo systemctl enable libvirtd

# Verify it's running
systemctl is-active libvirtd  # Should output: active
```

---

### Issue 5: Default network not active

**Cause**: Network not started or autostart disabled

**Solution**:
```bash
# Start default network
sudo virsh net-start default

# Enable autostart
sudo virsh net-autostart default

# Verify
virsh net-list --all
# Should show: default   active   yes   yes
```

---

## Next Steps After Successful Installation

### You're now ready for:

1. **VirtIO Drivers ISO Download** (if not already downloaded)
   - File: `virtio-win-0.1.285-1.iso` (~753 MB)
   - Location: `/home/kkk/Apps/win-qemu/source-iso/`

2. **Windows 11 VM Creation**
   - Use automated script (to be created): `scripts/create-vm.sh`
   - Or follow manual guide: `outlook-linux-guide/05-qemu-kvm-reference-architecture.md`

3. **Performance Optimization**
   - Apply Hyper-V enlightenments (14 features)
   - Configure CPU pinning and huge pages
   - Guide: `outlook-linux-guide/09-performance-optimization-playbook.md`

4. **Security Hardening**
   - Configure firewall (UFW with M365 whitelist)
   - Enable LUKS encryption
   - Setup virtio-fs read-only sharing
   - Guide: `research/06-security-hardening-analysis.md`

5. **Automation Setup**
   - Install QEMU guest agent
   - Create management scripts
   - Guide: `outlook-linux-guide/07-automation-engine.md`

---

## Understanding What You Installed (Deep Dive)

### The Virtualization Stack (Bottom to Top)

```
┌─────────────────────────────────────────────┐
│   virt-manager (GUI)                        │  <- You interact here
│   virsh (CLI)                               │
├─────────────────────────────────────────────┤
│   libvirt (Management API)                  │  <- Abstraction layer
├─────────────────────────────────────────────┤
│   QEMU (Emulation) + KVM (Acceleration)     │  <- Virtualization engine
├─────────────────────────────────────────────┤
│   Linux Kernel (KVM module)                 │  <- Hardware interface
├─────────────────────────────────────────────┤
│   Hardware (CPU VT-x/AMD-V, RAM, SSD)       │  <- Physical machine
└─────────────────────────────────────────────┘
```

**How it works**:
1. **Hardware** provides virtualization support (Intel VT-x or AMD-V)
2. **KVM kernel module** exposes hardware virtualization to userspace
3. **QEMU** emulates PC hardware (disk, network, graphics, etc.)
4. **KVM accelerates** CPU instructions (runs at near-native speed)
5. **libvirt** manages VMs, networks, storage (unified API)
6. **virsh/virt-manager** provide user interfaces to control everything

### Why This Approach vs VirtualBox/VMware?

| Feature | QEMU/KVM | VirtualBox | VMware Workstation |
|---------|----------|------------|-------------------|
| **License** | Free, open-source | Free (personal use) | $200+ (commercial) |
| **Performance** | 85-95% native | 60-75% native | 80-90% native |
| **Integration** | Linux kernel | Separate kernel module | Proprietary kernel module |
| **Professional Use** | Cloud providers | Desktop testing | Enterprise VMs |
| **Learning Curve** | Steeper (more powerful) | Gentle | Moderate |
| **Windows 11 Support** | Excellent (TPM 2.0, UEFI) | Good | Excellent |

**QEMU/KVM advantages**:
- ✅ Best performance (kernel-level acceleration)
- ✅ Production-grade (AWS, Google Cloud use it)
- ✅ Complete control (fine-tune every aspect)
- ✅ Active development (latest features first)

**QEMU/KVM challenges**:
- ❌ Steeper learning curve (more concepts to learn)
- ❌ More manual configuration (less "wizard-driven")
- ❌ Requires understanding of virtualization concepts

---

## Glossary of Terms

**Virtualization**: Running multiple operating systems simultaneously on one physical computer

**Host**: Your Ubuntu system (the physical computer)

**Guest**: The Windows 11 VM (the virtualized computer)

**Hypervisor**: Software that creates and manages VMs (QEMU/KVM in this case)

**Type 1 Hypervisor**: Runs directly on hardware (e.g., VMware ESXi, Proxmox)

**Type 2 Hypervisor**: Runs on top of host OS (e.g., VirtualBox, QEMU/KVM on Linux)

**KVM**: Kernel-based Virtual Machine - Linux kernel module for hardware acceleration

**QEMU**: Quick Emulator - Emulates PC hardware for VMs

**libvirt**: Management API and daemon for controlling VMs

**virsh**: Command-line tool to manage VMs via libvirt

**virt-manager**: Graphical tool to manage VMs via libvirt

**VirtIO**: Paravirtualized drivers for high-performance disk/network/graphics in VMs

**Paravirtualization**: Guest OS knows it's virtualized and uses optimized drivers

**Q35**: Modern chipset emulation (PCI-Express support, like Intel Q35 Express)

**UEFI**: Modern firmware (replacement for legacy BIOS)

**OVMF**: Open Virtual Machine Firmware - UEFI implementation for VMs

**TPM 2.0**: Trusted Platform Module - Security chip (required for Windows 11)

**swtpm**: Software TPM - Emulates TPM 2.0 for VMs

**NAT**: Network Address Translation - VM shares host's IP address

**Bridged Network**: VM gets its own IP address on physical network

**virtio-fs**: VirtIO filesystem sharing (high-performance file sharing between host and guest)

**Snapshot**: Point-in-time backup of VM state (can restore to this state later)

**QCOW2**: QEMU Copy-On-Write v2 - Disk image format (compressed, supports snapshots)

---

## Getting Help

**Official Documentation**:
- QEMU: https://www.qemu.org/documentation/
- libvirt: https://libvirt.org/docs.html
- KVM: https://www.linux-kvm.org/

**Community Support**:
- Ubuntu Forums: https://ubuntuforums.org/
- Reddit r/VFIO: https://www.reddit.com/r/VFIO/
- libvirt mailing list: https://libvirt.org/contact.html

**Project Documentation**:
- Main guide: `/home/kkk/Apps/win-qemu/outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- Research index: `/home/kkk/Apps/win-qemu/research/00-RESEARCH-INDEX.md`
- Troubleshooting: `/home/kkk/Apps/win-qemu/research/07-troubleshooting-failure-modes.md`

---

*This guide was created to help complete beginners understand QEMU/KVM installation.*
*If you found something confusing or have suggestions, please update this document!*

**Created**: 2025-11-17
**Version**: 1.0
**Status**: Initial installation guide for Ubuntu 25.10
