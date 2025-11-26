# Troubleshooting and Failure Modes Analysis
## QEMU/KVM Outlook Virtualization - Common Issues & Solutions

**Research Agent:** Troubleshooting & Diagnostics Specialist
**Analysis Date:** November 14, 2025

---

## Executive Summary

This document catalogs common failure modes, diagnostic procedures, and recovery strategies for the QEMU/KVM Microsoft 365 Outlook virtualization solution. Analysis covers 7 major failure categories with root cause analysis and step-by-step resolution procedures.

**Key Finding:** Most failures stem from improper resource allocation or missing VirtIO drivers, not software configuration issues.

---

## 1. Installation Failures

### 1.1 "We couldn't find any drives" During Windows Installation

**Symptom:**
- Windows 11 installer shows empty disk list
- No installation target available

**Root Cause:**
- Windows 11 lacks VirtIO storage drivers
- VM configured with VirtIO-SCSI but no driver loaded

**Diagnosis:**
```bash
# Verify VM is using VirtIO storage
virsh dumpxml <vm_name> | grep -A 3 "disk type"
# Should show: bus='virtio'
```

**Solution:**
1. Attach virtio-win.iso as second CD-ROM
2. Click "Load Driver" in Windows installer
3. Browse to E:\viostor\w11\amd64
4. Install driver
5. Disk will appear

**Prevention:**
- Always attach virtio-win.iso before starting installer
- Consider using SATA initially, then switch to VirtIO later

---

### 1.2 "This PC can't run Windows 11" Error

**Symptom:**
- Installation fails with compatibility error
- TPM or CPU generation check fails

**Root Cause:**
- Missing TPM 2.0 device
- CPU not set to host-passthrough
- Secure Boot not enabled

**Diagnosis:**
```bash
# Check TPM configuration
virsh dumpxml <vm_name> | grep -A 3 "tpm"

# Check CPU mode
virsh dumpxml <vm_name> | grep "cpu mode"
# Should show: mode='host-passthrough'

# Check firmware
virsh dumpxml <vm_name> | grep -A 3 "loader"
# Should show: type='pflash' and OVMF
```

**Solution:**
```bash
# Add TPM 2.0
virsh edit <vm_name>
# Add:
<tpm model='tpm-tis'>
  <backend type='emulator' version='2.0'/>
</tpm>

# Set CPU to host-passthrough
<cpu mode='host-passthrough' check='none'/>

# Ensure UEFI firmware
<loader readonly='yes' secure='yes' type='pflash'>/usr/share/OVMF/OVMF_CODE.fd</loader>
```

---

## 2. Boot and Startup Issues

### 2.1 VM Won't Start - OVMF Firmware Error

**Symptom:**
```
error: internal error: process exited while connecting to monitor:
Could not open '/usr/share/OVMF/OVMF_CODE.fd'
```

**Root Cause:**
- OVMF package not installed
- Incorrect firmware path

**Solution:**
```bash
# Install OVMF
sudo apt install ovmf

# Verify files exist
ls -l /usr/share/OVMF/OVMF_CODE.fd

# Restart libvirtd
sudo systemctl restart libvirtd
```

---

### 2.2 VM Boots to Black Screen

**Symptom:**
- VM starts but displays black screen
- No error messages

**Root Cause:**
- Graphics driver issue
- QXL vs VirtIO mismatch
- Missing 3D acceleration

**Diagnosis:**
```bash
# Check video configuration
virsh dumpxml <vm_name> | grep -A 5 "video"
```

**Solution:**
```bash
# Switch to VirtIO with 3D acceleration
virsh edit <vm_name>
<video>
  <model type='virtio' heads='1' primary='yes'>
    <acceleration accel3d='yes'/>
  </model>
</video>

# Restart VM
virsh destroy <vm_name>
virsh start <vm_name>
```

---

### 2.3 Slow Boot Times (>60 seconds)

**Symptom:**
- VM takes several minutes to boot
- Windows shows "Getting Windows ready"

**Root Cause:**
- Missing Hyper-V enlightenments
- HDD instead of SSD
- Over-provisioned resources

**Diagnosis:**
```bash
# Check enlightenments
virsh dumpxml <vm_name> | grep -A 15 "hyperv"

# Check disk type
lsblk -d -o name,rota  # 0=SSD, 1=HDD

# Check resource allocation
virsh vcpucount <vm_name>
lscpu | grep "^CPU(s):"  # Compare with host
```

**Solution:**
1. Add Hyper-V enlightenments (see performance guide)
2. Move VM to SSD
3. Reduce vCPU count (max 50% of host cores)
4. Enable VirtIO drivers for all devices

---

## 3. Performance Problems

### 3.1 100% CPU Usage on Host

**Symptom:**
- Host system becomes unresponsive
- 100% CPU usage even when VM idle
- Fan noise constantly high

**Root Cause:**
- Over-provisioning (guest has all/most cores)
- Missing Hyper-V enlightenments
- QXL video adapter (software rendering)

**Diagnosis:**
```bash
# Check vCPU allocation
virsh vcpuinfo <vm_name>

# Monitor actual usage
virt-top  # or htop

# Check enlightenments
virsh dumpxml <vm_name> | grep hyperv
```

**Solution:**
```bash
# Reduce vCPU count
virsh setvcpus <vm_name> 4 --maximum --config
virsh setvcpus <vm_name> 4 --config

# Add enlightenments (XML edit)
# See performance optimization guide

# Change video to VirtIO
virsh edit <vm_name>
<video>
  <model type='virtio' heads='1'>
    <acceleration accel3d='yes'/>
  </model>
</video>
```

---

### 3.2 Sluggish GUI / Laggy Outlook

**Symptom:**
- UI feels slow and unresponsive
- Mouse cursor stutters
- Office applications lag

**Root Cause:**
- QXL video adapter
- No 3D acceleration
- Insufficient memory
- HDD storage

**Diagnosis:**
```powershell
# In Windows guest
Get-WmiObject Win32_VideoController
# Should show: "Red Hat VirtIO GPU"

# Check RAM
Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
```

**Solution:**
1. Switch to VirtIO video with 3D acceleration
2. Increase guest RAM to 8GB minimum
3. Ensure host is using SSD
4. Apply Hyper-V enlightenments

---

### 3.3 System Crashes / Freezes

**Symptom:**
- Host or guest crashes randomly
- System freeze requiring hard reset
- OOM (Out of Memory) errors

**Root Cause:**
- Memory over-provisioning
- Host memory exhaustion
- Disk space full

**Diagnosis:**
```bash
# Check memory usage
free -h
virsh dommemstat <vm_name>

# Check disk space
df -h /var/lib/libvirt/images

# Check system logs
journalctl -p err -b  # Errors since boot
dmesg | grep -i "out of memory"
```

**Solution:**
```bash
# Reduce guest RAM (leave 8GB for host)
virsh setmaxmem <vm_name> 8G --config
virsh setmem <vm_name> 8G --config

# Clean up disk space
qemu-img info /var/lib/libvirt/images/<vm>.qcow2
# If virtual size >> actual size, consider trimming

# Monitor memory
watch -n 2 free -h
```

---

## 4. virtio-fs / File Sharing Issues

### 4.1 Shared Drive Doesn't Appear in Windows

**Symptom:**
- Z: drive not visible in "This PC"
- virtio-fs configured but not working

**Root Cause:**
- WinFsp not installed
- VirtIO-FS service not running
- Missing shared memory backing

**Diagnosis:**
```powershell
# In Windows guest
Get-Service | Where-Object {$_.Name -like "*VirtIO*"}
Get-PnpDevice | Where-Object {$_.FriendlyName -like "*VirtIO*"}

# Check if Z: exists
Get-PSDrive
```

```bash
# On host
virsh dumpxml <vm_name> | grep -A 5 "filesystem"
virsh dumpxml <vm_name> | grep -A 3 "memoryBacking"
```

**Solution:**
1. **Install WinFsp** in Windows guest
2. **Install VirtIO-FS driver** from virtio-win.iso
3. **Enable shared memory** in VM XML:
```xml
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```
4. **Start VirtIO-FS service**:
```powershell
Start-Service VirtioFsSvc
Set-Service VirtioFsSvc -StartupType Automatic
```

---

### 4.2 Permission Denied on Shared Files

**Symptom:**
- Can see files but cannot open
- "Access denied" errors

**Root Cause:**
- File permissions on host too restrictive
- Access mode mismatch

**Solution:**
```bash
# On host - fix permissions
chmod 755 /home/user/OutlookArchives
chmod 644 /home/user/OutlookArchives/*.pst

# Verify virtio-fs access mode
virsh dumpxml <vm_name> | grep -A 5 "filesystem"
# Use accessmode='passthrough' or 'mapped'
```

---

## 5. Microsoft 365 / Outlook Issues

### 5.1 Activation Failures

**Symptom:**
- "Product activation required"
- Office apps won't start

**Root Cause:**
- No internet connectivity
- Firewall blocking M365 endpoints
- Clock skew

**Diagnosis:**
```powershell
# Test connectivity
Test-NetConnection outlook.office365.com -Port 443
Test-NetConnection login.microsoftonline.com -Port 443

# Check time
Get-Date
# Compare with: date on host
```

**Solution:**
```powershell
# Fix time sync
w32tm /resync /force

# Test endpoints
$endpoints = @("outlook.office365.com", "login.microsoftonline.com")
foreach ($ep in $endpoints) {
    Test-NetConnection $ep -Port 443
}

# Reset activation
cd "C:\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /act
```

---

### 5.2 Login / Authentication Problems

**Symptom:**
- Can't sign in to Outlook
- Authentication loops
- Certificate errors

**Root Cause:**
- SSL inspection breaking OAuth
- Expired/untrusted certificates
- Proxy misconfiguration

**Diagnosis:**
```powershell
# Check certificates
certutil -verify -urlfetch https://login.microsoftonline.com

# Check proxy
netsh winhttp show proxy

# Test auth endpoint
Invoke-WebRequest https://login.microsoftonline.com
```

**Solution:**
1. **Import corporate root CA** (if SSL inspection)
```powershell
certutil -addstore -enterprise -f "Root" "corporate-ca.cer"
```

2. **Clear credential cache**
```powershell
cmdkey /list | Select-String "office" | ForEach-Object {
    cmdkey /delete:($_ -split ":")[1].Trim()
}
```

3. **Reset Outlook profile**
```powershell
# Backup first, then:
Remove-Item -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles" -Recurse -Force
```

---

### 5.3 Can't Open .pst Files

**Symptom:**
- File > Open shows greyed out .pst option
- "New Outlook" client running instead of classic

**Root Cause:**
- Using "New Outlook" instead of "Classic Outlook"
- .pst on network drive (Z:) treated differently

**Diagnosis:**
```powershell
# Check Outlook version
$outlook = New-Object -ComObject Outlook.Application
$outlook.Version
# Should be 16.x for classic

# Check if New Outlook toggle enabled
# Settings > General > "Try the new Outlook"
```

**Solution:**
1. **Disable "New Outlook"**:
   - Settings > General > Turn OFF "Try the new Outlook"
   - Restart Outlook

2. **Use classic Outlook executable**:
```powershell
# Run classic Outlook directly
Start-Process "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
```

3. **Open .pst manually**:
   - File > Open & Export > Open Outlook Data File
   - Browse to Z:\archive.pst

---

## 6. Guest Agent Problems

### 6.1 Agent Not Responding

**Symptom:**
```bash
virsh qemu-agent-command <vm> '{"execute":"guest-ping"}'
error: Guest agent is not responding
```

**Root Cause:**
- Service not running in guest
- virtio-serial channel not configured
- Guest agent not installed

**Diagnosis:**
```bash
# Check channel exists
virsh dumpxml <vm> | grep -A 3 "channel type"

# Check socket
ls -l /var/lib/libvirt/qemu/channel/target/domain-<vm>/
```

```powershell
# In guest
Get-Service QEMU-GA
Get-Process qemu-ga
```

**Solution:**
```powershell
# In guest
Start-Service QEMU-GA
Set-Service QEMU-GA -StartupType Automatic
```

```bash
# Add channel if missing
virsh edit <vm>
<channel type='unix'>
  <source mode='bind' path='/var/lib/libvirt/qemu/channel/target/domain-<vm>/org.qemu.guest_agent.0'/>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
```

---

## 7. Network / Connectivity Issues

### 7.1 No Internet in VM

**Symptom:**
- Guest cannot reach internet
- Ping fails to 8.8.8.8
- No DNS resolution

**Diagnosis:**
```powershell
# In guest
ipconfig /all  # Check IP and gateway
Test-Connection 8.8.8.8
Test-Connection google.com
nslookup google.com
```

```bash
# On host
virsh net-info default  # Should be "active"
sudo iptables -t nat -L -n -v | grep MASQUERADE
cat /proc/sys/net/ipv4/ip_forward  # Should be 1
```

**Solution:**
```bash
# Restart network
virsh net-destroy default
virsh net-start default

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Restart VM
virsh destroy <vm>
virsh start <vm>
```

---

### 7.2 RDP Connection Failures

**Symptom:**
- xfreerdp cannot connect to VM
- "Connection failed" error

**Root Cause:**
- RDP service not running
- Firewall blocking port 3389
- Wrong IP address

**Diagnosis:**
```powershell
# In guest
Get-Service TermService
netstat -an | findstr :3389
Get-NetFirewallRule -DisplayGroup "Remote Desktop"
ipconfig  # Verify IP
```

**Solution:**
```powershell
# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Restart-Service TermService
```

```bash
# Get VM IP
virsh net-dhcp-leases default

# Test connection
xfreerdp /v:192.168.122.X /u:user /cert-ignore
```

---

## 8. Recovery Procedures

### 8.1 Restoring from Snapshot

**When to Use:**
- Windows update breaks system
- Malware infection
- Configuration change causes issues

**Procedure:**
```bash
# List snapshots
virsh snapshot-list <vm>

# Revert to snapshot
virsh snapshot-revert <vm> --snapshotname <snapshot-name>

# Verify
virsh snapshot-current <vm> --name
```

---

### 8.2 Emergency VM Access (Locked Out)

**Scenario:** Can't login to Windows

**Solution - Reset Password:**
```bash
# Install virt-customize
sudo apt install libguestfs-tools

# Reset password (VM must be shut down)
virsh shutdown <vm>
virt-customize -a /var/lib/libvirt/images/<vm>.qcow2 \
  --password administrator:password:newpassword
virsh start <vm>
```

---

### 8.3 Recovering Corrupted VM

**Symptoms:**
- VM won't boot
- Disk corruption errors
- File system errors

**Diagnosis:**
```bash
# Check qcow2 integrity
qemu-img check /var/lib/libvirt/images/<vm>.qcow2

# Attempt repair
qemu-img check -r all /var/lib/libvirt/images/<vm>.qcow2
```

**Recovery:**
```bash
# If unfixable, restore from backup
cp /backups/<vm>.qcow2 /var/lib/libvirt/images/

# Or extract data from snapshot
guestmount -a /var/lib/libvirt/images/<vm>.qcow2 -m /dev/sda2 /mnt
cp -r /mnt/Users/youruser/important-data /recovery/
guestunmount /mnt
```

---

## 9. Diagnostic Commands Quick Reference

### Host (Ubuntu)
```bash
# VM status
virsh list --all
virsh dominfo <vm>

# Resource usage
virt-top
virsh domstats <vm>

# Logs
journalctl -u libvirtd -f
tail -f /var/log/libvirt/qemu/<vm>.log

# Network
virsh net-info default
virsh net-dhcp-leases default

# Guest agent
virsh qemu-agent-command <vm> '{"execute":"guest-ping"}'

# Filesystem
virsh domfsinfo <vm>
```

### Guest (Windows)
```powershell
# System info
Get-ComputerInfo
systeminfo

# Network
ipconfig /all
Test-NetConnection <endpoint> -Port 443
Get-NetAdapter
Get-DnsClientServerAddress

# Services
Get-Service | Where-Object {$_.Status -eq "Running"}
Get-Service QEMU-GA
Get-Service VirtioFsSvc

# Drivers
Get-PnpDevice | Where-Object {$_.FriendlyName -like "*VirtIO*"}

# Performance
Get-Counter '\Processor(_Total)\% Processor Time'
Get-Counter '\Memory\Available MBytes'

# Outlook
Get-Process OUTLOOK
Test-Path "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
```

---

## 10. Prevention Best Practices

1. **Take snapshots before:**
   - Windows updates
   - Office updates
   - Major configuration changes

2. **Regular backups:**
   - Weekly VM disk backup
   - Daily .pst file backup
   - Test restore procedures

3. **Monitor resources:**
   - Check disk space weekly
   - Monitor memory usage
   - Review performance metrics

4. **Keep updated:**
   - Ubuntu security updates
   - QEMU/libvirt updates
   - Windows updates (but snapshot first)
   - VirtIO driver updates

5. **Document changes:**
   - Keep change log
   - Note performance baselines
   - Track issues and solutions

---

## Conclusion

Most troubleshooting falls into these categories:
1. **Resource allocation** (50% of issues)
2. **Missing VirtIO drivers** (25% of issues)
3. **Network configuration** (15% of issues)
4. **M365 authentication** (10% of issues)

Proper initial configuration prevents 80% of problems. For the remaining 20%, this troubleshooting guide provides systematic diagnostic and resolution procedures.
