# Kubernetes Setup
## Overview

This guide covers the installation and configuration of a Kubernetes cluster using k0s, a lightweight and CNCF-certified Kubernetes distribution. The setup uses k0sctl for cluster lifecycle management and provides a minimal lab environment: one control plane node and one worker node.

## Prerequisites

Before proceeding, ensure you have completed:

1. **[Prerequisites](prerequisites.md)** - System requirements and software installation
2. **[Infrastructure Deployment](infrastructure-deployment.md)** - VM and network setup

### Verify Infrastructure

```bash
# Verify all VMs are running
virsh list

# Test connectivity to all nodes
ping -c 2 192.168.10.9   # bastion (general01)
ping -c 2 192.168.10.10  # master01
ping -c 2 192.168.10.11  # worker01

# Test SSH access (user must match the `user` fields in k0sctl.yaml)
ssh <user>@192.168.10.10 "hostname && uptime"
ssh <user>@192.168.10.11 "hostname && uptime"
```

## k0sctl Installation (from Bastion)

### Install k0sctl

k0sctl is the command-line tool for managing k0s Kubernetes clusters.

```bash
# Method 1: Download the release binary and verify its checksum (recommended)
K0SCTL_VERSION=v0.33.1
mkdir -p /tmp/k0sctl && cd /tmp/k0sctl
curl -fsSLO https://github.com/k0sproject/k0sctl/releases/download/${K0SCTL_VERSION}/k0sctl-linux-amd64
curl -fsSLO https://github.com/k0sproject/k0sctl/releases/download/${K0SCTL_VERSION}/checksums.txt
sha256sum --check --ignore-missing checksums.txt
sudo install -m 0755 k0sctl-linux-amd64 /usr/local/bin/k0sctl

# Method 2: Using Go (requires a Go toolchain)
go install github.com/k0sproject/k0sctl@${K0SCTL_VERSION}

# Verify installation
k0sctl version
```

> **Note:** `https://get.k0s.sh` installs the `k0s` binary, not `k0sctl`. k0sctl only needs to be installed on the bastion; k0s itself is deployed to the nodes by `k0sctl apply`.

## Cluster Configuration

### Download Configuration

```bash
# Download the k0sctl configuration
wget https://raw.githubusercontent.com/riupie/infra-lab/refs/heads/main/k0s/k0sctl.yaml

# Review the configuration
cat k0sctl.yaml
```

### Configuration Overview

The k0sctl configuration defines:

| Component | Node | IP Address | Role |
|-----------|------|------------|------|
| **Control Plane** | master01 | 192.168.10.10 | Controller |
| **Worker Node** | worker01 | 192.168.10.11 | Worker |

The cluster uses Calico as CNI, kube-proxy in IPVS mode (`strictARP: true`) and installs the MetalLB Helm chart through the k0s Helm extension. The controller runs only the control plane, so it does not appear in `kubectl get nodes`.

> **Note:** `k0s/k0sctl.yaml` connects as user `cloud`, while the Terraform VM modules create the admin user `debian`. Set the `user` fields in `k0sctl.yaml` to the account that exists on your VMs and that your SSH key is authorized for.

## Cluster Deployment

### Deploy the Cluster

```bash
# Apply the cluster configuration
k0sctl apply --config k0sctl.yaml

# Monitor deployment progress with debug output
k0sctl apply --config k0sctl.yaml --debug
```

### Deployment Process

The deployment performs the following steps:

1. **Connectivity Check**: Validates SSH access to all nodes
2. **System Preparation**: Installs k0s binary on all nodes
3. **Control Plane Init**: Initializes the Kubernetes control plane
4. **Worker Join**: Joins the worker node to the cluster
5. **Network Setup**: Configures Calico CNI
6. **Health Check**: Verifies cluster functionality

## Cluster Verification

### Get Cluster Access

```bash
# Generate kubeconfig
mkdir ~/.kube
k0sctl kubeconfig --config k0sctl.yaml > ~/.kube/config

# Verify kubectl access
kubectl cluster-info
```

### Verify Cluster Status

#### Check Node Status

```bash
# List all nodes
kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES    AGE   VERSION
# worker01   Ready    <none>   4m    v1.36.4+k0s

# Check node details
kubectl get nodes -o wide
```

#### Verify System Pods

```bash
# Check system pods status
kubectl get pods -n kube-system

# Expected pods:
# - calico-* (CNI networking)
# - coredns-* (DNS resolution)
# - konnectivity-* (API server connectivity)
# - metrics-server-* (resource metrics)

# Check MetalLB (installed by the k0s Helm extension)
kubectl get pods -n metallb

# Check pod status across all namespaces
kubectl get pods --all-namespaces
```

## Next Steps

After successful Kubernetes setup:

1. **MetalLB** - Define an `IPAddressPool` and `L2Advertisement` for LoadBalancer services (only the chart is installed)
2. **CI/CD** - Set up GitOps with ArgoCD
