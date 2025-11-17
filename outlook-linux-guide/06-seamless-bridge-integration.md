# **Section 5. Building the "Seamless Bridge": Host-Guest Integration**

With a stable, high-performance VM built, the next step is to integrate it with the host to satisfy the user's specific workflow constraints. This involves replicating (and improving upon) Winboat's filesystem and application integration.

## **5.1. Filesystem Integration (Solving Constraint #3: .pst Access via virtio-fs)**

This is the most critical piece of the architecture, directly solving the .pst file requirement. Instead of a slow network-based Samba share, this architecture uses virtio-fs, a modern, high-performance, FUSE-based shared filesystem that leverages the proximity of the guest and host.

**Host-side (Ubuntu) Configuration:**

1. Ensure the \<memoryBacking\> (from step 4.4) is present in the VM's XML.
2. Shut down the VM.
3. In virt-manager, open the VM's settings and click "Add Hardware."
4. Select "Filesystem".
5. Set "Driver" to: **virtiofs**.
6. Set "Source path" to the folder on the Ubuntu host that will hold the .pst files (e.g., /home/username/OutlookArchives).
7. Set "Target path" to a simple name (a "mount tag"), e.g., linux-archives.
8. Click "Finish."

**Guest-side (Windows 11) Configuration:**

1. **Install Prerequisite (WinFsp):** virtio-fs for Windows is a user-mode filesystem, and it *requires* the **WinFsp** (Windows File System in Userspace) framework. Download and install the latest WinFsp installer from its official project site (e.g., winfsp.dev).
2. **Install VirtIO-FS Driver:** Mount the virtio-win.iso again. Go to Device Manager and find the "Mass storage controller" under "Other devices". Update its driver, pointing to the virtio-win.iso.
3. **Install and Start Service:** The VirtIO driver ISO includes a VirtIO-FS Service (virtiofs.exe). This service is what actually mounts the drive.
   * Install the service (it may be a standalone .msi on the ISO or require manual installation via sc.exe create).
   * Open services.msc in Windows.
   * Find the "VirtIO-FS Service".
   * Set its "Startup type" to **Automatic** and click **Start**.

**Result:**
Within seconds, a new network drive (often Z:) will appear in "My Computer" (This PC) labeled with the "Target path" tag (e.g., "linux-archives"). This drive is a direct, high-performance channel to the /home/username/OutlookArchives folder on the host.
The user can now install Microsoft 365 Outlook, launch it, navigate to File > Open & Export > Open Outlook Data File, and select Z:\my_archive.pst. This directly, natively, and robustly satisfies Constraint #3.

## **5.2. Application Integration (The "Native" Feel via RemoteApp)**

This optional step replicates the "seamless window" feature of Winboat without the Winboat application itself. This relies on the same FreeRDP and RemoteApp technology.

**Guest-side (Windows 11) Configuration:**

1. This feature requires **Windows 11 Pro or Enterprise**.
2. Enable Remote Desktop in "System > Remote Desktop."
3. Publish Outlook as a RemoteApp. This is done by adding the application's path to a specific registry key:
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\outlook
   * Create a REG_SZ value named Path and set it to: C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE
   * Create a REG_SZ value named Name and set it to: Microsoft Outlook

**Host-side (Ubuntu) Configuration:**

1. Install the FreeRDP client: `sudo apt install freerdp2-x11`.
2. Create a shell script or a .desktop file on the Ubuntu desktop to launch the application. The command will be:
   ```bash
   xfreerdp /v:<vm_ip_address> /u:<windows_username> /p:<password> \
            /app:"||outlook" \
            /sound:sys:pulse /gfx:avc444 /gdi:hw
   ```
   (The ||outlook refers to the registry key name created above).

**Result:**
Executing this command on the host will start the VM (if configured with Wake-on-LAN) or connect to the running VM, and open only the Microsoft Outlook window on the Linux desktop. It will have its own icon and behave like a native application.

**Alternative (More Stable) Method:**
Given the known instability of RDP RemoteApp with multi-monitor setups, a simpler and often more robust solution is to forgo the "seamless" integration. The user can simply run the full Windows desktop in a standard virt-manager window, minimized or on a separate virtual desktop. This provides 100% stability and avoids all RDP-related bugs.
