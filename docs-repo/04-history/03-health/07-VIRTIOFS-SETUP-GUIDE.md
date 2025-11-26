# VirtIO-FS Filesystem Sharing - Complete Setup Guide

**Version**: 1.0.0 (January 2025)
**Purpose**: High-performance filesystem sharing for .pst file access with ransomware protection
**Technology**: virtio-fs (10x faster than Samba/CIFS)

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Files Created](#files-created)
4. [Setup Instructions](#setup-instructions)
5. [Windows Guest Configuration](#windows-guest-configuration)
6. [Security Verification](#security-verification)
7. [Troubleshooting](#troubleshooting)
8. [Performance Tuning](#performance-tuning)
9. [Testing Procedures](#testing-procedures)
10. [FAQ](#faq)

---

## Overview

### What is VirtIO-FS?

VirtIO-FS is a modern shared filesystem technology that allows direct file access between QEMU/KVM host and guest with near-native performance. It replaces legacy solutions like Samba/CIFS and 9p.

### Key Benefits

- **Performance**: 10x faster than Samba for .pst file access
- **Security**: Read-only mode prevents ransomware from encrypting host files
- **Simplicity**: No network configuration, no complex permissions
- **Integration**: Direct file access - appears as native Z: drive in Windows
- **Reliability**: No network overhead, direct filesystem passthrough

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Ubuntu Host                                                  │
│                                                              │
│  /home/user/outlook-data/                                   │
│  ├── archive-2024.pst                                       │
│  ├── mailbox.pst                                            │
│  └── contacts.pst                                           │
│                                                              │
│  ↓ virtio-fs (read-only, high-performance)                  │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Windows 11 Guest (QEMU/KVM)                         │   │
│  │                                                      │   │
│  │  Z:\ drive (mount tag: outlook-share)               │   │
│  │  ├── archive-2024.pst  ← READ ONLY                  │   │
│  │  ├── mailbox.pst       ← READ ONLY                  │   │
│  │  └── contacts.pst      ← READ ONLY                  │   │
│  │                                                      │   │
│  │  Microsoft 365 Outlook                               │   │
│  │  └── Accesses .pst files directly from Z:           │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Security Model

**CRITICAL**: Read-only mode is MANDATORY

- **Threat**: Ransomware in Windows guest encrypts .pst files on host
- **Protection**: `<readonly/>` tag prevents ALL write operations from guest
- **Result**: Guest malware CANNOT encrypt, delete, or modify host files

---

## Quick Start

**Total time**: 30 minutes (15 min host + 15 min guest)

### Host Setup (Ubuntu)

```bash
# 1. Run automated setup script
sudo /home/user/win-qemu/scripts/setup-virtio-fs.sh --vm win11-outlook

# 2. Script will:
#    - Create /home/user/outlook-data directory
#    - Configure virtio-fs in VM XML (read-only mode)
#    - Create test file for verification
#    - Restart VM if needed
```

### Guest Setup (Windows)

1. **Install WinFsp**: Download from https://github.com/winfsp/winfsp/releases
2. **Reboot Windows** (required for driver loading)
3. **Mount Z: drive** (PowerShell as Administrator):
   ```powershell
   net use Z: \\svc\outlook-share
   ```
4. **Verify read-only mode**: Try creating a file (should fail)

### Verification

```bash
# Run test suite
sudo /home/user/win-qemu/scripts/test-virtio-fs.sh --vm win11-outlook
```

---

## Files Created

### 1. Configuration Template

**File**: `/home/user/win-qemu/configs/virtio-fs-share.xml`
**Size**: 11 KB
**Purpose**: Libvirt XML snippet for virtio-fs configuration

**Key Features**:
- Read-only mode enforced (`<readonly/>` tag)
- Configurable queue size (1024/2048/4096)
- Source directory: `/home/user/outlook-data` (customizable)
- Target mount tag: `outlook-share`
- Extensive inline documentation (100+ lines of comments)

**Usage**:
```bash
# Attach to existing VM
virsh attach-device win11-outlook /home/user/win-qemu/configs/virtio-fs-share.xml --config

# Or manually insert into VM XML
virsh edit win11-outlook
# Copy <filesystem> block into <devices> section
```

### 2. Automated Setup Script

**File**: `/home/user/win-qemu/scripts/setup-virtio-fs.sh`
**Size**: 30 KB
**Lines**: 850+
**Language**: Bash

**Features**:
- Comprehensive pre-flight checks (libvirt version, virtiofsd binary)
- Automated directory creation and permission setup
- VM XML backup before modifications
- Syntax validation before applying changes
- Comprehensive error handling with rollback capability
- Detailed logging (`/var/log/win-qemu/setup-virtio-fs.log`)
- Dry-run mode for testing (`--dry-run`)
- Colorized output with progress indicators
- MANDATORY read-only mode enforcement (no option to disable)

**Command-Line Options**:
```bash
sudo ./scripts/setup-virtio-fs.sh --vm <vm-name> [OPTIONS]

OPTIONS:
  --vm <name>           VM name (REQUIRED)
  --source <path>       Source directory (default: /home/user/outlook-data)
  --target <tag>        Mount tag (default: outlook-share)
  --queue <size>        Queue size 1024/2048/4096 (default: 1024)
  --dry-run             Preview changes without applying
  --force               Skip confirmation prompts
  --help                Show help message
```

**Examples**:
```bash
# Basic setup
sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook

# Custom source directory
sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook --source /mnt/data/pst-files

# High performance (large .pst files)
sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook --queue 4096

# Dry run
./scripts/setup-virtio-fs.sh --vm win11-outlook --dry-run
```

### 3. Verification Test Script

**File**: `/home/user/win-qemu/scripts/test-virtio-fs.sh`
**Size**: 16 KB
**Purpose**: Automated testing and verification

**Tests Performed**:
1. VM existence check
2. VirtIO-FS configuration verification
3. Read-only mode enforcement check (CRITICAL)
4. Source directory existence
5. Directory permissions validation
6. Host file creation test
7. File readability test
8. Windows guest manual tests (instructions provided)

**Usage**:
```bash
sudo ./scripts/test-virtio-fs.sh --vm win11-outlook
```

---

## Setup Instructions

### Prerequisites

**Host Requirements**:
- Ubuntu 25.10 or later
- libvirt 9.0+ (virtio-fs support)
- QEMU 8.0+ with virtiofsd binary
- Running Windows 11 VM

**Guest Requirements**:
- Windows 11 Pro (activated)
- Administrator access
- Internet connection (for WinFsp download)

### Step-by-Step Setup

#### Phase 1: Pre-Flight Checks (5 minutes)

```bash
# 1. Verify libvirt version (must be 9.0+)
virsh version

# Expected output:
# libvirt library: 9.0.0 (or higher)

# 2. Check for virtiofsd binary
which virtiofsd || ls /usr/libexec/virtiofsd

# Expected output:
# /usr/libexec/virtiofsd (or similar path)

# 3. Verify VM exists
virsh list --all | grep win11-outlook

# Expected output:
# win11-outlook   shut off  (or running)

# 4. Check VM has enough resources
virsh dominfo win11-outlook | grep -E "Max memory|Used memory|CPU"
```

#### Phase 2: Run Setup Script (10 minutes)

```bash
# 1. Navigate to project directory
cd /home/user/win-qemu

# 2. Run setup script (with dry-run first for preview)
./scripts/setup-virtio-fs.sh --vm win11-outlook --dry-run

# 3. Review output, then run for real
sudo ./scripts/setup-virtio-fs.sh --vm win11-outlook

# 4. Script will:
#    - Create /home/user/outlook-data
#    - Set permissions (755, user:user)
#    - Backup VM XML to /var/lib/libvirt/qemu/backups/
#    - Attach virtio-fs device
#    - Verify read-only mode
#    - Restart VM if needed
```

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VirtIO-FS Filesystem Sharing Setup - Version 1.0.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Starting virtio-fs setup for VM: win11-outlook
[INFO] Source directory: /home/user/outlook-data
[INFO] Target mount tag: outlook-share
[INFO] Queue size: 1024

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: Pre-Flight Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] libvirt version: 9.0.0
[✓] Found virtiofsd: /usr/libexec/virtiofsd
[✓] VM 'win11-outlook' found
[✓] VM state: shut off

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: Host-Side Directory Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] Directory created: /home/user/outlook-data
[✓] Directory permissions: 755
[✓] Ownership: user:user
[✓] Test file created: test-virtio-fs.txt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 3: VM Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] Backup created: /var/lib/libvirt/qemu/backups/win11-outlook_20250119-041500_pre-virtiofs.xml
[✓] VirtIO-FS device attached successfully
[✓] VirtIO-FS configuration verified successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SETUP COMPLETE!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] VirtIO-FS configuration completed successfully!
```

#### Phase 3: Verify Configuration (2 minutes)

```bash
# 1. Verify virtio-fs in VM XML
virsh dumpxml win11-outlook | grep -A 7 "type='virtiofs'"

# Expected output:
# <filesystem type='mount' accessmode='passthrough'>
#   <driver type='virtiofs' queue='1024'/>
#   <source dir='/home/user/outlook-data'/>
#   <target dir='outlook-share'/>
#   <readonly/>
# </filesystem>

# 2. Verify read-only tag (CRITICAL!)
virsh dumpxml win11-outlook | grep -A 5 "type='virtiofs'" | grep readonly

# Expected output:
# <readonly/>

# 3. Check source directory
ls -la /home/user/outlook-data

# Expected output:
# drwxr-xr-x 2 user user 4096 Jan 19 04:15 .
# -rw-r--r-- 1 user user  512 Jan 19 04:15 README.txt
# -rw-r--r-- 1 user user  384 Jan 19 04:15 test-virtio-fs.txt
```

---

## Windows Guest Configuration

### Step 1: Install WinFsp (10 minutes)

**WinFsp** (Windows File System Proxy) is required for virtio-fs support in Windows.

#### Download

1. Open browser in Windows guest
2. Navigate to: https://github.com/winfsp/winfsp/releases
3. Download latest stable release:
   - Filename: `winfsp-2.0.23075.msi` (or newer)
   - Size: ~1 MB
4. (Optional) Verify SHA256 checksum from GitHub releases page

#### Install

1. Run `winfsp-2.0.23075.msi`
2. Accept license agreement
3. Installation path: `C:\Program Files (x86)\WinFsp` (default - do not change)
4. Select components: Install all (default)
5. Click "Install"
6. **IMPORTANT**: Reboot Windows when prompted (required for driver loading)

#### Verify Installation

After reboot, open PowerShell and run:

```powershell
Get-Package -Name WinFsp

# Expected output:
# Name     Version          Source       ProviderName
# ----     -------          ------       ------------
# WinFsp   2.0.23075        C:\Program...  msi
```

### Step 2: Install VirtIO-FS Service (5 minutes)

#### Locate Installer

1. In Windows guest, open File Explorer
2. Navigate to virtio-win ISO (usually D:\ or E:\)
   - If not mounted: Download from https://fedorapeople.org/groups/virt/virtio-win/
3. Go to: `D:\guest-agent\` folder
4. Find: `virtiofs-*.exe` or `virtiofs.msi`

#### Install Service

1. Run installer as **Administrator** (Right-click → Run as administrator)
2. Complete installation wizard (accept defaults)
3. Open `services.msc` (Win+R, type "services.msc")
4. Find "**VirtIO-FS Service**"
5. Right-click → Properties
6. Set **Startup type**: `Automatic`
7. Click **Start** to start service immediately
8. Click **OK**

#### Verify Service

```powershell
Get-Service | Where-Object {$_.Name -like "*virti*"}

# Expected output:
# Status   Name               DisplayName
# ------   ----               -----------
# Running  VirtioFsSvc        VirtIO-FS Service
```

### Step 3: Mount Z: Drive (2 minutes)

#### Mount Command

Open **PowerShell as Administrator** and run:

```powershell
net use Z: \\svc\outlook-share
```

**Expected Output**:
```
The command completed successfully.
```

#### Verify Mount

1. Open **File Explorer** (Win+E)
2. Look under "**This PC**"
3. You should see: **Z: (\\svc\outlook-share)** (or similar label)

#### Verify Files Visible

```powershell
# List files on Z: drive
Get-ChildItem Z:

# Expected output:
# Mode                 LastWriteTime         Length Name
# ----                 -------------         ------ ----
# -a---           1/19/2025  4:15 AM            512 README.txt
# -a---           1/19/2025  4:15 AM            384 test-virtio-fs.txt
```

### Step 4: Verify Read-Only Mode (CRITICAL SECURITY TEST)

This test confirms ransomware protection is active.

#### Test 1: File Creation (Should FAIL)

```powershell
# Try to create a file
New-Item -Path "Z:\test-write.txt" -ItemType File

# Expected output:
# New-Item : Access is denied
# At line:1 char:1
# + New-Item -Path "Z:\test-write.txt" -ItemType File
# + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

If file creation **succeeds**, this is a **CRITICAL SECURITY ISSUE**. Read-only mode is NOT enforced.

#### Test 2: File Deletion (Should FAIL)

1. In File Explorer, navigate to `Z:\`
2. Right-click on `test-virtio-fs.txt`
3. Click **Delete**

**Expected Result**: "Access Denied" or "Insufficient permissions" error

#### Test 3: File Modification (Should FAIL)

1. Open `Z:\test-virtio-fs.txt` in Notepad
2. Modify the text
3. Try to save (Ctrl+S)

**Expected Result**: "Access Denied" error when saving

#### Result Interpretation

| Test Result | Security Status | Action Required |
|-------------|-----------------|-----------------|
| All tests FAIL (Access Denied) | ✓ SECURE | Ransomware protection active |
| ANY test SUCCEEDS | ✗ VULNERABLE | STOP - Contact administrator |

If ANY write operation succeeds:
1. **SHUTDOWN VM IMMEDIATELY**
2. Review host-side configuration
3. Verify `<readonly/>` tag in VM XML
4. Contact security team

---

## Security Verification

### Complete Security Checklist

Before using virtio-fs in production, verify ALL items:

#### Host-Side Security

- [ ] **virtio-fs read-only mode verified**
  ```bash
  virsh dumpxml win11-outlook | grep -A 5 "type='virtiofs'" | grep readonly
  # Must show: <readonly/>
  ```

- [ ] **Source directory permissions are restrictive**
  ```bash
  ls -ld /home/user/outlook-data
  # Should show: drwxr-xr-x (755) or more restrictive
  ```

- [ ] **Source directory owned by user (not root)**
  ```bash
  stat -c "%U:%G" /home/user/outlook-data
  # Should show: user:user (your username)
  ```

- [ ] **LUKS encryption enabled on host partition** (RECOMMENDED)
  ```bash
  lsblk -o NAME,FSTYPE,MOUNTPOINT
  # Check for TYPE=crypto_LUKS
  ```

- [ ] **Host firewall configured (UFW)**
  ```bash
  sudo ufw status
  # Should show: Status: active
  ```

- [ ] **Regular backups configured for shared directory**
  ```bash
  # Verify backup strategy exists
  crontab -l | grep outlook-data
  # Or check backup software configuration
  ```

- [ ] **VM XML backup created before modifications**
  ```bash
  ls -la /var/lib/libvirt/qemu/backups/ | grep win11-outlook
  # Should show recent backup file
  ```

#### Guest-Side Security

- [ ] **WinFsp installed and up-to-date**
  ```powershell
  Get-Package -Name WinFsp
  # Version should be 2.0.23075 or newer
  ```

- [ ] **VirtIO-FS Service running and set to Automatic**
  ```powershell
  Get-Service VirtioFsSvc | Select Status,StartType
  # Status: Running, StartType: Automatic
  ```

- [ ] **Z: drive mounted successfully**
  ```powershell
  Test-Path Z:\
  # Should return: True
  ```

- [ ] **Write operations BLOCKED (read-only verified)**
  ```powershell
  New-Item -Path "Z:\test.txt" -ItemType File
  # Should fail with "Access is denied"
  ```

- [ ] **BitLocker enabled on C: drive** (RECOMMENDED)
  ```powershell
  Get-BitLockerVolume -MountPoint C:
  # VolumeStatus should be: FullyEncrypted
  ```

- [ ] **Windows Defender real-time protection active**
  ```powershell
  Get-MpComputerStatus | Select RealTimeProtectionEnabled
  # Should show: True
  ```

- [ ] **Windows Firewall enabled**
  ```powershell
  Get-NetFirewallProfile | Select Name,Enabled
  # All profiles should show: Enabled=True
  ```

- [ ] **Windows Updates current**
  ```powershell
  Get-WindowsUpdate
  # Should show no critical updates pending
  ```

#### Operational Security

- [ ] **No sensitive data in .pst files** (or encrypted backups exist)
- [ ] **IT approval obtained** (if using corporate M365 account)
- [ ] **Compliance requirements reviewed** (HIPAA, SOX, FINRA, etc.)
- [ ] **Disaster recovery plan documented**
- [ ] **Security incident response plan established**

### Security Risk Matrix

| Configuration | Risk Level | Mitigation |
|---------------|-----------|------------|
| Read-only + LUKS + Backups | **LOW** | Production-ready |
| Read-only + LUKS + No backups | **MEDIUM** | Add backup strategy |
| Read-only + No LUKS | **MEDIUM** | Enable LUKS encryption |
| Read-write + LUKS + Backups | **HIGH** | Use only if absolutely necessary |
| Read-write + No protections | **CRITICAL** | DO NOT USE |

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Z: Drive Not Appearing in Windows

**Symptoms**:
- virtio-fs configured in VM XML
- VirtIO-FS Service running
- But Z: drive not visible in File Explorer

**Diagnosis**:
```powershell
# Check WinFsp installation
Get-Package -Name WinFsp

# Check VirtIO-FS Service
Get-Service VirtioFsSvc

# Check for mount errors in Event Viewer
Get-EventLog -LogName System -Source "VirtioFsSvc" -Newest 10
```

**Solutions**:

1. **WinFsp not installed**:
   ```powershell
   # Reinstall WinFsp from GitHub releases
   # Then REBOOT Windows
   ```

2. **VirtIO-FS Service not running**:
   ```powershell
   Start-Service VirtioFsSvc
   Set-Service VirtioFsSvc -StartupType Automatic
   ```

3. **Wrong mount tag**:
   ```bash
   # On host: Check target dir in VM XML
   virsh dumpxml win11-outlook | grep -A 3 "target dir"
   # Must match: outlook-share
   ```

4. **Memory backing missing** (required for virtio-fs):
   ```bash
   # Check for memoryBacking in VM XML
   virsh dumpxml win11-outlook | grep -A 3 memoryBacking

   # If missing, add to VM XML:
   virsh edit win11-outlook
   # Add inside <domain> section:
   # <memoryBacking>
   #   <source type='memfd'/>
   # </memoryBacking>
   ```

5. **Restart required**:
   ```powershell
   # Reboot Windows guest
   Restart-Computer
   ```

---

#### Issue 2: "Access Denied" When Reading Files

**Symptoms**:
- Z: drive visible
- But cannot open any files
- Permission denied errors

**Diagnosis**:
```bash
# On host: Check file permissions
ls -la /home/user/outlook-data/

# Check ownership
stat /home/user/outlook-data/*.pst

# Check SELinux context (if applicable)
ls -Z /home/user/outlook-data/
```

**Solutions**:

1. **Incorrect file permissions**:
   ```bash
   # Fix permissions (644 = rw-r--r--)
   sudo chmod 644 /home/user/outlook-data/*.pst

   # Fix directory permissions (755 = rwxr-xr-x)
   sudo chmod 755 /home/user/outlook-data
   ```

2. **Wrong ownership**:
   ```bash
   # Set correct owner
   sudo chown user:user /home/user/outlook-data/*.pst
   sudo chown user:user /home/user/outlook-data
   ```

3. **SELinux blocking access**:
   ```bash
   # Check SELinux status
   sudo getenforce

   # If enforcing, check for denials
   sudo ausearch -m avc -ts recent | grep virtiofs

   # Fix SELinux context
   sudo chcon -R -t virt_home_t /home/user/outlook-data
   ```

4. **AppArmor blocking access**:
   ```bash
   # Check AppArmor status
   sudo aa-status | grep libvirt

   # Check for denials in logs
   sudo journalctl -xe | grep -i apparmor | grep -i denied
   ```

---

#### Issue 3: Poor Performance (Slow .pst Access)

**Symptoms**:
- .pst files take >5 seconds to open
- Search operations timeout
- Outlook freezes during file access

**Diagnosis**:
```bash
# Check queue size
virsh dumpxml win11-outlook | grep "queue="
# Default: queue='1024'

# Check memory backing
virsh dumpxml win11-outlook | grep -A 3 memoryBacking
# Should show: <source type='memfd'/>

# Check host storage performance
sudo hdparm -t /dev/sda
# SSD should show: >500 MB/sec
```

**Solutions**:

1. **Increase queue size**:
   ```bash
   # Shutdown VM
   virsh shutdown win11-outlook

   # Edit VM XML
   virsh edit win11-outlook

   # Change queue size:
   # <driver type='virtiofs' queue='2048'/>  (or 4096)

   # Restart VM
   virsh start win11-outlook
   ```

2. **Add memory backing** (required for virtio-fs):
   ```bash
   virsh edit win11-outlook

   # Add inside <domain> section:
   <memoryBacking>
     <source type='memfd'/>
   </memoryBacking>
   ```

3. **Enable Hyper-V enlightenments**:
   ```bash
   # Contact performance-optimization-specialist agent
   # Or manually add to VM XML (see AGENTS.md)
   ```

4. **Use SSD storage**:
   ```bash
   # Move shared directory to SSD
   sudo mv /home/user/outlook-data /mnt/ssd/outlook-data
   sudo ln -s /mnt/ssd/outlook-data /home/user/outlook-data

   # Update VM XML with new path
   virsh edit win11-outlook
   ```

5. **Reduce .pst file size**:
   - Archive old emails to separate .pst files
   - Compact .pst files in Outlook (File → Account Settings → Data Files → Settings → Compact Now)

---

#### Issue 4: Write Access Working (CRITICAL SECURITY RISK)

**Symptoms**:
- Can create/delete files on Z: drive
- No "Access Denied" errors
- Read-only mode not enforced

**Diagnosis**:
```bash
# Check for <readonly/> tag
virsh dumpxml win11-outlook | grep -A 7 "type='virtiofs'" | grep readonly

# Should return: <readonly/>
# If empty: CRITICAL SECURITY ISSUE
```

**Solution (IMMEDIATE ACTION REQUIRED)**:

```bash
# 1. SHUTDOWN VM IMMEDIATELY
virsh shutdown win11-outlook
# Wait for graceful shutdown (max 60 seconds)
sleep 30

# 2. Force shutdown if needed
if [ "$(virsh domstate win11-outlook)" != "shut off" ]; then
    virsh destroy win11-outlook
fi

# 3. Edit VM XML
virsh edit win11-outlook

# 4. Find the <filesystem> block and ADD <readonly/> tag:
# <filesystem type='mount' accessmode='passthrough'>
#   <driver type='virtiofs' queue='1024'/>
#   <source dir='/home/user/outlook-data'/>
#   <target dir='outlook-share'/>
#   <readonly/>  <!-- ADD THIS LINE IF MISSING -->
# </filesystem>

# 5. Save and exit (:wq in vim)

# 6. Verify configuration
virsh dumpxml win11-outlook | grep -A 7 "type='virtiofs'"

# 7. Restart VM
virsh start win11-outlook

# 8. Re-verify read-only mode in Windows guest
# Run: New-Item -Path "Z:\test.txt" -ItemType File
# Should fail with "Access is denied"
```

**Post-Fix Verification**:
```bash
# Run test suite
sudo /home/user/win-qemu/scripts/test-virtio-fs.sh --vm win11-outlook
```

---

#### Issue 5: VM Won't Start After Adding virtio-fs

**Symptoms**:
- VM fails to start after virtio-fs configuration
- Error messages in libvirt logs

**Diagnosis**:
```bash
# Check libvirt logs
sudo journalctl -xe | grep libvirt | tail -20

# Check VM XML syntax
virsh dumpxml win11-outlook > /tmp/test.xml
virsh define /tmp/test.xml  # Should not show errors
```

**Solutions**:

1. **Restore from backup**:
   ```bash
   # Find backup file
   ls -lrt /var/lib/libvirt/qemu/backups/ | tail -1

   # Restore
   virsh define /var/lib/libvirt/qemu/backups/win11-outlook_TIMESTAMP_pre-virtiofs.xml

   # Try starting VM
   virsh start win11-outlook
   ```

2. **Check virtiofsd binary**:
   ```bash
   which virtiofsd
   # Or: ls /usr/libexec/virtiofsd

   # If missing, install:
   sudo apt install qemu-system-x86
   ```

3. **Check memory backing**:
   ```bash
   # virtio-fs requires memory backing
   virsh edit win11-outlook

   # Add if missing:
   <memoryBacking>
     <source type='memfd'/>
   </memoryBacking>
   ```

---

## Performance Tuning

### Queue Size Optimization

**Queue size** controls the number of concurrent I/O operations between host and guest.

| .pst File Size | Queue Size | Expected Open Time | Expected Search Time |
|----------------|------------|-------------------|---------------------|
| <500 MB        | 1024       | <1 second         | <500 ms             |
| 500 MB - 1 GB  | 1024       | <2 seconds        | <1 second           |
| 1 GB - 2 GB    | 2048       | <3 seconds        | <2 seconds          |
| 2 GB - 5 GB    | 4096       | <5 seconds        | <3 seconds          |
| >5 GB          | 4096*      | <8 seconds        | <5 seconds          |

*For files >5 GB, also enable Hyper-V enlightenments and CPU pinning.

**How to Change Queue Size**:
```bash
# 1. Shutdown VM
virsh shutdown win11-outlook

# 2. Edit VM XML
virsh edit win11-outlook

# 3. Find virtio-fs driver line:
# <driver type='virtiofs' queue='1024'/>

# 4. Change to desired size:
# <driver type='virtiofs' queue='2048'/>  (or 4096)

# 5. Save and exit

# 6. Restart VM
virsh start win11-outlook
```

### Cache Mode Options

**Cache mode** controls how file data is cached.

```xml
<!-- Default: auto (recommended) -->
<driver type='virtiofs' queue='1024'/>

<!-- Maximum caching (best performance, less safe) -->
<driver type='virtiofs' queue='1024' cache='always'/>

<!-- No caching (safest, lowest performance) -->
<driver type='virtiofs' queue='1024' cache='none'/>
```

**Recommendations**:
- **Production**: Use `auto` (balanced)
- **High Performance**: Use `always` (if system is stable)
- **Regulated Industries**: Use `none` (HIPAA, SOX, FINRA)

### Memory Backing (Required)

virtio-fs **requires** shared memory between host and guest:

```xml
<memoryBacking>
  <source type='memfd'/>
</memoryBacking>
```

**How to Add**:
```bash
virsh edit win11-outlook
# Add inside <domain> section (before <devices>)
```

### Hyper-V Enlightenments (Recommended)

For maximum performance, enable Hyper-V enlightenments:

```bash
# Use performance-optimization-specialist agent
# Or see AGENTS.md for manual configuration
```

**Performance Impact**:
- Without enlightenments: 50-60% of native performance
- With enlightenments: 85-95% of native performance

---

## Testing Procedures

### Automated Testing

```bash
# Run full test suite
sudo /home/user/win-qemu/scripts/test-virtio-fs.sh --vm win11-outlook
```

**Test Coverage**:
1. VM existence and state
2. VirtIO-FS configuration verification
3. Read-only mode enforcement (CRITICAL)
4. Source directory permissions
5. File creation and readability
6. Windows guest manual tests (instructions provided)

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Results:
  Passed: 7
  Failed: 0
  Total:  7

✓ All host-side tests PASSED!
```

### Manual Testing (Windows Guest)

#### Test 1: File Visibility

```powershell
# List files on Z: drive
Get-ChildItem Z:

# Expected: See test file and README
```

#### Test 2: Read-Only Enforcement (File Creation)

```powershell
# Try to create file
New-Item -Path "Z:\test-write.txt" -ItemType File

# Expected: "Access is denied" error
```

#### Test 3: Read-Only Enforcement (File Deletion)

1. Open File Explorer → Z: drive
2. Right-click on test file → Delete
3. Expected: "Access Denied" error

#### Test 4: Read-Only Enforcement (File Modification)

1. Open test file in Notepad
2. Modify text
3. Save (Ctrl+S)
4. Expected: "Access Denied" error

#### Test 5: Outlook .pst Access

1. Copy test .pst file to `/home/user/outlook-data` on host
2. Open Outlook in Windows guest
3. File → Open & Export → Open Outlook Data File
4. Navigate to Z: drive
5. Select .pst file
6. Expected: Opens successfully, archive appears in folder pane

### Performance Testing

```bash
# Create 1GB test .pst file
dd if=/dev/zero of=/home/user/outlook-data/test-1gb.pst bs=1M count=1024

# Time file access from Windows
# In PowerShell:
Measure-Command { Get-Item Z:\test-1gb.pst }

# Expected: <2 seconds for 1GB file
```

---

## FAQ

### General Questions

**Q: What is the performance difference between virtio-fs and Samba?**

A: virtio-fs is approximately 10x faster than Samba for .pst file access:
- virtio-fs: <2 seconds to open 1GB .pst file
- Samba: 8-15 seconds for same file
- Reason: virtio-fs uses direct filesystem passthrough, no network overhead

**Q: Can I use virtio-fs for other file types besides .pst?**

A: Yes, virtio-fs works with any file type. Common uses:
- Documents (Word, Excel, PDF)
- Media files (photos, videos)
- Development files (source code, databases)
- Archives (ZIP, RAR, 7z)

**Q: How many .pst files can I share?**

A: No limit. You can share an entire directory tree with unlimited files.

**Q: Can I share multiple directories?**

A: Yes, add multiple `<filesystem>` blocks in VM XML with different source directories and mount tags.

### Security Questions

**Q: Why is read-only mode mandatory?**

A: Ransomware protection. If Windows is infected with ransomware, the malware cannot:
- Encrypt .pst files on the host
- Delete files in the shared directory
- Modify existing files

Without read-only mode, ransomware can permanently destroy your data.

**Q: Can I temporarily enable write mode?**

A: Technically yes, but NOT RECOMMENDED. If you must:
1. Shutdown VM
2. Remove `<readonly/>` tag from VM XML
3. Restart VM
4. Perform write operations
5. IMMEDIATELY restore `<readonly/>` tag
6. Restart VM again

**Q: Is virtio-fs encrypted?**

A: No, virtio-fs does not provide encryption. For encryption:
- Use LUKS on host partition containing shared directory
- Enable BitLocker in Windows guest (protects VM disk, not shared files)

**Q: What if my organization prohibits read-only mode?**

A: If you need write access:
1. Get IT approval in writing
2. Enable LUKS encryption on host
3. Implement real-time antivirus in guest
4. Set up automated backups (daily minimum)
5. Document risk acceptance
6. Remove `<readonly/>` tag carefully

### Technical Questions

**Q: Why do I need WinFsp?**

A: WinFsp (Windows File System Proxy) provides userspace filesystem support in Windows. virtio-fs runs in userspace, so it requires WinFsp to interface with Windows.

**Q: Can I use a different drive letter than Z:?**

A: Yes. Use any available drive letter:
```powershell
net use X: \\svc\outlook-share
```

**Q: What is the mount tag (outlook-share)?**

A: The mount tag is the identifier Windows uses to connect to the shared directory. It's defined in the VM XML:
```xml
<target dir='outlook-share'/>
```

**Q: Can I change the mount tag?**

A: Yes:
1. Shutdown VM
2. Edit VM XML: `virsh edit win11-outlook`
3. Change `<target dir='outlook-share'/>` to desired tag
4. Restart VM
5. In Windows: `net use Z: \\svc\<new-tag>`

**Q: Do I need to restart the VM after configuration changes?**

A: Yes, virtio-fs changes require VM restart. Graceful shutdown recommended:
```bash
virsh shutdown win11-outlook
# Wait 30 seconds
virsh start win11-outlook
```

### Troubleshooting Questions

**Q: Z: drive not appearing - what to check?**

A: Follow this checklist:
1. WinFsp installed: `Get-Package -Name WinFsp`
2. VirtIO-FS Service running: `Get-Service VirtioFsSvc`
3. VM has virtio-fs configured: `virsh dumpxml win11-outlook | grep virtiofs`
4. Memory backing enabled: `virsh dumpxml win11-outlook | grep memoryBacking`
5. Windows rebooted after WinFsp install

**Q: Files visible but cannot open - what to check?**

A: Permission issue. Check:
1. File permissions on host: `ls -l /home/user/outlook-data/`
2. Ownership: `stat /home/user/outlook-data/`
3. SELinux context (if applicable): `ls -Z /home/user/outlook-data/`

**Q: Performance is slow (<5 seconds for 1GB .pst) - how to fix?**

A: Try these optimizations:
1. Increase queue size to 2048 or 4096
2. Enable Hyper-V enlightenments
3. Use SSD storage on host
4. Add memory backing if missing
5. Contact performance-optimization-specialist agent

---

## Quick Reference Card

### Essential Commands

```bash
# Setup (one-time)
sudo /home/user/win-qemu/scripts/setup-virtio-fs.sh --vm win11-outlook

# Verify configuration
virsh dumpxml win11-outlook | grep -A 7 "type='virtiofs'"

# Test setup
sudo /home/user/win-qemu/scripts/test-virtio-fs.sh --vm win11-outlook

# Check source directory
ls -la /home/user/outlook-data

# View logs
tail -f /var/log/win-qemu/setup-virtio-fs.log

# Backup VM XML
virsh dumpxml win11-outlook > ~/backup-$(date +%Y%m%d).xml
```

### Windows Commands

```powershell
# Mount Z: drive
net use Z: \\svc\outlook-share

# Unmount Z: drive
net use Z: /delete

# Verify mount
Test-Path Z:\

# List files
Get-ChildItem Z:

# Test read-only (should fail)
New-Item -Path "Z:\test.txt" -ItemType File

# Check WinFsp
Get-Package -Name WinFsp

# Check service
Get-Service VirtioFsSvc
```

### File Locations

- **XML Template**: `/home/user/win-qemu/configs/virtio-fs-share.xml`
- **Setup Script**: `/home/user/win-qemu/scripts/setup-virtio-fs.sh`
- **Test Script**: `/home/user/win-qemu/scripts/test-virtio-fs.sh`
- **Shared Directory**: `/home/user/outlook-data`
- **VM XML Backups**: `/var/lib/libvirt/qemu/backups/`
- **Log File**: `/var/log/win-qemu/setup-virtio-fs.log`

---

## Additional Resources

### Documentation

- **Implementation Guide**: `outlook-linux-guide/06-seamless-bridge-integration.md`
- **Security Analysis**: `research/06-security-hardening-analysis.md`
- **Troubleshooting**: `research/07-troubleshooting-failure-modes.md`
- **Agent System**: `.claude/agents/virtio-fs-specialist.md`

### External Links

- **WinFsp Project**: https://github.com/winfsp/winfsp
- **VirtIO Drivers**: https://fedorapeople.org/groups/virt/virtio-win/
- **Libvirt Documentation**: https://libvirt.org/formatdomain.html#filesystems
- **QEMU virtio-fs**: https://qemu.readthedocs.io/en/latest/tools/virtiofsd.html

### Support

For issues or questions:
1. Check this documentation first
2. Run test script: `sudo /home/user/win-qemu/scripts/test-virtio-fs.sh --vm win11-outlook`
3. Review logs: `/var/log/win-qemu/setup-virtio-fs.log`
4. Consult agent system: `.claude/agents/virtio-fs-specialist.md`

---

**Document Version**: 1.0.0
**Last Updated**: 2025-01-19
**Maintainer**: win-qemu agent ecosystem
**License**: See project LICENSE file
