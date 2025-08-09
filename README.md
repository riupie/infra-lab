
# Infra Lab
This project is designed as a hands-on learning experience to set up an on-premise Kubernetes cluster using KVM. It covers the deployment of core Kubernetes services and demonstrates how to automate infrastructure setup and application delivery using Infrastructure as Code (IaC) and GitOps principles, leveraging tools like Terraform and ArgoCD.

Every step of the process—from planning and designing the cluster architecture to manually configuring each component—has been carefully documented. These guides are available in the documentation section, making it easy for anyone to replicate and build their own home Kubernetes cluster.

## Directory Hierarchy

```
.
├── addons
│   └── bind9
├── docs
│   ├── assets
│   ├── getting-started
│   ├── storage
│   └── stylesheets
├── jarvis-kvm
│   ├── ansible
│   └── terraform
├── k0s
│   └── k0sctl.yaml
├── LICENSE
├── mkdocs.yml
├── README.md
└── requirements.txt
```

`.git-crypt`: contains gpg files of collaborators who can open encrypted git-crypt file.

`jarvis-kvm`: terraform code to provision VMs and other resources on top KVM hypervisor.

## Technology Stack

The following picture shows the high level components of opensource solutions used so far in the cluster, which installation process has been documented and its deployment has been automated with Open Tofu:

<p align="center">
  <img src="docs/assets/imgs/tech-stack.svg" width="500"/>
</p>

<div class="d-flex">
<table class="table table-white table-borderer border-dark w-auto align-middle">
    <tr>
        <th></th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img width="32" src="https://argo-cd.readthedocs.io/en/stable/assets/logo.png"></td>
        <td><a href="https://argo-cd.readthedocs.io/en/stable/">ArgoCD</a></td>
        <td>GitOps tool</td>
    </tr>
    <tr>
        <td><img width="32" src="https://cloudinit.readthedocs.io/en/latest/_static/logo.png"></td>
        <td><a href="https://cloudinit.readthedocs.io/en/latest/">Cloud-init</a></td>
        <td>Automate OS initial installation</td>
    </tr>
    <tr>
        <td><img width="32" src="https://ceph.io/assets/favicons/android-chrome-192x192.png"></td>
        <td><a href="https://ceph.io/">Ceph</a></td>
        <td>Distributed Storage</td>
    </tr>
    <tr>
        <td><img width="32" src="https://landscape.cncf.io/logos/f26381b645b2f14293a2a597bc98b5bbe1e5e086029de41830ba7c667353bf3e.svg"></td>
        <td><a href="https://containerd.io/">Containerd</a></td>
        <td>Container runtime integrated with K0S</td>
    </tr>
    <tr>
        <td><img width="60" src="https://www.tigera.io/app/uploads/2021/07/calico_logo_white.svg" alt="cilium logo"></td>
        <td><a href="https://www.tigera.io/project-calico">Calico</a></td>
        <td>Kubernetes Networking (CNI) and Load Balancer</td>
    </tr>
    <tr>
        <td><img width="32" src="https://coredns.io/images/CoreDNS_Colour_Horizontal.png"></td>
        <td><a href="https://coredns.io/">CoreDNS</a></td>
        <td>Kubernetes DNS</td>
    </tr>
    <tr>
        <td><img width="32" src="https://www.debian.org/Pics/openlogo-50.png"></td>
        <td><a href="https://debian.org/">Debian</a></td>
        <td>Cluster nodes OS & Host OS</td>
    </tr>
    <tr>
        <td><img width="32" src="https://kubernetes-sigs.github.io/external-dns/v0.15.0/docs/img/external-dns.png" alt="external-dns logo"></td>
        <td><a href="https://kubernetes-sigs.github.io/external-dns/">ExternalDNS</a></td>
        <td>External DNS synchronization</td>
    </tr>
    <tr>
        <td><img width="32" src="https://cert-manager.io/images/cert-manager-logo-icon.svg"></td>
        <td><a href="https://cert-manager.io">Cert-manager</a></td>
        <td>TLS Certificates management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://k0sproject.io/images/k0s_logo.svg"></td>
        <td><a href="https://k0sproject.io/">K0S</a></td>
        <td> The simple, solid & certified Kubernetes distribution that works on any infrastructure</td>
    </tr>
    <tr>
        <td><img width="32" src="https://linux-kvm.org/kvmless/kvmbanner-logo3.png"></td>
        <td><a href="https://linux-kvm.org/page/Main_Page">KVM</a></td>
        <td> Full virtualization solution for Linux on x86 hardware containing virtualization extensions (Intel VT or AMD-V)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://landscape.cncf.io/logos/d19371232c839420223f96327f99332bce52962724a113bd61f3eef10a0bc637.svg"></td>
        <td><a href="https://metallb.io/">MetalLB</a></td>
        <td>Load-balancer implementation for bare metal Kubernetes clusters</td>
    </tr>
</table>
</div>