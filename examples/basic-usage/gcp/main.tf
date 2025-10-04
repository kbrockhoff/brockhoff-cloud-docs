# Basic GCP Compute Example
# This example demonstrates a simple Compute Engine instance deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"

  name           = var.name
  environment    = var.environment
  cloud_provider = "gcp"

  # Override context if provided
  context = var.context
}

# Basic compute module following standardized interface
module "compute" {
  source = "../../../modules/services/compute/gcp"

  # Standard variables from context
  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  data_tags        = module.context.data_tags
  environment_type = var.environment_type

  # GCP-specific configuration
  project_id = var.gcp_project_id
  region     = var.gcp_region
  zone       = var.gcp_zone

  # Compute-specific configuration
  machine_type  = local.machine_type_map[var.instance_type]
  image_family  = var.image_family
  image_project = var.image_project

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
  network_name = var.network_name != "" ? var.network_name : "default"
  subnet_name  = var.subnet_name

  # Security configuration
  allowed_cidr_blocks = var.allowed_cidr_blocks
  ssh_public_keys     = var.ssh_public_keys
}

# Local mappings for GCP-specific configurations
locals {
  machine_type_map = {
    small  = "e2-micro"      # 2 vCPU, 1 GB RAM (shared-core)
    medium = "e2-small"      # 2 vCPU, 2 GB RAM (shared-core)
    large  = "e2-standard-2" # 2 vCPU, 8 GB RAM
  }
}

# Data sources for defaults
data "google_client_config" "current" {}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

data "google_compute_network" "existing" {
  count = var.network_name != "" && var.network_name != "default" ? 1 : 0
  name  = var.network_name
}

data "google_compute_subnetwork" "existing" {
  count = var.subnet_name != "" ? 1 : 0

  name   = var.subnet_name
  region = var.gcp_region
}