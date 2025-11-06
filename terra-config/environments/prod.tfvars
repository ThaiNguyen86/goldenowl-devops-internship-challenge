environment        = "prod"
ec2_instance_type  = "t2.micro"
asg_min_size       = 1
asg_desired_capacity = 2
asg_max_size       = 2

ssh_allowed_cidrs = []

domain_name       = "project3cloudinus.click"
dns_record_name   = "goldenowl-app"
# enable_cloudflare = true
# cloudflare_zone_id = ""
# cloudflare_proxied = true
