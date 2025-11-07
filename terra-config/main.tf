data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket" "tf_state" {
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
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project_name}-nat-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}



resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % local.nat_gateway_count].id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_nat_gateway.main]
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "vpc_endpoints" {
  name   = "${var.project_name}-vpc-endpoints-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-vpc-endpoints-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ssm-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ssmmessages-endpoint"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ec2messages-endpoint"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2" {
  name   = "${var.project_name}-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-ssm-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ssm_parameter_access" {
  name = "${var.project_name}-ssm-parameter-access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = {
    Name        = "${var.project_name}-ec2-profile"
    Environment = var.environment
  }
}

locals {
  env_norm          = lower(var.environment)
  is_prod           = contains(["prod", "production", "master"], local.env_norm)
  image_tag         = local.is_prod ? "latest" : "dev-latest"
  docker_image      = "${var.docker_repository}:${local.image_tag}"
  node_env          = local.is_prod ? "production" : "development"
  nat_gateway_count = local.is_prod ? length(var.availability_zones) : 1
  use_docker_auth   = var.dockerhub_username != "" && var.dockerhub_token != ""
}

resource "aws_ssm_parameter" "dockerhub_username" {
  count       = local.use_docker_auth ? 1 : 0
  name        = "/${var.project_name}/dockerhub/username"
  description = "DockerHub username for pulling private images"
  type        = "String"
  value       = var.dockerhub_username
  overwrite   = true

  tags = {
    Name        = "${var.project_name}-dockerhub-username"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "dockerhub_token" {
  count       = local.use_docker_auth ? 1 : 0
  name        = "/${var.project_name}/dockerhub/token"
  description = "DockerHub access token for pulling private images"
  type        = "SecureString"
  value       = var.dockerhub_token
  overwrite   = true
  tags = {
    Name        = "${var.project_name}-dockerhub-token"
    Environment = var.environment
  }
}

resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  key_name = var.key_pair_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        set -uxo pipefail
        exec > >(tee -a /var/log/user-data.log) 2>&1

        echo "=== User data script started at $(date) ==="

        # Wait for network connectivity
        echo "Waiting for internet connectivity..."
        for i in {1..30}; do
          if ping -c 1 8.8.8.8 &>/dev/null; then
            echo "Internet connectivity established"
            break
          fi
          echo "Attempt $i: No internet connectivity, waiting..."
          sleep 10
        done

        # Retry apt-get update with exponential backoff
        echo "Updating package lists..."
        for i in {1..5}; do
          if apt-get update -y; then
            echo "apt-get update successful"
            break
          fi
          echo "apt-get update failed (attempt $i), retrying in $((i * 10)) seconds..."
          sleep $((i * 10))
        done

        # Install Docker and AWS CLI
        echo "Installing Docker and AWS CLI..."
        for i in {1..3}; do
          if apt-get install -y docker.io awscli; then
            echo "Installation successful"
            break
          fi
          echo "Installation failed (attempt $i), retrying..."
          sleep 10
        done

        systemctl enable docker
        systemctl start docker

        usermod -aG docker ubuntu || true
        usermod -aG docker ssm-user || true

        # Ensure SSM agent is running (for Snap version)
        snap start amazon-ssm-agent || true
        systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
        systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

        # Wait for Docker to be ready
        echo "Waiting for Docker to be ready..."
        until docker info >/dev/null 2>&1; do 
          echo "Docker not ready, waiting..."
          sleep 2
        done
        echo "Docker is ready"

        # Login to DockerHub if credentials are available
        if [ "${local.use_docker_auth}" = "true" ]; then
          echo "Retrieving Docker credentials from Parameter Store..."
          DOCKER_USER=$(aws ssm get-parameter --name "/${var.project_name}/dockerhub/username" --region ${var.aws_region} --query 'Parameter.Value' --output text 2>/dev/null || echo "")
          DOCKER_TOKEN=$(aws ssm get-parameter --name "/${var.project_name}/dockerhub/token" --region ${var.aws_region} --with-decryption --query 'Parameter.Value' --output text 2>/dev/null || echo "")
          
          if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_TOKEN" ]; then
            echo "Logging into DockerHub..."
            echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
            if [ $? -eq 0 ]; then
              echo "DockerHub login successful"
            else
              echo "DockerHub login failed"
            fi
          else
            echo "Docker credentials not found in Parameter Store"
          fi
        else
          echo "Skipping DockerHub login (using public repository)"
        fi

        # Pull and run application
        echo "Pulling Docker image: ${local.docker_image}"
        docker pull "${local.docker_image}"
        
        echo "Starting application container..."
        docker rm -f "goldenowl-app" 2>/dev/null || true
        docker run -d \
          --name "goldenowl-app" \
          --restart always \
          -e NODE_ENV="${local.node_env}" \
          -p ${var.app_port}:${var.app_port} \
          "${local.docker_image}"

        echo "=== User data completed successfully at $(date) ==="
      EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-instance"
      Environment = var.environment
      DockerImage = local.docker_image
      NodeEnv     = local.node_env
    }
  }

  tags = {
    Name        = "${var.project_name}-lt"
    Environment = var.environment
    DockerImage = local.docker_image
    NodeEnv     = local.node_env
  }
}

resource "aws_autoscaling_group" "main" {
  name                      = "${var.project_name}-asg-${aws_launch_template.main.latest_version}"
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  target_group_arns         = [aws_lb_target_group.main.arn]
  vpc_zone_identifier       = aws_subnet.private[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "DockerImage"
    value               = local.docker_image
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_nat_gateway.main,
    aws_route_table.private,
    aws_route_table_association.private
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
