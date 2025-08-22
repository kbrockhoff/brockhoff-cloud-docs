# Basic Context Integration Example
# This example demonstrates the simplest way to integrate terraform-external-context
# into a Brockhoff Cloud module for consistent naming and tagging.

terraform {
  required_version = ">= 1.5.0"
  
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
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  # Basic context configuration
  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  
  # Standard tags
  tags = var.tags
  
  # Additional tag map for extra tags
  additional_tag_map = var.additional_tags
}

# Example compute module using context
module "web_server" {
  source = "../../modules/compute-example"  # Local example module
  
  # Pass context to child module
  context = module.context.context
  
  # Module-specific configuration
  instance_type = var.instance_type
  environment_type = var.environment_type
  
  # Additional module-specific tags
  tags = {
    Purpose = "WebServer"
    Tier    = "Application"
  }
  
  # Encryption configuration
  encryption_config = {
    create_kms_key               = var.create_kms_key
    kms_key_deletion_window_days = var.kms_key_deletion_window_days
  }
  
  # Monitoring configuration
  monitoring_config = {
    enabled = var.enable_monitoring
  }
  
  # Alarms configuration
  alarms_config = {
    enabled          = var.enable_alarms
    create_sns_topic = var.create_sns_topic
  }
}

# Example of direct context usage (without child module)
locals {
  # Use context-generated values directly
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
  
  # Cloud provider detection
  cloud_provider = "aws"  # Detected from provider
  
  # Environment-specific configuration
  environment_config = {
    Development = {
      instance_size = "small"
      backup_enabled = false
      monitoring_level = "basic"
    }
    Production = {
      instance_size = "medium"
      backup_enabled = true
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