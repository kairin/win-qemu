# Getting Started: VM Creation Workflow

**Purpose**: Step-by-step guide for first-time VM creation
**Audience**: Users who have NEVER created a QEMU/KVM VM before
**Time Required**: 2-3 hours total (including downloads)

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   VM CREATION WORKFLOW                       │
│                                                              │
│  Phase 1: System Prep (15 min)                              │
│    → Install QEMU/KVM                                        │
│    → Configure user permissions                              │
│    → LOGOUT/LOGIN                                            │
│                                                              │
│  Phase 2: ISO Prep (30-60 min)                              │
│    → Download Windows 11 ISO (~5GB)                          │
│    → Download VirtIO drivers ISO (~500MB)                    │
│    → Move to source-iso/ directory                           │
│                                                              │
│  Phase 3: VM Creation (5 min)                               │
│    → Verify prerequisites (--check)                          │
│    → Create VM configuration                                 │
│                                                              │
│  Phase 4: Windows Install (45-60 min)                       │
│    → Start VM                                                │
│    → Install Windows + VirtIO drivers                        │
│    → Post-installation tasks                                 │
│                                                              │
│  Phase 5: Optimization (30 min, optional)                   │
│    → Performance tuning                                      │
│    → Security hardening                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: System Preparation (15 minutes)

**Goal**: Install QEMU/KVM virtualization stack and configure user permissions.

### Step 1.1: Install QEMU/KVM Packages

```bash
cd ~/Apps/win-qemu
sudo ./scripts/install-master.sh
```

**What this does**:
- Installs 10+ packages (qemu-system-x86, libvirt-daemon-system, ovmf, swtpm, etc.)
- Configures libvirtd service (auto-start on boot)
- Creates default NAT network for VMs
- Verifies hardware virtualization (Intel VT-x or AMD-V)

**Expected output**:
```
[✓] Hardware virtualization enabled (16 cores)
[✓] Installed qemu-system-x86
[✓] Installed libvirt-daemon-system
[✓] Installed ovmf (UEFI firmware)
[✓] Installed swtpm (TPM 2.0 emulator)
[✓] libvirtd service enabled and started
Installation complete!
```

**Troubleshooting**:
- If hardware virtualization check fails:
  - Reboot into BIOS/UEFI settings (usually F2, F10, or Del key)
  - Enable "Intel Virtualization Technology" (VT-x) or "AMD-V"
  - Save and exit BIOS

### Step 1.2: Add User to Required Groups

```bash
sudo usermod -aG libvirt,kvm $USER
```

**What this does**:
- Grants your user account permission to manage VMs
- Required for `virsh` commands and virt-manager GUI
- Group membership is checked at login time only

**⚠️ CRITICAL**: Changes take effect ONLY after logout/login.

### Step 1.3: Logout and Login

**You MUST logout and login for group changes to take effect.**

```bash
# Option 1: Logout via GUI
# Click username → Logout

# Option 2: Reboot system (safest)
sudo reboot

# Option 3: Switch to different TTY (advanced)
# Ctrl+Alt+F2 → login → continue
```

### Step 1.4: Verify Group Membership (after login)

```bash
groups | grep -E 'libvirt|kvm'
```

**Expected output**:
```
kkk adm cdrom sudo dip plugdev libvirt kvm lpadmin sambashare
```

**Must see both**: `libvirt` and `kvm` in the output.

---

## Phase 2: ISO Preparation (30-60 minutes)

**Goal**: Download and prepare Windows 11 and VirtIO driver installation media.

### Step 2.1: Create ISO Directory

```bash
mkdir -p ~/Apps/win-qemu/source-iso
```

### Step 2.2: Download Windows 11 ISO (~5GB, 10-30 minutes)

**Official source**: https://www.microsoft.com/software-download/windows11

**Steps**:
1. Open browser → visit link above
2. Select: "Windows 11 (multi-edition ISO)"
3. Choose language (e.g., "English International")
4. Click "64-bit Download"
5. Save to `~/Downloads/`

**Expected filename**: `Win11_23H2_EnglishInternational_x64.iso` (or similar)

**File size**: ~5-6 GB

### Step 2.3: Download VirtIO Drivers ISO (~500MB, 2-5 minutes)

**Official source**: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

**Steps**:
1. Open browser → visit link above
2. Navigate to: "latest-virtio/" directory
3. Download: `virtio-win.iso` (stable release)
4. Save to `~/Downloads/`

**File size**: ~500-600 MB

### Step 2.4: Move ISOs to Project Directory

```bash
# Move Windows 11 ISO (rename to standardized name)
mv ~/Downloads/Win11*.iso ~/Apps/win-qemu/source-iso/Win11.iso

# Move VirtIO drivers ISO (keep original name)
mv ~/Downloads/virtio-win*.iso ~/Apps/win-qemu/source-iso/virtio-win.iso
```

**⚠️ Important**: ISOs MUST be named exactly `Win11.iso` and `virtio-win.iso` (script expects these exact names).

### Step 2.5: Verify ISOs are Present

```bash
ls -lh ~/Apps/win-qemu/source-iso/
```

**Expected output**:
```
total 6.0G
-rw-r--r-- 1 kkk kkk 5.2G Nov 27 10:30 Win11.iso
-rw-r--r-- 1 kkk kkk 526M Nov 27 10:35 virtio-win.iso
```

---

## Phase 3: VM Creation (5 minutes)

**Goal**: Create VM configuration with Q35 chipset, UEFI firmware, and TPM 2.0.

### Step 3.1: Verify All Prerequisites

```bash
cd ~/Apps/win-qemu
sudo ./scripts/create-vm.sh --check
```

**Expected output** (ALL GREEN):
```
VM CREATION PREREQUISITE CHECKLIST
===================================

SYSTEM REQUIREMENTS:
  [✓] Hardware virtualization enabled (16 cores)
  [✓] Sufficient RAM (32GB total, 24GB available)
  [✓] SSD storage detected
  [✓] Sufficient disk space (500GB available)

SOFTWARE INSTALLATION:
  [✓] QEMU/KVM packages installed
  [✓] libvirtd service active

USER PERMISSIONS:
  [✓] User 'kkk' in libvirt and kvm groups

ISO FILES:
  [✓] Win11.iso present (5.2GB)
  [✓] virtio-win.iso present (526MB)

CONFIGURATION:
  [✓] Template file exists (configs/win11-vm.xml)

STATUS: ✅ READY TO CREATE VM
```

**If any items show [✗]**:
- Go back to previous phases and complete missing steps
- Re-run `--check` until all green

### Step 3.2: Create VM (Interactive Mode)

```bash
sudo ./scripts/create-vm.sh
```

**Interactive prompts** (press Enter for defaults):

1. **VM name**: `win11-vm` (default) or custom name
2. **RAM allocation**: `8192` MB (8GB, default) or custom (minimum 4GB)
3. **vCPUs**: `4` (default) or custom (max = your CPU cores)
4. **Disk size**: `100` GB (default) or custom (minimum 60GB)
5. **Confirm creation**: Type `yes` and press Enter

**Expected output**:
```
[✓] Pre-flight checks passed
[✓] VM disk created: /var/lib/libvirt/images/win11-vm.qcow2 (100GB)
[✓] VM XML configuration generated
[✓] VM defined with libvirt
[✓] TPM directory created

VM 'win11-vm' created successfully!

Next Steps:
  1. Start VM: virsh start win11-vm
  2. Install Windows (see instructions below)
```

### Step 3.3: Alternative - Non-Interactive Creation

```bash
sudo ./scripts/create-vm.sh \
  --name win11-outlook \
  --ram 16384 \
  --vcpus 8 \
  --disk 150
```

**Useful for**:
- Automation/scripting
- Multiple VMs with different configurations
- Skipping prompts

---

## Phase 4: Windows Installation (45-60 minutes)

**Goal**: Install Windows 11 with VirtIO drivers for optimal performance.

### Step 4.1: Start VM and Open Console

```bash
cd ~/Apps/win-qemu
./scripts/start-vm.sh win11-vm --console
```

**What this does**:
- Starts the VM
- Opens virt-viewer (graphical console)
- VM boots from Windows 11 ISO

**Alternative (if virt-viewer not available)**:
```bash
# Start VM without auto-opening console
./scripts/start-vm.sh win11-vm

# Then open virt-manager GUI manually
virt-manager
# Double-click "win11-vm" to open console
```

### Step 4.2: Windows Installation - Initial Setup

**In the VM console window**:

1. **Language selection**:
   - Language to install: English (United States)
   - Time and currency format: Your preference
   - Keyboard: Your preference
   - Click "Next"

2. **Install now**:
   - Click "Install now" button

3. **Product key** (if prompted):
   - Click "I don't have a product key" (can activate later)
   - OR enter valid Windows 11 Pro retail key

4. **Windows edition**:
   - Select "Windows 11 Pro" (required for Hyper-V features)
   - Click "Next"

5. **License agreement**:
   - Check "I accept the license terms"
   - Click "Next"

6. **Installation type**:
   - Select "Custom: Install Windows only (advanced)"

### Step 4.3: Load VirtIO Storage Driver (CRITICAL STEP)

**At "Where do you want to install Windows?" screen**:

**⚠️ The disk list will be EMPTY - this is EXPECTED.**

Windows does not have VirtIO drivers in-box. You MUST load them manually:

**Steps**:

1. **Click "Load driver"** (bottom-left of window)

2. **Click "Browse"**

3. **Navigate to VirtIO CD-ROM**:
   - Look for drive labeled "virtio-win" (usually E:\ or D:\)
   - Double-click to open it

4. **Navigate to storage driver**:
   - Open folder: `viostor`
   - Open folder: `w11`
   - Open folder: `amd64`
   - Click "OK"

5. **Install driver**:
   - Windows will detect "Red Hat VirtIO SCSI controller"
   - Click "Next"

6. **Disk appears**:
   - You will now see "Drive 0 Unallocated Space" (100GB or your size)
   - Select it
   - Click "Next"

**Windows installation will now proceed** (10-15 minutes).

### Step 4.4: Post-Installation (Inside Windows)

**After Windows boots for the first time**:

1. **Complete Windows setup wizard**:
   - Region: Your location
   - Keyboard layout: Your preference
   - Additional keyboard: Skip
   - Network: Skip for now (configure later)
   - Account: Create local account OR sign in with Microsoft account

2. **Install remaining VirtIO drivers**:
   - Open File Explorer
   - Navigate to VirtIO CD-ROM (E:\ or D:\)
   - Run: `virtio-win-gt-x64.msi` (installs all drivers)
   - Follow installation wizard (click "Next" → "Install" → "Finish")

3. **Install QEMU Guest Agent** (REQUIRED for automation):
   - On VirtIO CD-ROM, navigate to: `guest-agent\`
   - Run: `qemu-ga-x86_64.msi`
   - Complete installation wizard

4. **Verify Device Manager** (no yellow warnings):
   - Press Win+X → Device Manager
   - Expand all categories
   - Should see NO yellow warning icons
   - All devices should show "Working properly"

5. **Run Windows Updates**:
   - Settings → Windows Update → "Check for updates"
   - Install all available updates
   - Restart if prompted
   - Repeat until no more updates available

6. **Activate Windows**:
   - Settings → System → Activation
   - Enter valid Windows 11 Pro retail license key
   - Click "Activate"

### Step 4.5: Network Configuration (Optional)

**If you skipped network setup**:

1. **Connect to network**:
   - Settings → Network & Internet → Ethernet
   - VM uses NAT (internet access via host)
   - Network should show "Connected"

2. **Test connectivity**:
   - Open PowerShell
   - Run: `Test-NetConnection google.com`
   - Should show: `TcpTestSucceeded : True`

---

## Phase 5: Optimization (30 minutes, OPTIONAL)

**Goal**: Apply performance tuning and security hardening.

### Step 5.1: Create Baseline Snapshot (Recommended)

**Before optimization, create a rollback point**:

```bash
cd ~/Apps/win-qemu
sudo ./scripts/backup-vm.sh win11-vm --snapshot-only --snapshot-name baseline
```

**What this does**:
- Creates snapshot of VM in current state
- Allows easy rollback if optimization causes issues
- No disk export (fast, <1 minute)

### Step 5.2: Performance Optimization

```bash
sudo ./scripts/configure-performance.sh win11-vm
```

**What this does**:
- Applies 14 Hyper-V enlightenments (85-95% native performance)
- Configures CPU pinning (optional)
- Enables huge pages for memory (optional)
- Benchmarks performance before/after

**Expected improvement**:
- Boot time: 45s → 22s
- Outlook startup: 12s → 4s
- Disk IOPS: 8,000 → 45,000

### Step 5.3: Security Hardening

```bash
sudo ./scripts/secure-vm.sh win11-vm
```

**What this does**:
- Configures virtio-fs in read-only mode (ransomware protection)
- Sets up egress firewall (whitelist M365 endpoints)
- Enables AppArmor profile for QEMU
- Provides BitLocker setup instructions

**60+ item checklist** (automated where possible).

### Step 5.4: Verify Optimization

```bash
# Check Hyper-V enlightenments are active
virsh dumpxml win11-vm | grep -c '<hyperv'
# Should return: 14 (or >0)

# Check VM info
virsh dominfo win11-vm

# Monitor real-time performance
virt-top -1
```

---

## Daily Operations: Quick Reference

### Start VM

```bash
cd ~/Apps/win-qemu
./scripts/start-vm.sh win11-vm
```

**Options**:
- `--console` - Auto-open graphical console
- `--wait-agent` - Wait for QEMU guest agent (automation)

### Stop VM (Graceful)

```bash
./scripts/stop-vm.sh win11-vm
```

**Options**:
- `--timeout 120` - Wait 120s for graceful shutdown
- `--force` - Immediate power-off (use only if graceful fails)
- `--snapshot` - Create snapshot before shutdown

### Backup VM

```bash
sudo ./scripts/backup-vm.sh win11-vm --verify
```

**Options**:
- `--offline` - Stop VM before backup (most consistent)
- `--live` - Backup while running (no downtime)
- `--compress` - Compress backup (~50% smaller, slower)
- `--keep 10` - Keep last 10 backups

### Check VM Status

```bash
# Quick status
virsh domstate win11-vm

# Detailed info
virsh dominfo win11-vm

# Resource usage
virt-top -1
```

### Connect to VM Console

```bash
# Graphical console
virt-viewer win11-vm

# OR use virt-manager GUI
virt-manager
```

---

## Troubleshooting Common Issues

### Issue 1: "VM won't boot (black screen)"

**Cause**: UEFI firmware not configured properly

**Diagnosis**:
```bash
virsh dumpxml win11-vm | grep -A3 '<os'
```

**Look for**: `<os firmware='efi'>`

**Fix**: See `outlook-linux-guide/05-qemu-kvm-reference-architecture.md` section on UEFI.

### Issue 2: "Windows installer can't find disk"

**Cause**: VirtIO storage driver not loaded

**Fix**: See Step 4.3 above (Load VirtIO storage driver).

### Issue 3: "No network connectivity in Windows"

**Cause**: VirtIO network driver not installed

**Fix**:
1. Open Device Manager
2. Right-click "Ethernet Controller" (yellow warning)
3. Update driver → Browse to VirtIO CD-ROM
4. Windows will auto-detect and install driver

### Issue 4: "Permission denied" errors

**Cause**: User not in libvirt/kvm groups, or didn't logout/login

**Fix**:
```bash
# Verify groups
groups | grep -E 'libvirt|kvm'

# If missing, add user
sudo usermod -aG libvirt,kvm $USER

# CRITICAL: Logout and login
```

### Issue 5: "Insufficient RAM" when starting VM

**Cause**: VM allocated more RAM than host has available

**Fix**:
```bash
# Check available RAM
free -h

# Reduce VM RAM allocation
virsh shutdown win11-vm
virsh edit win11-vm
# Find <memory> and <currentMemory> tags, reduce values
# Example: Change 8388608 (8GB) to 4194304 (4GB)
virsh start win11-vm
```

---

## Next Steps After VM Creation

1. **Install Microsoft 365 Outlook**:
   - Sign in with M365 account
   - Configure email profiles
   - Test PST file access (if using virtio-fs)

2. **Configure virtio-fs for PST sharing** (optional):
   ```bash
   sudo ./scripts/setup-virtio-fs.sh win11-vm
   ```

3. **Automate VM startup** (optional):
   ```bash
   virsh autostart win11-vm
   ```

4. **Create weekly backup schedule** (optional):
   ```bash
   # Add to crontab
   0 2 * * 0 /home/kkk/Apps/win-qemu/scripts/backup-vm.sh win11-vm --yes
   ```

---

## Additional Documentation

- **Main guide**: `outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- **Performance tuning**: `outlook-linux-guide/09-performance-optimization-playbook.md`
- **Security hardening**: `research/06-security-hardening-analysis.md`
- **Troubleshooting**: `research/07-troubleshooting-failure-modes.md`
- **UX analysis**: `docs-repo/VM-SCRIPT-UX-ANALYSIS.md`

---

**Last Updated**: 2025-11-27
**Maintained By**: guardian-vm agent
**Feedback**: Report issues or suggestions via GitHub issues
