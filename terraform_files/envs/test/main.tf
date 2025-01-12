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

module "ecs" {
  source = "../../modules/ecs"

  cluster_name       = "test-cluster"
  family             = "test-family"
  container_definitions = <<DEFINITION
[
  {
    "name": "test-app",
    "image": "nginx",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
  memory             = "512"
  cpu                = "256"
  execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
  desired_count      = 2
  subnets            = module.network.public_subnets
  security_groups    = [aws_security_group.ecs_sg.id]
}
