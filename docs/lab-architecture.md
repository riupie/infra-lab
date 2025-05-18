## Overview
<p align="center">
  <img src="/docs/assets/imgs/lab-architecture.svg" width="900"/>
</p>

This document describes the network configuration and virtual machine layout for a KVM-based home lab using libvirt on a Linux host. It is intended as a reference for anyone wanting to replicate a similar setup.

---

## Host Network Interfaces Overview

The host machine (`jarvis`) has the following network interfaces:

### Interface Details

- **`enp8s0`**: Physical NIC connected to your LAN.
- **`virbr1`**: Custom bridge for VMs to connect to each other with subnet 192.168.10.0/24.
- **`vnet0–vnet3`**: Virtual interfaces created automatically by libvirt when VMs start; attached to `virbr1`.

---

## Virtual Machines

The home lab includes 4 running VMs:

| ID | Name       | State   | Role                                  | Network Interface |
|----|------------|---------|----------------------------------------|--------------------|
| 2  | bastion01  | running | Internal DNS + Tailscale Exit Node     | vnet0              |
| 3  | master01   | running | Kubernetes Control Plane               | vnet1              |
| 4  | worker01   | running | Kubernetes Worker Node                 | vnet2              |
| 5  | worker02   | running | Kubernetes Worker Node                 | vnet3              |

Each VM is attached to the `virbr1` bridge network and can communicate with each other and the host.

---

## Networking Mode: NAT

The `virbr1` interface operates in **NAT (Network Address Translation)** mode. This means:

- VMs are on a **private subnet** managed by libvirt (e.g., `192.168.10.0/24`).
- VMs can **access the internet** via the host’s connection.
- VMs can **talk to each other** and the **host**.
- LAN devices **cannot initiate connections** to the VMs by default. Port forwarding will be used to allow external access from Internet.

## Bastion: Internal DNS + Tailscale Agent

Currently, the `bastion01` VM serves two key roles:

### 1. Internal DNS Server (BIND9)

- Provides **DNS resolution** for VMs using `BIND9`.
- Hosts an **authoritative zone** for internal services (`*.lab.riupie.com`).
- Forwards unknown queries to external DNS servers (e.g., 1.1.1.1, 8.8.8.8).

### 2. Tailscale Agent (Subnet Router / Exit Node)
- Runs a Tailscale client authenticated to Tailnet.
- Acts as a subnet router, advertising the internal VM network to my Tailnet.
- Allows remote access to all VMs over Tailscale without port forwarding.