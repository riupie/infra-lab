resource "libvirt_network" "net_lab" {
  name = "net-lab"
  addresses = ["192.168.10.0/24"]
}

resource "libvirt_network" "net_ceph" {
  name = "ceph-lab"
  addresses = ["192.168.11.0/24"]
}
