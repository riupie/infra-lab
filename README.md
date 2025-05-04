# Infra Lab
This repository contains some IaaC that I use to provision resource at my personal lab.

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