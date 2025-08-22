# Basic Context Integration Example Variables

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Context Configuration
variable "namespace" {
  description = "Namespace, which could be your organization name or abbreviation"
  type        = string
  default     = "brockhoff"
}

variable "environment" {
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT'"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Solution name, e.g. 'app' or 'jenkins'"
  type        = string
  default     = "example"
}

variable "tags" {
  description = "Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`)"
  type        = map(string)
  default = {
    Project = "ContextIntegrationExample"
    Owner   = "DevTeam"
  }
}

variable "additional_tags" {
  description = "Additional tags to be added to the `additional_tag_map`"
  type        = map(string)
  default = {
    Example = "BasicUsage"
  }
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

# Module Configuration
variable "instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.micro"
}

variable "create_kms_key" {
  description = "Whether to create a KMS key for encryption"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_days" {
  description = "Number of days to wait before deleting KMS key"
  type        = number
  default     = 7
  validation {
    condition     = var.kms_key_deletion_window_days >= 7 && var.kms_key_deletion_window_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_monitoring" {
  description = "Whether to enable monitoring"
  type        = bool
  default     = false
}

variable "enable_alarms" {
  description = "Whether to enable CloudWatch alarms"
  type        = bool
  default     = false
}

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for alarms"
  type        = bool
  default     = true
}

# Resource Creation Flags
variable "create_s3_bucket" {
  description = "Whether to create an example S3 bucket"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Whether to create an example IAM role"
  type        = bool
  default     = true
}