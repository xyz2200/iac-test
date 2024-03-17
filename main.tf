provider "aws" {
  region = "us-east-1"
}

locals {
  region = var.region

  tags = {
    project     = "totem"
    source      = "terraform"
    evnv        = "prod"
  }
}


module "vpc" {
  source    = "./modules/vpc"
  tags      = local.tags
  region    = local.region
}

module "ecr" {
  source    = "./modules/ecr"
  tags      = local.tags
  region    = local.region
}