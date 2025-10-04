# Basic Azure Compute Example
# This example demonstrates a simple Virtual Machine deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"

  name           = var.name
  environment    = var.environment
  cloud_provider = "az"

  # Override context if provided
  context = var.context
}

# Basic compute module following standardized interface
module "compute" {
  source = "../../../modules/services/compute/azure"

  # Standard variables from context
  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  data_tags        = module.context.data_tags
  environment_type = var.environment_type

  # Azure-specific configuration
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  # Compute-specific configuration
  vm_size = local.vm_size_map[var.instance_type]

  # Standard configuration objects
  encryption_config = {
    create_kms_key               = var.create_key_vault
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
  vnet_name   = var.vnet_name
  subnet_name = var.subnet_name

  # Security configuration
  allowed_cidr_blocks = var.allowed_cidr_blocks
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
}

# Create resource group if not provided
resource "azurerm_resource_group" "main" {
  count = var.resource_group_name == "" ? 1 : 0

  name     = "${module.context.name_prefix}-rg"
  location = var.azure_location

  tags = module.context.tags
}

# Local mappings for Azure-specific configurations
locals {
  vm_size_map = {
    small  = "Standard_B1s"  # 1 vCPU, 1 GB RAM
    medium = "Standard_B2s"  # 2 vCPU, 4 GB RAM
    large  = "Standard_B4ms" # 4 vCPU, 16 GB RAM
  }
}

# Data sources for defaults
data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "existing" {
  count = var.vnet_name != "" ? 1 : 0

  name                = var.vnet_name
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}

data "azurerm_subnet" "existing" {
  count = var.subnet_name != "" ? 1 : 0

  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}