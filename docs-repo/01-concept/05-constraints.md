# **Section 1. Deconstruction of Constraints and Problem Vector Analysis**

The five constraints provided form a highly specific problem space. Their interactions and interdependencies serve to eliminate the vast majority of common "run Windows apps on Linux" solutions, pointing toward a single, robust architecture.

## **1.1. The Primacy of Constraint #3: The .pst File Imperative**

The requirement to "have access to local ms outlook archive.pst files" is the single most important technical driver. This constraint functions as a "Great Filter" that immediately clarifies the nature of the application that must be run.

In the 2025 Microsoft 365 ecosystem, the "New Outlook" client has been aggressively pushed as the default. However, this client, along with its purely browser-based counterparts (Outlook on the Web, or OWA, and the Progressive Web App, or PWA), is a web-based application. These applications run in a sandboxed environment and, by design, do not have the ability to arbitrarily access the local filesystem to open arbitrary data files like a .pst.

The available research and community discussions from 2024 and 2025 are unambiguous on this point. The *only* workflow Microsoft supports for .pst files in relation to OWA or the "New Outlook" is a one-time, server-side *import* (often referred to as "ingestion"). This process involves uploading the .pst data into the user's Exchange Online mailbox, effectively merging it with their cloud data. This workflow is fundamentally different from the user's implied need: the ability to mount, access, and manage local, separate archive files, likely for compliance, data segregation, or historical reference. This is a workflow that many long-time Outlook users depend on, and its deprecation in the new client is a significant point of confusion and concern.

The "classic" Outlook desktop application, however, explicitly retains this functionality. It is designed to work with both online data files (.ost) and local personal storage table (.pst) files. Microsoft confirms that the classic client supports the File > Open & Export workflow to open .pst files directly from the local filesystem.

This chain of facts leads to an inescapable conclusion: the user's constraints *require* them to run the "classic" C++/Win32 desktop version of Outlook, which is still distributed as part of the "Microsoft 365 Apps" (formerly Office 365 ProPlus) suite. Any solution that only supports the PWA or "New Outlook" is non-viable. This eliminates an entire class of simple "web app container" solutions and focuses the analysis on methods for running the full, native x64 Windows application.

## **1.2. The "Locked-Box": How Constraints #1 and #2 Define the Interface**

The IT department's policy constraints create a "locked-box" scenario that directly conflicts with the user's desire for automation.

* **Constraint #1 (No Graph API):** This policy forbids the use of Microsoft's modern, standard, REST-based API for all Microsoft 365 services. This restriction is severe. It prevents all forms of cloud-native automation, disables integration with modern third-party services, and blocks any custom scripting that would interact with the user's mailbox data at the service level.
* **Constraint #2 (No 3rd-party clients):** This policy forbids the use of traditional Linux-native email clients that could otherwise connect to the Exchange server, such as Evolution (using evolution-ews) or Thunderbird (using an EWS or ActiveSync plugin).

When combined, these two constraints force the user to interact with their Microsoft 365 account *only* through the officially sanctioned, native Outlook desktop client. This client becomes an opaque "black box." The IT department is effectively stating that the user is permitted to *use* the tool as an end-user, but not *integrate* with it as a developer or power user.

This creates a direct and seemingly irreconcilable conflict with **Constraint #4** (the desire for "some form of AI control or my own automation implementation"). A method is needed to automate a "black box" without access to its internal (Graph API) or external (third-party client) interfaces.

This paradox is solved by shifting the automation vector. Instead of attempting to automate the *application* or the *service*, the solution is to automate the *environment in which the application runs*. By virtualizing the entire Windows operating system using QEMU/KVM 2, the Linux host (Ubuntu) gains hypervisor-level control over the Windows guest. This control is exercised through a local, secure channel (the QEMU guest agent) that is completely invisible to the Exchange server and the corporate IT department. It does not use the Graph API and is not a "third-party client."

This approach allows the user to script the VM's lifecycle (start, stop, snapshot), inject commands into the guest OS (e.g., "run this PowerShell script"), and, most importantly, directly access the VM's filesystem (or a shared portion of it) from the host. This resolves the conflict: the user remains compliant with IT policy by using the native client inside the "box," while simultaneously fulfilling their automation requirement by manipulating the "box" itself from the outside. The user's constraints, rather than being contradictory, ironically point directly to a hypervisor-based architecture as the only logical and compliant solution.
