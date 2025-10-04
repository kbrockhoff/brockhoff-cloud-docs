variable "name" {
  description = "Name of the application"
  type        = string
  default     = "multi-tier-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "environment_type" {
  description = "Environment type for resource configuration"
  type        = string
  default     = "Production"
  validation {
    condition = contains([
      "None", "Ephemeral", "Development", "Testing",
      "UAT", "Production", "MissionCritical"
    ], var.environment_type)
    error_message = "Environment type must be one of: None, Ephemeral, Development, Testing, UAT, Production, MissionCritical."
  }
}

variable "cidr_primary" {
  description = "Primary CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    Project = "MultiTierApp"
    Owner   = "DevOps"
  }
}