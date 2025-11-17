# Pre-Installation Action Plan - Quick Reference

**Generated**: 2025-11-17
**Overall Readiness**: 65% (YELLOW - Ready with Prep Work)
**Time to Ready**: 1.5 hours (Critical + High Priority)

---

## PHASE 1: CRITICAL BLOCKERS ⚠️

**Status**: MUST COMPLETE BEFORE VM CREATION
**Total Time**: 1 hour 12 minutes

### Task 1.1: Download VirtIO Drivers ISO (15 min)
```bash
cd /home/kkk/Apps/win-qemu/source-iso
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
```
**Verify**: `ls -lh virtio-win.iso` (should show ~500MB file)

---

### Task 1.2: Install QEMU/KVM Software Stack (45 min)
```bash
# Update package lists
sudo apt update

# Install all required packages
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    swtpm \
    guestfs-tools \
    virt-top \
    libvirt-daemon-driver-qemu \
    qemu-block-extra

# Add user to virtualization groups
sudo usermod -aG libvirt,kvm $USER
```
**Packages Installing**: 7 critical + 3 optional = 10 packages

---

### Task 1.3: Reboot System (5 min)
```bash
sudo reboot
```
**Required**: Group membership changes require logout/login or reboot

---

### Task 1.4: Verify Installation (5 min)
```bash
# After reboot, verify:

# 1. Check virsh works
virsh version

# 2. Check libvirtd is running
systemctl status libvirtd

# 3. Verify group membership
groups | grep -E 'libvirt|kvm'

# 4. Check default network
virsh net-list --all

# 5. Verify KVM acceleration available
virsh capabilities | grep kvm
```

**Expected Output**:
- virsh version: libvirt 9.x+
- libvirtd: active (running)
- groups: shows "libvirt kvm"
- net-list: shows "default" network
- capabilities: shows kvm support

---

### Task 1.5: Create Missing Directories (1 min)
```bash
cd /home/kkk/Apps/win-qemu
mkdir -p scripts configs
echo "# Automation Scripts" > scripts/README.md
echo "# Configuration Templates" > configs/README.md
```

---

## PHASE 2: HIGH PRIORITY 🔥

**Status**: COMPLETE BEFORE VM INTERNET ACCESS
**Total Time**: 22 minutes

### Task 2.1: Configure UFW Firewall (20 min)
```bash
# Install UFW if not present
sudo apt install ufw

# Enable firewall
sudo ufw enable

# Default deny all traffic
sudo ufw default deny outgoing
sudo ufw default deny incoming

# Allow localhost
sudo ufw allow from 127.0.0.1
sudo ufw allow to 127.0.0.1

# Whitelist Microsoft 365 endpoints (critical for Outlook)
sudo ufw allow out to outlook.office365.com port 443
sudo ufw allow out proto tcp to 52.96.0.0/12 port 443
sudo ufw allow out proto tcp to 40.96.0.0/12 port 443

# Allow DNS (required for M365 name resolution)
sudo ufw allow out 53

# Verify rules
sudo ufw status verbose
```

**Expected Output**:
- Status: active
- Default: deny (incoming), deny (outgoing)
- M365 endpoints whitelisted

---

### Task 2.2: Commit Repository Changes (2 min)
```bash
cd /home/kkk/Apps/win-qemu

# Stage changes
git add scripts/ configs/

# Commit with constitutional format
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout -b "${DATETIME}-config-pre-installation-setup"

git commit -m "Pre-installation setup: created scripts/ and configs/ directories

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Merge to main
git checkout main
git merge "${DATETIME}-config-pre-installation-setup" --no-ff
```

---

## PHASE 3: MEDIUM PRIORITY ⚙️

**Status**: CAN DEFER TO POST-INSTALLATION
**Total Time**: 47 minutes

### Task 3.1: Create Encrypted Container for PST Files (45 min)
```bash
# Create 50GB encrypted LUKS container
sudo dd if=/dev/zero of=/home/kkk/outlook-encrypted.img bs=1G count=50

# Format as LUKS (will prompt for password)
sudo cryptsetup luksFormat /home/kkk/outlook-encrypted.img

# Open encrypted container
sudo cryptsetup open /home/kkk/outlook-encrypted.img outlook-crypt

# Create filesystem
sudo mkfs.ext4 /dev/mapper/outlook-crypt

# Mount for use
sudo mkdir -p /mnt/outlook-encrypted
sudo mount /dev/mapper/outlook-crypt /mnt/outlook-encrypted

# Set ownership
sudo chown $USER:$USER /mnt/outlook-encrypted
```

**Purpose**: Protect PST files with encryption (MANDATORY per AGENTS.md, but can defer until PST files exist)

---

### Task 3.2: Verify AppArmor Configuration (2 min)
```bash
# Check if AppArmor is active
sudo aa-status | grep qemu

# Verify libvirt profiles loaded
sudo aa-status | grep libvirt
```

**Expected**: AppArmor profiles for QEMU/libvirt should be loaded automatically after libvirt installation.

---

## PHASE 4: IMPLEMENTATION ASSETS 🛠️

**Status**: CREATE DURING VM IMPLEMENTATION
**Total Time**: 7-8 hours (incremental)

**Approach**: Create these scripts/configs iteratively as you implement each phase of VM setup.

### Scripts to Create (5-6 hours)
1. **scripts/create-vm.sh** - Automated VM creation (2 hours)
2. **scripts/install-virtio-drivers.sh** - VirtIO automation (1 hour)
3. **scripts/configure-performance.sh** - Hyper-V enlightenments (1 hour)
4. **scripts/setup-virtio-fs.sh** - Filesystem sharing (1 hour)
5. **scripts/health-check.sh** - System validation (30 min)

### Configs to Create (2 hours)
1. **configs/win11-vm.xml** - Complete VM definition (1 hour)
2. **configs/virtio-fs-share.xml** - Filesystem config (30 min)
3. **configs/network-nat.xml** - Network config (20 min)

**Recommendation**: Use specialized agents to generate these:
- vm-operations-specialist
- performance-optimization-specialist
- virtio-fs-specialist
- qemu-automation-specialist

---

## Quick Verification Checklist

### Hardware ✅
- [x] CPU: AMD Ryzen 5 5600X (12 threads) - EXCELLENT
- [x] RAM: 76GB - EXCELLENT
- [x] Storage: 1.4TB NVMe SSD - EXCELLENT
- [x] Virtualization: AMD-V enabled - PASS
- [x] Windows 11 ISO: 7.7GB ready - PASS
- [ ] VirtIO ISO: **MISSING - DOWNLOAD REQUIRED**

### Software (After Phase 1)
- [ ] qemu-kvm installed
- [ ] libvirt-daemon-system installed
- [ ] libvirt-clients installed
- [ ] bridge-utils installed
- [ ] virt-manager installed
- [ ] swtpm installed
- [ ] guestfs-tools installed
- [ ] User in libvirt/kvm groups
- [ ] libvirtd service running
- [ ] virsh commands working

### Security (After Phase 2)
- [ ] UFW firewall active
- [ ] M365 endpoints whitelisted
- [ ] Default deny outgoing/incoming
- [ ] AppArmor profiles loaded

### Repository
- [x] Documentation complete (45+ files)
- [x] CLAUDE.md/GEMINI.md symlinks valid
- [x] Git status clean
- [ ] scripts/ directory created
- [ ] configs/ directory created

---

## Execution Sequence

**TODAY (1.5 hours)**:
```
1. Download VirtIO ISO (15 min)
   ↓
2. Install QEMU/KVM packages (45 min)
   ↓
3. Reboot system (5 min)
   ↓
4. Verify installation (5 min)
   ↓
5. Create directories (1 min)
   ↓
6. Configure firewall (20 min)
   ↓
7. Commit changes (2 min)
   ↓
READY FOR VM CREATION ✅
```

**NEXT SESSION (2-3 hours)**:
- Begin VM creation with vm-operations-specialist
- Follow `outlook-linux-guide/05-qemu-kvm-reference-architecture.md`
- Install Windows 11 with VirtIO drivers

**WEEK 1 (Additional 5-8 hours)**:
- Performance optimization (Hyper-V enlightenments)
- Security hardening (LUKS, BitLocker, firewall refinement)
- virtio-fs setup for PST file sharing
- QEMU guest agent installation

**WEEK 2 (Additional 7-8 hours)**:
- Create automation scripts
- Generate configuration templates
- Document custom workflows
- Test and validate complete setup

---

## Agent Coordination

### Phase 1 (Critical)
- **Manual execution required** (apt install, reboot)
- **Verification**: project-health-auditor

### Phase 2 (High Priority)
- **Security**: security-hardening-specialist
- **Git**: git-operations-specialist

### Phase 3 (Medium Priority)
- **Encryption**: security-hardening-specialist

### Phase 4 (Implementation)
- **VM Creation**: vm-operations-specialist
- **Performance**: performance-optimization-specialist
- **Filesystem**: virtio-fs-specialist
- **Automation**: qemu-automation-specialist
- **Orchestration**: master-orchestrator

---

## Success Criteria

**After Phase 1 + Phase 2 Complete**:
- ✅ virsh version shows libvirt 9.x+
- ✅ virsh net-list shows default network
- ✅ User in libvirt and kvm groups
- ✅ libvirtd service active
- ✅ VirtIO ISO downloaded and ready
- ✅ UFW firewall active with M365 whitelist
- ✅ scripts/ and configs/ directories created
- ✅ Repository changes committed

**Ready for VM Creation**: YES ✅

---

## Emergency Rollback

**If something goes wrong**:

### Rollback Software Installation
```bash
# Remove installed packages
sudo apt remove --purge qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virt-manager swtpm guestfs-tools virt-top \
    libvirt-daemon-driver-qemu qemu-block-extra

# Remove user from groups
sudo deluser $USER libvirt
sudo deluser $USER kvm

# Reboot
sudo reboot
```

### Rollback Firewall
```bash
# Disable UFW
sudo ufw disable

# Reset to defaults
sudo ufw --force reset
```

### Rollback Git Changes
```bash
# If commit hasn't been pushed
git reset --hard HEAD~1

# If branch exists
git branch -D <branch-name>
```

---

## References

**Detailed Report**: `docs-repo/pre-installation-readiness-report.md`

**Implementation Guides**:
- `outlook-linux-guide/05-qemu-kvm-reference-architecture.md` - Primary setup guide
- `outlook-linux-guide/09-performance-optimization-playbook.md` - Performance tuning
- `research/02-software-dependencies-analysis.md` - Software requirements
- `research/06-security-hardening-analysis.md` - Security checklist

**Agent Documentation**: `.claude/agents/README.md`

---

**NEXT ACTION**: Execute Phase 1 Task 1.1 (Download VirtIO ISO)
