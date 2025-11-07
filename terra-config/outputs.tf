output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.main.arn
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  value = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  value = aws_launch_template.main.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2.id
}

output "application_url" {
  value = "http://${aws_lb.main.dns_name}"
}

output "app_port" {
  value = var.app_port
}

output "iam_role_name" {
  value = aws_iam_role.ec2_ssm_role.name
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "ssm_endpoint_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "docker_image" {
  value       = local.docker_image
  description = "Docker image being deployed"
}
