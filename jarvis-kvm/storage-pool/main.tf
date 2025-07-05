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

resource "libvirt_volume" "fedora42" {
  name   = "fedora42"
  pool   = libvirt_pool.default.name
  source = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
}