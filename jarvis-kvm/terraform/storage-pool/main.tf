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

resource "libvirt_volume" "rocky9" {
  name   = "rocky9"
  pool   = libvirt_pool.default.name
  source = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  
}