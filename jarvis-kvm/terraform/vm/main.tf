module "bastion" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.0"

  vm_hostname_prefix = "bastion"
  vm_count           = 1
  base_pool_name     = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name   = data.terraform_remote_state.pool.outputs.image_debian12
  memory             = "2048"
  vcpu               = 1
  pool               = "default"
  system_volume      = 20
  dhcp               = false
  ip_address = [
    "192.168.10.9"
  ]
  network_name  = data.terraform_remote_state.network.outputs.network_name
  ip_gateway    = "192.168.10.1"
  ip_nameserver = "8.8.8.8"

  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
  ]
}

module "kube_master" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.0"

  vm_hostname_prefix = "master"
  vm_count           = 1
  base_pool_name     = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name   = data.terraform_remote_state.pool.outputs.image_debian12
  memory             = "4096"
  vcpu               = 2
  pool               = "default"
  system_volume      = 50
  dhcp               = false
  ip_address = [
    "192.168.10.10"
  ]
  network_name       = data.terraform_remote_state.network.outputs.network_name
  ip_gateway         = "192.168.10.1"
  ip_nameserver      = "8.8.8.8"
  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
  ]
}

module "kube_worker" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.0"

  vm_hostname_prefix = "worker"
  vm_count           = 2
  base_pool_name     = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name   = data.terraform_remote_state.pool.outputs.image_debian12
  memory             = "8196"
  vcpu               = 4
  pool               = "default"
  system_volume      = 100
  dhcp               = false
  network_name       = data.terraform_remote_state.network.outputs.network_name
  ip_address = [
    "192.168.10.11",
    "192.168.10.12"
  ]
  ip_gateway         = "192.168.10.1"
  ip_nameserver      = "8.8.8.8"
  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
  ]
}

module "ceph" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "ceph"
  vm_count           = 3
  base_pool_name     = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name   = data.terraform_remote_state.pool.outputs.image_centos9
  disable_ipv6       = true
  additional_disks = {
    0 = [
      { name = "ceph-osd", size = 1024 * 1024 * 1024 * 100 },
      { name = "ceph-db", size = 1024 * 1024 * 1024 * 50 }
    ]
    1 = [
      { name = "ceph-osd", size = 1024 * 1024 * 1024 * 100 },
      { name = "ceph-db", size = 1024 * 1024 * 1024 * 50 }
    ]
    2 = [
      { name = "ceph-osd", size = 1024 * 1024 * 1024 * 100 },
      { name = "ceph-db", size = 1024 * 1024 * 1024 * 50 }
    ]
  }
  attach_individual_disks_per_vm = true
  memory                         = "8096"
  vcpu                           = 2
  pool                           = "default"
  system_volume                  = 50
  dhcp                           = false
  network_name                   = data.terraform_remote_state.network.outputs.network_name
  network_interfaces = {
    0 = [
      {
        #name    = "eth0"
        address      = "192.168.10.20"
        gateway      = "192.168.10.1"
        dns          = ["8.8.8.8"]
        network_name = "net-lab"
      },
      {
        #name    = "eth1"
        address      = "192.168.11.20"
        network_name = "ceph-lab"
      }
    ]
    1 = [
      {
        #name    = "eth0"
        address      = "192.168.10.21"
        gateway      = "192.168.10.1"
        dns          = ["8.8.8.8"]
        network_name = "net-lab"
      },
      {
        #name    = "eth1"
        address      = "192.168.11.21"
        network_name = "ceph-lab"
      }
    ]
    2 = [
      {
        #name    = "eth0"
        address      = "192.168.10.22"
        gateway      = "192.168.10.1"
        dns          = ["8.8.8.8"]
        network_name = "net-lab"
      },
      {
        #name    = "eth1"
        address      = "192.168.11.22"
        network_name = "ceph-lab"
      }
    ]
  }
  local_admin        = "rocky"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfl2UgdFY/qCAu3mGV/3l1FsaUSgdLB+G7010I2hwSJuAa/9FkdtM0DCqNQWKN5HSSUDGgLXV2+2fyStWrIUmig6Jq/lybxOAfg9m8KpFO81S0qJoan/xhmIqMh/mg0pLoTkdzrMmNSehDsxfsxKQZyS1Sy16gfzMOLy/ubcFiAf1Ql2FB/QuPWDnKtYkHC7CpUWU/0YJU7A9NzZzw3cRFlKpPCTfog7Qm/lYT8tC+FnN09QkIlyQxQfsvZ57W7BRRi4QnW4RSc3H2m53nmBapT6ftsgm1Eo4bX6stMIXLn/XShtPkzr6EDTTtAp9DnNOvu4BtNBEDGVKKJHSmUbjj"
  ]
}
