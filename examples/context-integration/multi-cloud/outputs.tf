# Multi-Cloud Context Integration Example Outputs

# Global Context Outputs
output "global_context_environment_type" {
  description = "Global context environment type used across all clouds"
  value       = module.global_context.environment_type
}

output "global_context_tags" {
  description = "Global context tags"
  value       = module.global_context.tags
}

# AWS Context and Resource Outputs
output "aws_context_environment_type" {
  description = "AWS-specific context environment type"
  value       = module.aws_context.environment_type
}

output "aws_context_tags" {
  description = "AWS-specific context tags"
  value       = module.aws_context.tags
}

output "aws_s3_bucket_name" {
  description = "Name of the AWS S3 bucket"
  value       = var.create_aws_resources ? aws_s3_bucket.example[0].bucket : null
}

output "aws_s3_bucket_arn" {
  description = "ARN of the AWS S3 bucket"
  value       = var.create_aws_resources ? aws_s3_bucket.example[0].arn : null
}

output "aws_iam_role_name" {
  description = "Name of the AWS IAM role"
  value       = var.create_aws_resources ? aws_iam_role.example[0].name : null
}

output "aws_iam_role_arn" {
  description = "ARN of the AWS IAM role"
  value       = var.create_aws_resources ? aws_iam_role.example[0].arn : null
}

# Azure Context and Resource Outputs
output "azure_context_environment_type" {
  description = "Azure-specific context environment type"
  value       = module.azure_context.environment_type
}

output "azure_context_tags" {
  description = "Azure-specific context tags"
  value       = module.azure_context.tags
}

output "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  value       = var.create_azure_resources ? azurerm_resource_group.example[0].name : null
}

output "azure_resource_group_id" {
  description = "ID of the Azure resource group"
  value       = var.create_azure_resources ? azurerm_resource_group.example[0].id : null
}

output "azure_storage_account_name" {
  description = "Name of the Azure storage account"
  value       = var.create_azure_resources ? azurerm_storage_account.example[0].name : null
}

output "azure_storage_account_id" {
  description = "ID of the Azure storage account"
  value       = var.create_azure_resources ? azurerm_storage_account.example[0].id : null
}

# GCP Context and Resource Outputs
output "gcp_context_environment_type" {
  description = "GCP-specific context environment type"
  value       = module.gcp_context.environment_type
}

output "gcp_context_labels" {
  description = "GCP-specific context labels (converted from tags)"
  value       = local.gcp_labels
}

output "gcp_storage_bucket_name" {
  description = "Name of the GCP storage bucket"
  value       = var.create_gcp_resources ? google_storage_bucket.example[0].name : null
}

output "gcp_storage_bucket_url" {
  description = "URL of the GCP storage bucket"
  value       = var.create_gcp_resources ? google_storage_bucket.example[0].url : null
}

output "gcp_service_account_email" {
  description = "Email of the GCP service account"
  value       = var.create_gcp_resources ? google_service_account.example[0].email : null
}

output "gcp_service_account_id" {
  description = "ID of the GCP service account"
  value       = var.create_gcp_resources ? google_service_account.example[0].id : null
}

# Cross-Cloud Comparison
output "naming_comparison" {
  description = "Comparison of naming conventions across cloud providers"
  value = {
    global_prefix = module.global_context.name_prefix
    aws_prefix    = local.aws_name_prefix
    azure_prefix  = local.azure_name_prefix
    gcp_prefix    = local.gcp_name_prefix
  }
}

output "tagging_comparison" {
  description = "Comparison of tagging/labeling across cloud providers"
  value = {
    aws_tags   = local.aws_tags
    azure_tags = local.azure_tags
    gcp_labels = local.gcp_labels
  }
}

# Validation Results
output "validation_results" {
  description = "Validation results for each cloud provider"
  value = {
    aws = {
      name_valid  = can(regex(local.aws_constraints.name_pattern, local.aws_name_prefix))
      name_length = length(local.aws_name_prefix)
      max_length  = local.aws_constraints.max_name_length
      tags_count  = length(local.aws_tags)
      max_tags    = local.aws_constraints.max_tags
    }
    azure = {
      name_valid    = can(regex(local.azure_constraints.name_pattern, local.azure_name_prefix))
      name_length   = length(local.azure_name_prefix)
      max_length    = local.azure_constraints.max_name_length
      storage_name  = local.azure_storage_name
      storage_valid = can(regex(local.azure_constraints.storage_pattern, local.azure_storage_name))
      tags_count    = length(local.azure_tags)
      max_tags      = local.azure_constraints.max_tags
    }
    gcp = {
      name_valid   = can(regex(local.gcp_constraints.name_pattern, local.gcp_name_prefix))
      name_length  = length(local.gcp_name_prefix)
      max_length   = local.gcp_constraints.max_name_length
      labels_count = length(local.gcp_labels)
      max_labels   = local.gcp_constraints.max_labels
    }
  }
}

# Debug Information
output "debug_info" {
  description = "Debug information for multi-cloud context integration"
  value = {
    global_context_enabled = module.global_context.context.enabled
    aws_enabled            = var.create_aws_resources
    azure_enabled          = var.create_azure_resources
    gcp_enabled            = var.create_gcp_resources
    environment_type       = var.environment_type

    # Name generation details
    name_components = {
      namespace   = var.namespace
      environment = var.environment
      name        = var.name
    }

    # Cloud-specific configurations
    cloud_configs = {
      aws = {
        name_prefix = module.aws_context.name_prefix
        environment = module.aws_context.context.environment
      }
      azure = {
        name_prefix = module.azure_context.name_prefix
        environment = module.azure_context.context.environment
      }
      gcp = {
        name_prefix = module.gcp_context.name_prefix
        environment = module.gcp_context.context.environment
      }
    }
  }
}