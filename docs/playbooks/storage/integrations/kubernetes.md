# Integrate Ceph RBD with Kubernetes (Ceph CSI)

This playbook enables dynamic provisioning of persistent volumes in Kubernetes backed by Ceph, using the Ceph CSI (Container Storage Interface) driver for RBD (block storage).

Use it when a Kubernetes cluster needs `ReadWriteOnce` PVCs from the lab Ceph cluster, after [Ceph deployment](../deployment.md) (the `kubernetes` pool must exist).

Stack: Ceph CSI (RBD), Helm · Target: namespace `ceph-csi-rbd` · Env: lab

## Prerequisites

- [ ] Ceph cluster deployed and healthy ([Ceph deployment](../deployment.md)); `ceph -s` works on an admin node
- [ ] Ceph pool with name `kubernetes` (already created via ansible): `ceph osd pool ls | grep kubernetes`
- [ ] `kubectl` access to the target cluster: `kubectl config current-context`
- [ ] `helm` (or the GitOps repo below) to install the chart

## Steps

### 1. Set up client authentication

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

### 2. Collect cluster information

Collect the following information needed for CSI configuration:

```bash
# Get monitor addresses
ceph mon dump

# Get cluster FSID
ceph status

# Verify client access
ceph auth get client.kubernetes
```

### 3. Create the namespace

Create a dedicated namespace for the CSI driver:

```bash
kubectl create namespace ceph-csi-rbd
```

### 4. Install the CSI driver (Helm and Kustomize)

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

### 5. Provision a test volume

Basic PersistentVolumeClaim:

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

Pod using the Ceph RBD volume:

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

## Verify

Check that all CSI components are running:

```bash
# Check CSI pods
kubectl get pods -n ceph-csi-rbd

# Check CSI driver registration
kubectl get csidrivers

# Check storage class
kubectl get storageclass
```

> TODO: add the end-to-end check for step 5 (expected PVC `Bound` and pod `Running` output).

## Troubleshooting

> TODO: no troubleshooting content in the source. Add symptom / likely cause / fix rows (e.g. PVC `Pending`, CSI pods not ready).

## References

- [Ceph CSI Official Documentation](https://github.com/ceph/ceph-csi)
- [Ceph RBD Documentation](https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/)
