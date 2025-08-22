# Basic AWS Compute Example Variables
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

# AWS-specific variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
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

variable "ami_id" {
  description = "AMI ID to use (leave empty for latest Amazon Linux 2)"
  type        = string
  default     = ""
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID (leave empty to use default subnet)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "ssh_key_name" {
  description = "AWS key pair name for SSH access (optional)"
  type        = string
  default     = ""
}

# Feature toggles
variable "create_kms_key" {
  description = "Create a KMS key for encryption"
  type        = bool
  default     = true
}

variable "monitoring_enabled" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "alarms_enabled" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}