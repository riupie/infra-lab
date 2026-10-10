# Infrastructure Deployment

## Overview

This guide walks through the automated deployment of virtual infrastructure using OpenTofu (an open-source Terraform alternative). The deployment creates a virtualized environment with networking, storage, and virtual machines ready for Kubernetes installation.

### What Will Be Deployed

| Component | Description | Configuration |
|-----------|-------------|---------------|
| **Virtual Networks** | Two libvirt NAT networks | `net-lab` 192.168.10.0/24 and `ceph-lab` 192.168.11.0/24 (libvirt assigns the `virbrN` bridge names) |
| **Storage Pool** | Disk storage for VM images | `/var/lib/libvirt/images/` |
| **Virtual Machines** | 7 VMs for the lab environment | 1 bastion + 1 control plane + 2 workers + 3 Ceph nodes |

## Prerequisites

Before starting, complete the [Prerequisites](prerequisites.md) guide. You need, in your shell:

- `tofu` 1.7+ and the `TF_ENCRYPTION` variable (your own passphrase)
- `TF_VAR_admin_password`
- an SSH public key (`~/.ssh/id_ed25519.pub`)
- access to the system libvirt instance (`virsh list` works without `sudo`)

## Repository Setup

### Clone the Repository

```bash
# Clone the infra-lab repository
git clone https://github.com/riupie/infra-lab.git
cd infra-lab

# Verify repository structure
ls -la
```

**Expected directory structure** (abbreviated):

```text
infra-lab/
├── addons/
├── docs/
├── jarvis-kvm/
│   ├── ansible/
│   └── terraform
│       ├── networks
│       ├── storage-pool
│       ├── tf-state
│       └── vm
├── k0s/
└── mkdocs.yml
```

!!! warning "Remove the author's state before the first run"
    Each module stores its state under `jarvis-kvm/terraform/tf-state/`. If that directory contains `terraform.tfstate` files in your clone, they are encrypted with the author's passphrase and your first `tofu init`/`plan` will fail with a decryption error. Delete them so OpenTofu starts from empty state:

    ```bash
    rm -f jarvis-kvm/terraform/tf-state/*/terraform.tfstate
    ls -R jarvis-kvm/terraform/tf-state    # directories remain, state files gone
    ```

    Also ignore the root-level `main.key`: it is a git-crypt encrypted file used by the author and is not needed here.

## Network Deployment

### Step 1: Deploy Virtual Network

```bash
# Navigate to network configuration
cd jarvis-kvm/terraform/networks

# Initialize OpenTofu
tofu init

# Review the planned changes and save the plan
tofu plan -out=tfplan

# Apply exactly the reviewed plan
tofu apply tfplan
```

The plan must show **2 to add, 0 to change, 0 to destroy** (`net-lab` and `ceph-lab`). Stop and investigate anything else.

**What this creates:**

- Two libvirt networks with NAT and autostart: `net-lab` (`192.168.10.0/24`) and `ceph-lab` (`192.168.11.0/24`)
- A bridge for each (typically `virbr1` and `virbr2`; libvirt picks the numbers)
- Gateways `192.168.10.1` and `192.168.11.1`

### Verify Network Creation

```bash
# Check network status
virsh net-list

# Inspect one network (bridge name, subnet, forward mode)
virsh net-dumpxml net-lab
```

Expected `virsh net-list`:

```text
 Name       State    Autostart   Persistent
---------------------------------------------
 ceph-lab   active   yes         yes
 default    active   yes         yes
 net-lab    active   yes         yes
```

## Storage Deployment

### Step 2: Create Storage Pool

```bash
# Navigate to storage pool configuration
cd ../storage-pool

# Initialize, review, apply
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

**What this creates:**

- A libvirt storage pool named `default` at `/var/lib/libvirt/images/`
- Two base images downloaded into that pool (this can take several minutes and a few GB of disk):
    - `debian12` from the Debian 12 `genericcloud` image (`latest`)
    - `rocky9` from the Rocky 9 `GenericCloud-Base` image (`latest`)

The image URLs point at `latest`, so contents drift over time. For repeatable builds, pin a dated image URL in `storage-pool/main.tf`.

#### Troubleshooting: storage pool `default` already exists

If a `default` pool already exists on your host (check with `virsh pool-list --all`), `tofu apply` fails with an error from libvirt similar to:

```text
Error: ... pool 'default' already exists with uuid ...
```

Import the existing pool into state instead of creating it. Declarative `import` blocks (OpenTofu 1.5+) let you review the import in the plan. Get the UUID first:

```bash
virsh pool-info default | grep UUID
```

Then add a file `import.tf` next to `main.tf`:

```hcl
import {
  to = libvirt_pool.default
  id = "<uuid-from-virsh-pool-info>"
}
```

```bash
tofu plan -out=tfplan   # should show 1 to import
tofu apply tfplan
```

If the plan shows a different `path` than the existing pool (check with `virsh pool-dumpxml default`), update `target.path` in `main.tf` to match, rather than letting OpenTofu replace the pool.

!!! warning "Destroying an imported pool"
    Once `default` is in state, `tofu destroy` in this directory will delete your host's system `default` pool and the images in it. Skip the storage-pool teardown step in [Cleanup](#cleanup) if you imported it, and remove it from state instead.

### Verify Storage Pool

```bash
# Check storage pool status
virsh pool-list

# Check storage pool details
virsh pool-info default

# Verify the base images exist
virsh vol-list default
```

Expected `virsh pool-list`:

```text
 Name      State    Autostart
-----------------------------
 default   active   yes
```

`virsh vol-list default` must list `debian12` and `rocky9`.

## Virtual Machine Deployment

### Step 3: Deploy VMs

Before applying, edit `jarvis-kvm/terraform/vm/main.tf` and replace the `ssh_keys` entry of **every** module (`bastion`, `kube_master`, `kube_worker`, `ceph`) with your own public key (`cat ~/.ssh/id_ed25519.pub`). The repository contains the author's key, so SSH will fail for you otherwise.

```bash
# Navigate to VM configuration
cd ../vm

# Initialize OpenTofu
tofu init

# Review the plan and save it
tofu plan -out=tfplan

# Deploy VMs (applies the reviewed plan; uses TF_VAR_admin_password)
tofu apply tfplan
```

The VM stack reads the pool and network outputs from the other two states, so steps 1 and 2 must be applied first, with the same `TF_ENCRYPTION` value.

**VM Specifications:**

| VM Name | Role | vCPUs | Memory | System disk | Extra disks | IP address(es) |
|---------|------|-------|--------|-------------|-------------|----------------|
| **bastion01** | DNS + Tailscale Router | 1 | 2GB | 20GB | n/a | 192.168.10.9 |
| **master01** | Kubernetes Control Plane | 2 | 4GB | 50GB | n/a | 192.168.10.10 |
| **worker01** | Kubernetes Worker | 4 | 8GB | 100GB | n/a | 192.168.10.11 |
| **worker02** | Kubernetes Worker | 4 | 8GB | 100GB | n/a | 192.168.10.12 |
| **ceph01** | Ceph node | 2 | 8GB | 50GB | 100GB (`ceph-osd`) + 50GB (`ceph-db`) | 192.168.10.20 / 192.168.11.20 |
| **ceph02** | Ceph node | 2 | 8GB | 50GB | 100GB + 50GB | 192.168.10.21 / 192.168.11.21 |
| **ceph03** | Ceph node | 2 | 8GB | 50GB | 100GB + 50GB | 192.168.10.22 / 192.168.11.22 |

Bastion, master and workers use the Debian 12 image; the Ceph nodes use Rocky 9. Values come from `jarvis-kvm/terraform/vm/main.tf`; if you change them there, update your expectations accordingly.

### Deployment Process

The VM deployment will:

1. **Create VM Disks**: Individual disk images for each VM, backed by the base images
2. **Configure Cloud-Init**: User accounts and SSH keys
3. **Network Assignment**: Static IP addresses in the lab networks
4. **Start VMs**: Boot all virtual machines

## Verification

### Step 4: Verify VM Deployment

#### Check VM Status

```bash
virsh list --all
```

```text
 Id   Name        State
--------------------------
 1    bastion01   running
 2    master01    running
 3    worker01    running
 4    worker02    running
 5    ceph01      running
 6    ceph02      running
 7    ceph03      running
```

IDs and ordering will differ.

#### Test Network Connectivity

```bash
for ip in 192.168.10.{9,10,11,12,20,21,22}; do
  ping -c 2 -W 2 "$ip" >/dev/null && echo "$ip up" || echo "$ip DOWN"
done
```

Every address should print `up`.

#### SSH Access Test

```bash
# After the VMs have fully booted (usually 1 to 2 minutes)
ssh cloud@192.168.10.9    # bastion01
ssh cloud@192.168.10.10   # master01
```

If SSH fails, the VMs may still be booting. Check the console (exit with `Ctrl+]`):

```bash
virsh console bastion01
```

If it still fails, confirm you replaced `ssh_keys` with your own public key.

## Troubleshooting

| Symptom | Likely cause | Check / fix |
|---------|--------------|-------------|
| Decryption error on `tofu init`/`plan` | Author's state files present, or `TF_ENCRYPTION` not set or different | See the warning under *Repository Setup*; `echo "${TF_ENCRYPTION:0:20}"` must show the key provider block |
| `No such file or directory` on `cd` | Wrong working directory | Run `pwd`; every step starts from the previous module directory (`../storage-pool`, `../vm`) |
| Step 3 plan fails with `Unsupported attribute ... image_...` | Pool outputs not applied or stale | Re-run step 2 and confirm `tofu output` there shows `image_debian12` and `image_rocky9` |
| `Permission denied (publickey)` | Author's key still in `main.tf` | Replace `ssh_keys` and re-apply the VM stack |
| Pool or image errors on download | No internet or slow mirror | `curl -I` the image URLs from `storage-pool/main.tf` |

## Cleanup

⚠ WARNING: Destructive operation. This removes all lab VMs, their disks (including the Ceph data disks), the networks and the base images. Review each plan before applying it.

Tear down in reverse order, using a saved destroy plan each time:

```bash
cd jarvis-kvm/terraform/vm
tofu plan -destroy -out=destroy.tfplan
tofu apply destroy.tfplan

# Skip this block if you imported the host's existing `default` pool
cd ../storage-pool
tofu plan -destroy -out=destroy.tfplan
tofu apply destroy.tfplan

cd ../networks
tofu plan -destroy -out=destroy.tfplan
tofu apply destroy.tfplan
```

Verify nothing is left:

```bash
virsh list --all
virsh net-list --all
virsh pool-list --all
virsh vol-list default
```

Remove the saved plan files afterwards (`rm -f tfplan destroy.tfplan` in each directory).

## Next Steps

Once infrastructure deployment is complete:

1. **[Kubernetes Setup](kubernetes-setup.md)** - Deploy k0s Kubernetes cluster
2. **Service Configuration** - Configure DNS, monitoring, and other services
