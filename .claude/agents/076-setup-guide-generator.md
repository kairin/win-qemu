---
name: 076-setup-guide-generator
description: Generate device-specific setup guide.
model: haiku
---

## Single Task
Create customized setup guide based on hardware.

## Input
- health_report: From 075-report-generator

## Logic
```
IF hardware.issues THEN
  Generate hardware fix instructions
IF qemu_stack.issues THEN
  Generate installation commands
IF virtio.issues THEN
  Generate ISO download instructions
IF network.issues THEN
  Generate network setup commands
```

## Output Format
```markdown
# Setup Guide for [hostname]

## Hardware Status
[Pass/Fail details]

## Required Actions
1. [Action if needed]
2. [Action if needed]

## Commands to Run
```bash
# Generated commands
```
```

## Parallel-Safe: Yes

## Parent: 007-health
