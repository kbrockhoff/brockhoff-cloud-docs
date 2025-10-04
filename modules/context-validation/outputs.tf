# Multi-Cloud Context Validation Module Outputs

output "cloud_provider" {
  description = "Detected or specified cloud provider"
  value       = local.cloud_provider
}

output "validation_results" {
  description = "Comprehensive validation results for the current cloud provider"
  value = {
    cloud_provider    = local.cloud_provider
    name_prefix       = var.name_prefix
    name_valid        = local.name_valid
    name_length_ok    = local.name_length_ok
    metadata_count_ok = local.metadata_count_ok
    metadata_valid    = local.metadata_valid
    all_valid         = local.all_valid

    # Detailed validation info
    constraints_applied = local.active_constraints
    tags_processed      = local.cloud_provider == "gcp" ? local.gcp_labels : var.tags

    # Resource-specific validation
    resource_validation = {
      aws_s3_bucket_valid = local.aws_s3_bucket_valid
      azure_storage_valid = local.azure_storage_valid
      gcp_bucket_valid    = local.gcp_bucket_valid
    }
  }
}

output "resource_names" {
  description = "Generated resource names following cloud provider-specific constraints"
  value = {
    # AWS resource names
    aws_s3_bucket = local.resource_names.aws_s3_bucket
    aws_iam_role  = local.resource_names.aws_iam_role

    # Azure resource names
    azure_storage_account = local.resource_names.azure_storage_account
    azure_resource_group  = local.resource_names.azure_resource_group

    # GCP resource names
    gcp_storage_bucket  = local.resource_names.gcp_storage_bucket
    gcp_service_account = local.resource_names.gcp_service_account
  }
}

output "cloud_provider_constraints" {
  description = "Active constraints for the detected/specified cloud provider"
  value       = local.active_constraints
}

output "tags_for_cloud_provider" {
  description = "Tags/labels formatted appropriately for the cloud provider"
  value       = local.cloud_provider == "gcp" ? local.gcp_labels : var.tags
}

output "validation_errors" {
  description = "List of validation errors (empty if all validations pass)"
  value = [
    for error in [
      !local.name_valid ? "Name '${var.name_prefix}' does not match ${local.cloud_provider} naming pattern" : null,
      !local.name_length_ok ? "Name '${var.name_prefix}' exceeds maximum length for ${local.cloud_provider}" : null,
      !local.metadata_count_ok ? "Too many tags/labels for ${local.cloud_provider}" : null,
      !local.metadata_valid ? "Tag/label validation failed for ${local.cloud_provider}" : null,
      !local.aws_s3_bucket_valid ? "AWS S3 bucket name validation failed" : null,
      !local.azure_storage_valid ? "Azure storage account name validation failed" : null,
      !local.gcp_bucket_valid ? "GCP storage bucket name validation failed" : null
    ] : error if error != null
  ]
}

output "cross_cloud_compatible" {
  description = "Whether the configuration is compatible across all cloud providers"
  value       = local.cross_cloud_compatible
}

# Helper functions for module consumers
output "helper_functions" {
  description = "Helper functions and utilities for cloud provider detection and configuration"
  value = {
    # Cloud provider detection
    detect_cloud_provider = {
      aws_available       = local.cloud_detection.aws_available
      azure_available     = local.cloud_detection.azure_available
      gcp_available       = local.cloud_detection.gcp_available
      detected            = local.detected_cloud_provider
      available_providers = local.available_providers
      is_multi_cloud      = local.is_multi_cloud
    }

    # Naming utilities
    naming_utilities = {
      # Convert name to cloud-specific format
      aws_format   = var.name_prefix        # AWS allows mixed case
      azure_format = var.name_prefix        # Azure allows mixed case
      gcp_format   = lower(var.name_prefix) # GCP prefers lowercase

      # Storage-specific names
      storage_names = {
        aws_s3        = local.resource_names.aws_s3_bucket
        azure_storage = local.resource_names.azure_storage_account
        gcp_bucket    = local.resource_names.gcp_storage_bucket
      }

      # Universal naming
      universal_name           = local.universal_name
      universal_resource_names = local.universal_resource_names
    }

    # Tag/label utilities
    metadata_utilities = {
      # Convert tags to cloud-specific format
      aws_tags   = var.tags
      azure_tags = var.tags
      gcp_labels = local.gcp_labels

      # Universal metadata
      universal_metadata = local.universal_metadata
      metadata_for_cloud = local.metadata_for_cloud
    }
  }
}

# Configuration recommendations
output "recommendations" {
  description = "Recommendations for improving cloud provider compatibility"
  value = {
    name_recommendations = length(var.name_prefix) > 50 ? [
      "Consider shortening the name prefix to 50 characters or less for better cross-cloud compatibility"
    ] : []

    tag_recommendations = length(var.tags) > 50 ? [
      "Consider reducing the number of tags to 50 or less for better cross-cloud compatibility"
    ] : []

    cloud_specific_recommendations = local.cloud_provider == "aws" ? [
      "AWS detected - ensure tag keys don't start with 'aws:' or 'AWS:'",
      "Consider using consistent casing for better readability"
      ] : local.cloud_provider == "azure" ? [
      "Azure detected - avoid using 'name', 'Name', or 'NAME' as tag keys",
      "Consider using underscores in resource names where appropriate"
      ] : local.cloud_provider == "gcp" ? [
      "GCP detected - use lowercase for optimal compatibility",
      "Convert spaces to underscores in labels",
      "Avoid using 'goog-' or 'google-' prefixes in label keys"
    ] : []
  }
}