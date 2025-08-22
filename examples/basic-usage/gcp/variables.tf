# Basic GCP Compute Example Variables
# Following Brockhoff Cloud standardized variable patterns

# Core variables (required)
variable "name" {
  description = "Base name for resources"
  type        = string
  default     = "basic-compute"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains([
      "dev", "development", "staging", "stage", "prod", "production"
    ], var.environment)
    error_message = "Environment must be one of: dev, development, staging, stage, prod, production."
  }
}

variable "environment_type" {
  description = "Environment type for resource configuration defaults"
  type        = string
  default     = "Development"
  
  validation {
    condition = contains([
      "None", "Ephemeral", "Development", "Testing", "UAT", "Production", "MissionCritical"
    ], var.environment_type)
    error_message = "Environment type must be one of: None, Ephemeral, Development, Testing, UAT, Production, MissionCritical."
  }
}

# Context override (optional)
variable "context" {
  description = "Context object from terraform-external-context module (optional override)"
  type = object({
    name_prefix = string
    tags        = map(string)
    data_tags   = map(string)
  })
  default = null
}

# GCP-specific variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-west1"
}

variable "gcp_zone" {
  description = "GCP zone for resources (optional, uses first available zone if not specified)"
  type        = string
  default     = ""
}

# Compute configuration
variable "instance_type" {
  description = "Instance size (small, medium, large)"
  type        = string
  default     = "small"
  
  validation {
    condition     = contains(["small", "medium", "large"], var.instance_type)
    error_message = "Instance type must be small, medium, or large."
  }
}

variable "image_family" {
  description = "OS image family"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "image_project" {
  description = "Project containing the OS image"
  type        = string
  default     = "ubuntu-os-cloud"
}

# Network configuration
variable "network_name" {
  description = "VPC network name (leave empty to use default network)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name (leave empty to use default subnet)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# SSH configuration
variable "ssh_public_keys" {
  description = "List of SSH public keys for instance access"
  type        = list(string)
  default     = []
}

# Feature toggles
variable "create_kms_key" {
  description = "Create a Cloud KMS key for encryption"
  type        = bool
  default     = true
}

variable "monitoring_enabled" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = false
}

variable "alarms_enabled" {
  description = "Enable Cloud Monitoring alerts"
  type        = bool
  default     = false
}

# Labels (GCP equivalent of tags)
variable "additional_labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}