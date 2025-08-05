# Lab Architecture
## Overview

<figure markdown="span">
  ![Lab Architecture](../assets/imgs/lab-architecture.svg){ width=900 }
  <figcaption>Infrastructure Lab Architecture Diagram</figcaption>
</figure>

This document provides a comprehensive overview of the network configuration and virtual machine layout for a KVM-based home lab environment. The architecture uses libvirt for virtualization management on a Linux host and is designed for learning, development, and testing purposes.

### Architecture Highlights

- **Hypervisor**: KVM with libvirt management
- **Network Design**: NAT-based virtual networks with custom bridges
- **Service Discovery**: Internal DNS with Tailscale integration
- **Orchestration**: Kubernetes cluster for container workloads
- **Remote Access**: Tailscale subnet routing for secure external access

---

## Host Network Configuration

The host machine (`jarvis`) manages multiple network interfaces for VM connectivity and external access.

### Network Interface Details

| Interface | Type | Purpose | Configuration |
|-----------|------|---------|---------------|
| **`enp8s0`** | Physical NIC | LAN connectivity | Connected to home/office network |
| **`virbr1`** | Virtual Bridge | VM internal network | Subnet: `192.168.10.0/24` |
| **`virbr2`** | Virtual Bridge | VM storage internal network | Subnet: `192.168.11.0/24` |
| **`vnetX`** | Virtual TAP | VM network adapters | Auto-created by libvirt, attached to `virbr1` and `virbr2` |

---

## Virtual Machine Inventory

The lab environment consists of 5 virtual machines, each serving specific roles in the infrastructure:

| VM ID | Hostname | Status | Role | IP Address | Interface | Resources |
|-------|----------|--------|------|------------|-----------|-----------|
| 2 | **bastion01** | Running | DNS Server + Tailscale Router | `192.168.10.15` | vnet4 | 2 vCPU, 4GB RAM |
| 3 | **master01** | Running | Kubernetes Control Plane | `192.168.10.10` | vnet5 | 2 vCPU, 4GB RAM |
| 4 | **worker01** | Running | Kubernetes Worker Node | `192.168.10.11` | vnet6 | 2 vCPU, 8GB RAM |
| 5 | **worker02** | Running | Kubernetes Worker Node | `192.168.10.12` | vnet7 | 2 vCPU, 8GB RAM |
| 6 | **worker03** | Running | Kubernetes Worker Node | `192.168.10.13` | vnet9 | 2 vCPU, 8GB RAM |

### VM Connectivity

- **Internal Communication**: All VMs connected via `virbr1` bridge (192.168.10.0/24)
- **External Access**: NAT through host machine
- **Service Discovery**: Internal DNS provided by bastion01
- **Remote Access**: Tailscale subnet routing for external connectivity

---

## Network Architecture

### NAT-based Networking

The lab uses NAT (Network Address Translation) mode for VM connectivity, providing isolation and security:

| Feature | Description | Note |
|---------|-------------|---------|
| **Private Subnet** | VMs operate on `192.168.10.0/24` and `192.168.11.0/24` | Network isolation from external networks |
| **Internet Access** | Outbound connectivity via host | VMs can reach external services |
| **External Isolation** | No direct inbound access from LAN | Enhanced security posture |

### Access Patterns

```
Direction    | Source        | Destination   | Status
-------------|---------------|---------------|--------
Outbound     | VMs           | Internet      | ✅ Allowed
Internal     | VM ↔ VM       | Internal IPs  | ✅ Allowed
Host Access  | VMs ↔ Host    | Host Bridge   | ✅ Allowed
Inbound      | LAN → VMs     | VM IPs        | ❌ Blocked (NAT)
```

!!! note
    External access to VMs requires either port forwarding or Tailscale subnet routing.

## Infrastructure Services

### Bastion Host (bastion01)

The bastion host provides critical infrastructure services for the lab environment:

#### Internal DNS Server (BIND9)

| Service | Configuration | Purpose |
|---------|---------------|---------|
| **DNS Software** | BIND9 | Authoritative DNS for internal zone |
| **Zone** | `*.lab.riupie.com` | Internal service discovery |
| **Forwarders** | 1.1.1.1, 8.8.8.8 | External DNS resolution |
| **Clients** | All lab VMs | Centralized name resolution |

#### Tailscale Integration

| Feature | Configuration | Benefit |
|---------|---------------|---------|
| **Subnet Router** | Advertises `192.168.10.0/24` | Remote access to entire lab |
| **Exit Node** | Optional internet routing | Secure external connectivity |
| **Authentication** | Tailnet integration | SSO-based access control |
| **Encryption** | WireGuard protocol | Zero-trust network security |

## Hardware Requirements

### Production Host Specifications

The lab runs on a dedicated bare-metal server with the following specifications:

| Component | Specification | Usage |
|-----------|---------------|--------|
| **CPU** | AMD Ryzen 5 3600 (12 cores @ 3.6GHz) | VM compute resources |
| **Memory** | 64GB DDR4 | VM memory allocation |
| **Storage** | SSD storage pool | VM disk images and data |
| **Network** | 1Gbps Ethernet | Internet and LAN connectivity |
| **OS** | Debian GNU/Linux 12 (bookworm) | KVM hypervisor host |

### Host System Details

```bash
# System Information
OS: Debian GNU/Linux 12 (bookworm) x86_64
Kernel: 6.1.0-28-amd64
CPU: AMD Ryzen 5 3600 (12) @ 3.600GHz
Memory: 64GB DDR4
Virtualization: KVM with libvirt
```

### Minimum Requirements

For testing or development environments, you can use alternative hardware:

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 4 cores | 8+ cores | Must support virtualization (VT-x/AMD-V) |
| **Memory** | 16GB | 32GB+ | 4GB per VM + host overhead |
| **Storage** | 100GB | 500GB+ | SSD recommended for performance |
| **Network** | 1Gbps | 1Gbps+ | For VM and container networking |

!!! note
    Laptop or desktop systems can be used as long as they meet the minimum requirements and support hardware virtualization.