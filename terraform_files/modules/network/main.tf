#############################################
# VPC
#############################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, { Name = "${var.name}-vpc" })
}

#############################################
# Public Resources
#############################################

# Create Public Subnets
resource "aws_subnet" "public" {
  count                 = length(var.availability_zones)
  vpc_id                = aws_vpc.main.id
  cidr_block            = var.public_subnet_cidrs[count.index]
  availability_zone     = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "${var.name}-public-subnet-${count.index + 1}" })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, { Name = "${var.name}-igw" })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, { Name = "${var.name}-public-rt", Type = "Public" })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#############################################
# Private Resources
#############################################

# Create Private Subnets
resource "aws_subnet" "private" {
  count                 = length(var.availability_zones)
  vpc_id                = aws_vpc.main.id
  cidr_block            = var.private_subnet_cidrs[count.index]
  availability_zone     = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, { Name = "${var.name}-private-subnet-${count.index + 1}" })
}

# NAT Gateway
resource "aws_eip" "nat" {
  tags = merge(var.common_tags, { Name = "${var.name}-eip-for-nat" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Attach NAT Gateway to the first public subnet

  tags = merge(var.common_tags, { Name = "${var.name}-nat-gateway" })
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.common_tags, { Name = "${var.name}-private-rt", Type = "Private" })
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#############################################
# Application Load Balancer (ALB)
#############################################

resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [var.alb_security_group]
  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.common_tags, { Name = "${var.name}-alb" })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, { Name = "${var.name}-tg" })
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
