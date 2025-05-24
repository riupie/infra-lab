output "pool_default" {
value = libvirt_pool.default.name
}

output "image_debian12" {
value = libvirt_volume.debian12.name 
}

