terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  default     = ""
  description = "AWS CLI profile (optional)"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment label for tagging"
}

variable "create_bucket" {
  type        = bool
  default     = true
  description = "Create the S3 bucket if it does not exist"
}

data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket" "tf_state" {
  count         = var.create_bucket ? 1 : 0
  bucket        = local.state_bucket_name
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = local.state_bucket_name
    Purpose     = "terraform-backend"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = var.create_bucket ? aws_s3_bucket.tf_state[0].id : local.state_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = var.create_bucket ? aws_s3_bucket.tf_state[0].id : local.state_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = var.create_bucket ? aws_s3_bucket.tf_state[0].id : local.state_bucket_name
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value       = local.state_bucket_name
  description = "S3 bucket name used for Terraform backend state"
}