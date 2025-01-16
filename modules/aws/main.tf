provider "aws" {
  region = var.default_region
}

# IAM Roles and Policies
resource "aws_iam_role" "vm_role" {
  name = "vm-mercurylayer-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "secret_manager_policy" {
  name        = "SecretManagerPolicy"
  description = "Allows read access to AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secret_manager_policy" {
  role       = aws_iam_role.vm_role.name
  policy_arn = aws_iam_policy.secret_manager_policy.arn
}

# Secrets Manager
resource "aws_secretsmanager_secret" "postgres_password" {
  name        = "postgres_db_mercurylayer_user_password"
  description = "Password for the PostgreSQL database user"
}

resource "aws_secretsmanager_secret_version" "postgres_password_version" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = random_password.postgres_password.result
}

resource "random_password" "postgres_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# VPC
resource "aws_vpc" "private_network" {
  cidr_block           = var.vpc_subnet_private_ip_reservation
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ml-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.private_network.id
  cidr_block              = var.vpc_subnet_private_ip_reservation
  availability_zone       = var.default_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "ml-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.private_network.id
  tags = {
    Name = "ml-internet-gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.private_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "ml-route-table"
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# Security Groups
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.private_network.id
  name   = "allow-http"

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
    Name = "allow-http"
  }
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.private_network.id
  name   = "allow-ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.firewall_ssh_source_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
  }
}

# RDS (PostgreSQL)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "ml-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Name = "ml-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres_instance" {
  identifier              = "ml-postgres-instance"
  engine                  = "postgres"
  engine_version          = var.postgres_db_engine
  instance_class          = var.postgres_db_instance_type
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = var.postgres_db_mercurylayer_user
  password                = random_password.postgres_password.result
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.allow_ssh.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  deletion_protection     = var.postgres_db_deletion_protection
  multi_az                = true
  backup_retention_period = 7
  backup_window           = "05:00-06:00"
}

# EC2 Instance
resource "aws_instance" "mercurylayer" {
  ami                         = var.vm_os_version
  instance_type               = var.vm_instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = data.template_file.startup_script_mercurylayer.rendered

  tags = {
    Name = "mercurylayer"
  }

  iam_instance_profile = aws_iam_instance_profile.vm_instance_profile.name
}

resource "aws_iam_instance_profile" "vm_instance_profile" {
  name = "vm-instance-profile"
  role = aws_iam_role.vm_role.name
}

# Startup Script
data "template_file" "startup_script_mercurylayer" {
  template = file("${path.module}/${var.vm_mercurylayer_startup_script}")
  vars = {
    project_id   = var.project_id
    default_zone = var.default_zone
  }
}
