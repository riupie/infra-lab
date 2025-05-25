# Quickstart Guide
This are the instructions to quickly setup virtualization on your Linux Debian for Kubernetes cluster using following tool:
* KVM: Hypervisor to provision VM
* Open Tofu: automate VM creation

## Setup KVM
Install required packages

```bash

root@jarvis:~# apt -y install qemu-kvm libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools
# confirm modules are loaded
root@jarvis:~# lsmod | grep kvm
kvm_amd               155648  10
kvm                  1146880  1 kvm_amd
irqbypass              16384  26 kvm
ccp                   118784  1 kvm_amd
```

## Setup VM for Kubernetes

1. Clone [infra-lab](https://github.com/riupie/infra-lab.git) repo.

```bash
git clone https://github.com/riupie/infra-lab.git
```

2. Create virtual network for VM.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/networks
tofu init
tofu apply
```

!!! info

    Make sure you already have OpenTofu installed on host server.

3. Create storage pool for VM.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/storage-pool
tofu init
tofu apply
```

4. Create VM for kubernetes cluster. Adjust VM spesification based on your need.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/storage-pool
tofu init
tofu apply
```

## Setup Kubernetes using k0sctl