output "pool_default" {
value = libvirt_pool.default.name
}

output "image_debian12" {
value = libvirt_volume.debian12.name 
}

output "image_fedora42" {
value = libvirt_volume.fedora42.name 
}
output "image_centos9" {
value = libvirt_volume.centos9.name
}
output "image_rocky9" {
value = libvirt_volume.rocky9.name
}