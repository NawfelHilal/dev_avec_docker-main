terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "eu-west-3" # Paris
}

# 1. AMI Ubuntu 24.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 2. Suffixe unique pour éviter les conflits (tfstate éphémère)
resource "random_id" "suffix" {
  byte_length = 4
}

# 3. Clé SSH
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "dashboard-key-${random_id.suffix.hex}"
  public_key = tls_private_key.pk.public_key_openssh
}


resource "local_file" "ssh_key" {
  filename        = "${path.module}/registry-key-simple.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# 4. Security Group (lookup existing or create if not exists)
# On cherche d'abord si le SG existe déjà
data "aws_security_groups" "existing" {
  filter {
    name   = "group-name"
    values = ["dashboard-sg"]
  }
}

# Création du SG seulement s'il n'existe pas
resource "aws_security_group" "registry_sg" {
  count       = length(data.aws_security_groups.existing.ids) == 0 ? 1 : 0
  name        = "dashboard-sg"
  description = "Allow SSH, Frontend, API, Adminer"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Frontend Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "API Backend"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Adminer UI"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Registry Docker API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ID du Security Group (existant ou nouvellement créé)
locals {
  sg_id = length(data.aws_security_groups.existing.ids) > 0 ? data.aws_security_groups.existing.ids[0] : aws_security_group.registry_sg[0].id
}

# 5. Instance EC2
resource "aws_instance" "registry_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [local.sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Terraform-Registry-Simple"
  }
}

output "instance_ip" {
  value = aws_instance.registry_server.public_ip
}

output "ssh_private_key" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}
