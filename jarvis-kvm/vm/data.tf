data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "./../tf-state/network/terraform.tfstate"
  }
}
