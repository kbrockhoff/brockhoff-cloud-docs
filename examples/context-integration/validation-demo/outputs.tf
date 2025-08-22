# Context Validation Demo Outputs

# Validation Results
output "validation_summary" {
  description = "Summary of all validation results"
  value = {
    all_validations_passed = local.all_validations_passed
    validation_errors      = local.all_validation_errors
    enabled_validations    = [
      for provider in ["aws", "azure", "gcp", "auto"] :
      provider if (
        (provider == "aws" && var.enable_aws_validation) ||
        (provider == "azure" && var.enable_azure_validation) ||
        (provider == "gcp" && var.enable_gcp_validation) ||
        (provider == "auto" && var.enable_auto_detection)
      )
    ]
  }
}

output "validation_results" {
  description = "Detailed validation results from all enabled providers"
  value       = local.validation_results
}

output "cross_cloud_compatibility" {
  description = "Cross-cloud compatibility assessment"
  value       = local.cross_cloud_summary
}

# Context Information
output "context_info" {
  description = "Information about the generated context"
  value = {
    name_prefix = module.context.name_prefix
    tags        = module.context.tags
    id          = module.context.id
  }
}

# Resource Names
output "generated_resource_names" {
  description = "Generated resource names for all cloud providers"
  value       = local.all_resource_names
}

# AWS-specific outputs
output "aws_validation" {
  description = "AWS validation results and resource names"
  value = var.enable_aws_validation ? {
    cloud_provider     = module.aws_validation[0].cloud_provider
    validation_results = module.aws_validation[0].validation_results
    resource_names     = module.aws_validation[0].resource_names
    recommendations    = module.aws_validation[0].recommendations
    validation_errors  = module.aws_validation[0].validation_errors
  } : null
}

# Azure-specific outputs
output "azure_validation" {
  description = "Azure validation results and resource names"
  value = var.enable_azure_validation ? {
    cloud_provider     = module.azure_validation[0].cloud_provider
    validation_results = module.azure_validation[0].validation_results
    resource_names     = module.azure_validation[0].resource_names
    recommendations    = module.azure_validation[0].recommendations
    validation_errors  = module.azure_validation[0].validation_errors
  } : null
}

# GCP-specific outputs
output "gcp_validation" {
  description = "GCP validation results and resource names"
  value = var.enable_gcp_validation ? {
    cloud_provider     = module.gcp_validation[0].cloud_provider
    validation_results = module.gcp_validation[0].validation_results
    resource_names     = module.gcp_validation[0].resource_names
    recommendations    = module.gcp_validation[0].recommendations
    validation_errors  = module.gcp_validation[0].validation_errors
  } : null
}

# Auto-detection outputs
output "auto_detection" {
  description = "Auto-detection validation results"
  value = var.enable_auto_detection ? {
    detected_provider  = module.auto_validation[0].cloud_provider
    validation_results = module.auto_validation[0].validation_results
    helper_functions   = module.auto_validation[0].helper_functions
  } : null
}

# Helper Functions
output "helper_functions" {
  description = "Helper functions from validation modules"
  value = var.enable_auto_detection ? module.auto_validation[0].helper_functions : (
    var.enable_aws_validation ? module.aws_validation[0].helper_functions : (
      var.enable_azure_validation ? module.azure_validation[0].helper_functions : (
        var.enable_gcp_validation ? module.gcp_validation[0].helper_functions : null
      )
    )
  )
}

# Recommendations
output "recommendations" {
  description = "Recommendations for improving cloud provider compatibility"
  value = {
    aws   = var.enable_aws_validation ? module.aws_validation[0].recommendations : null
    azure = var.enable_azure_validation ? module.azure_validation[0].recommendations : null
    gcp   = var.enable_gcp_validation ? module.gcp_validation[0].recommendations : null
  }
}

# Demo Resources (if created)
output "demo_resources" {
  description = "Information about created demo resources"
  value = var.create_demo_resources ? {
    aws_s3_bucket = var.enable_aws_validation ? (
      length(aws_s3_bucket.demo) > 0 ? aws_s3_bucket.demo[0].bucket : null
    ) : null
    
    azure_storage_account = var.enable_azure_validation ? (
      length(azurerm_storage_account.demo) > 0 ? azurerm_storage_account.demo[0].name : null
    ) : null
    
    gcp_storage_bucket = var.enable_gcp_validation ? (
      length(google_storage_bucket.demo) > 0 ? google_storage_bucket.demo[0].name : null
    ) : null
  } : null
}

# Validation Constraints
output "validation_constraints" {
  description = "Active validation constraints for each cloud provider"
  value = {
    aws   = var.enable_aws_validation ? module.aws_validation[0].cloud_provider_constraints : null
    azure = var.enable_azure_validation ? module.azure_validation[0].cloud_provider_constraints : null
    gcp   = var.enable_gcp_validation ? module.gcp_validation[0].cloud_provider_constraints : null
  }
}

# Usage Examples
output "usage_examples" {
  description = "Examples of how to use the validated resource names"
  value = {
    terraform_examples = {
      aws_s3_bucket = var.enable_aws_validation ? {
        resource_block = <<-EOT
          resource "aws_s3_bucket" "example" {
            bucket = "${module.aws_validation[0].resource_names.aws_s3_bucket}"
            tags   = module.aws_validation.tags_for_cloud_provider
          }
        EOT
      } : null
      
      azure_storage_account = var.enable_azure_validation ? {
        resource_block = <<-EOT
          resource "azurerm_storage_account" "example" {
            name                = "${module.azure_validation[0].resource_names.azure_storage_account}"
            resource_group_name = azurerm_resource_group.example.name
            location           = "East US"
            account_tier       = "Standard"
            account_replication_type = "LRS"
            tags = module.azure_validation.tags_for_cloud_provider
          }
        EOT
      } : null
      
      gcp_storage_bucket = var.enable_gcp_validation ? {
        resource_block = <<-EOT
          resource "google_storage_bucket" "example" {
            name     = "${module.gcp_validation[0].resource_names.gcp_storage_bucket}"
            location = "US"
            labels   = module.gcp_validation.tags_for_cloud_provider
          }
        EOT
      } : null
    }
  }
}