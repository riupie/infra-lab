resource "libvirt_network" "net_lab" {
  name = "net-lab"
  addresses = ["192.168.10.0/24"]
}
