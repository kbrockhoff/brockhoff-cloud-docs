# Basic Azure Compute Example Variables
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

# Azure-specific variables
variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "Resource group name (leave empty to create new)"
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

# Network configuration
variable "vnet_name" {
  description = "Virtual network name (leave empty to create new)"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name (leave empty to create new)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the VM"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# VM configuration
variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "azureuser"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.admin_username))
    error_message = "Admin username must be 3-20 characters, start with lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (optional)"
  type        = string
  default     = ""
}

# Feature toggles
variable "create_key_vault" {
  description = "Create a Key Vault for encryption"
  type        = bool
  default     = true
}

variable "monitoring_enabled" {
  description = "Enable Azure Monitor"
  type        = bool
  default     = false
}

variable "alarms_enabled" {
  description = "Enable Azure Monitor alerts"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}