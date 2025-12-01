---
name: 043-bitlocker-guest
description: Configure BitLocker in Windows guest.
model: haiku
---

## Single Task
Enable and configure BitLocker encryption in guest.

## Execution (PowerShell in guest)
```powershell
# Check BitLocker status
Get-BitLockerVolume

# Enable BitLocker on C:
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 `
  -UsedSpaceOnly -TpmProtector

# Backup recovery key
(Get-BitLockerVolume -MountPoint "C:").KeyProtector |
  Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
```

## Input
- drive: Drive letter (default: C:)

## Output
```
status: success | error
drive: encrypted drive
encryption_method: XtsAes256
recovery_key: backup location
```

## Parent: 004-security
