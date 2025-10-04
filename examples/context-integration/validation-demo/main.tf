# Context Validation Demo Example
# This example demonstrates the multi-cloud context validation module

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure providers (optional - for demonstration)
provider "aws" {
  region = var.aws_region

  # Skip provider configuration if not using AWS
  skip_credentials_validation = !var.enable_aws_validation
  skip_metadata_api_check     = !var.enable_aws_validation
  skip_region_validation      = !var.enable_aws_validation
}

provider "azurerm" {
  features {}

  # Skip provider configuration if not using Azure
  skip_provider_registration = !var.enable_azure_validation
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # Skip provider configuration if not using GCP
  user_project_override = var.enable_gcp_validation
}

# Generate random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Context module for consistent naming and tagging
module "context" {
  source  = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name

  tags = var.tags

  # Optimize for multi-cloud compatibility
  id_length_limit     = 45 # Leave room for suffixes
  delimiter           = "-"
  regex_replace_chars = "/[^a-zA-Z0-9-]/"
}

# AWS Context Validation
module "aws_validation" {
  count = var.enable_aws_validation ? 1 : 0

  source = "../../../modules/context-validation"

  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  cloud_provider   = "aws"
  random_suffix    = random_id.suffix.hex
  environment_type = var.environment_type

  # Enable cross-cloud compatibility checking
  enforce_cross_cloud_compatibility = var.enforce_cross_cloud_compatibility

  providers = {
    aws     = aws
    azurerm = azurerm
    google  = google
  }
}

# Azure Context Validation
module "azure_validation" {
  count = var.enable_azure_validation ? 1 : 0

  source = "../../../modules/context-validation"

  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  cloud_provider   = "azure"
  random_suffix    = random_id.suffix.hex
  environment_type = var.environment_type

  enforce_cross_cloud_compatibility = var.enforce_cross_cloud_compatibility

  providers = {
    aws     = aws
    azurerm = azurerm
    google  = google
  }
}

# GCP Context Validation
module "gcp_validation" {
  count = var.enable_gcp_validation ? 1 : 0

  source = "../../../modules/context-validation"

  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  cloud_provider   = "gcp"
  random_suffix    = random_id.suffix.hex
  environment_type = var.environment_type

  enforce_cross_cloud_compatibility = var.enforce_cross_cloud_compatibility

  providers = {
    aws     = aws
    azurerm = azurerm
    google  = google
  }
}

# Auto-detect cloud provider validation
module "auto_validation" {
  count = var.enable_auto_detection ? 1 : 0

  source = "../../../modules/context-validation"

  name_prefix = module.context.name_prefix
  tags        = module.context.tags
  # cloud_provider = null  # Auto-detect
  random_suffix    = random_id.suffix.hex
  environment_type = var.environment_type

  enforce_cross_cloud_compatibility = var.enforce_cross_cloud_compatibility

  providers = {
    aws     = aws
    azurerm = azurerm
    google  = google
  }
}

# Demonstrate resource creation with validated names (AWS)
resource "aws_s3_bucket" "demo" {
  count = var.enable_aws_validation && var.create_demo_resources ? 1 : 0

  bucket = module.aws_validation[0].resource_names.aws_s3_bucket
  tags   = module.aws_validation[0].tags_for_cloud_provider
}

# Demonstrate resource creation with validated names (Azure)
resource "azurerm_resource_group" "demo" {
  count = var.enable_azure_validation && var.create_demo_resources ? 1 : 0

  name     = module.azure_validation[0].resource_names.azure_resource_group
  location = var.azure_region
  tags     = module.azure_validation[0].tags_for_cloud_provider
}

resource "azurerm_storage_account" "demo" {
  count = var.enable_azure_validation && var.create_demo_resources ? 1 : 0

  name                     = module.azure_validation[0].resource_names.azure_storage_account
  resource_group_name      = azurerm_resource_group.demo[0].name
  location                 = azurerm_resource_group.demo[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = module.azure_validation[0].tags_for_cloud_provider
}

# Demonstrate resource creation with validated names (GCP)
resource "google_storage_bucket" "demo" {
  count = var.enable_gcp_validation && var.create_demo_resources ? 1 : 0

  name     = module.gcp_validation[0].resource_names.gcp_storage_bucket
  location = var.gcp_region

  labels = module.gcp_validation[0].tags_for_cloud_provider

  uniform_bucket_level_access = true
}

# Local values for demonstration
locals {
  # Collect validation results from all enabled validations
  validation_results = merge(
    var.enable_aws_validation ? {
      aws = module.aws_validation[0].validation_results
    } : {},
    var.enable_azure_validation ? {
      azure = module.azure_validation[0].validation_results
    } : {},
    var.enable_gcp_validation ? {
      gcp = module.gcp_validation[0].validation_results
    } : {},
    var.enable_auto_detection ? {
      auto = module.auto_validation[0].validation_results
    } : {}
  )

  # Collect all validation errors
  all_validation_errors = flatten([
    for provider, results in local.validation_results :
    results.all_valid ? [] : ["${provider}: validation failed"]
  ])

  # Check if all validations passed
  all_validations_passed = length(local.all_validation_errors) == 0

  # Collect resource names from all providers
  all_resource_names = merge(
    var.enable_aws_validation ? {
      aws = module.aws_validation[0].resource_names
    } : {},
    var.enable_azure_validation ? {
      azure = module.azure_validation[0].resource_names
    } : {},
    var.enable_gcp_validation ? {
      gcp = module.gcp_validation[0].resource_names
    } : {}
  )

  # Cross-cloud compatibility summary
  cross_cloud_summary = {
    aws_compatible   = var.enable_aws_validation ? module.aws_validation[0].cross_cloud_compatible : null
    azure_compatible = var.enable_azure_validation ? module.azure_validation[0].cross_cloud_compatible : null
    gcp_compatible   = var.enable_gcp_validation ? module.gcp_validation[0].cross_cloud_compatible : null

    all_compatible = alltrue([
      for compatible in [
        var.enable_aws_validation ? module.aws_validation[0].cross_cloud_compatible : true,
        var.enable_azure_validation ? module.azure_validation[0].cross_cloud_compatible : true,
        var.enable_gcp_validation ? module.gcp_validation[0].cross_cloud_compatible : true
      ] : compatible
    ])
  }
}