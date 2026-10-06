# Prerequisites

## Overview

This document outlines the system requirements and software prerequisites needed to set up the infra-lab environment. Ensure all requirements are met before proceeding with the infrastructure deployment.

!!! warning "Lab-only shortcuts"
    This guide trades some security for simplicity (passphrase in an environment variable, a shared SSH key, a password passed via `TF_VAR_*`). Do not reuse these shortcuts for production.

## Tested with

| Component | Version |
|-----------|---------|
| Host OS | Rocky Linux 9 (also run on Fedora; see the libvirt daemon note below) |
| OpenTofu | 1.7 or newer (state encryption requires 1.7+). Run `tofu version` and record yours |
| libvirt provider | `dmacvicar/libvirt` 0.8.3 (pinned in `providers.tf`) |
| VM images | Debian 12 (bookworm) and Rocky Linux 9 GenericCloud, downloaded as `latest` |

## System Requirements

### Minimum Requirements

The full lab runs 7 VMs: bastion, 1 control plane, 2 workers and 3 Ceph nodes (about 46 GB of VM RAM in total). The Ceph nodes carry 3 × 150 GB of extra disks. Qcow2 volumes are thin-provisioned, but plan for the full size.

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 8 cores | 16+ cores | Must support virtualization (VT-x/AMD-V) |
| **Memory** | 64GB | 96GB+ | VMs use ~46GB; the rest is host overhead and page cache |
| **Storage** | 600GB | 1TB+ | SSD/NVMe strongly recommended (Ceph + 7 OS disks) |
| **Network** | Any | Any | Lab traffic stays on libvirt NAT networks; internet is needed to download images |
| **OS** | RHEL-based Linux (RHEL, Rocky, AlmaLinux, Fedora) | Rocky Linux 9 / RHEL 9 | Red Hat based distributions |

Running only the Kubernetes part (bastion, master, workers; ~26GB RAM, ~370GB disk) is possible by removing the `ceph` module from `jarvis-kvm/terraform/vm/main.tf`.

### Virtualization Support

Your CPU must support hardware virtualization:

```bash
# Check for virtualization support
grep -Ec '(vmx|svm)' /proc/cpuinfo

# Should return > 0 for Intel VT-x or AMD-V
# If 0, check BIOS settings to enable virtualization
```

## Software Installation

All commands below assume a regular user with `sudo`.

### Install KVM and Virtualization Tools

```bash
# Update package metadata
sudo dnf makecache

# Install git, KVM and virtualization packages
sudo dnf -y install \
    git \
    qemu-kvm \
    libvirt \
    libvirt-daemon \
    virt-install \
    libosinfo \
    guestfs-tools

# Enable and start libvirt
sudo systemctl enable --now libvirtd

# Allow your user to manage the system libvirt instance
sudo usermod -aG libvirt "$USER"

# Log out and back in to apply the group change
```

!!! note "libvirt daemon on newer distributions"
    Newer Fedora and RHEL-family releases use modular daemons (`virtqemud`, `virtnetworkd`, `virtstoraged`) instead of the monolithic `libvirtd`. Check what your host provides with `systemctl list-unit-files 'virt*d*'`. This guide is written against Rocky Linux 9, where `libvirtd` is correct. If `libvirtd` is missing on your host, enable the modular sockets instead (`sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket`) and use `systemctl status virtqemud` in the verification steps.

Non-root users default to the per-user session (`qemu:///session`) connection. To make `virsh` use the system connection without `sudo`, set `LIBVIRT_DEFAULT_URI` and persist it in `.bashrc`/`.zshrc` (depends on your shell). The OpenTofu providers in this repo already use `qemu:///system` explicitly.

```bash
echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.bashrc
source ~/.bashrc

# Verify (should list VMs without sudo)
virsh list --all
```

### Install OpenTofu

OpenTofu is used for infrastructure automation and VM provisioning. It is not in the default Rocky or Fedora repositories, so add the official OpenTofu repository first. Follow the [OpenTofu RPM installation instructions](https://opentofu.org/docs/intro/install/rpm/) for your distribution, then:

```bash
sudo dnf install -y tofu

# Verify installation (must be 1.7 or newer)
tofu version
```

### Create an SSH key

The VMs are provisioned with your public key through cloud-init. Create one if you don't have it yet:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "infra-lab"
cat ~/.ssh/id_ed25519.pub
```

You will paste the public key into `jarvis-kvm/terraform/vm/main.tf` in the [Infrastructure Deployment](infrastructure-deployment.md) guide.

### Encrypt OpenTofu state

OpenTofu (1.7+) can encrypt state at rest. This is an OpenTofu feature; Terraform has no equivalent. The `encryption` block lives inside the `terraform {}` block of each `providers.tf` (see [`jarvis-kvm/terraform/vm/providers.tf`](https://github.com/riupie/infra-lab/blob/17ba3ee57b26277b25bbf172515fc0ea4f943ab4/jarvis-kvm/terraform/vm/providers.tf#L6) for an example). For simplicity, the key provider (PBKDF2) is passed in through the `TF_ENCRYPTION` environment variable, so the passphrase never lands in the repository.

Generate your **own** passphrase and persist the variable:

```bash
PASSPHRASE="$(openssl rand -hex 24)"

cat >> ~/.bashrc <<EOF
export TF_ENCRYPTION='key_provider "pbkdf2" "key" {
  passphrase    = "${PASSPHRASE}"
  key_length    = 32
  salt_length   = 16
  hash_function = "sha256"
}'
EOF
unset PASSPHRASE
source ~/.bashrc
```

!!! warning "Keep this passphrase"
    Losing it means losing access to your state. Back it up in a password manager. Storing it in `.bashrc` is a lab shortcut; for anything real, use a KMS-backed key provider.

!!! warning "Do not reuse state from the repository"
    Any `terraform.tfstate` that exists in a clone of this repository was encrypted with the author's passphrase and cannot be decrypted with yours. If `tofu init` or `tofu plan` fails with a decryption error, delete the stale state files under `jarvis-kvm/terraform/tf-state/` (they are only the author's lab state) and start from scratch.

### Set the VM admin password

The VM module requires `admin_password` (the local `debian` account password). Provide it through the environment instead of typing it at each prompt:

```bash
export TF_VAR_admin_password="$(openssl rand -base64 18)"
echo "$TF_VAR_admin_password"   # store it in your password manager
```

### Install Additional Tools

```bash
# Packages for cloud-init ISO creation (provider needs mkisofs or a compatible tool)
sudo dnf install -y genisoimage libxslt

# Verify installations
which mkisofs xsltproc
```

If `genisoimage` is not available on your release, find the replacement with `dnf provides mkisofs` (typically `xorriso`).

Optionally, install the GUI tools if you work from a desktop (not needed on a headless host):

```bash
sudo dnf install -y virt-manager virt-viewer
```

## Verification

### Verify KVM Installation

```bash
# Check if KVM modules are loaded
lsmod | grep kvm

# Verify libvirt service
systemctl status libvirtd

# Test virtualization capabilities
virt-host-validate
```

**Expected `lsmod` output** (module sizes and use counts vary):

```text
# AMD
kvm_amd               155648  10
kvm                  1146880  1 kvm_amd

# Intel
kvm_intel             294912  6
kvm                  1146880  1 kvm_intel
```

**Expected `virt-host-validate` output** (the QEMU lines must be `PASS`; WARN lines such as IOMMU are common and not blocking):

```text
  QEMU: Checking for hardware virtualization                 : PASS
  QEMU: Checking if device /dev/kvm exists                   : PASS
  QEMU: Checking if device /dev/kvm is accessible            : PASS
  QEMU: Checking if device /dev/vhost-net exists             : PASS
```

### Verify Network Configuration

```bash
# Check default libvirt network
virsh net-list --all
```

```text
 Name      State    Autostart   Persistent
 default   active   yes         yes
```

If the default network is not active:

```bash
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

`df` should report at least the free space listed in the requirements. On a fresh host `virsh pool-list --all` may be empty or list a `default` pool. Both cases are handled in the [storage pool step](infrastructure-deployment.md#step-2-create-storage-pool).

## Troubleshooting

| Symptom | Likely cause | Check / fix |
|---------|--------------|-------------|
| `grep -Ec '(vmx\|svm)'` returns `0` | Virtualization disabled | Enable VT-x/AMD-V in firmware |
| `virsh list` fails with `Failed to connect socket to '/run/user/.../libvirt-sock'` | Using the session connection | Set `LIBVIRT_DEFAULT_URI="qemu:///system"` and re-login |
| `virsh` asks for authentication or `permission denied` | Not in the `libvirt` group yet | `id` must list `libvirt`; log out and in again |
| `Unit libvirtd.service not found` | Modular-daemon distribution | See the note under *Install KVM and Virtualization Tools* |
| `dnf: No match for argument: tofu` | OpenTofu repo not configured | Add the repo from the OpenTofu install page |

## Cleanup

Nothing in this page needs cleanup beyond uninstalling packages. Teardown of the lab itself is in [Infrastructure Deployment](infrastructure-deployment.md#cleanup).

## Next Steps

Once all prerequisites are met and verified:

1. **[Infrastructure Deployment](infrastructure-deployment.md)** - Deploy VMs and networking
2. **[Kubernetes Setup](kubernetes-setup.md)** - Install and configure k0s cluster
