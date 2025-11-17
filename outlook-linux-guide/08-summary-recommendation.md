# **Section 7. Summary of Findings and Final Recommendation**

The objective of this report was to identify a freely available, open-source, and stable alternative to Winboat for running the native Microsoft 365 Outlook client on Ubuntu 25.10, subject to five highly restrictive constraints. The analysis of these constraints and the available solution vectors leads to a single, definitive recommendation.

The solution vectors were evaluated as follows:

1. **Vector 1 (Web/PWA/New Outlook): FAILS.** This vector is eliminated by **Constraint #3** (local .pst access). Web-based clients are fundamentally incapable of opening local data files in the manner required.
2. **Vector 2 (Wine/FOSS): FAILS.** This vector (using Wine, PlayOnLinux, or Bottles) fails to reliably run the modern, subscription-based Microsoft 365 suite due to complex, network-based installers and authentication mechanisms.
3. **Vector 3 (Wine/Commercial): FAILED (by constraints).** The release of CrossOver 25.1 in August 2025 provides a technically viable path by fixing M365 login issues. However, it is a proprietary, paid solution and fails the user's explicit "free," "open-source," and "custom automation" requirements.
4. **Vector 4 (VM Wrappers): FAILS.** This vector (Winboat) represents the correct *concept* (virtualization) but a flawed *implementation*.1 It is a "black box" wrapper that suffers from documented RDP bugs, poor performance (no GPU acceleration 3), and is difficult for an end-user to debug or control.
5. **Vector 5 (Self-Managed QEMU/KVM): SUCCEEDS.** Building a "roll-your-own" virtual machine using the open-source QEMU/KVM stack is the *only* solution that comprehensively satisfies all five user constraints.

## **Final Recommendation**

This report definitively recommends the adoption of the dedicated QEMU/KVM reference architecture detailed in Sections 4, 5, and 6. This solution provides a 100% compatible, stable, and performant environment for the "classic" native Outlook desktop client.

This architecture *specifically* uses:

1. **QEMU/KVM + libvirt** as the open-source, high-performance hypervisor, which the user was already investigating.
2. **VirtIO Drivers** for all virtual hardware (storage, network, graphics) to ensure near-native performance.
3. **virtio-fs** as the high-speed, direct filesystem sharing mechanism. This robustly solves **Constraint #3** by providing native access to .pst files on the Linux host.
4. **qemu-guest-agent** as the secure, local, and API-less automation bridge. This solves **Constraint #4** (automation) in a way that is fully compliant with **Constraint #1** (No Graph API).
5. **(Optional) FreeRDP + RemoteApp** for a "seamless" windowed integration, providing an open-source alternative to Winboat's core feature.

While this solution requires a significant, one-time setup investment (approximately 2-3 hours of technical configuration), it is the only architecture that delivers a permanent, stable, and compliant "sandbox" for the Outlook application. It is the definitive engineer's solution, insulating the user's workflow from both Microsoft's disruptive updates and their own IT department's severe restrictions.

## **Works cited**

1. TibixDev/winboat: Run Windows apps on Linux with ... - GitHub, accessed November 14, 2025, [https://github.com/TibixDev/winboat](https://github.com/TibixDev/winboat)
2. QEMU, accessed November 14, 2025, [https://www.qemu.org/](https://www.qemu.org/)
3. WinBoat - Run Windows Apps on Linux with Seamless Integration, accessed November 14, 2025, [https://www.winboat.app/](https://www.winboat.app/)
