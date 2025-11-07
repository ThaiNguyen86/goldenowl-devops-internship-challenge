terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {}
    bucket = "tfstate-584968901462-ap-southeast-1"
    key    = "prod/terraform.tfstate"
    region = "ap-southeast-1"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}
