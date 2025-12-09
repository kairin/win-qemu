# **Section 4. The QEMU/KVM Reference Architecture: A Definitive Guide**

This section provides the comprehensive, step-by-step reference architecture for building a robust, high-performance, and controllable Windows 11 virtual machine on Ubuntu 25.10 using open-source tools. This architecture will serve as the foundation for satisfying all remaining user constraints.

## **4.1. Host Environment Setup (Ubuntu 25.10)**

The first step is to install and configure the core virtualization stack on the Ubuntu 25.10 host. This stack consists of the QEMU/KVM hypervisor, the libvirt management daemon, and the virt-manager GUI.

1. **Install Core Packages:** The required packages can be installed from the standard Ubuntu repositories.
   ```bash
   sudo apt update
   sudo apt install qemu-kvm qemu-system-x86 libvirt-daemon-system \
                    libvirt-clients bridge-utils virt-manager \
                    libosinfo-bin ovmf swtpm swtpm-tools
   ```

2. **User Group Configuration:** The user account must be added to the libvirt and kvm groups to manage virtual machines without sudo.
   ```bash
   sudo usermod -aG libvirt $USER
   sudo usermod -aG kvm $USER
   ```
   (A re-login or newgrp libvirt is required for this to take effect).

3. **Verify Service Status:** Enable and start the libvirtd service.
   ```bash
   sudo systemctl enable --now libvirtd
   sudo systemctl status libvirtd
   ```

The primary tool for this guide will be virt-manager (Virtual Machine Manager), a mature graphical front-end for libvirt that provides an excellent balance between usability and deep XML-level configuration.

## **4.2. Guest VM Creation (Windows 11)**

The most common failure point for users is creating a Windows 11 guest that is both stable and performant. This is due to Windows 11's strict hardware requirements (TPM 2.0, Secure Boot, modern CPU), which must be "faked" by the hypervisor.

Using virt-manager, create a new VM with the following *mandatory* settings:

1. **Chipset:** At the final "Customize configuration before install" screen, ensure the Chipset is set to **Q35**.
2. **Firmware:** The Firmware *must* be set to **OVMF (UEFI)**. The default OVMF_CODE.fd file provided by the ovmf package is sufficient. Secure Boot should be enabled by editing the XML to include \<loader readonly='yes' secure='yes'\>....
3. **TPM:** Add a new hardware device:
   * Type: **TPM**
   * Model: **TIS**
   * Version: **2.0**
   * This will automatically use the host's swtpm (Software TPM) daemon installed in step 4.1.
4. **CPU:** In the "CPUs" section, set the "CPU model" to **host-passthrough**. This passes the host CPU's exact model and features to the guest, satisfying the Windows 11 generation check.
5. **Storage:** When creating the primary virtual disk (e.g., vdisk.qcow2), expand the "Advanced options" and set the "Disk bus" to **VirtIO**. This is *critical* for performance.
6. **Networking:** In the "NIC" section, set the "Device model" to **virtio**.

## **4.3. Windows 11 Installation and VirtIO Driver-Loading**

This configuration creates a high-performance VM, but Windows 11 does not have VirtIO drivers "in-box." This will lead to the installer failing to find any disks or network adapters.

1. **Download VirtIO Drivers:** Before starting, download the "latest stable virtio-win ISO" from the official Fedora repository (this is the standard, upstream-signed driver package).
2. **Attach ISOs:** In virt-manager, attach two CD-ROM devices:
   * CD-ROM 1: The Windows 11 installation ISO.
   * CD-ROM 2: The virtio-win.iso file.
3. **Boot and Load Driver:** Start the VM and begin the Windows installer.
4. At the "Where do you want to install Windows?" screen, the disk list will be empty.
5. Click **"Load Driver"**.
6. Click "Browse" and navigate to the VirtIO CD-ROM (e.g., E:).
7. Select the storage driver directory: viostor\w11\amd64.
8. Click "Next." The installer will load the VirtIO storage driver, and the virtual disk will appear.
9. **Post-Installation:** After Windows 11 is installed, open "Device Manager." There will be several "Unknown devices" (e.g., "Ethernet Controller," "PCI Simple Communications Controller"). For each one, right-click, select "Update driver," "Browse my computer," and point it to the root of the VirtIO CD-ROM. Windows will automatically find and install all remaining drivers.

## **4.3.1. VirtIO GPU Driver Installation (Critical for Resolution)**

After Windows installation, the display will be limited to 1280x800 resolution because Windows uses the generic "Microsoft Basic Display Adapter" instead of the VirtIO GPU driver. This step is **essential** for high-resolution display support.

1. **Open Device Manager** (Win+X → Device Manager)
2. **Expand "Display adapters"** - You will see "Microsoft Basic Display Adapter"
3. **Right-click** the adapter and select **"Update driver"**
4. **Choose "Browse my computer for drivers"**
5. **Navigate to:** `D:\viogpudo\w11\amd64\` (VirtIO CD-ROM)
6. **Click "Next"** and allow the driver installation
7. **Reboot Windows**

After reboot, Device Manager should show "Red Hat VirtIO GPU DOD controller" and Display Settings will offer multiple resolution options up to 4K (depending on VRAM allocation).

**Troubleshooting:**
| Issue | Solution |
|-------|----------|
| Driver folder not found | Verify VirtIO ISO is mounted; check drive letter |
| Still limited resolution | Increase VM VRAM allocation in libvirt config |
| viogpudo folder missing | Download latest VirtIO ISO from Fedora |

## **4.4. Performance Tuning and Host-Guest Optimization**

A default Windows 11 KVM install can be unstable or suffer from high CPU usage and poor GUI performance. The following post-installation tuning steps are *essential* for a stable, desktop-class experience.

1. **Hyper-V Enlightenments:** This is the most critical tuning step. It makes the Windows guest "KVM-aware," which dramatically improves performance and stability.
   * Shut down the VM.
   * On the host, run `sudo virsh edit <vm_name>`.
   * Inside the \<features\>...\</features\> block, add the following \<hyperv\> block:
     ```xml
     <hyperv mode='custom'>
       <relaxed state='on'/>
       <vapic state='on'/>
       <spinlocks state='on' retries='8191'/>
       <vpindex state='on'/>
       <runtime state='on'/>
       <synic state='on'/>
       <stimer state='on'>
         <direct state='on'/>
       </stimer>
       <reset state='on'/>
       <vendor_id state='on' value='KVM Hv'/>
       <frequencies state='on'/>
       <reenlightenment state='on'/>
       <tlbflush state='on'/>
       <ipi state='on'/>
     </hyperv>
     <kvm>
       <hidden state='on'/>
     </kvm>
     ```
   * Inside the \<clock...\> block, add this timer:
     ```xml
     <timer name='hypervclock' present='yes'/>
     ```

2. **Memory Backing (Prerequisite for Filesharing):** This enables shared memory, which is required for virtio-fs. In the XML, add this block directly under the \<domain...\> opening tag:
   ```xml
   <memoryBacking>
     <source type='memfd'/>
     <access mode='shared'/>
   </memoryBacking>
   ```

3. **GUI Performance:** The default "QXL" video adapter is old. In virt-manager, change the "Video" device model to **VirtIO**. Ensure "3D acceleration" is checked. This provides a modern, accelerated graphics driver (Venus) for a much smoother Office GUI experience.

4. **Resource Contention:** Community reports of "100% CPU" or full system crashes are often caused by over-provisioning (assigning all host cores to the guest) or starving the host OS. The host *is* the hypervisor; it must have dedicated resources. A stable configuration for a host with 8+ cores and 16GB+ RAM is:
   * Guest CPUs: 4 vCPUs
   * Guest RAM: 8 GB
