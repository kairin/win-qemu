---
name: 042-firewall-rules
description: Configure UFW firewall with M365 whitelist.
model: haiku
---

## Single Task
Set up egress firewall with Microsoft 365 endpoints only.

## Execution
```bash
# Enable UFW
sudo ufw enable

# Default deny outgoing
sudo ufw default deny outgoing

# Allow M365 endpoints
sudo ufw allow out to outlook.office365.com port 443
sudo ufw allow out to login.microsoftonline.com port 443
sudo ufw allow out to graph.microsoft.com port 443

# Verify rules
sudo ufw status verbose
```

## Input
- action: enable | configure | status

## Output
```
status: success | error
rules_count: number of rules
default_outgoing: deny
```

## Parent: 004-security
