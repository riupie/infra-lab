terraform {
  backend "local" {
    path = "./../tf-state/vm/terraform.tfstate"
  }

  encryption {
    method "aes_gcm" "passphrase" {
      keys = key_provider.pbkdf2.key
    }

    state {
      method = method.aes_gcm.passphrase
      enforced = true
    }

    remote_state_data_sources {
      default {
        method = method.aes_gcm.passphrase
      }
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
  uri = "qemu+ssh://root@jarvis.riupie.com:3110/system?keyfile=~/.ssh/id_rsa&no_verify=1"
}