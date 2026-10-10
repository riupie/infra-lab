# Kubernetes Setup

This guide installs a minimal k0s cluster (`lab-cluster`) on master01 and worker01 with k0sctl, then hands the cluster over to Flux, which installs every add-on from [`riupie/gitops-fluxcd`](https://github.com/riupie/gitops-fluxcd).

Stack: k0s `v1.36.4+k0s.1`, k0sctl `v0.33.1`, Calico, flux-operator `0.61.0` (Flux 2.x) · Target: master01 (`192.168.10.10`, controller), worker01 (`192.168.10.11`, worker) · Run from: the Fedora 44 host · Env: lab

## Prerequisites

- [ ] [Prerequisites](prerequisites.md) and [Infrastructure Deployment](infrastructure-deployment.md) completed
- [ ] VMs running and reachable over SSH as `cloud` (the `ssh_admin` user created by the VM module):

    ```bash
    virsh list
    ssh cloud@192.168.10.10 "hostname && uptime"
    ssh cloud@192.168.10.11 "hostname && uptime"
    ```

- [ ] `kubectl` installed on the host: `kubectl version --client`

## Steps

### 1. Install k0sctl

*On the host.* Download the release binary and verify its checksum:

```bash
K0SCTL_VERSION=v0.33.1
mkdir -p /tmp/k0sctl && cd /tmp/k0sctl
curl -fsSLO https://github.com/k0sproject/k0sctl/releases/download/${K0SCTL_VERSION}/k0sctl-linux-amd64
curl -fsSLO https://github.com/k0sproject/k0sctl/releases/download/${K0SCTL_VERSION}/checksums.txt
sha256sum --check --ignore-missing checksums.txt
sudo install -m 0755 k0sctl-linux-amd64 /usr/local/bin/k0sctl
k0sctl version
```

!!! note
    `https://get.k0s.sh` installs the `k0s` binary, not `k0sctl`. k0sctl only runs on the host; it installs k0s on the nodes over SSH.

### 2. Review the cluster configuration

The configuration is [`k0s/k0sctl.yaml`](https://github.com/riupie/infra-lab/blob/main/k0s/k0sctl.yaml) in this repo:

| Setting | Value |
|---|---|
| Controller | master01 `192.168.10.10` (control plane only; it does not appear in `kubectl get nodes`) |
| Worker | worker01 `192.168.10.11` |
| SSH user | `cloud` |
| CNI | Calico |
| kube-proxy | IPVS with `strictARP: true` (required by MetalLB L2) |
| Helm extension | `flux-operator` chart `0.61.0` in `flux-system`; nothing else |

### 3. Deploy the cluster

*On the host, from the repo root:*

```bash
k0sctl apply --config k0s/k0sctl.yaml
```

Add `--debug` if a step fails. k0sctl checks SSH access, installs k0s on both nodes, initializes the controller, joins the worker and installs the flux-operator chart.

### 4. Get cluster access

```bash
mkdir -p ~/.kube
k0sctl kubeconfig --config k0s/k0sctl.yaml > ~/.kube/config
kubectl config current-context    # lab-cluster
kubectl --context lab-cluster cluster-info
```

!!! warning
    This overwrites `~/.kube/config`. If you already have other clusters, write to a separate file and merge it, or use `KUBECONFIG`.

### 5. Connect Flux to the GitOps repository

flux-operator is running but has nothing to sync yet. Create the `FluxInstance` that points it at `gitops-fluxcd`:

```bash
kubectl --context lab-cluster apply -f - <<'EOF'
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.x"
    registry: ghcr.io/fluxcd
    artifact: oci://ghcr.io/controlplaneio-fluxcd/flux-operator-manifests
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes
    size: small
    networkPolicy: true
  sync:
    kind: GitRepository
    url: https://github.com/riupie/gitops-fluxcd.git
    ref: refs/heads/main
    path: clusters/development
    interval: 1m
EOF
```

From here on, Flux manages the `FluxInstance` and every add-on from `clusters/development` in the repo. Change the cluster by committing to `gitops-fluxcd`, not with `kubectl apply`.

## Verify

### 1. Nodes and system pods

```bash
kubectl --context lab-cluster get nodes -o wide
kubectl --context lab-cluster -n kube-system get pods
```

Expected output:

```text
NAME       STATUS   ROLES    AGE   VERSION       INTERNAL-IP     ...
worker01   Ready    <none>   4m    v1.36.4+k0s   192.168.10.11   ...
```

`kube-system` contains `calico-*`, `coredns-*`, `konnectivity-agent-*`, `kube-proxy-*` and `metrics-server-*` pods, all `Running`.

### 2. Flux

```bash
kubectl --context lab-cluster -n flux-system get fluxinstance,gitrepository,kustomization
kubectl --context lab-cluster get helmrelease -A
```

Expected: the `FluxInstance` `flux` is `READY True`, the `flux-system` GitRepository points at `https://github.com/riupie/gitops-fluxcd.git`, and the Kustomizations (`flux-system`, `infrastructure`, `infrastructure-configs`, `apps`) are `READY True`. HelmReleases for MetalLB, cert-manager, External-DNS, External Secrets, Sealed Secrets and agentgateway appear as they reconcile.

### 3. MetalLB

```bash
kubectl --context lab-cluster -n metallb get ipaddresspool,l2advertisement
```

Expected: `IPAddressPool` `lb-pool` with `192.168.10.100-192.168.10.110` and a matching `L2Advertisement`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `k0sctl apply` fails at SSH connect | Your key isn't on the VMs, or the user isn't `cloud` | Re-check the `ssh_keys` step in [Infrastructure Deployment](infrastructure-deployment.md#step-3-deploy-vms) |
| `kubectl get nodes` shows only worker01 | Expected: the controller runs no kubelet | Nothing to fix |
| `FluxInstance` not ready | flux-operator can't pull the distribution from `ghcr.io` | `kubectl --context lab-cluster -n flux-system logs deploy/flux-operator` |
| Kustomization `infrastructure` fails | A manifest in `gitops-fluxcd` is invalid | `kubectl --context lab-cluster -n flux-system describe kustomization infrastructure`, fix it in the repo |

## Next steps

1. [Set Up Dynamic DNS](../playbooks/dynamic-dns.md): BIND9 on general01, which External-DNS writes to
2. [Secure MCP Servers with OAuth](../playbooks/mcp-oauth.md): Keycloak in front of MCP servers on agentgateway
