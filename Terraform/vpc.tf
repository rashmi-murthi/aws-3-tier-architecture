
# fetch the available AZs dynamically
data "aws_availability_zones" "available" {}

# VPC Resource 
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = { 
    Name = "${var.project_name}-vpc"
  }
}
# Public Subnets (2)
resource "aws_subnet" "public"{
    count                     = length(var.public_subnets)
    vpc_id                    = aws_vpc.main.id
    cidr_block                = var.public_subnets[count.index]
    map_public_ip_on_launch   = true
    availability_zone         = data.aws_availability_zones.available.names[count.index]
    tags = { Name = "${var.project_name}-public-${count.index + 1}"}
}
resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-private-${count.index + 1}"}
  }
  # internet gateway
  resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = { Name = "${var.project_name}-igw"}
  }
  # Public Route Table
  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = { Name = "${var.project_name}-public-rt" }  
  }
  # Public Route to igw 
  resource "aws_route" "public_internet_access" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  # Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
# Private Route Table (No Internet Gateway - for now)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-private-rt" }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
# Security Group for ALB - Allow inbound HTTP 80 from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# Security Group for EC2 web servers - Allow HTTP from ALB SG and SSH from allowed CIDR
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow HTTP from ALB and SSH from allowed CIDR"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}

# Security Group for RDS - Allow MySQL 3306 from EC2 SG only
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# Security Group for EFS - Allow NFS 2049 from EC2 SG only
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-efs-sg"}
}
