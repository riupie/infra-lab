## Overview

<figure markdown="span">
  ![Lab Architecture](../assets/imgs/lab-architecture.svg){ width=900 }
  <figcaption>Lab Architecture</figcaption>
</figure>

This document describes the network configuration and virtual machine layout for a KVM-based home lab using libvirt on a Linux host. It is intended as a reference for anyone wanting to replicate a similar setup.

---

## Host Network Interfaces Overview

The host machine (`jarvis`) has the following network interfaces:

### Interface Details

- **`enp8s0`**: Physical NIC connected to your LAN.
- **`virbr1`**: Custom bridge for VMs to connect to each other with subnet 192.168.10.0/24.
- **`vnetX`**: Virtual interfaces created automatically by libvirt when VMs start; attached to `virbr1`.

---

## Virtual Machines

The home lab includes 4 running VMs:

| ID | Name       | State   | Role                                  | Network Interface |
|----|------------|---------|----------------------------------------|--------------------|
| 2  | bastion01  | running | Internal DNS + Tailscale Exit Node     | vnet4              |
| 3  | master01   | running | Kubernetes Control Plane               | vnet5              |
| 4  | worker01   | running | Kubernetes Worker Node                 | vnet6              |
| 5  | worker02   | running | Kubernetes Worker Node                 | vnet7              |
| 6  | worker03   | running | Kubernetes Worker Node                 | vnet9              |

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

## Hardware
For this lab architecture, I use baremetal server with following spec:
```
       _,met$$$$$gg.          root@jarvis
    ,g$$$$$$$$$$$$$$$P.       -----------
  ,g$$P"     """Y$$.".        OS: Debian GNU/Linux 12 (bookworm) x86_64
 ,$$P'              `$$$.     Kernel: 6.1.0-28-amd64
',$$P       ,ggs.     `$$b:   Uptime: 5 days, 40 mins
`d$$'     ,$P"'   .    $$$    Packages: 579 (dpkg)
 $$P      d$'     ,    $$P    Shell: bash 5.2.15
 $$:      $$.   -    ,d$$'    Resolution: 1280x1024
 $$;      Y$b._   _,d$P'      Terminal: /dev/pts/10
 Y$$.    `.`"Y$$$$P"'         CPU: AMD Ryzen 5 3600 (12) @ 3.600GHz
 `$$b      "-.__              GPU: 07:00.0 ASPEED Technology, Inc. ASPEED Graphics Family
  `Y$$                        Memory: 27776MiB / 64203MiB
   `Y$$.
     `$$b.
       `Y$$b.
          `"Y$b._
              `"""

```

You can use your laptop instead of server as long you have enough CPU and RAM.