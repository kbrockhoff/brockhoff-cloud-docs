# Multi-Cloud Context Integration Example
# This example demonstrates how to use terraform-external-context
# consistently across AWS, Azure, and GCP with provider-specific constraints

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Configure providers
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Example   = "MultiCloudContext"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Data sources for cloud provider detection
data "aws_caller_identity" "current" {}
data "azurerm_client_config" "current" {}
data "google_client_config" "current" {}

# Global context for consistent naming across all clouds
module "global_context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  
  tags = var.tags
  
  # Use shorter names for multi-cloud to avoid length limits
  id_length_limit = 50
  
  # Clean up characters that might not be valid across all clouds
  regex_replace_chars = "/[^a-zA-Z0-9-]/"
}

# AWS-specific context and resources
module "aws_context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  # Inherit from global context
  context = module.global_context.context
  
  # AWS-specific overrides
  environment = "${var.environment}-aws"
  
  # AWS allows mixed case in some resources
  label_value_case = "none"
  
  # AWS-specific tags
  additional_tag_map = {
    CloudProvider = "AWS"
    Region        = var.aws_region
  }
}

# Azure-specific context and resources
module "azure_context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  # Inherit from global context
  context = module.global_context.context
  
  # Azure-specific overrides
  environment = "${var.environment}-azure"
  
  # Azure allows underscores in some resources
  delimiter = "_"
  
  # Azure-specific tags
  additional_tag_map = {
    CloudProvider = "Azure"
    Region        = var.azure_region
  }
}

# GCP-specific context and resources
module "gcp_context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  # Inherit from global context
  context = module.global_context.context
  
  # GCP-specific overrides
  environment = "${var.environment}-gcp"
  
  # GCP requires lowercase for most resources
  label_key_case   = "lower"
  label_value_case = "lower"
  
  # GCP-specific labels (converted from tags)
  additional_tag_map = {
    cloud_provider = "gcp"
    region         = var.gcp_region
  }
}

# AWS Resources with AWS-specific constraints
locals {
  aws_constraints = {
    max_name_length = 63
    name_pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
    max_tags = 50
  }
  
  aws_name_prefix = module.aws_context.name_prefix
  aws_tags = module.aws_context.tags
}

# AWS S3 Bucket (globally unique naming required)
resource "aws_s3_bucket" "example" {
  count = var.create_aws_resources ? 1 : 0
  
  bucket = "${local.aws_name_prefix}-bucket-${random_id.aws_suffix[0].hex}"
  
  tags = merge(local.aws_tags, {
    ResourceType = "S3Bucket"
    Purpose      = "MultiCloudExample"
  })
}

resource "random_id" "aws_suffix" {
  count       = var.create_aws_resources ? 1 : 0
  byte_length = 4
  
  keepers = {
    name_prefix = local.aws_name_prefix
  }
}

# AWS IAM Role
resource "aws_iam_role" "example" {
  count = var.create_aws_resources ? 1 : 0
  
  name = "${local.aws_name_prefix}-role"
  
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
  
  tags = merge(local.aws_tags, {
    ResourceType = "IAMRole"
  })
}

# Validation for AWS resources
validation {
  condition = !var.create_aws_resources || can(regex(local.aws_constraints.name_pattern, local.aws_name_prefix))
  error_message = "AWS resource name '${local.aws_name_prefix}' must start with a letter, contain only letters, numbers, and hyphens, and end with a letter or number."
}

validation {
  condition = !var.create_aws_resources || length(local.aws_name_prefix) <= local.aws_constraints.max_name_length
  error_message = "AWS resource name '${local.aws_name_prefix}' exceeds maximum length of ${local.aws_constraints.max_name_length} characters."
}

# Azure Resources with Azure-specific constraints
locals {
  azure_constraints = {
    max_name_length = 80
    name_pattern = "^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$"
    storage_pattern = "^[a-z0-9]{3,24}$"
    max_tags = 50
  }
  
  azure_name_prefix = module.azure_context.name_prefix
  azure_tags = module.azure_context.tags
  
  # Azure storage account name (lowercase, no hyphens)
  azure_storage_name = lower(replace("${local.azure_name_prefix}sa${random_id.azure_suffix[0].hex}", "-", ""))
}

# Azure Resource Group
resource "azurerm_resource_group" "example" {
  count = var.create_azure_resources ? 1 : 0
  
  name     = "${local.azure_name_prefix}-rg"
  location = var.azure_region
  
  tags = merge(local.azure_tags, {
    ResourceType = "ResourceGroup"
    Purpose      = "MultiCloudExample"
  })
}

# Azure Storage Account
resource "azurerm_storage_account" "example" {
  count = var.create_azure_resources ? 1 : 0
  
  name                     = local.azure_storage_name
  resource_group_name      = azurerm_resource_group.example[0].name
  location                 = azurerm_resource_group.example[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = merge(local.azure_tags, {
    ResourceType = "StorageAccount"
  })
}

resource "random_id" "azure_suffix" {
  count       = var.create_azure_resources ? 1 : 0
  byte_length = 4
  
  keepers = {
    name_prefix = local.azure_name_prefix
  }
}

# Validation for Azure resources
validation {
  condition = !var.create_azure_resources || can(regex(local.azure_constraints.name_pattern, local.azure_name_prefix))
  error_message = "Azure resource name '${local.azure_name_prefix}' must start with a letter, contain only letters, numbers, hyphens, and underscores, and end with a letter or number."
}

validation {
  condition = !var.create_azure_resources || length(local.azure_name_prefix) <= local.azure_constraints.max_name_length
  error_message = "Azure resource name '${local.azure_name_prefix}' exceeds maximum length of ${local.azure_constraints.max_name_length} characters."
}

validation {
  condition = !var.create_azure_resources || can(regex(local.azure_constraints.storage_pattern, local.azure_storage_name))
  error_message = "Azure storage account name '${local.azure_storage_name}' must be 3-24 characters, lowercase letters and numbers only."
}

# GCP Resources with GCP-specific constraints
locals {
  gcp_constraints = {
    max_name_length = 63
    name_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    max_labels = 64
  }
  
  gcp_name_prefix = module.gcp_context.name_prefix
  gcp_tags = module.gcp_context.tags
  
  # Convert tags to GCP labels (lowercase)
  gcp_labels = {
    for key, value in local.gcp_tags :
    lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
  }
  
  # GCP project ID (if creating a new project)
  gcp_project_name = "${local.gcp_name_prefix}-${random_id.gcp_suffix[0].hex}"
}

# GCP Storage Bucket
resource "google_storage_bucket" "example" {
  count = var.create_gcp_resources ? 1 : 0
  
  name     = "${local.gcp_name_prefix}-bucket-${random_id.gcp_suffix[0].hex}"
  location = var.gcp_region
  
  labels = merge(local.gcp_labels, {
    resource_type = "storage_bucket"
    purpose       = "multicloud_example"
  })
  
  uniform_bucket_level_access = true
}

# GCP Service Account
resource "google_service_account" "example" {
  count = var.create_gcp_resources ? 1 : 0
  
  account_id   = "${local.gcp_name_prefix}-sa"
  display_name = "Multi-Cloud Example Service Account"
  description  = "Service account for multi-cloud context integration example"
}

resource "random_id" "gcp_suffix" {
  count       = var.create_gcp_resources ? 1 : 0
  byte_length = 4
  
  keepers = {
    name_prefix = local.gcp_name_prefix
  }
}

# Validation for GCP resources
validation {
  condition = !var.create_gcp_resources || can(regex(local.gcp_constraints.name_pattern, local.gcp_name_prefix))
  error_message = "GCP resource name '${local.gcp_name_prefix}' must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
}

validation {
  condition = !var.create_gcp_resources || length(local.gcp_name_prefix) <= local.gcp_constraints.max_name_length
  error_message = "GCP resource name '${local.gcp_name_prefix}' exceeds maximum length of ${local.gcp_constraints.max_name_length} characters."
}

validation {
  condition = !var.create_gcp_resources || length(local.gcp_labels) <= local.gcp_constraints.max_labels
  error_message = "GCP resource labels exceed maximum of ${local.gcp_constraints.max_labels} labels."
}

# Cross-cloud validation
validation {
  condition = length(var.namespace) <= 10
  error_message = "Namespace should be 10 characters or less for multi-cloud compatibility."
}

validation {
  condition = length(var.name) <= 15
  error_message = "Name should be 15 characters or less for multi-cloud compatibility."
}