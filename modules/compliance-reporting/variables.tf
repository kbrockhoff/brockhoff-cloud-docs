# Compliance Reporting Module Variables

variable "enabled" {
  description = "Enable compliance reporting and assessment"
  type        = bool
  default     = true
}

variable "module_name" {
  description = "Name of the module being assessed"
  type        = string
}

variable "module_version" {
  description = "Version of the module being assessed"
  type        = string
  default     = "1.0.0"
}

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp). If empty, will be detected from context"
  type        = string
  default     = ""
  validation {
    condition     = contains(["", "aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp, or empty for auto-detection."
  }
}

variable "environment_type" {
  description = "Environment type for compliance thresholds"
  type        = string
  default     = "Development"
  validation {
    condition = contains([
      "None", "Ephemeral", "Development", "Testing", "UAT", "Production", "MissionCritical"
    ], var.environment_type)
    error_message = "Environment type must be one of: None, Ephemeral, Development, Testing, UAT, Production, MissionCritical."
  }
}

variable "context" {
  description = "Context object from terraform-external-context module"
  type = object({
    cloud_provider = optional(string, "")
    environment    = optional(string, "")
    name_prefix    = optional(string, "")
    tags           = optional(map(string), {})
  })
  default = {
    cloud_provider = ""
    environment    = ""
    name_prefix    = ""
    tags           = {}
  }
}

variable "tags" {
  description = "Additional tags to apply to compliance metadata"
  type        = map(string)
  default     = {}
}

variable "resource_evidence" {
  description = "Evidence data collected from Terraform resources for compliance assessment"
  type = map(object({
    found   = bool
    value   = any
    message = optional(string, "")
  }))
  default = {}
}

variable "generate_report_file" {
  description = "Generate compliance report as JSON file"
  type        = bool
  default     = true
}

variable "generate_security_docs" {
  description = "Generate security controls documentation"
  type        = bool
  default     = true
}

variable "output_path" {
  description = "Path where compliance reports and documentation will be generated"
  type        = string
  default     = "./compliance-reports"
}

variable "run_advanced_assessment" {
  description = "Run advanced compliance assessment using external script"
  type        = bool
  default     = false
}

variable "terraform_plan_file" {
  description = "Path to Terraform plan JSON file for advanced assessment"
  type        = string
  default     = ""
}