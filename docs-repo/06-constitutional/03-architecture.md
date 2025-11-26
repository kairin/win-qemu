# System Architecture

## Directory Structure (MANDATORY)

**Root Principle**: Keep root clean. All documentation goes in `docs-repo/`.

**Preservation Mandate**:
- **DO NOT** create new top-level directories.
- **DO NOT** move documentation out of `docs-repo/`.
- **DO NOT** rename established subfolders (`01-concept`, `02-setup`, etc.) without a constitutional amendment.
- **DO** place new documentation in the most relevant subfolder.

```
win-qemu/
├── docs-repo/                    # ALL Documentation
│   ├── 00-INDEX.md               # Master Index
│   ├── 01-concept/               # Requirements, Constraints, Legal
│   ├── 02-setup/                 # Install Guides, Start Guide, Automation
│   ├── 03-ops/                   # Security, Performance, Troubleshooting
│   ├── 04-history/               # Archives, Logs, Validation Reports
│   ├── 05-agents/                # Agent System Manuals
│   └── 06-constitutional/        # Core Mandates & Guidelines
├── scripts/                      # Automation scripts (Bash)
├── configs/                      # XML Templates
├── .claude/                      # Agent configuration
├── AGENTS.md                     # Single Source of Truth (Gateway)
├── CLAUDE.md -> AGENTS.md
└── GEMINI.md -> AGENTS.md
```

## Technology Stack (NON-NEGOTIABLE)

- **Virtualization**: QEMU 8.0+, KVM, libvirt, Q35, OVMF (UEFI), swtpm (TPM 2.0).
- **Drivers**: VirtIO (Storage, Net, GPU, Balloon, FS).
- **Integration**: QEMU Guest Agent, WinFsp (virtio-fs).
- **Optional**: FreeRDP, virt-manager.