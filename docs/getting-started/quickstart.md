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

2. Install required packages on host where OpenTofu wil be executed.

```bash
apt install -y mkisofs xsltproc
```

3. Create virtual network for VM.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/networks
tofu init
tofu apply
```

!!! info

    Make sure you already have OpenTofu installed on host server.

4. Create storage pool for VM.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/terraform/storage-pool
tofu init
tofu apply
```

5. Create VM for kubernetes cluster. Adjust VM spesification based on your need.

```bash
# From repo infra-lab root directory
cd jarvis-kvm/terraform/vm
tofu init
tofu apply
```

## Setup Kubernetes using k0sctl

From bastion server, install [k0sctl](https://github.com/k0sproject/k0sctl?tab=readme-ov-file#installation) and run this command. File `k0sctl.yaml` can be retrieved from [here](https://raw.githubusercontent.com/riupie/infra-lab/refs/heads/main/k0s/k0sctl.yaml).

```bash
k0sctl apply --config k0sctl.yaml
```

Check kubernetes cluster installation.

```bash
# Check cluster info
cloud@bastion01:~$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.10.10:6443
CoreDNS is running at https://192.168.10.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Check worker nodes
cloud@bastion01:~$ kubectl get nodes
NAME       STATUS   ROLES    AGE     VERSION
worker01   Ready    <none>   5d16h   v1.33.1+k0s
worker02   Ready    <none>   5d16h   v1.33.1+k0s
worker03   Ready    <none>   17h     v1.33.1+k0s


```