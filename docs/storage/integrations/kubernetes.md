# Kubernetes Integration Guide

## Overview

This guide provides comprehensive instructions for integrating Ceph storage with Kubernetes using the Ceph CSI (Container Storage Interface) driver. The integration enables dynamic provisioning of persistent volumes with support for RBD (block storage) and S3 compatible storage.

## Prerequisites
- Ceph pool with name `kubernetes` (already created via ansible)

## Ceph Cluster Preparation

### 1. Setup Client Authentication

Create a dedicated Ceph user for Kubernetes with minimal required permissions:

```bash
# Create the client with specific permissions
ceph auth get-or-create client.kubernetes \
  mon 'profile rbd' \
  osd 'profile rbd pool=kubernetes' \
  mgr 'profile rbd pool=kubernetes'
```

Example output:
```
[client.kubernetes]
    key = AQD9o0Fd6hQRChAAt7fMaSZXduT3NWEqylNpmg==
```

### 2. Verify Cluster Information

Collect the following information needed for CSI configuration:

```bash
# Get monitor addresses
ceph mon dump

# Get cluster FSID
ceph status

# Verify client access
ceph auth get client.kubernetes
```

## Install Ceph CSI Driver

### 1. Create Namespace

Create a dedicated namespace for the CSI driver:

```bash
kubectl create namespace ceph-csi-rbd
```

### 2. Install CSI Driver using Helm and Kustomize

Create a values file for the Helm chart:

```yaml
# values.yaml
csiConfig:
  - clusterID: "YOUR_CLUSTER_FSID"
    monitors:
      - "MONITOR_IP_1:6789"
      - "MONITOR_IP_2:6789" 
      - "MONITOR_IP_3:6789"

secret:
  create: true
  name: csi-rbd-secret
  userID: kubernetes
  userKey: AQD9o0Fd6hQRChAAt7fMaSZXduT3NWEqylNpmg==

storageClass:
  create: true
  name: ceph-rbd
  clusterID: YOUR_CLUSTER_FSID
  pool: kubernetes
  reclaimPolicy: Delete
  allowVolumeExpansion: true
  mountOptions: []

provisioner:
  name: rbd.csi.ceph.com
  replicaCount: 2
  
nodeplugin:
  name: csi-rbdplugin
```

Alternative installation method using the referenced helm chart configuration [here](https://github.com/riupie/gitops-argocd/blob/main/overlays/development/ceph-csi-rbd/values.yaml)

### 3. Verify Installation

Check that all CSI components are running:

```bash
# Check CSI pods
kubectl get pods -n ceph-csi-rbd

# Check CSI driver registration
kubectl get csidrivers

# Check storage class
kubectl get storageclass
```

## Usage Examples

### Basic PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rbd-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ceph-rbd
```

### Pod Using Ceph RBD Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ceph-rbd-pod
spec:
  containers:
  - name: web-server
    image: nginx
    volumeMounts:
    - name: mypd
      mountPath: /var/lib/www/html
  volumes:
  - name: mypd
    persistentVolumeClaim:
      claimName: rbd-pvc
      readOnly: false
```

## References

- [Ceph CSI Official Documentation](https://github.com/ceph/ceph-csi)
- [Ceph RBD Documentation](https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/)