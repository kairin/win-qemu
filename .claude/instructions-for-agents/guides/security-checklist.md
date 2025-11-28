# Security Hardening Checklist (60+ Items)

[← Back to Index](../README.md)

---

## Host Security (30 items)

### Encryption (5 items)
- [ ] LUKS encryption for VM images partition
- [ ] LUKS encryption for PST files partition
- [ ] Strong passphrase (20+ characters)
- [ ] Backup LUKS header
- [ ] Auto-mount with crypttab

### File Permissions (5 items)
- [ ] VM images: 600 (owner only)
- [ ] PST files: 600 (owner only)
- [ ] VM directories: 700
- [ ] libvirt-qemu:kvm ownership for VMs
- [ ] No world-readable sensitive files

### Process Isolation (5 items)
- [ ] AppArmor profile for QEMU
- [ ] SELinux context for VMs
- [ ] Dedicated libvirt-qemu user
- [ ] No root execution of VMs
- [ ] Cgroup isolation enabled

### System Hardening (5 items)
- [ ] Kernel updates current
- [ ] QEMU updates current
- [ ] No unnecessary services
- [ ] SSH key-only authentication
- [ ] Fail2ban configured

### Audit Logging (5 items)
- [ ] auditd enabled
- [ ] VM start/stop logged
- [ ] File access logged
- [ ] Login attempts logged
- [ ] Log rotation configured

### Backup Security (5 items)
- [ ] Encrypted backups
- [ ] Off-site backup copy
- [ ] Backup verification tested
- [ ] Backup access restricted
- [ ] Recovery procedure documented

---

## Network Security (15 items)

### Firewall (5 items)
- [ ] UFW enabled
- [ ] Default deny outgoing
- [ ] M365 endpoints whitelisted
- [ ] No open inbound ports
- [ ] Rate limiting configured

### VM Network (5 items)
- [ ] NAT mode (not bridged)
- [ ] No promiscuous mode
- [ ] MAC filtering enabled
- [ ] DHCP snooping
- [ ] ARP inspection

### Traffic Control (5 items)
- [ ] DNS over HTTPS
- [ ] No split tunneling
- [ ] Egress filtering active
- [ ] Traffic logging enabled
- [ ] Anomaly detection

---

## virtio-fs Security (10 items)

### Configuration (5 items)
- [ ] **READ-ONLY MODE** (CRITICAL)
- [ ] Minimal share scope
- [ ] No executable files shared
- [ ] PST files only in share
- [ ] No recursive permissions

### Access Control (5 items)
- [ ] WinFsp installed
- [ ] Guest cannot modify host files
- [ ] No admin shares exposed
- [ ] Share unmounted when not needed
- [ ] Access logging enabled

---

## Guest Security (10 items)

### Windows Hardening (5 items)
- [ ] BitLocker enabled
- [ ] Windows Defender active
- [ ] Windows Update current
- [ ] No unnecessary services
- [ ] SmartScreen enabled

### Application Security (5 items)
- [ ] Office 365 updates current
- [ ] Macro execution disabled
- [ ] Protected View enabled
- [ ] Only signed add-ins
- [ ] No third-party plugins

---

## Quick Validation Commands

```bash
# Check LUKS encryption
sudo cryptsetup status encrypted-vms

# Verify file permissions
find /encrypted/vms -type f -perm /o+r -ls

# Check AppArmor status
sudo aa-status | grep qemu

# Verify firewall rules
sudo ufw status verbose

# Validate virtio-fs read-only
virsh dumpxml VM_NAME | grep -A5 filesystem | grep readonly
```

---

## Critical Security Rules (NEVER VIOLATE)

1. **virtio-fs MUST be read-only** - Ransomware protection
2. **LUKS encryption MUST be enabled** - Data at rest protection
3. **Firewall MUST whitelist only M365** - Egress control
4. **No sensitive files in shares** - Least privilege
5. **Regular backups MUST be encrypted** - Recovery protection

---

[← Back to Index](../README.md)
