terraform {
  backend "local" {
    path = "./../tf-state/network/terraform.tfstate"
  }

  encryption {
    method "aes_gcm" "passphrase" {
      keys = key_provider.pbkdf2.key
    }

    state {
      method = method.aes_gcm.passphrase
      enforced = true
    }
  }

  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://root@jarvis.riupie.com/system?keyfile=~/.ssh/id_rsa&no_verify=1"
}
