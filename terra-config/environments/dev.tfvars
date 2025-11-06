environment        = "dev"
ec2_instance_type  = "t2.micro"
asg_min_size       = 1
asg_desired_capacity = 1
asg_max_size       = 2

ssh_allowed_cidrs = ["0.0.0.0/0"]

domain_name       = "project3cloudinus.click"
dns_record_name   = "goldenowl-dev"

