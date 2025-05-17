
# Infra Lab
This project is designed as a hands-on learning experience to set up an on-premise Kubernetes cluster using KVM. It covers the deployment of core Kubernetes services and demonstrates how to automate infrastructure setup and application delivery using Infrastructure as Code (IaC) and GitOps principles, leveraging tools like Ansible and ArgoCD.

Every step of the process—from planning and designing the cluster architecture to manually configuring each component—has been carefully documented. These guides are available in the documentation section, making it easy for anyone to replicate and build their own home Kubernetes cluster.

The project’s Git repository includes Ansible automation playbooks and a collection of Kubernetes applications that can be deployed using ArgoCD, enabling a fully automated and reproducible setup.

## Directory Hierarchy

```
.
├── .gitattributes
├── .git-crypt
│   ├── .gitattributes
│   └── keys
├── .gitignore
├── LICENSE
├── jarvis-kvm
│   ├── networks
│   ├── tf-state
│   └── vm
└── README.md
```

`.git-crypt`: contains gpg files of collaborators who can open encrypted git-crypt file.

`jarvis-kvm`: terraform code to provision VMs and other resources on top KVM hypervisor.

## Lab Environment
- KVM Hypervisor
- Rocky Linux 9.6