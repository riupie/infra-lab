module "general" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.2"

  vm_hostname_prefix = "general"
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
  ip_nameserver = "192.168.10.1"

  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfl2UgdFY/qCAu3mGV/3l1FsaUSgdLB+G7010I2hwSJuAa/9FkdtM0DCqNQWKN5HSSUDGgLXV2+2fyStWrIUmig6Jq/lybxOAfg9m8KpFO81S0qJoan/xhmIqMh/mg0pLoTkdzrMmNSehDsxfsxKQZyS1Sy16gfzMOLy/ubcFiAf1Ql2FB/QuPWDnKtYkHC7CpUWU/0YJU7A9NzZzw3cRFlKpPCTfog7Qm/lYT8tC+FnN09QkIlyQxQfsvZ57W7BRRi4QnW4RSc3H2m53nmBapT6ftsgm1Eo4bX6stMIXLn/XShtPkzr6EDTTtAp9DnNOvu4BtNBEDGVKKJHSmUbjj"
  ]
}

module "kube_master" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.2"

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
  ip_nameserver      = "192.168.10.1"
  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfl2UgdFY/qCAu3mGV/3l1FsaUSgdLB+G7010I2hwSJuAa/9FkdtM0DCqNQWKN5HSSUDGgLXV2+2fyStWrIUmig6Jq/lybxOAfg9m8KpFO81S0qJoan/xhmIqMh/mg0pLoTkdzrMmNSehDsxfsxKQZyS1Sy16gfzMOLy/ubcFiAf1Ql2FB/QuPWDnKtYkHC7CpUWU/0YJU7A9NzZzw3cRFlKpPCTfog7Qm/lYT8tC+FnN09QkIlyQxQfsvZ57W7BRRi4QnW4RSc3H2m53nmBapT6ftsgm1Eo4bX6stMIXLn/XShtPkzr6EDTTtAp9DnNOvu4BtNBEDGVKKJHSmUbjj"
  ]
}

module "kube_worker" {
  source = "git::https://github.com/riupie/terraform-libvirt-vm.git?ref=v1.0.2"

  vm_hostname_prefix = "worker"
  vm_count           = 1
  base_pool_name     = data.terraform_remote_state.pool.outputs.pool_default
  base_volume_name   = data.terraform_remote_state.pool.outputs.image_debian12
  memory             = "8196"
  vcpu               = 2
  pool               = "default"
  system_volume      = 50
  dhcp               = false
  network_name       = data.terraform_remote_state.network.outputs.network_name
  ip_address = [
    "192.168.10.11"
  ]
  ip_gateway         = "192.168.10.1"
  ip_nameserver      = "192.168.10.1"
  local_admin        = "debian"
  local_admin_passwd = var.admin_password
  ssh_admin          = "cloud"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfl2UgdFY/qCAu3mGV/3l1FsaUSgdLB+G7010I2hwSJuAa/9FkdtM0DCqNQWKN5HSSUDGgLXV2+2fyStWrIUmig6Jq/lybxOAfg9m8KpFO81S0qJoan/xhmIqMh/mg0pLoTkdzrMmNSehDsxfsxKQZyS1Sy16gfzMOLy/ubcFiAf1Ql2FB/QuPWDnKtYkHC7CpUWU/0YJU7A9NzZzw3cRFlKpPCTfog7Qm/lYT8tC+FnN09QkIlyQxQfsvZ57W7BRRi4QnW4RSc3H2m53nmBapT6ftsgm1Eo4bX6stMIXLn/XShtPkzr6EDTTtAp9DnNOvu4BtNBEDGVKKJHSmUbjj"
  ]
}