terraform {
  backend "local" {
    path = "./../tf-state/vm/terraform.tfstate"
  }
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
     version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}