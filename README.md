# Infra Lab
A hands-on lab for running an on-premise Kubernetes cluster on KVM. It deploys the core Kubernetes services and automates infrastructure setup and application delivery with Infrastructure as Code (OpenTofu) and GitOps (Flux).

The guides in the documentation section cover every step, from planning the cluster architecture to configuring each component by hand, so you can build the same cluster at home.

## Directory hierarchy

```text
.
├── addons
│   ├── bind9
│   └── keycloak
├── docs
│   ├── assets
│   ├── getting-started
│   ├── playbooks
│   └── stylesheets
├── jarvis-kvm
│   ├── ansible        # Ceph playbooks (obsolete)
│   └── terraform
├── k0s
│   └── k0sctl.yaml
├── LICENSE
├── README.md
├── requirements.txt
└── zensical.toml
```

`.git-crypt`: GPG keys of the collaborators who can decrypt the git-crypt encrypted files.

`jarvis-kvm`: OpenTofu code that provisions the network, storage pool and VMs on the KVM host.

## Technology stack

The diagram and table below list the open-source components the lab uses so far. Their installation is documented in these guides, and their deployment is automated with OpenTofu and Flux.

<p align="center">
  <img src="https://riupie.com/infra-lab/assets/imgs/tech-stack.svg" width="500"/>
</p>

<div class="d-flex">
<table class="table table-white table-borderer border-dark w-auto align-middle">
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img width="32" src="https://fluxcd.io/favicons/android-chrome-192x192.png" alt="Flux logo"></td>
        <td><a href="https://fluxcd.io/">Flux</a></td>
        <td>GitOps tool (manifests in <a href="https://github.com/riupie/gitops-fluxcd">gitops-fluxcd</a>)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://cloudinit.readthedocs.io/en/latest/_static/logo.png" alt="Cloud-init logo"></td>
        <td><a href="https://cloudinit.readthedocs.io/en/latest/">Cloud-init</a></td>
        <td>First-boot configuration of the VMs</td>
    </tr>
    <tr>
        <td><img width="32" src="https://landscape.cncf.io/logos/f26381b645b2f14293a2a597bc98b5bbe1e5e086029de41830ba7c667353bf3e.svg" alt="Containerd logo"></td>
        <td><a href="https://containerd.io/">Containerd</a></td>
        <td>Container runtime integrated with K0S</td>
    </tr>
    <tr>
        <td><img width="60" src="https://www.tigera.io/app/uploads/2021/07/calico_logo_white.svg" alt="calico logo"></td>
        <td><a href="https://www.tigera.io/project-calico">Calico</a></td>
        <td>Kubernetes networking (CNI)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://coredns.io/images/CoreDNS_Colour_Horizontal.png" alt="CoreDNS logo"></td>
        <td><a href="https://coredns.io/">CoreDNS</a></td>
        <td>Kubernetes DNS</td>
    </tr>
    <tr>
        <td><img width="32" src="https://www.debian.org/Pics/openlogo-50.png" alt="Debian logo"></td>
        <td><a href="https://debian.org/">Debian</a></td>
        <td>VM OS (cluster nodes and general01)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://fedoraproject.org/favicon.ico" alt="Fedora logo"></td>
        <td><a href="https://fedoraproject.org/">Fedora</a></td>
        <td>KVM host OS</td>
    </tr>
    <tr>
        <td><img width="32" src="https://kubernetes-sigs.github.io/external-dns/v0.15.0/docs/img/external-dns.png" alt="external-dns logo"></td>
        <td><a href="https://kubernetes-sigs.github.io/external-dns/">ExternalDNS</a></td>
        <td>External DNS synchronization</td>
    </tr>
    <tr>
        <td><img width="32" src="https://cert-manager.io/images/cert-manager-logo-icon.svg" alt="Cert-manager logo"></td>
        <td><a href="https://cert-manager.io">Cert-manager</a></td>
        <td>TLS certificate management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://k0sproject.io/images/k0s_logo.svg" alt="K0S logo"></td>
        <td><a href="https://k0sproject.io/">K0S</a></td>
        <td>Lightweight, CNCF-certified Kubernetes distribution</td>
    </tr>
    <tr>
        <td><img width="32" src="https://linux-kvm.org/kvmless/kvmbanner-logo3.png" alt="KVM logo"></td>
        <td><a href="https://linux-kvm.org/page/Main_Page">KVM</a></td>
        <td>Linux hypervisor; needs a CPU with Intel VT-x or AMD-V</td>
    </tr>
    <tr>
        <td><img width="32" src="https://landscape.cncf.io/logos/d19371232c839420223f96327f99332bce52962724a113bd61f3eef10a0bc637.svg" alt="MetalLB logo"></td>
        <td><a href="https://metallb.io/">MetalLB</a></td>
        <td>Load-balancer implementation for bare metal Kubernetes clusters</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://www.isc.org/bind/">BIND9</a></td>
        <td>Authoritative and recursive DNS for the lab zone, with TSIG dynamic updates</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://www.keycloak.org/">Keycloak</a></td>
        <td>Identity provider (OIDC, Dynamic Client Registration) for MCP servers</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://agentgateway.dev/">agentgateway</a></td>
        <td>Gateway API implementation for MCP and AI traffic</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://external-secrets.io/">External Secrets</a></td>
        <td>Syncs secrets from external stores into Kubernetes</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://github.com/bitnami-labs/sealed-secrets">Sealed Secrets</a></td>
        <td>Encrypted secrets that are safe to store in Git</td>
    </tr>
    <tr>
        <td></td>
        <td><a href="https://infisical.com/">Infisical</a></td>
        <td>Secret store behind External Secrets (lab project, environment <code>dev</code>)</td>
    </tr>
</table>
</div>