module "bastion" {
  source  = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "bastion"
  vm_count    = 1
  base_pool_name = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name = data.terraform_remote_state.pool.outputs.image_debian12
  memory      = "2048"
  vcpu        = 1
  pool        = "default"
  system_volume = 20
  dhcp        = false
  ip_address  = [
                  "192.168.10.9"
                ]
  network_name = data.terraform_remote_state.network.outputs.network_name
  ip_gateway  = "192.168.10.1"
  ip_nameserver = "8.8.8.8"

  local_admin = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin   = "cloud"
  ssh_keys    = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
    ]
  #os_img_url  = "file:///var/lib/libvirt/images/debian-12.img"
}

module "kube_master" {
  source  = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "master"
  vm_count    = 1
  base_pool_name = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name = data.terraform_remote_state.pool.outputs.image_debian12
  memory      = "4096"
  vcpu        = 2
  pool        = "default"
  system_volume = 50
  dhcp        = false
  ip_address  = [
                  "192.168.10.10"
                ]
  network_name = data.terraform_remote_state.network.outputs.network_name
  ip_gateway  = "192.168.10.1"
  ip_nameserver = "8.8.8.8"
  local_admin = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin   = "cloud"
  ssh_keys    = [
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
    ]
  #os_img_url  = "file:///var/lib/libvirt/images/debian-12.img"
}

module "kube_worker" {
  source  = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "worker"
  vm_count    = 3
  base_pool_name = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name = data.terraform_remote_state.pool.outputs.image_debian12
  memory      = "8196"
  vcpu        = 4
  pool        = "default"
  system_volume = 100
  dhcp        = false
  network_name = data.terraform_remote_state.network.outputs.network_name
  ip_address  = [
    "192.168.10.11",
    "192.168.10.12",
    "192.168.10.13"
  ]
  ip_gateway  = "192.168.10.1"
  ip_nameserver = "8.8.8.8"
  local_admin = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin   = "cloud"
  ssh_keys    = [
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx3+15+21wQA2BkX4kKwOPNCWnfanm53niPynjs83RtFL//Jv9Mytln5mF2bkR4Mkh20yNS3uX1tSWJ0hEASlRUyjLcbicPgPBAbkMvmzab800ZYeFtCpP+wq9hji5CEyUPHwvlxxJe6L8uT2grSD2/3whcCsZY3TVL7vqGpX1TWR77zjrVDT+xhNYvkQFR/sycHaziR/iiaDFShN0G0cfR6/flZCk5SVafkbwsdkF6FWQIv3J2XEx/ddfogiWIR2PGYvdLio8a0nkutO4YfIshKlZR36jmpioFzRI4U4vT1c/cTODd+/Rx+1/AFu9PAlEV/E6DL8VGyVWBFZZ/k2XjLBqB21Q8cMD67Yskl7h/R26KFzIbe2Sef3O08qhlA5Xdyag3mzD+mulkOeyiwYAfQhfURskjnnyumDZL3sa9cEfFJ+x6P3KWbgrcp3NsPBJIM8YEhfIHWWIkt8kBqwivbMtm6EjFBSTpZkNGP6LrPBoLYjA6m47k5juAsL0P/s= root@jarvis"
    ]
  #os_img_url  = "file:///var/lib/libvirt/images/debian-12.img"
}