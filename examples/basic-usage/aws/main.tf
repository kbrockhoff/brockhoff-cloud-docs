# Basic AWS Compute Example
# This example demonstrates a simple EC2 instance deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.0"
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
  source = "kbrockhoff/external-context/terraform"

  name           = var.name
  environment    = var.environment
  cloud_provider = "aws"

  # Override context if provided
  context = var.context
}

# Basic compute module following standardized interface
module "compute" {
  source = "../../../modules/services/compute/aws"

  # Standard variables from context
  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  data_tags        = module.context.data_tags
  environment_type = var.environment_type

  # Compute-specific configuration
  instance_type = var.instance_type
  ami_id        = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id

  # Standard configuration objects
  encryption_config = {
    create_kms_key               = var.create_kms_key
    kms_key_id                   = ""
    kms_key_deletion_window_days = var.environment_type == "Development" ? 7 : 30
  }

  monitoring_config = {
    enabled = var.monitoring_enabled
  }

  alarms_config = {
    enabled          = var.alarms_enabled
    create_sns_topic = true
    sns_topic_arn    = ""
  }

  # Network configuration
  vpc_id    = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id
  subnet_id = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.default.ids[0]

  # Security configuration
  allowed_cidr_blocks = var.allowed_cidr_blocks
  ssh_key_name        = var.ssh_key_name
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