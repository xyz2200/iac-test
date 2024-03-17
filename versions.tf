terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.41"
    }
    local = {
        source = "hashicorp/local",
        version =  ">=2.1.0"
    }
  }
}