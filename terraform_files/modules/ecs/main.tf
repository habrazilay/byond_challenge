module "network" {
  source = "../../modules/network"

  name                 = "test-env"
  vpc_cidr_block       = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  alb_security_group   = aws_security_group.alb_sg.id
  enable_deletion_protection = false
  target_port          = 80
  health_check_path    = "/"
  common_tags = {
    Environment = "test"
    Owner       = "DevOps"
  }
}

output "alb_dns_name" {
  value = module.network.alb_dns_name
}
