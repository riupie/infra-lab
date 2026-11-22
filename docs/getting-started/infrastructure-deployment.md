# Infrastructure deployment

This guide uses OpenTofu (an open-source fork of Terraform) to create the lab network, storage pool and VMs on the KVM host. At the end, the VMs are ready for [Kubernetes Setup](kubernetes-setup.md).

## What gets deployed

| Component | Description | Configuration |
|-----------|-------------|---------------|
| Virtual network | One libvirt NAT network | `net-lab` 192.168.10.0/24 (libvirt assigns the `virbrN` bridge name; `virbr1` on the reference host) |
| Storage pool | Disk storage for VM images | `/var/lib/libvirt/images/` |
| Virtual machines | 3 VMs | general01 (DNS, Keycloak) + master01 (control plane) + worker01 (worker) |

## Prerequisites

Before starting, complete the [Prerequisites](prerequisites.md) guide. You need, in your shell:

- `tofu` 1.7+ and the `TF_ENCRYPTION` variable (your own passphrase)
- `TF_VAR_admin_password`
- an SSH public key (`~/.ssh/id_ed25519.pub`)
- `LIBVIRT_DEFAULT_URI="qemu:///system"` exported and membership of the `libvirt` group (`virsh uri` prints `qemu:///system`, `virsh list --all` works without `sudo`)

## Repository setup

### Clone the repository

```bash
# Clone the infra-lab repository
git clone https://github.com/riupie/infra-lab.git
cd infra-lab

# Verify repository structure
ls -la
```

Expected layout (abbreviated):

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
└── zensical.toml
```

!!! warning "Remove the author's state before the first run"
    Each module stores its state under `jarvis-kvm/terraform/tf-state/`. If that directory contains `terraform.tfstate` files in your clone, they are encrypted with the author's passphrase and your first `tofu init`/`plan` will fail with a decryption error. Delete them so OpenTofu starts from empty state:

    ```bash
    rm -f jarvis-kvm/terraform/tf-state/*/terraform.tfstate
    ls -R jarvis-kvm/terraform/tf-state    # directories remain, state files gone
    ```

    Also ignore the root-level `main.key`: it is a git-crypt encrypted file used by the author and is not needed here.

## Network deployment

### Step 1: Deploy the virtual network

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

The plan must show **1 to add, 0 to change, 0 to destroy** (`net-lab`). Stop and investigate anything else.

**What this creates:**

- One libvirt network with NAT and autostart: `net-lab` (`192.168.10.0/24`)
- A bridge for it (typically `virbr1`; libvirt picks the number)
- Gateway and DNS forwarder `192.168.10.1`

### Verify the network

```bash
# Check network status
virsh net-list

# Inspect one network (bridge name, subnet, forward mode)
virsh net-dumpxml net-lab
```

Expected `virsh net-list`:

```text
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
 net-lab   active   yes         yes
```

## Storage deployment

### Step 2: Create storage pool

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
    - `debian12` from the Debian 12 `genericcloud` image (`latest`), used by all VMs
    - `rocky9` from the Rocky 9 `GenericCloud-Base` image (`latest`), still defined in `storage-pool/main.tf` but not used by any current VM

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
    Once `default` is in state, `tofu destroy` in this directory will delete your host's system `default` pool and the images in it. Before the storage-pool teardown in [Cleanup](#cleanup), detach the pool from state declaratively (OpenTofu 1.7 or newer):

    1. In `storage-pool/main.tf`, replace `libvirt_pool.default.name` with `"default"` in both volumes, and in `outputs.tf` for `pool_default`. Then delete the `resource "libvirt_pool" "default"` block.
    2. Add `removed.tf` next to `main.tf`:

        ```hcl
        removed {
          from = libvirt_pool.default

          lifecycle {
            destroy = false
          }
        }
        ```

    3. `tofu plan -destroy -out=destroy.tfplan` must list only the `debian12` and `rocky9` volumes as destroyed. If the pool appears in the destroy list, stop and re-check steps 1 and 2.

### Verify the storage pool

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

## Virtual machine deployment

### Step 3: Deploy VMs

Before applying, edit `jarvis-kvm/terraform/vm/main.tf` and replace the `ssh_keys` entry of **every** module (`general`, `kube_master`, `kube_worker`) with your own public key (`cat ~/.ssh/id_ed25519.pub`). The repository contains the author's key, so SSH will fail for you otherwise.

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

VM specifications:

| VM Name | Role | vCPUs | Memory | System disk | Extra disks | IP address(es) |
|---------|------|-------|--------|-------------|-------------|----------------|
| general01 | DNS (BIND9) + Keycloak | 1 | 2GB | 20GB | n/a | 192.168.10.9 |
| master01 | Kubernetes control plane | 2 | 4GB | 50GB | n/a | 192.168.10.10 |
| worker01 | Kubernetes worker | 2 | 8GB | 50GB | n/a | 192.168.10.11 |

All VMs use the Debian 12 image. Values come from `jarvis-kvm/terraform/vm/main.tf`; if you change them there, this table no longer applies.

The apply creates a disk for each VM backed by the base image, configures the user accounts and SSH keys through cloud-init, assigns the static IP addresses in `net-lab`, and boots the VMs.

## Verification

### Step 4: Verify the VMs

#### Check VM status

```bash
virsh list --all
```

```text
 Id   Name        State
--------------------------
 1    general01   running
 2    master01    running
 3    worker01    running
```

IDs and ordering will differ.

#### Test network connectivity

```bash
for ip in 192.168.10.{9,10,11}; do
  ping -c 2 -W 2 "$ip" >/dev/null && echo "$ip up" || echo "$ip DOWN"
done
```

Every address should print `up`.

#### Test SSH access

```bash
# After the VMs have fully booted (usually 1 to 2 minutes)
ssh cloud@192.168.10.9    # general01
ssh cloud@192.168.10.10   # master01
```

If SSH fails, the VMs may still be booting. Check the console (exit with `Ctrl+]`):

```bash
virsh console general01
```

If it still fails, confirm you replaced `ssh_keys` with your own public key.

## Troubleshooting

| Symptom | Likely cause | Check / fix |
|---------|--------------|-------------|
| Decryption error on `tofu init`/`plan` | Author's state files present, or `TF_ENCRYPTION` not set or different | See the warning under *Repository setup*; `echo "${TF_ENCRYPTION:0:20}"` must show the key provider block |
| `No such file or directory` on `cd` | Wrong working directory | Run `pwd`; every step starts from the previous module directory (`../storage-pool`, `../vm`) |
| Step 3 plan fails with `Unsupported attribute ... image_...` | Pool outputs not applied or stale | Re-run step 2 and confirm `tofu output` there shows `image_debian12` and `image_rocky9` |
| `Permission denied (publickey)` | Author's key still in `main.tf` | Replace `ssh_keys` and re-apply the VM stack |
| Pool or image errors on download | No internet or slow mirror | `curl -I` the image URLs from `storage-pool/main.tf` |

## Cleanup

⚠ WARNING: Destructive operation. This removes all lab VMs, their disks, the network and the base images. Review each plan before applying it.

Tear down in reverse order, using a saved destroy plan each time:

1. VMs:

    ```bash
    cd jarvis-kvm/terraform/vm
    tofu plan -destroy -out=destroy.tfplan
    tofu apply destroy.tfplan
    ```

2. Storage pool and base images.

    ⚠ WARNING: If you imported the host's existing `default` pool, first detach it as described in the "Destroying an imported pool" warning under [storage pool `default` already exists](#troubleshooting-storage-pool-default-already-exists). Otherwise this deletes the host's system pool and every image in it. The saved plan must not contain `libvirt_pool.default`.

    ```bash
    cd ../storage-pool
    tofu plan -destroy -out=destroy.tfplan
    tofu apply destroy.tfplan
    ```

3. Network:

    ```bash
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

## Next steps

1. [Kubernetes Setup](kubernetes-setup.md): deploy the k0s cluster
2. [Set Up Dynamic DNS](../playbooks/dynamic-dns.md): BIND9 on general01 for the `lab.riupie.com` zone
