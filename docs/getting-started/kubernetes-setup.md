# Kubernetes Setup
## Overview

This guide covers the installation and configuration of a Kubernetes cluster using k0s, a lightweight and CNCF-certified Kubernetes distribution. The setup uses k0sctl for cluster lifecycle management and provides a production-ready environment.

## Prerequisites

Before proceeding, ensure you have completed:

1. **[Prerequisites](prerequisites.md)** - System requirements and software installation
2. **[Infrastructure Deployment](infrastructure-deployment.md)** - VM and network setup

### Verify Infrastructure

```bash
# Verify all VMs are running
virsh list

# Test connectivity to all nodes
ping -c 2 192.168.10.9   # bastion01
ping -c 2 192.168.10.10  # master01
ping -c 2 192.168.10.11  # worker01
ping -c 2 192.168.10.12  # worker02
ping -c 2 192.168.10.13  # worker03

# Test SSH access
ssh cloud@192.168.10.10 "hostname && uptime"
```

## k0sctl Installation (from Bastion)

### Install k0sctl

k0sctl is the command-line tool for managing k0s Kubernetes clusters.

```bash
# Method 1: Using the install script (recommended)
curl -sSLf https://get.k0s.sh | sudo sh

# Method 2: Manual installation
wget https://github.com/k0sproject/k0sctl/releases/download/v0.15.5/k0sctl-linux-x64
chmod +x k0sctl-linux-x64
sudo mv k0sctl-linux-x64 /usr/local/bin/k0sctl

# Verify installation
k0sctl version
```

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
| **Worker Node** | worker02 | 192.168.10.12 | Worker |
| **Worker Node** | worker03 | 192.168.10.13 | Worker |

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
4. **Worker Join**: Joins worker nodes to the cluster
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
# NAME       STATUS   ROLES                  AGE   VERSION
# master01   Ready    control-plane,worker   5m    v1.33.1+k0s
# worker01   Ready    worker                 4m    v1.33.1+k0s
# worker02   Ready    worker                 4m    v1.33.1+k0s
# worker03   Ready    worker                 4m    v1.33.1+k0s

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

# Check pod status across all namespaces
kubectl get pods --all-namespaces
```

## Next Steps

After successful Kubernetes setup:

1. **[Storage Integration](../storage/integrations/kubernetes.md)** - Configure Ceph storage
2. **CI/CD** - Set up GitOps with ArgoCD