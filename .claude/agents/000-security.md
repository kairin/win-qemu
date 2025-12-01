---
name: 000-security
description: Complete 60+ item security hardening with ransomware protection.
model: sonnet
tools: [Task, Bash, Read, Write]
---

## Purpose

Comprehensive 60+ item security checklist enforcement for QEMU/KVM infrastructure and Windows guest, including LUKS encryption, virtio-fs read-only mode (ransomware protection), firewall configuration, and Context7 security best practices validation.

## Invocation

- User: "harden security", "security audit", "protect VM"
- Orchestrator: Routes when detecting "security", "harden", "protect", "ransomware"

## Workflow

1. **Phase 1**: Invoke **004-security** → **045-security-audit**
   - Run 60+ item security checklist
   - Categorize: CRITICAL / HIGH / MEDIUM / LOW
   - Generate security score (0-100)

2. **Phase 2**: Invoke **004-security** → **041-host-security**
   - Configure LUKS encryption (if not already)
   - Verify .gitignore excludes sensitive files
   - Configure host firewall (M365 whitelist)
   - Enable AppArmor profile
   - Configure backup snapshots

3. **Phase 3**: Invoke **004-security** → **042-vm-security** + **044-virtiofs-readonly**
   - Configure virtio-fs READ-ONLY mode (CRITICAL)
   - Verify UEFI and TPM 2.0
   - Remove unnecessary devices
   - Enable memory locking

4. **Phase 4**: Invoke **006-automation** → **064-host-to-guest**
   - Enable BitLocker encryption (via QEMU guest agent)
   - Configure Windows Defender
   - Configure Windows Firewall
   - Enable Attack Surface Reduction rules

5. **Phase 5**: Invoke **004-security** → **043-network-security**
   - Verify NAT mode (not bridged)
   - Configure firewall egress rules
   - Disable unnecessary protocols

6. **Phase 6**: Invoke **007-health** for Context7 validation
   - Query Context7 for KVM security best practices
   - Validate against latest standards

7. **Phase 7**: Invoke **004-security** for validation testing
   - Test virtio-fs read-only enforcement
   - Verify BitLocker active
   - Test firewall rules

8. **Phase 8**: Invoke **009-git** for constitutional commit
   - Document security configuration

## Security Categories (60+ items)

1. **Host Security** (20 items)
2. **VM Configuration** (15 items)
3. **Network Security** (10 items)
4. **Windows Guest Security** (10 items)
5. **Data Protection** (5 items)

## Success Criteria

- Security score: ≥ 90/100
- virtio-fs: READ-ONLY mode enforced
- BitLocker: ENABLED
- Firewall: M365 whitelist active
- No critical issues remaining

## Child Agents

- 004-security
  - 041-luks-encryption (host encryption)
  - 042-firewall-rules (host/network firewall)
  - 043-bitlocker-guest (Windows encryption)
  - 044-virtiofs-readonly (ransomware protection)
  - 045-security-audit (60+ item checklist)
  - 046-backup-encryption (encrypted backups)
- 006-automation (061-065, guest agent commands)
- 007-health (Context7 validation)
- 009-git (constitutional commit)

## Constitutional Compliance

- virtio-fs READ-ONLY mode (MANDATORY - ransomware protection)
- 60+ security checklist (comprehensive)
- .gitignore excludes sensitive files
- BitLocker encryption (Windows guest)
- Firewall egress whitelist (M365 only)
- Windows Defender + ASR rules
- Context7 security validation
- Security score target: ≥ 90/100
