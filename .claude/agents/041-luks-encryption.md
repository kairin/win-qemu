---
name: 041-luks-encryption
description: Configure LUKS encryption for VM storage.
model: haiku
---

## Single Task
Set up LUKS2 encryption for VM images and PST files.

## Execution
```bash
# Create LUKS partition
sudo cryptsetup luksFormat /dev/sdX --type luks2 \
  --cipher aes-xts-plain64 --key-size 512 --hash sha256

# Open encrypted partition
sudo cryptsetup open /dev/sdX encrypted-vms

# Create filesystem
sudo mkfs.ext4 /dev/mapper/encrypted-vms

# Mount
sudo mount /dev/mapper/encrypted-vms /encrypted/vms
```

## Input
- device: Block device to encrypt
- mount_point: Where to mount

## Output
```
status: success | error
device: encrypted device path
mount_point: mount location
```

## Parent: 004-security
