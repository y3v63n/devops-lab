#!/usr/bin/env bash
# reset.sh — Exercise 0E-01: Reading Terraform Config Files
# Creates a sample AWS-style Terraform config for reading/analysis

WORK_DIR="/tmp/devops-lab/0E-01"

echo "Resetting exercise 0E-01..."

# Clean up previous work
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/sample-config"

# Create main.tf
cat > "$WORK_DIR/sample-config/main.tf" << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name        = "${var.project_name}-web"
    Environment = var.environment
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

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
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the web server"
}

output "security_group_id" {
  value = aws_security_group.web.id
}
EOF

# Create variables.tf
cat > "$WORK_DIR/sample-config/variables.tf" << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
EOF

# Remove any previous answer files
rm -f "$WORK_DIR/annotations.txt"
rm -f "$WORK_DIR/security-review.txt"

echo ""
echo "Done. Sample config written to: $WORK_DIR/sample-config/"
echo ""
echo "Files created:"
echo "  $WORK_DIR/sample-config/main.tf"
echo "  $WORK_DIR/sample-config/variables.tf"
echo ""
echo "Your task:"
echo "  Read those files, then create:"
echo "  $WORK_DIR/annotations.txt"
echo "  $WORK_DIR/security-review.txt"
