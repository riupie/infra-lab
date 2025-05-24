resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  target {
    path = "/var/lib/libvirt/images"
  }
}

resource "libvirt_volume" "debian12" {
  name   = "debian12"
  pool   = libvirt_pool.default.name
  source = "https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}
