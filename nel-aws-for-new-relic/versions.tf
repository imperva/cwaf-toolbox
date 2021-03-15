terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    incapsula = {
      source = "imperva/incapsula"
    }
  }
  required_version = ">= 0.13"
}
