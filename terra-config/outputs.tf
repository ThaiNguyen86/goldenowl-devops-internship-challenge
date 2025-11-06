output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "alb_security_group_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "Security Group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "app_port" {
  description = "Application port exposed on instances"
  value       = var.app_port
}

output "app_fqdn" {
  description = "Application FQDN (Cloudflare if configured, else ALB DNS)"
  value       = var.domain_name != "" ? (var.dns_record_name == "@" || var.dns_record_name == "" ? var.domain_name : "${var.dns_record_name}.${var.domain_name}") : aws_lb.main.dns_name
}

output "application_url_https" {
  description = "HTTPS URL to access the application"
  value       = var.enable_https && var.domain_name != "" ? "https://${local.fqdn}" : "http://${aws_lb.main.dns_name}"
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate (if created)"
  value       = try(aws_acm_certificate.alb[0].arn, null)
}

output "acm_validation_records" {
  description = "ACM DNS validation records to create manually in your DNS provider"
  value       = try([for dvo in aws_acm_certificate.alb[0].domain_validation_options : {
    name  = dvo.resource_record_name,
    type  = dvo.resource_record_type,
    value = dvo.resource_record_value
  }], [])
}

