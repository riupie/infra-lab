terraform {
  backend "local" {
    path = "./../tf-state/network/terraform.tfstate"
  }

  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
