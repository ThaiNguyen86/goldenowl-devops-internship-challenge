variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "goldenowl"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "SSH key pair name"
  type        = string
  default     = "lab01"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "docker_repository" {
  description = "Docker image repository (without tag)"
  type        = string
  default     = "ngtthai/goldenowl-app"
}

variable "enable_https" {
  description = "Enable HTTPS on ALB with ACM certificate and redirect HTTP->HTTPS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Root domain managed in Cloudflare (e.g., example.com). Leave empty to skip cert/DNS."
  type        = string
  default     = "project3cloudinus.click"
}

variable "dns_record_name" {
  description = "DNS record name to create in Cloudflare (e.g., 'app' for app.example.com, or '@' for root)"
  type        = string
  default     = "goldenowl-dev"
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH into EC2 instances (use your IPs; empty list to disable SSH)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

