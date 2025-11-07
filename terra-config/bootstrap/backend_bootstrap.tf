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
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile (optional)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment label for tagging"
  type        = string
  default     = "dev"
}

variable "create_bucket" {
  description = "Create the S3 bucket if it does not exist"
  type        = bool
  default     = true
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
  bucket = local.state_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = var.create_bucket ? [aws_s3_bucket.tf_state] : []
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = local.state_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = var.create_bucket ? [aws_s3_bucket.tf_state] : []
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = local.state_bucket_name
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
  depends_on              = var.create_bucket ? [aws_s3_bucket.tf_state] : []
}

output "state_bucket_name" {
  value       = local.state_bucket_name
  description = "S3 bucket name used for Terraform backend state"
}