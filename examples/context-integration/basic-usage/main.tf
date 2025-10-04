# Basic Context Integration Example
# This example demonstrates the simplest way to integrate terraform-external-context
# into a Brockhoff Cloud module for consistent naming and tagging.

terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Example   = "BasicContextIntegration"
    }
  }
}

# Data source for cloud provider detection
data "aws_caller_identity" "current" {}

# Context module - provides consistent naming and tagging
module "context" {
  source = "kbrockhoff/context/external"

  # Basic context configuration
  name        = var.name
  environment = var.environment
}

# Example EC2 instance using context naming and tagging
resource "aws_instance" "web_server" {
  count = var.create_ec2_instance ? 1 : 0

  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type_map[var.instance_type]

  # Use context-generated name
  tags = merge(local.tags, {
    Name         = "${local.name_prefix}-web-server"
    ResourceType = "EC2Instance"
    Purpose      = "WebServer"
    Tier         = "Application"
  })

  # Enable detailed monitoring if requested
  monitoring = var.enable_monitoring

  # Use KMS key for EBS encryption if created
  root_block_device {
    encrypted   = var.create_kms_key
    kms_key_id  = var.create_kms_key ? aws_kms_key.example[0].arn : null
    volume_type = "gp3"
    volume_size = 20
  }
}

# Data source for latest Amazon Linux AMI
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

# SNS topic for alarms (if enabled)
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0

  name = "${local.name_prefix}-alarms"

  tags = merge(local.tags, {
    ResourceType = "SNSTopic"
    Purpose      = "Alarms"
  })
}

# Example of direct context usage (without child module)
locals {
  # Use context-generated values directly
  name_prefix = module.context.name_prefix
  tags        = module.context.tags

  # Instance type mapping
  instance_type_map = {
    small  = "t3.micro"
    medium = "t3.small"
    large  = "t3.medium"
  }

  # Cloud provider detection
  cloud_provider = "aws" # Detected from provider

  # Environment-specific configuration
  environment_config = {
    Development = {
      instance_size    = "small"
      backup_enabled   = false
      monitoring_level = "basic"
    }
    Production = {
      instance_size    = "medium"
      backup_enabled   = true
      monitoring_level = "detailed"
    }
  }

  effective_config = local.environment_config[var.environment_type]
}

# Example S3 bucket using context naming and tagging
resource "aws_s3_bucket" "example" {
  count = var.create_s3_bucket ? 1 : 0

  # Use context-generated name
  bucket = "${local.name_prefix}-bucket-${random_id.bucket_suffix[0].hex}"

  tags = merge(local.tags, {
    ResourceType = "S3Bucket"
    Purpose      = "ExampleStorage"
  })
}

resource "random_id" "bucket_suffix" {
  count       = var.create_s3_bucket ? 1 : 0
  byte_length = 4

  keepers = {
    name_prefix = local.name_prefix
  }
}

# Example IAM role using context naming and tagging
resource "aws_iam_role" "example" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    ResourceType = "IAMRole"
    Purpose      = "ExampleRole"
  })
}

# Example KMS key using context naming and tagging
resource "aws_kms_key" "example" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for ${local.name_prefix}"
  deletion_window_in_days = var.kms_key_deletion_window_days

  tags = merge(local.tags, {
    ResourceType = "KMSKey"
    Purpose      = "ExampleEncryption"
  })
}

resource "aws_kms_alias" "example" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.name_prefix}-key"
  target_key_id = aws_kms_key.example[0].key_id
}