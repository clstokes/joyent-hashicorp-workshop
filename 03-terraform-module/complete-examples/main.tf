terraform {
  backend "manta" {
    path       = "terraform-state/hashicorp-workshop"
    objectName = "terraform.tfstate"
  }
}

module "nginx" {
  source = "./nginx-module"

  nginx_package = "g4-general-8G"
}
