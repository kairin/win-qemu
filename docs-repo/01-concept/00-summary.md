# **Reference Architecture: Native Microsoft 365 Outlook on Ubuntu 25.10 within Constrained Enterprise Environments**

## **Executive Summary: A Definitive Architecture for a Constrained Environment**

This report provides a definitive technical architecture for running the native Microsoft 365 Outlook desktop application on an Ubuntu 25.10 workstation (circa November 2025) under a specific and highly restrictive set of operational and corporate policy constraints. The query specifies a solution that must be freely available, open-source, and serve as a stable alternative to wrapper solutions like Winboat. The analysis of the five specified constraints reveals a complex technical challenge where most common solutions are rendered non-viable.

The most critical technical driver identified is Constraint #3: the requirement for direct, local access to Microsoft Outlook .pst archive files. As of late 2025, this single constraint definitively invalidates all solutions based on web technologies. This includes the Microsoft 365 Progressive Web App (PWA), Outlook on the Web (OWA), and the "New Outlook" desktop client, which is fundamentally a web wrapper. These platforms do not support direct local .pst file access, offering only server-side *import* functionality, which does not satisfy the requirement. This forces any viable solution to be capable of running the "classic" Win32/x64 Microsoft 365 desktop application suite.

With web-based solutions eliminated, two primary vectors remain: application compatibility layers (e.g., the Wine ecosystem) and full operating system virtualization (e.g., the QEMU ecosystem).

This report will demonstrate that the Wine-based vector, while aligning with the open-source preference, is not a stable or reliable solution for the modern, subscription-based, network-authenticated Microsoft 365 platform. Community data overwhelmingly indicates that while older, perpetually-licensed Office versions (e.g., 2016) may function, Microsoft 365 itself fails due to complex authentication and installer mechanisms.

The second vector, virtualization, is the correct conceptual path. The user's query regarding Winboat's "issues" is valid; analysis reveals these issues (e.g., multi-monitor instability) are symptomatic of its specific implementation as a "black box" RDP/RemoteApp wrapper 1, not a fundamental flaw in its underlying VM technology.

Therefore, this report provides the reference architecture for the only solution that comprehensively satisfies all five user constraints: a dedicated, user-managed, and highly-optimized **QEMU/KVM virtual machine**. This architecture represents the "alternative" to Winboat by removing the fragile wrapper and giving the user transparent, granular control over the full stack. This solution *uniquely* satisfies all constraints by employing:

1. **QEMU/KVM and libvirt** as the open-source, high-performance virtualization stack.2
2. **virtio-fs** as the native, high-speed, host-guest filesystem bridge, providing direct, local access to .pst files residing on the Ubuntu host.
3. **qemu-guest-agent** as the secure, local, API-less control plane, enabling the user's custom automation *without* violating IT policies that forbid Graph API access.

This document provides the complete, in-depth implementation and configuration guide for this reference architecture.
