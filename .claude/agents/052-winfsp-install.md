---
name: 052-winfsp-install
description: Install WinFsp in Windows guest.
model: haiku
---

## Single Task
Install WinFsp filesystem driver in Windows guest.

## Execution (PowerShell in guest)
```powershell
# Download WinFsp
Invoke-WebRequest -Uri "https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi" `
  -OutFile "$env:TEMP\winfsp.msi"

# Install silently
Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\winfsp.msi /quiet" -Wait

# Verify installation
Get-Service WinFsp.Launcher
```

## Input
- version: WinFsp version (default: 2.0)

## Output
```
status: success | error
version_installed: WinFsp version
service_status: running | stopped
```

## Parent: 005-virtiofs
