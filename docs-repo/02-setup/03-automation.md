# **Section 6. The Automation Engine (Fulfilling Constraint #4)**

This section provides the solution for the "AI control or my own automation implementation" requirement. This is accomplished using the **QEMU Guest Agent**, which provides a secure, local, API-less control plane between the Ubuntu host and the Windows guest, thus respecting the IT policy constraints.

## **6.1. Installing the QEMU Guest Agent**

1. **Guest-side (Windows 11):** The guest agent is included on the virtio-win.iso.
   * Mount the ISO.
   * Run the qemu-ga-x86_64.msi installer.
   * This installs the "QEMU Guest Agent" service. Open services.msc and verify it is **Running** and set to **Automatic** startup.
2. **Host-side (Ubuntu):** The agent requires a communication channel. virt-manager typically adds this automatically. Verify the VM's XML (sudo virsh edit \<vm_name\>) contains the following channel definition:
   ```xml
   <channel type='unix'>
     <source mode='bind' path='/var/lib/libvirt/qemu/channel/target/domain-VM_NAME/org.qemu.guest_agent.0'/>
     <target type='virtio' name='org.qemu.guest_agent.0'/>
   </channel>
   ```

## **6.2. The Host-to-Guest Control Plane (virsh)**

With the agent running, the Ubuntu host can now issue a variety of powerful commands to the guest using the libvirt command-line tool, virsh. This is the core of the automation engine.

Key commands include:

* `virsh shutdown <vm_name> --mode=agent`: Initiates a clean, guest-OS-aware shutdown. This is far more reliable than an ACPI shutdown event.
* `virsh domfsinfo <vm_name>`: Lists all mounted filesystems within the running guest, allowing a script to verify that the virtio-fs share is active.
* `virsh set-user-password <vm_name> <username> <password>`: Sets the password for a local user account inside the guest.
* `virsh qemu-agent-command <vm_name> '{"execute":"guest-ping"}'`: A basic "heartbeat" command to check if the agent is responsive.
* **The Automation Command:** `virsh qemu-agent-command <vm_name> '{"execute": "guest-exec",...}'`: This is the most powerful command. It allows the host to execute *any* arbitrary program or script (like cmd.exe or powershell.exe) inside the guest OS.

## **6.3. The Automation "Cookbook": Scripting Outlook**

This architecture provides a complete, scriptable solution. The user can write a bash script on their Ubuntu host to manage the entire Outlook workflow.

**Example Automation Script (Conceptual):**
This script demonstrates how to start the VM, launch Outlook, run a local Python script on the shared .pst files, and then cleanly shut down the VM.

```bash
#!/bin/bash
VM_NAME="win11-outlook"
PST_DIR="/home/username/OutlookArchives"

# 1. Start the VM (if not running) and wait for agent
echo "Starting VM: $VM_NAME..."
virsh start "$VM_NAME"

echo "Waiting for QEMU Guest Agent..."
while ! virsh qemu-agent-command "$VM_NAME" \
        '{"execute":"guest-ping"}' --pretty > /dev/null 2>&1; do
  sleep 1
done
echo "Guest agent is alive."

# 2. Execute a command *inside* the Windows guest to launch Outlook
echo "Launching Outlook inside the guest..."
virsh qemu-agent-command "$VM_NAME" \
  '{"execute": "guest-exec", "arguments": { \
    "path": "C:\\Windows\\System32\\cmd.exe", \
    "arg": ["/c", "start", "", "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"] \
  }}'

# 3. Host-side "AI" / Automation
#    The host can now access the .pst files *directly* via the virtio-fs
#    share. The user's AI/automation script runs on the *host*.
echo "Running local Python AI script on PST metadata in $PST_DIR..."
# (This assumes a Python library that can read .pst files)
python3 /home/username/scripts/my_pst_analyzer.py "$PST_DIR/my_archive.pst"

# 4. When automation is complete, shut down the VM cleanly
echo "Automation complete. Shutting down VM..."
virsh shutdown "$VM_NAME" --mode=agent
```

This solution is the ultimate fulfillment of the user's constraints. It uses the native client (Constraint #2) to access .pst files (Constraint #3) via virtio-fs. The automation (Constraint #4) is performed by the host (via qemu-guest-agent) and acts on the files *locally*, requiring no Graph API (Constraint #1). The entire stack is built on the user's preferred FOSS tool, QEMU (Constraint #5).

## **Table 6.1: QEMU Guest Agent Command Matrix (Host-to-Guest)**

This table provides a quick-reference for scripting the Windows guest from the Ubuntu host.

| Use Case | virsh Host Command | Raw JSON-RPC (via qemu-agent-command) | Windows Guest-Side Action | Source(s) |
| :---- | :---- | :---- | :---- | :---- |
| **Health Check** | virsh qemu-agent-command... | {"execute": "guest-ping"} | Responds with a simple "pong" acknowledgment to the host. |  |
| **Clean Shutdown** | virsh shutdown \<vm\> --mode=agent | {"execute": "guest-shutdown", "arguments": {"mode": "powerdown"}} | Initiates a clean, graceful OS shutdown (equivalent to shutdown /s). |  |
| **Clean Reboot** | virsh reboot \<vm\> --mode=agent | {"execute": "guest-shutdown", "arguments": {"mode": "reboot"}} | Initiates a clean, graceful OS reboot. |  |
| **Run Program** | virsh qemu-agent-command... | {"execute": "guest-exec", "arguments": {"path": "C:\\Windows\\System32\\cmd.exe", "arg": ["/c", "echo hello"]}} | Executes an arbitrary executable (cmd.exe, powershell.exe) in the guest. |  |
| **List Filesystems** | virsh domfsinfo \<vm\> | {"execute": "guest-get-fsinfo"} | Returns a JSON list of all mounted filesystems and their usage. |  |
| **Set User Password** | virsh set-user-password \<vm\>... | {"execute": "guest-set-user-password", "arguments": {"username": "...", "password": "...", "crypted": false}} | Sets a local user account's password within the guest OS. |  |
| **Get Guest Time** | virsh qemu-agent-command... | {"execute": "guest-get-time"} | Returns the guest's current system time as a Unix timestamp. |  |
