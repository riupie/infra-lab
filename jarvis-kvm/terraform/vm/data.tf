data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "./../tf-state/network/terraform.tfstate"
  }
}

data "terraform_remote_state" "pool" {
  backend = "local"
  config = {
    path = "./../tf-state/pool/terraform.tfstate"
  }

}
