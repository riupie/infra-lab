# Prerequisites

## Overview

This document outlines the system requirements and software prerequisites needed to set up the infra-lab environment. Ensure all requirements are met before proceeding with the infrastructure deployment.

!!! warning "Lab-only shortcuts"
    This guide trades some security for simplicity (passphrase in an environment variable, a shared SSH key, a password passed via `TF_VAR_*`). Do not reuse these shortcuts for production.

## Tested with

| Component | Version |
|-----------|---------|
| Host OS | Fedora 44 (other RHEL-family hosts work; see the libvirt daemon note below) |
| libvirt | 12.0 (Fedora 44 package) |
| OpenTofu | 1.11.5; 1.7 or newer is required for state encryption |
| libvirt provider | `dmacvicar/libvirt` 0.8.3 (pinned in `providers.tf`) |
| VM images | Debian 12 (bookworm) GenericCloud, downloaded as `latest` |

## System Requirements

### Minimum Requirements

The lab runs 3 VMs (general01, master01, worker01): 5 vCPUs, 14 GB of VM RAM and about 120 GB of disk in total. Qcow2 volumes are thin-provisioned, but plan for the full size.

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 4 cores | 8+ cores | Must support virtualization (VT-x/AMD-V) |
| **Memory** | 24GB | 32GB+ | VMs use 14GB; the rest is host overhead and page cache |
| **Storage** | 150GB | 250GB+ | SSD/NVMe recommended |
| **Network** | Any | Any | Lab traffic stays on the libvirt NAT network; internet is needed to download images |
| **OS** | RHEL-family Linux (Fedora, RHEL, Rocky, AlmaLinux) | Fedora 44 | The tested host |

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
sudo dnf -y install \
    git \
    qemu-kvm \
    libvirt \
    virt-install \
    libosinfo \
    guestfs-tools
```

### Enable the libvirt daemons

Current libvirt uses **modular daemons**: one per driver (`virtqemud` for VMs, `virtnetworkd` for networks, `virtstoraged` for storage pools, and so on), each started on demand by its systemd socket. The monolithic `libvirtd` is deprecated; don't enable it. Fedora enables the modular sockets by default, so this loop usually changes nothing, but it is safe to run:

```bash
for drv in qemu network storage nodedev nwfilter secret interface proxy; do
  sudo systemctl enable --now virt${drv}d.socket virt${drv}d-ro.socket virt${drv}d-admin.socket
done
```

!!! warning "Host that already runs `libvirtd`"
    If `systemctl is-active libvirtd` prints `active` (for example, after following an older version of this guide), switch to the modular daemons. Shut down the lab VMs first: the daemon switch disconnects running guests from management until `virtqemud` takes over.

    ```bash
    sudo systemctl disable --now libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket
    # then re-run the loop above
    ```

### Allow your user to use the system connection

Two things are needed to run `virsh` against the system instance (`qemu:///system`, where the lab VMs live) without `sudo`:

1. Membership of the `libvirt` group, which polkit uses to authorize access:

    ```bash
    sudo usermod -aG libvirt "$USER"
    ```

    Log out and back in to apply the group change.

2. `LIBVIRT_DEFAULT_URI`. Without it, `virsh` run as a normal user connects to the per-user session instance (`qemu:///session`) and shows no lab VMs or networks. Persist it in your shell profile (`~/.bashrc` here; use `~/.zshrc` for zsh):

    ```bash
    echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.bashrc
    source ~/.bashrc
    virsh uri          # qemu:///system
    virsh list --all   # works without sudo
    ```

The OpenTofu providers in this repo set `qemu:///system` explicitly and don't need the variable.

### Install OpenTofu

OpenTofu is used for infrastructure automation and VM provisioning. It is not in the default Fedora or Rocky repositories, so add the official OpenTofu repository first. Follow the [OpenTofu RPM installation instructions](https://opentofu.org/docs/intro/install/rpm/) for your distribution, then:

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

# Verify the libvirt sockets are listening (the daemons start on first use)
systemctl is-active virtqemud.socket virtnetworkd.socket virtstoraged.socket
systemctl is-active libvirtd    # should print inactive

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
| `virsh list --all` is empty, or `virsh` errors with `Failed to connect socket to '/run/user/.../...-sock'` | Connected to the session instance | Set `LIBVIRT_DEFAULT_URI="qemu:///system"` (check with `virsh uri`) |
| `virsh` asks for authentication or `permission denied` | Not in the `libvirt` group yet | `id` must list `libvirt`; log out and in again |
| `Failed to connect socket to '/var/run/libvirt/virtqemud-sock'` | Modular sockets not enabled | Run the loop in *Enable the libvirt daemons* |
| `dnf: No match for argument: tofu` | OpenTofu repo not configured | Add the repo from the OpenTofu install page |

## Cleanup

Nothing in this page needs cleanup beyond uninstalling packages. Teardown of the lab itself is in [Infrastructure Deployment](infrastructure-deployment.md#cleanup).

## Next Steps

Once all prerequisites are met and verified:

1. **[Infrastructure Deployment](infrastructure-deployment.md)** - Deploy VMs and networking
2. **[Kubernetes Setup](kubernetes-setup.md)** - Install and configure k0s cluster
