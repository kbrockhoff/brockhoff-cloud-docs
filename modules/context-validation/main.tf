# Multi-Cloud Context Validation Module
# This module provides validation logic for cloud provider-specific constraints
# and helper functions for cloud provider detection and configuration

# Data sources for cloud provider detection
data "aws_caller_identity" "current" {
  count = var.enabled && (var.cloud_provider == "aws" || var.cloud_provider == null) ? 1 : 0
}

data "azurerm_client_config" "current" {
  count = var.enabled && (var.cloud_provider == "azure" || var.cloud_provider == null) ? 1 : 0
}

data "google_client_config" "current" {
  count = var.enabled && (var.cloud_provider == "gcp" || var.cloud_provider == null) ? 1 : 0
}

# Cloud provider detection and constraints
locals {
  # Detect active cloud provider
  detected_cloud_provider = (
    length(data.aws_caller_identity.current) > 0 ? "aws" :
    length(data.azurerm_client_config.current) > 0 ? "azure" :
    length(data.google_client_config.current) > 0 ? "gcp" :
    "unknown"
  )
  
  # Use specified provider or detected provider
  cloud_provider = var.cloud_provider != null ? var.cloud_provider : local.detected_cloud_provider
  
  # Cloud provider-specific constraints
  constraints = {
    aws = {
      max_name_length = 63
      name_pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
      allowed_chars = "a-zA-Z0-9-"
      max_tags = 50
      max_tag_key_length = 128
      max_tag_value_length = 256
      reserved_tag_prefixes = ["aws:", "AWS:"]
      
      # Resource-specific constraints
      s3_bucket = {
        pattern = "^[a-z0-9][a-z0-9-]*[a-z0-9]$"
        max_length = 63
        min_length = 3
      }
      iam_role = {
        pattern = "^[a-zA-Z][a-zA-Z0-9+=,.@_-]*$"
        max_length = 64
      }
    }
    
    azure = {
      max_name_length = 80
      name_pattern = "^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$"
      allowed_chars = "a-zA-Z0-9-_"
      max_tags = 50
      max_tag_key_length = 512
      max_tag_value_length = 256
      reserved_tag_keys = ["name", "Name", "NAME"]
      
      # Resource-specific constraints
      storage_account = {
        pattern = "^[a-z0-9]{3,24}$"
        max_length = 24
        min_length = 3
      }
      resource_group = {
        pattern = "^[a-zA-Z0-9][a-zA-Z0-9-_.()]*[a-zA-Z0-9_)]$"
        max_length = 90
      }
    }
    
    gcp = {
      max_name_length = 63
      name_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
      allowed_chars = "a-z0-9-"
      max_labels = 64
      max_label_key_length = 63
      max_label_value_length = 63
      label_key_pattern = "^[a-z][a-z0-9_-]*$"
      label_value_pattern = "^[a-z0-9_-]*$"
      reserved_label_prefixes = ["goog-", "google-"]
      
      # Resource-specific constraints
      storage_bucket = {
        pattern = "^[a-z0-9][a-z0-9-._]*[a-z0-9]$"
        max_length = 63
        min_length = 3
      }
      service_account = {
        pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
        max_length = 30
        min_length = 6
      }
    }
  }
  
  # Active constraints for the current cloud provider
  active_constraints = local.constraints[local.cloud_provider]
  
  # GCP label conversion (GCP requires lowercase labels)
  gcp_labels = local.cloud_provider == "gcp" ? {
    for key, value in var.tags :
    lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
  } : {}
  
  # Validation logic
  name_valid = can(regex(local.active_constraints.name_pattern, var.name_prefix))
  name_length_ok = length(var.name_prefix) <= local.active_constraints.max_name_length
  
  # Tag/Label validation based on cloud provider
  metadata_count_ok = local.cloud_provider == "gcp" ? (
    length(local.gcp_labels) <= local.active_constraints.max_labels
  ) : (
    length(var.tags) <= local.active_constraints.max_tags
  )
  
  # Cloud-specific metadata validation
  tags_valid = local.cloud_provider == "aws" ? alltrue([
    for key, value in var.tags :
    length(key) <= local.active_constraints.max_tag_key_length &&
    length(value) <= local.active_constraints.max_tag_value_length &&
    !startswith(key, "aws:") &&
    !startswith(key, "AWS:")
  ]) : local.cloud_provider == "azure" ? alltrue([
    for key, value in var.tags :
    length(key) <= local.active_constraints.max_tag_key_length &&
    length(value) <= local.active_constraints.max_tag_value_length &&
    !contains(local.active_constraints.reserved_tag_keys, key)
  ]) : true
  
  gcp_labels_valid = local.cloud_provider == "gcp" ? alltrue([
    for key, value in local.gcp_labels :
    length(key) <= local.active_constraints.max_label_key_length &&
    length(value) <= local.active_constraints.max_label_value_length &&
    can(regex(local.active_constraints.label_key_pattern, key)) &&
    can(regex(local.active_constraints.label_value_pattern, value)) &&
    !startswith(key, "goog-") &&
    !startswith(key, "google-")
  ]) : true
  
  metadata_valid = local.cloud_provider == "gcp" ? local.gcp_labels_valid : local.tags_valid
  
  # Resource-specific naming
  resource_names = {
    # AWS resource names
    aws_s3_bucket = local.cloud_provider == "aws" ? "${lower(var.name_prefix)}-bucket-${var.random_suffix}" : null
    aws_iam_role = local.cloud_provider == "aws" ? "${var.name_prefix}-role" : null
    
    # Azure resource names
    azure_storage_account = local.cloud_provider == "azure" ? substr(
      lower(replace("${var.name_prefix}sa${var.random_suffix}", "/[^a-z0-9]/", "")),
      0, 24
    ) : null
    azure_resource_group = local.cloud_provider == "azure" ? "${var.name_prefix}-rg" : null
    
    # GCP resource names
    gcp_storage_bucket = local.cloud_provider == "gcp" ? "${lower(var.name_prefix)}-bucket-${var.random_suffix}" : null
    gcp_service_account = local.cloud_provider == "gcp" ? "${lower(var.name_prefix)}-sa" : null
  }
  
  # Resource-specific validation
  aws_s3_bucket_valid = local.cloud_provider == "aws" && local.resource_names.aws_s3_bucket != null ? (
    can(regex(local.active_constraints.s3_bucket.pattern, local.resource_names.aws_s3_bucket)) &&
    length(local.resource_names.aws_s3_bucket) >= local.active_constraints.s3_bucket.min_length &&
    length(local.resource_names.aws_s3_bucket) <= local.active_constraints.s3_bucket.max_length
  ) : true
  
  azure_storage_valid = local.cloud_provider == "azure" && local.resource_names.azure_storage_account != null ? (
    can(regex(local.active_constraints.storage_account.pattern, local.resource_names.azure_storage_account)) &&
    length(local.resource_names.azure_storage_account) >= local.active_constraints.storage_account.min_length &&
    length(local.resource_names.azure_storage_account) <= local.active_constraints.storage_account.max_length
  ) : true
  
  gcp_bucket_valid = local.cloud_provider == "gcp" && local.resource_names.gcp_storage_bucket != null ? (
    can(regex(local.active_constraints.storage_bucket.pattern, local.resource_names.gcp_storage_bucket)) &&
    length(local.resource_names.gcp_storage_bucket) >= local.active_constraints.storage_bucket.min_length &&
    length(local.resource_names.gcp_storage_bucket) <= local.active_constraints.storage_bucket.max_length
  ) : true
  
  # Overall validation status
  all_valid = (
    local.name_valid &&
    local.name_length_ok &&
    local.metadata_count_ok &&
    local.metadata_valid &&
    local.aws_s3_bucket_valid &&
    local.azure_storage_valid &&
    local.gcp_bucket_valid
  )
  
  # Cross-cloud compatibility check
  cross_cloud_compatible = (
    length(var.name_prefix) <= 50 &&
    can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name_prefix)) &&
    length(var.tags) <= 50 &&
    alltrue([
      for key, value in var.tags :
      length(key) <= 63 && length(value) <= 63
    ])
  )
}