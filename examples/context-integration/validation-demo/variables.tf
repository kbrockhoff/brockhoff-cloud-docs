# Context Validation Demo Variables

# Global Configuration
variable "namespace" {
  description = "Namespace, which could be your organization name or abbreviation"
  type        = string
  default     = "demo"
  validation {
    condition     = length(var.namespace) <= 10
    error_message = "Namespace must be 10 characters or less for multi-cloud compatibility."
  }
}

variable "environment" {
  description = "Environment, e.g. 'prod', 'staging', 'dev'"
  type        = string
  default     = "dev"
  validation {
    condition     = length(var.environment) <= 8
    error_message = "Environment must be 8 characters or less for multi-cloud compatibility."
  }
}

variable "name" {
  description = "Solution name, e.g. 'app' or 'web'"
  type        = string
  default     = "validation"
  validation {
    condition     = length(var.name) <= 15
    error_message = "Name must be 15 characters or less for multi-cloud compatibility."
  }
}

variable "tags" {
  description = "Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`)"
  type        = map(string)
  default = {
    Project = "ContextValidation"
    Owner   = "DevTeam"
    Purpose = "Demo"
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

# Validation Control
variable "enable_aws_validation" {
  description = "Whether to enable AWS context validation"
  type        = bool
  default     = true
}

variable "enable_azure_validation" {
  description = "Whether to enable Azure context validation"
  type        = bool
  default     = false
}

variable "enable_gcp_validation" {
  description = "Whether to enable GCP context validation"
  type        = bool
  default     = false
}

variable "enable_auto_detection" {
  description = "Whether to enable automatic cloud provider detection"
  type        = bool
  default     = true
}

variable "enforce_cross_cloud_compatibility" {
  description = "Whether to enforce cross-cloud compatibility constraints"
  type        = bool
  default     = true
}

# Resource Creation Control
variable "create_demo_resources" {
  description = "Whether to create demo resources to test validation"
  type        = bool
  default     = false
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Azure Configuration
variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
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

# Testing Variables
variable "test_invalid_names" {
  description = "Whether to test invalid name scenarios (will cause validation errors)"
  type        = bool
  default     = false
}

variable "test_name_scenarios" {
  description = "Different name scenarios to test"
  type = object({
    valid_short       = optional(string, "demo-app")
    valid_long        = optional(string, "demo-very-long-application-name")
    invalid_aws       = optional(string, "-invalid-aws-name-")
    invalid_azure     = optional(string, "invalid azure name with spaces")
    invalid_gcp       = optional(string, "Invalid-GCP-Name-With-Uppercase")
    too_long          = optional(string, "this-is-an-extremely-long-name-that-exceeds-all-cloud-provider-limits-and-should-fail-validation")
  })
  default = {}
}