module "kube_master" {
  source  = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "master"
  vm_count    = 1
  memory      = "4096"
  vcpu        = 1
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
  local_admin_passwd = "mysecuresecret"
  ssh_admin   = "cloud"
  ssh_keys    = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu9cByz/mucN/LP+DTMhkNag7FK2VvkqrkCme04Rw26eB0+7e/LsWuEgUX1HGd3h3xXyw9WD8wP+Jd6O59AV1PUkEaKRiBrHD0ibPQN4mEUYL86uQ5EE4v5oa5duHDRUakW2P9npmqy5LuxZZTjDaigKiK2ioyPvxzPUWhrfD7Kjfy3jgVTwcaWFuZ5qL+VUOYH30bZpuZ94cxCEvlwzZGLTtUUGQPAAdBgU8y/GqJBnmRF4UmuWqIP7qzUZqu9kKa9uB6IY9El4Z+is6XaIqX3TjBM9gUVpNy40Tm3FxBM5LWJ1HwB5lxWX0Zt3X2adxjebpzOs1c98XhhXGZ88+ASjUX6riaQUXN6pXPErA+iH1BZepR3ZVjfALr511x579/xM33KW04EAM/jSDJ+eZOAad7Df1QHi2dI3IqVPKhfvG2jxL4Y06xGGIt/lQWB0F3SYAvAWI10RlY5HEXRu7IiRsCAM/NFjx7uLw29hdFGlR6iaJtHvd7VWi3VgxrCSU= mimin@pikachu",
    ]
  os_img_url  = "file:///var/lib/libvirt/images/debian-12.img"
}

module "kube_worker" {
  source  = "git::https://github.com/riupie/terraform-libvirt-vm.git"

  vm_hostname_prefix = "worker"
  vm_count    = 2
  memory      = "8196"
  vcpu        = 1
  pool        = "default"
  system_volume = 50
  dhcp        = false
  network_name = data.terraform_remote_state.network.outputs.network_name
  ip_address  = [
                  "192.168.10.11",
                  "192.168.10.12"
                ]
  ip_gateway  = "192.168.10.1"
  ip_nameserver = "8.8.8.8"

  local_admin = "debian"
  local_admin_passwd = "mysecuresecret"
  ssh_admin   = "cloud"
  ssh_keys    = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu9cByz/mucN/LP+DTMhkNag7FK2VvkqrkCme04Rw26eB0+7e/LsWuEgUX1HGd3h3xXyw9WD8wP+Jd6O59AV1PUkEaKRiBrHD0ibPQN4mEUYL86uQ5EE4v5oa5duHDRUakW2P9npmqy5LuxZZTjDaigKiK2ioyPvxzPUWhrfD7Kjfy3jgVTwcaWFuZ5qL+VUOYH30bZpuZ94cxCEvlwzZGLTtUUGQPAAdBgU8y/GqJBnmRF4UmuWqIP7qzUZqu9kKa9uB6IY9El4Z+is6XaIqX3TjBM9gUVpNy40Tm3FxBM5LWJ1HwB5lxWX0Zt3X2adxjebpzOs1c98XhhXGZ88+ASjUX6riaQUXN6pXPErA+iH1BZepR3ZVjfALr511x579/xM33KW04EAM/jSDJ+eZOAad7Df1QHi2dI3IqVPKhfvG2jxL4Y06xGGIt/lQWB0F3SYAvAWI10RlY5HEXRu7IiRsCAM/NFjx7uLw29hdFGlR6iaJtHvd7VWi3VgxrCSU= mimin@pikachu",
    ]
  os_img_url  = "file:///var/lib/libvirt/images/debian-12.img"
}
