# Infrastructure Deployment
## Overview

This guide walks through the automated deployment of virtual infrastructure using OpenTofu (Terraform alternative). The deployment creates a complete virtualized environment with networking, storage, and virtual machines ready for Kubernetes installation.

### What Will Be Deployed

| Component | Description | Configuration |
|-----------|-------------|---------------|
| **Virtual Network** | NAT bridge for VM connectivity | `virbr1` - 192.168.10.0/24 & `virbr2` - 192.168.11.0/24|
| **Storage Pool** | Disk storage for VM images | `/var/lib/libvirt/images/` |
| **Virtual Machines** | 5 VMs for the lab environment | 1 bastion + 1 control plane + 3 workers |

## Prerequisites

Before starting, ensure you have completed the [Prerequisites](prerequisites.md) guide.

## Repository Setup

### Clone the Repository

```bash
# Clone the infra-lab repository
git clone https://github.com/riupie/infra-lab.git
cd infra-lab

# Verify repository structure
ls -la
```

**Expected Directory Structure:**
```
infra-lab/
├── docs/
├── jarvis-kvm/
│   ├── ansible/
│   └── terraform
│       ├── networks
│       ├── storage-pool
│       ├── tf-state
│       └── vm
└── k0s/
```

## Network Deployment

### Step 1: Deploy Virtual Network

```bash
# Navigate to network configuration
cd jarvis-kvm/terraform/networks

# Initialize OpenTofu
tofu init

# Review the planned changes
tofu plan

# Apply network configuration
tofu apply
```

**What this creates:**
- Virtual bridge (`virbr1` and `virbr2`) with NAT configuration
- Network subnet: `192.168.10.0/24` (net-lab), `192.168.11.0/24` (ceph-lab)
- Gateway: `192.168.10.1`, `192.168.11.1`

### Verify Network Creation

```bash
# Check network status
virsh net-list

# Expected output:
# Name       State    Autostart   Persistent
#---------------------------------------------
# ceph-lab   active   yes         yes
# net-lab    active   yes         yes

```

## Storage Deployment

### Step 2: Create Storage Pool

```bash
# Navigate to storage pool configuration
cd ../terraform/storage-pool

# Initialize and apply
tofu init
tofu plan
tofu apply
```

**What this creates:**
- Libvirt storage pool named `default`
- Storage location: `/var/lib/libvirt/images/`
- Automatic permission management for libvirt
- Directory structure for VM disk images

### Verify Storage Pool

```bash
# Check storage pool status
virsh pool-list

# Expected output:
# Name      State    Autostart   Persistent
# default   active   yes         yes

# Check storage pool details
virsh pool-info default

# Verify storage location
ls -la /var/lib/libvirt/images/
```

## Virtual Machine Deployment

### Step 3: Deploy VMs

```bash
# Navigate to VM configuration
cd ../vm

# Initialize OpenTofu
tofu init

# Review VM specifications (optional)
tofu plan

# Deploy VMs
tofu apply
```

**VM Specifications:**

| VM Name | Role | vCPUs | Memory | Disk | IP Address |
|---------|------|-------|---------|------|------------|
| **bastion01** | DNS + Tailscale Router | 2 | 4GB | 40GB | 192.168.10.9 |
| **master01** | Kubernetes Control Plane | 2 | 4GB | 40GB | 192.168.10.10 |
| **worker01** | Kubernetes Worker | 2 | 8GB | 40GB | 192.168.10.11 |
| **worker02** | Kubernetes Worker | 2 | 8GB | 40GB | 192.168.10.12 |
| **worker03** | Kubernetes Worker | 2 | 8GB | 40GB | 192.168.10.13 |

### Deployment Process

The VM deployment will:
1. **Create VM Disks**: Individual disk images for each VM
2. **Configure Cloud-Init**: User accounts and SSH keys
3. **Network Assignment**: Static IP addresses in the lab network
4. **Start VMs**: Boot all virtual machines

## Verification

### Step 4: Verify VM Deployment

#### Check VM Status

```bash
# Check VM status
virsh list --all

# Expected output:
# Id   Name        State
# 1    bastion01   running
# 2    master01    running
# 3    worker01    running
# 4    worker02    running
# 5    worker03    running
```

#### Test Network Connectivity

```bash
# Test VM connectivity
ping -c 3 192.168.10.9   # bastion01
ping -c 3 192.168.10.10  # master01
ping -c 3 192.168.10.11  # worker01
ping -c 3 192.168.10.12  # worker02
ping -c 3 192.168.10.13  # worker03
```

#### SSH Access Test

```bash
# Test SSH access (after VMs are fully booted)
ssh cloud@192.168.10.9   # bastion01
ssh cloud@192.168.10.10  # master01

# If SSH fails, VMs may still be booting
# Check VM console:
virsh console bastion01
```

## Next Steps

Once infrastructure deployment is complete:

1. **[Kubernetes Setup](kubernetes-setup.md)** - Deploy k0s Kubernetes cluster
2. **[Storage Configuration](../storage/deployment.md)** - Set up Ceph storage
3. **Service Configuration** - Configure DNS, monitoring, and other services