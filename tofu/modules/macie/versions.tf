terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
