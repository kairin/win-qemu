# Network, Connectivity, and Firewall Requirements
## QEMU/KVM Outlook Virtualization Solution

**Research Agent:** Network & Connectivity Specialist
**Analysis Date:** November 14, 2025

---

## Executive Summary

This document analyzes network architecture, connectivity requirements, and firewall configurations for running Microsoft 365 Outlook in a QEMU/KVM virtual machine. The solution uses NAT networking by default, providing security isolation while enabling full M365 functionality.

**Key Finding:** NAT networking provides optimal balance of security and functionality. No special port forwarding or firewall rules required for basic operation. All M365 communication uses standard HTTPS (port 443).

---

## 1. VM Network Configuration

### 1.1 Recommended: NAT (Network Address Translation)

**Default libvirt Configuration:**
```
Guest VM (192.168.122.x)
    ↓ virtio-net
virbr0 NAT bridge (192.168.122.1)
    ↓ iptables NAT/MASQUERADE
Host network interface
    ↓
Internet / Microsoft 365
```

**Advantages:**
- ✅ Security isolation (guest behind NAT firewall)
- ✅ No manual configuration required
- ✅ Works across all host network types (WiFi, Ethernet, VPN)
- ✅ Host mobility (switching networks doesn't break VM)
- ✅ Guest not exposed to external network attacks

**Default DHCP Range:** 192.168.122.2 - 192.168.122.254

### 1.2 Alternative: Bridged Networking

**Only use if:**
- Corporate network requires device registration
- Need direct network access for specific services
- Multiple VMs need to communicate directly

**Trade-off:** Reduced isolation, guest appears as separate physical machine on network

---

## 2. Microsoft 365 Network Requirements

### 2.1 Required Endpoints (Critical)

**Authentication (Azure AD):**
```
login.microsoftonline.com:443 (TCP)
login.microsoft.com:443 (TCP)
login.windows.net:443 (TCP)
```

**Exchange Online / Outlook:**
```
outlook.office365.com:443 (TCP)
outlook.office.com:443 (TCP)
*.outlook.com:443 (TCP)
*.protection.outlook.com:443,587 (TCP)
```

**Office Services:**
```
*.office.com:443 (TCP)
*.office.net:443 (TCP)
officecdn.microsoft.com:443,80 (TCP)
```

**Updates & CDN:**
```
*.windows.net:443 (TCP)
*.windowsupdate.com:443,80 (TCP)
```

### 2.2 Connectivity Test Script

```powershell
# Windows Guest - PowerShell
$endpoints = @(
    "login.microsoftonline.com",
    "outlook.office365.com",
    "officecdn.microsoft.com"
)

foreach ($endpoint in $endpoints) {
    $result = Test-NetConnection $endpoint -Port 443
    if ($result.TcpTestSucceeded) {
        Write-Host "✓ $endpoint" -ForegroundColor Green
    } else {
        Write-Host "✗ $endpoint FAILED" -ForegroundColor Red
    }
}
```

---

## 3. Firewall Configuration

### 3.1 Host Firewall (Ubuntu)

**Default:** libvirt automatically creates necessary iptables rules

**Verify NAT rules:**
```bash
# Check MASQUERADE rule exists
sudo iptables -t nat -L POSTROUTING -v -n | grep MASQUERADE

# Check FORWARD rules
sudo iptables -L FORWARD -v -n
```

**Enhanced Security (Optional):**
```bash
# Block guest access to host services (except DNS/DHCP)
sudo iptables -I FORWARD -i virbr0 -d 192.168.122.1 \
    -p tcp --dport 22 -j REJECT  # Block SSH
sudo iptables -I FORWARD -i virbr0 -d 192.168.122.1 \
    -p tcp --dport 80 -j REJECT  # Block HTTP
```

### 3.2 Guest Firewall (Windows 11)

**Default:** Windows Firewall enabled and should remain enabled

**Verify Outlook rules exist:**
```powershell
Get-NetFirewallApplicationFilter |
    Where-Object {$_.Program -like "*OUTLOOK.EXE*"}
```

**Recommended hardening:**
```powershell
# Block inbound by default
Set-NetFirewallProfile -Profile Domain,Public,Private `
    -DefaultInboundAction Block

# Allow only essential outbound
# (Outlook rules created automatically on install)
```

---

## 4. Corporate Network Scenarios

### 4.1 VPN Configuration Options

**Option 1: VPN on Host (Recommended)**
```
[Guest] → [Host NAT] → [Host VPN] → [Corporate Network]
```
- Simplest configuration
- Guest traffic automatically tunneled
- No VPN client needed in Windows

**Option 2: VPN in Guest**
```
[Guest with VPN client] → [Host NAT] → [Corporate VPN] → [M365]
```
- Better isolation (corporate VPN can't monitor host)
- Clearer security boundary
- Requires VPN client installation in Windows

**Option 3: Split-Tunnel VPN**
```
[Guest] → [Host VPN] → M365 traffic only
         → [Regular Internet] → Other traffic
```
- Best of both worlds
- Requires VPN configuration

### 4.2 Proxy Configuration

**Transparent Proxy:**
- No guest configuration needed
- Works automatically through NAT

**Explicit Proxy:**
```powershell
# Windows guest - configure proxy
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
    -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
    -Name ProxyServer -Value "http://proxy.company.com:8080"
```

**Proxy bypass for M365:**
```
*.microsoftonline.com;*.office.com;*.outlook.com;*.windows.net
```

### 4.3 SSL Inspection Issues

**Problem:** Corporate SSL inspection breaks M365 authentication

**Symptoms:**
- "Certificate not trusted" errors
- Authentication failures
- Login loops

**Solutions:**
1. **Install corporate root CA in Windows guest:**
```powershell
certutil -addstore -enterprise -f "Root" "corporate-root-ca.cer"
```

2. **Request SSL inspection bypass for M365 endpoints** (preferred)

3. **Verify certificate chain:**
```powershell
$req = [Net.WebRequest]::Create("https://login.microsoftonline.com")
$req.GetResponse() | Out-Null
$req.ServicePoint.Certificate.Subject
# Should show: CN=login.microsoftonline.com (NOT corporate proxy)
```

---

## 5. virtio-fs and Guest Agent Communication

### 5.1 virtio-fs Does NOT Use Network

**Important:** virtio-fs filesystem sharing uses **shared memory**, not network protocols.

```
Host: /home/user/OutlookArchives
  ↓ virtiofsd daemon
  ↓ Shared memory (memfd)
  ↓ VirtIO-FS protocol
Guest: Z:\ drive (WinFsp + VirtIO-FS driver)
```

**No network ports used**
**No firewall rules needed**
**Cannot be accessed over network**

### 5.2 QEMU Guest Agent Communication

**Transport:** virtio-serial channel (NOT network)

```
Host: /var/lib/libvirt/qemu/channel/target/.../org.qemu.guest_agent.0 (Unix socket)
  ↓ QEMU virtio-serial emulation
Guest: VirtIO Serial driver + qemu-ga.exe service
```

**Security:**
- Local-only communication
- No network exposure
- Requires host-level access to use

**Test connectivity:**
```bash
virsh qemu-agent-command <vm_name> '{"execute":"guest-ping"}'
```

---

## 6. Network Troubleshooting

### 6.1 Common Issues and Solutions

**Issue: "No internet access in guest"**

Diagnosis:
```bash
# Host - verify NAT network is active
virsh net-info default

# Check IP forwarding enabled
cat /proc/sys/net/ipv4/ip_forward  # Should be 1
```

Solution:
```bash
# Restart libvirt network
virsh net-destroy default
virsh net-start default

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
```

**Issue: "Cannot reach M365 services"**

Diagnosis:
```powershell
# Windows guest
nslookup outlook.office365.com
Test-NetConnection outlook.office365.com -Port 443
```

Solution:
```powershell
# Change DNS to public resolver
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses ("8.8.8.8","1.1.1.1")

# Flush DNS cache
ipconfig /flushdns
```

**Issue: "Authentication fails with certificate errors"**

Diagnosis:
```powershell
certutil -url https://login.microsoftonline.com
```

Solution:
```powershell
# Update root certificates
certutil -generateSSTFromWU roots.sst

# Import corporate CA if using SSL inspection
certmgr.msc  # Manual import
```

### 6.2 Diagnostic Commands

**Host (Ubuntu):**
```bash
# Verify guest has IP address
virsh net-dhcp-leases default

# Monitor guest network traffic
sudo tcpdump -i virbr0 -n port 443

# Check NAT rules
sudo iptables -t nat -L -v -n

# Test host connectivity
curl -I https://outlook.office365.com
```

**Guest (Windows):**
```powershell
# Network adapter status
Get-NetAdapter | Select Name, Status, LinkSpeed

# IP configuration
ipconfig /all

# Test DNS
nslookup outlook.office365.com

# Test connectivity
Test-NetConnection outlook.office365.com -Port 443

# Check firewall
Get-NetFirewallProfile

# Check proxy
netsh winhttp show proxy

# Route table
route print
```

---

## 7. RDP/RemoteApp Networking (Optional)

### 7.1 RDP Connection Path

```
Ubuntu Host: xfreerdp client
    ↓ TCP connection to 192.168.122.x:3389
virbr0 bridge
    ↓ Local NAT network
Windows Guest: RDP server (Terminal Services)
```

**Security:**
- RDP port NOT exposed to external network
- Only accessible from host
- Uses local NAT network (192.168.122.0/24)

### 7.2 RDP Configuration

**Enable RDP in guest:**
```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name "fDenyTSConnections" -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Verify listening
netstat -an | findstr :3389
```

**Connect from host:**
```bash
xfreerdp /v:192.168.122.10 /u:username /p:password \
         /app:"||outlook" \
         /sound:sys:pulse /gfx:avc444
```

**Known Issue:** Multi-monitor setups cause RDP RemoteApp window crashes
**Recommendation:** Use full desktop view in virt-manager instead

---

## 8. Security Recommendations

### 8.1 Network Hardening

**Egress Filtering (Recommended):**
```bash
# Allow only M365 domains (whitelist approach)
# Requires DNS-based filtering or IP list maintenance
sudo iptables -A FORWARD -i virbr0 -d <M365_IP_RANGES> -j ACCEPT
sudo iptables -A FORWARD -i virbr0 -j REJECT
```

**Guest Access Restrictions:**
```bash
# Prevent guest from accessing host services
sudo iptables -I FORWARD -i virbr0 -d 192.168.122.1 \
    -p tcp --dport 22 -j REJECT  # SSH
sudo iptables -I FORWARD -i virbr0 -d 192.168.122.1 \
    -p tcp --dport 80:443 -j REJECT  # HTTP/HTTPS
```

**Network Monitoring:**
```bash
# Log suspicious connections
sudo iptables -A FORWARD -i virbr0 -p tcp --dport 22 \
    -j LOG --log-prefix "VM_SSH_SCAN: "

# Packet capture for analysis
sudo tcpdump -i virbr0 -w /var/log/vm-traffic.pcap
```

### 8.2 Corporate Network Best Practices

1. **Use VPN in guest** for clear security boundary
2. **Install corporate root CA** if SSL inspection required
3. **Configure DNS** to use corporate DNS servers
4. **Enable Windows Firewall** with strict outbound rules
5. **Monitor guest traffic** for anomalies
6. **Use split-tunnel VPN** to minimize corporate exposure

---

## 9. Network Architecture Diagram

```
═══════════════════════════════════════════════════════════
                    NETWORK TOPOLOGY
═══════════════════════════════════════════════════════════

Internet / Microsoft 365 Cloud
    ↑
    │ HTTPS (443)
    │ OAuth 2.0 Authentication
    │
┌───┴────────────────────────────────────────────────────┐
│ Ubuntu 25.10 Host                                      │
│                                                         │
│ Physical NIC (eth0/wlan0): 192.168.1.100              │
│           ↑                                             │
│           │ iptables NAT/MASQUERADE                    │
│           │                                             │
│  ┌────────┴────────────────────────────────┐          │
│  │ libvirt NAT Network (virbr0)            │          │
│  │ Bridge IP: 192.168.122.1                │          │
│  │ DHCP: 192.168.122.2-254 (dnsmasq)       │          │
│  │                                          │          │
│  │   ┌──────────────────────────────────┐  │          │
│  │   │ Windows 11 Guest VM              │  │          │
│  │   │                                  │  │          │
│  │   │ virtio-net NIC                   │  │          │
│  │   │ IP: 192.168.122.10 (DHCP)        │  │          │
│  │   │ Gateway: 192.168.122.1           │  │          │
│  │   │ DNS: 192.168.122.1 (→host DNS)   │  │          │
│  │   │                                  │  │          │
│  │   │ Microsoft 365 Outlook            │  │          │
│  │   │ ├─ Connects to M365 via NAT      │  │          │
│  │   │ └─ All traffic encrypted (HTTPS) │  │          │
│  │   └──────────────────────────────────┘  │          │
│  └─────────────────────────────────────────┘          │
│                                                         │
│  Non-Network Communication Channels:                   │
│  • virtio-fs: Shared memory (not network)             │
│  • Guest agent: Unix socket + virtio-serial           │
└─────────────────────────────────────────────────────────┘
```

---

## 10. Quick Reference: Port Matrix

| Service | Port | Protocol | Direction | Endpoint | Required |
|---------|------|----------|-----------|----------|----------|
| **Microsoft 365** |
| HTTPS | 443 | TCP | Outbound | *.office365.com | ✅ Critical |
| HTTPS | 443 | TCP | Outbound | *.microsoftonline.com | ✅ Critical |
| HTTPS | 443 | TCP | Outbound | *.outlook.com | ✅ Critical |
| SMTP (optional) | 587 | TCP | Outbound | smtp.office365.com | 🟡 Optional |
| **RDP (Optional)** |
| RDP | 3389 | TCP | Host→Guest | 192.168.122.x | 🟡 Optional |
| **No Network Required** |
| virtio-fs | N/A | Shared mem | Host↔Guest | N/A | ✅ For .pst |
| Guest agent | N/A | virtio-serial | Host→Guest | N/A | ✅ For automation |

---

## Conclusion

The NAT networking configuration provides an optimal balance of security and functionality for the Microsoft 365 Outlook virtualization solution:

- **Security:** Guest isolated behind NAT firewall
- **Simplicity:** No manual configuration required
- **Compatibility:** Works with all M365 services
- **Performance:** virtio-net provides near-native throughput
- **Flexibility:** Supports VPN, proxy, and corporate networks

The most common network issues are DNS-related or caused by corporate SSL inspection, both of which have well-documented solutions. The architecture requires no special firewall rules or port forwarding for basic operation.
