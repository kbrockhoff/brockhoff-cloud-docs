# Basic AWS Compute Example
# This example demonstrates a simple EC2 instance deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.5"
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

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/context/external"

  name        = var.name
  environment = var.environment
}

# Map instance types to actual AWS instance types
locals {
  instance_type_map = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }

  actual_instance_type = local.instance_type_map[var.instance_type]
}

# Security Group
resource "aws_security_group" "main" {
  name_prefix = "${module.context.name_prefix}-"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  # SSH access
  dynamic "ingress" {
    for_each = var.ssh_key_name != "" ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.context.tags
}

# KMS Key for encryption (if enabled)
resource "aws_kms_key" "main" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for ${module.context.name_prefix}"
  deletion_window_in_days = var.environment_type == "Development" ? 7 : 30

  tags = module.context.tags
}

resource "aws_kms_alias" "main" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${module.context.name_prefix}"
  target_key_id = aws_kms_key.main[0].key_id
}

# EC2 Instance
resource "aws_instance" "main" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = local.actual_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.default.ids[0]

  # Enable detailed monitoring if requested
  monitoring = var.monitoring_enabled

  # Encrypt EBS volumes if KMS key is created
  dynamic "root_block_device" {
    for_each = var.create_kms_key ? [1] : []
    content {
      encrypted   = true
      kms_key_id  = aws_kms_key.main[0].arn
      volume_type = "gp3"
      volume_size = 20
    }
  }

  # User data for basic setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    name_prefix = module.context.name_prefix
  }))

  tags = merge(module.context.tags, {
    Name = "${module.context.name_prefix}-instance"
  })
}

# SNS Topic for alarms (if enabled)
resource "aws_sns_topic" "alarms" {
  count = var.alarms_enabled ? 1 : 0

  name = "${module.context.name_prefix}-alarms"

  tags = module.context.tags
}

# CloudWatch Alarms (if enabled)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.alarms_enabled ? 1 : 0

  alarm_name          = "${module.context.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = module.context.tags
}

# Data sources for defaults
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
