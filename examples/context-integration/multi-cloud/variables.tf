# Multi-Cloud Context Integration Example Variables

# Global Configuration
variable "namespace" {
  description = "Namespace, which could be your organization name or abbreviation (keep short for multi-cloud)"
  type        = string
  default     = "brockhoff"
  validation {
    condition     = length(var.namespace) <= 10
    error_message = "Namespace must be 10 characters or less for multi-cloud compatibility."
  }
}

variable "environment" {
  description = "Environment, e.g. 'prod', 'staging', 'dev' (keep short for multi-cloud)"
  type        = string
  default     = "dev"
  validation {
    condition     = length(var.environment) <= 8
    error_message = "Environment must be 8 characters or less for multi-cloud compatibility."
  }
}

variable "name" {
  description = "Solution name, e.g. 'app' or 'web' (keep short for multi-cloud)"
  type        = string
  default     = "multicloud"
  validation {
    condition     = length(var.name) <= 15
    error_message = "Name must be 15 characters or less for multi-cloud compatibility."
  }
}

variable "tags" {
  description = "Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`)"
  type        = map(string)
  default = {
    Project = "MultiCloudExample"
    Owner   = "DevTeam"
    Purpose = "ContextIntegration"
  }
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "create_aws_resources" {
  description = "Whether to create AWS resources"
  type        = bool
  default     = true
}

# Azure Configuration
variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "create_azure_resources" {
  description = "Whether to create Azure resources"
  type        = bool
  default     = false  # Set to false by default to avoid requiring Azure credentials
}

# GCP Configuration
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "create_gcp_resources" {
  description = "Whether to create GCP resources"
  type        = bool
  default     = false  # Set to false by default to avoid requiring GCP credentials
}

# Environment Configuration
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