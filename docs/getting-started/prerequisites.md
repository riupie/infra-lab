# Prerequisites
## Overview

This document outlines the system requirements and software prerequisites needed to set up the infra-lab environment. Ensure all requirements are met before proceeding with the infrastructure deployment.

## System Requirements

### Minimum Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 4 cores | 8+ cores | Must support virtualization (VT-x/AMD-V) |
| **Memory** | 16GB | 32GB+ | 4GB per VM + host overhead |
| **Storage** | 100GB | 500GB+ | SSD recommended for performance |
| **Network** | 1Gbps | 1Gbps+ | For VM and container networking |
| **OS** | Debian/Ubuntu Linux | Debian 12 (bookworm) | Tested distributions |

### Virtualization Support

Your CPU must support hardware virtualization:

```bash
# Check for virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo

# Should return > 0 for Intel VT-x or AMD-V
# If 0, check BIOS settings to enable virtualization
```

## Software Installation

### Install KVM and Virtualization Tools

```bash
# Update package list
apt update

# Install KVM and virtualization packages
apt -y install \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-daemon \
    virtinst \
    bridge-utils \
    libosinfo-bin \
    libguestfs-tools

# Add user to libvirt group (if not root)
usermod -aG libvirt $USER

# Logout and login again to apply group changes
```

### Install OpenTofu

OpenTofu is used for infrastructure automation and VM provisioning:

```bash
# Method 1: Using package manager (recommended)
curl -Lo /tmp/tofu.deb https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_amd64.deb
dpkg -i /tmp/tofu.deb

# Method 2: Manual installation
wget https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip
unzip tofu_1.6.0_linux_amd64.zip
sudo mv tofu /usr/local/bin/

# Verify installation
tofu version
```

### Install Additional Tools

```bash
# Install packages required for VM image creation
apt install -y mkisofs xsltproc

# Install helpful tools for VM management
apt install -y virt-manager virt-viewer

# Verify installations
which mkisofs xsltproc
```

## Verification

### Verify KVM Installation

```bash
# Check if KVM modules are loaded
lsmod | grep kvm

# Expected output for AMD:
# kvm_amd               155648  10
# kvm                  1146880  1 kvm_amd
# irqbypass              16384  26 kvm
# ccp                   118784  1 kvm_amd

# Expected output for Intel:
# kvm_intel             294912  6
# kvm                  1146880  1 kvm_intel

# Verify libvirt service
systemctl status libvirtd

# Test virtualization capabilities
virt-host-validate
```

**Expected `virt-host-validate` output:**
```
  QEMU: Checking for hardware virtualization                 : PASS
  QEMU: Checking if device /dev/kvm exists                   : PASS
  QEMU: Checking if device /dev/kvm is accessible           : PASS
  QEMU: Checking if device /dev/vhost-net exists            : PASS
   LXC: Checking for Linux >= 2.6.26                        : PASS
```

### Verify Network Configuration

```bash
# Check default libvirt network
virsh net-list --all

# Expected output:
# Name      State    Autostart   Persistent
# default   active   yes         yes

# If default network is not active:
virsh net-start default
virsh net-autostart default
```

### Verify Storage

```bash
# Check available disk space
df -h /var/lib/libvirt/images

# Verify libvirt storage pools
virsh pool-list --all
```

## Next Steps

Once all prerequisites are met and verified:

1. **[Infrastructure Deployment](infrastructure-deployment.md)** - Deploy VMs and networking
2. **[Kubernetes Setup](kubernetes-setup.md)** - Install and configure k0s cluster