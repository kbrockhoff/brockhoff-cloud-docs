# Cloud Provider-Specific Constraints and Naming Rules

This document provides comprehensive information about naming conventions, tagging constraints, and resource-specific requirements for AWS, Azure, and GCP when using Brockhoff Cloud Terraform modules with terraform-external-context integration.

## Table of Contents

- [Overview](#overview)
- [AWS Constraints](#aws-constraints)
- [Azure Constraints](#azure-constraints)
- [GCP Constraints](#gcp-constraints)
- [Cross-Cloud Compatibility](#cross-cloud-compatibility)
- [Implementation Patterns](#implementation-patterns)
- [Validation Examples](#validation-examples)
- [Troubleshooting](#troubleshooting)

## Overview

Each cloud provider has specific requirements for resource naming and metadata (tags/labels). The terraform-external-context module handles these differences automatically, but understanding the constraints helps in designing compatible naming schemes and avoiding validation errors.

### Key Differences Summary

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| **Naming Case** | Mixed case allowed | Mixed case allowed | Lowercase preferred |
| **Separators** | Hyphens (-) | Hyphens (-), Underscores (_) | Hyphens (-) |
| **Max Name Length** | 63 chars (most resources) | 80 chars (most resources) | 63 chars (most resources) |
| **Metadata Name** | Tags | Tags | Labels |
| **Max Metadata Count** | 50 | 50 | 64 |
| **Metadata Key Length** | 128 chars | 512 chars | 63 chars |
| **Metadata Value Length** | 256 chars | 256 chars | 63 chars |

## AWS Constraints

### General Naming Rules

```hcl
locals {
  aws_naming_constraints = {
    # General pattern for most AWS resources
    general_pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
    max_length = 63
    min_length = 1
    allowed_chars = "a-zA-Z0-9-"
    
    # Must start with letter
    # Must end with letter or number
    # Cannot have consecutive hyphens
    # Cannot start or end with hyphen
  }
}
```

### Resource-Specific Naming Rules

#### S3 Buckets
```hcl
locals {
  s3_constraints = {
    pattern = "^[a-z0-9][a-z0-9-]*[a-z0-9]$"
    max_length = 63
    min_length = 3
    
    # Additional rules:
    # - Globally unique across all AWS accounts
    # - Lowercase only
    # - No periods in bucket names (for SSL compatibility)
    # - Cannot be formatted as IP address
    # - Cannot start with 'xn--'
    # - Cannot end with '-s3alias'
  }
}

# S3 bucket naming implementation
resource "aws_s3_bucket" "example" {
  bucket = "${lower(local.name_prefix)}-bucket-${random_id.suffix.hex}"
  
  tags = local.common_tags
}
```

#### IAM Resources
```hcl
locals {
  iam_constraints = {
    # IAM roles, users, groups
    pattern = "^[a-zA-Z][a-zA-Z0-9+=,.@_-]*$"
    max_length = 64
    
    # IAM policies
    policy_pattern = "^[a-zA-Z][a-zA-Z0-9+=,.@_-]*$"
    policy_max_length = 128
  }
}

# IAM role naming implementation
resource "aws_iam_role" "example" {
  name = "${local.name_prefix}-role"
  
  # Validation
  lifecycle {
    precondition {
      condition = can(regex(local.iam_constraints.pattern, "${local.name_prefix}-role"))
      error_message = "IAM role name must match pattern: ${local.iam_constraints.pattern}"
    }
  }
  
  tags = local.common_tags
}
```

#### RDS Instances
```hcl
locals {
  rds_constraints = {
    pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
    max_length = 63
    
    # Additional rules:
    # - Cannot end with hyphen
    # - Cannot contain consecutive hyphens
    # - Must be unique within AWS account and region
  }
}
```

#### Lambda Functions
```hcl
locals {
  lambda_constraints = {
    pattern = "^[a-zA-Z0-9-_]*$"
    max_length = 64
    
    # Additional rules:
    # - Can contain letters, numbers, hyphens, and underscores
    # - Cannot start with number
  }
}
```

### AWS Tagging Constraints

```hcl
locals {
  aws_tag_constraints = {
    max_tags = 50
    max_key_length = 128
    max_value_length = 256
    
    # Reserved prefixes (cannot be used)
    reserved_prefixes = ["aws:", "AWS:"]
    
    # Case sensitive
    case_sensitive = true
    
    # Allowed characters in keys and values
    key_pattern = "^[a-zA-Z0-9\\s_.:/=+\\-@]*$"
    value_pattern = "^[a-zA-Z0-9\\s_.:/=+\\-@]*$"
  }
}

# Tag validation implementation
validation {
  condition = length(local.common_tags) <= local.aws_tag_constraints.max_tags
  error_message = "AWS resources support a maximum of ${local.aws_tag_constraints.max_tags} tags."
}

validation {
  condition = alltrue([
    for key, value in local.common_tags :
    length(key) <= local.aws_tag_constraints.max_key_length &&
    length(value) <= local.aws_tag_constraints.max_value_length &&
    !startswith(key, "aws:") &&
    !startswith(key, "AWS:") &&
    can(regex(local.aws_tag_constraints.key_pattern, key)) &&
    can(regex(local.aws_tag_constraints.value_pattern, value))
  ])
  error_message = "AWS tags must meet length and character requirements, and keys cannot start with 'aws:' or 'AWS:'."
}
```

### AWS Implementation Example

```hcl
# AWS-specific context configuration
module "aws_context" {
  source = "kbrockhoff/external-context/terraform"
  
  context = var.context
  
  # AWS-specific overrides
  label_value_case = "none"  # Allow mixed case
  delimiter = "-"            # Use hyphens
  
  # AWS-specific additional tags
  additional_tag_map = {
    CloudProvider = "AWS"
    ManagedBy     = "Terraform"
  }
}

locals {
  aws_name_prefix = module.aws_context.name_prefix
  aws_tags = module.aws_context.tags
  
  # Validate AWS naming
  aws_name_valid = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", local.aws_name_prefix))
  aws_name_length_ok = length(local.aws_name_prefix) <= 63
}
```

## Azure Constraints

### General Naming Rules

```hcl
locals {
  azure_naming_constraints = {
    # General pattern for most Azure resources
    general_pattern = "^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$"
    max_length = 80
    min_length = 1
    allowed_chars = "a-zA-Z0-9-_"
    
    # Must start with letter
    # Must end with letter or number
    # Can contain hyphens and underscores
  }
}
```

### Resource-Specific Naming Rules

#### Storage Accounts
```hcl
locals {
  azure_storage_constraints = {
    pattern = "^[a-z0-9]{3,24}$"
    max_length = 24
    min_length = 3
    
    # Additional rules:
    # - Lowercase letters and numbers only
    # - Globally unique across all Azure
    # - No hyphens, underscores, or special characters
  }
}

# Storage account naming implementation
resource "azurerm_storage_account" "example" {
  name = lower(replace("${local.azure_name_prefix}sa${random_id.suffix.hex}", "/[^a-z0-9]/", ""))
  
  # Ensure length constraints
  name = substr(local.storage_name, 0, min(24, length(local.storage_name)))
  
  tags = local.azure_tags
}
```

#### Resource Groups
```hcl
locals {
  azure_rg_constraints = {
    pattern = "^[a-zA-Z0-9][a-zA-Z0-9-_.()]*[a-zA-Z0-9_)]$"
    max_length = 90
    
    # Additional rules:
    # - Cannot end with period
    # - Can contain parentheses, periods, hyphens, underscores
  }
}
```

#### Virtual Machines
```hcl
locals {
  azure_vm_constraints = {
    pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
    max_length = 64
    
    # Additional rules:
    # - Cannot contain underscores
    # - Cannot end with hyphen or period
  }
}
```

#### Key Vault
```hcl
locals {
  azure_keyvault_constraints = {
    pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
    max_length = 24
    min_length = 3
    
    # Additional rules:
    # - Globally unique
    # - Cannot contain consecutive hyphens
    # - Cannot start or end with hyphen
  }
}
```

### Azure Tagging Constraints

```hcl
locals {
  azure_tag_constraints = {
    max_tags = 50
    max_key_length = 512
    max_value_length = 256
    
    # Case insensitive (Azure normalizes to lowercase)
    case_sensitive = false
    
    # Cannot use these names as tag keys
    reserved_keys = [
      "Name", "name", "NAME"  # Reserved by Azure
    ]
    
    # Allowed characters
    key_pattern = "^[^<>%&\\?/]*$"
    value_pattern = "^[^<>%&\\?/]*$"
  }
}

# Azure tag validation
validation {
  condition = length(local.azure_tags) <= local.azure_tag_constraints.max_tags
  error_message = "Azure resources support a maximum of ${local.azure_tag_constraints.max_tags} tags."
}

validation {
  condition = alltrue([
    for key, value in local.azure_tags :
    length(key) <= local.azure_tag_constraints.max_key_length &&
    length(value) <= local.azure_tag_constraints.max_value_length &&
    !contains(local.azure_tag_constraints.reserved_keys, lower(key)) &&
    can(regex(local.azure_tag_constraints.key_pattern, key)) &&
    can(regex(local.azure_tag_constraints.value_pattern, value))
  ])
  error_message = "Azure tags must meet length and character requirements, and cannot use reserved key names."
}
```

### Azure Implementation Example

```hcl
# Azure-specific context configuration
module "azure_context" {
  source = "kbrockhoff/external-context/terraform"
  
  context = var.context
  
  # Azure-specific overrides
  delimiter = "_"            # Use underscores (allowed in Azure)
  label_value_case = "none"  # Allow mixed case
  
  # Azure-specific additional tags
  additional_tag_map = {
    CloudProvider = "Azure"
    ManagedBy     = "Terraform"
  }
}

locals {
  azure_name_prefix = module.azure_context.name_prefix
  azure_tags = module.azure_context.tags
  
  # Special handling for storage account names
  azure_storage_name = lower(replace("${local.azure_name_prefix}sa${random_id.suffix.hex}", "/[^a-z0-9]/", ""))
  azure_storage_name_final = substr(local.azure_storage_name, 0, min(24, length(local.azure_storage_name)))
  
  # Validate Azure naming
  azure_name_valid = can(regex("^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$", local.azure_name_prefix))
  azure_storage_valid = can(regex("^[a-z0-9]{3,24}$", local.azure_storage_name_final))
}
```

## GCP Constraints

### General Naming Rules

```hcl
locals {
  gcp_naming_constraints = {
    # General pattern for most GCP resources
    general_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    max_length = 63
    min_length = 1
    allowed_chars = "a-z0-9-"
    
    # Must start with lowercase letter
    # Must end with lowercase letter or number
    # Lowercase only for most resources
    # Cannot have consecutive hyphens
  }
}
```

### Resource-Specific Naming Rules

#### Storage Buckets
```hcl
locals {
  gcp_bucket_constraints = {
    pattern = "^[a-z0-9][a-z0-9-._]*[a-z0-9]$"
    max_length = 63
    min_length = 3
    
    # Additional rules:
    # - Globally unique across all GCP
    # - Can contain periods (but not recommended for SSL)
    # - Cannot contain 'google' or close misspellings
    # - Cannot be formatted as IP address
  }
}

# GCP bucket naming implementation
resource "google_storage_bucket" "example" {
  name = "${lower(local.gcp_name_prefix)}-bucket-${random_id.suffix.hex}"
  
  labels = local.gcp_labels
}
```

#### Compute Instances
```hcl
locals {
  gcp_instance_constraints = {
    pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    max_length = 63
    
    # Additional rules:
    # - Must be unique within project and zone
    # - Cannot contain consecutive hyphens
  }
}
```

#### Service Accounts
```hcl
locals {
  gcp_sa_constraints = {
    pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    max_length = 30  # Note: shorter than general limit
    min_length = 6
    
    # Additional rules:
    # - Must be unique within project
    # - Cannot end with '-compute@developer.gserviceaccount.com'
  }
}
```

#### Projects
```hcl
locals {
  gcp_project_constraints = {
    pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    max_length = 30
    min_length = 6
    
    # Additional rules:
    # - Globally unique across all GCP
    # - Cannot be changed after creation
    # - Cannot contain 'google' or 'ssl'
  }
}
```

### GCP Labeling Constraints

```hcl
locals {
  gcp_label_constraints = {
    max_labels = 64
    max_key_length = 63
    max_value_length = 63
    
    # Case sensitive but lowercase recommended
    case_sensitive = true
    
    # Key and value patterns
    key_pattern = "^[a-z][a-z0-9_-]*$"
    value_pattern = "^[a-z0-9_-]*$"
    
    # Reserved prefixes
    reserved_prefixes = ["goog-", "google-"]
  }
}

# GCP label validation
validation {
  condition = length(local.gcp_labels) <= local.gcp_label_constraints.max_labels
  error_message = "GCP resources support a maximum of ${local.gcp_label_constraints.max_labels} labels."
}

validation {
  condition = alltrue([
    for key, value in local.gcp_labels :
    length(key) <= local.gcp_label_constraints.max_key_length &&
    length(value) <= local.gcp_label_constraints.max_value_length &&
    !startswith(key, "goog-") &&
    !startswith(key, "google-") &&
    can(regex(local.gcp_label_constraints.key_pattern, key)) &&
    can(regex(local.gcp_label_constraints.value_pattern, value))
  ])
  error_message = "GCP labels must meet length and character requirements, and keys cannot start with 'goog-' or 'google-'."
}
```

### GCP Implementation Example

```hcl
# GCP-specific context configuration
module "gcp_context" {
  source = "kbrockhoff/external-context/terraform"
  
  context = var.context
  
  # GCP-specific overrides
  label_key_case = "lower"    # Force lowercase keys
  label_value_case = "lower"  # Force lowercase values
  delimiter = "-"             # Use hyphens
  
  # Convert underscores to hyphens for GCP compatibility
  regex_replace_chars = "/[_]/"
  
  # GCP-specific additional labels
  additional_tag_map = {
    cloud_provider = "gcp"
    managed_by     = "terraform"
  }
}

locals {
  gcp_name_prefix = module.gcp_context.name_prefix
  gcp_tags = module.gcp_context.tags
  
  # Convert tags to labels (GCP terminology)
  gcp_labels = {
    for key, value in local.gcp_tags :
    lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
  }
  
  # Validate GCP naming
  gcp_name_valid = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.gcp_name_prefix))
  gcp_name_length_ok = length(local.gcp_name_prefix) <= 63
}
```

## Cross-Cloud Compatibility

### Recommended Naming Strategy

To ensure compatibility across all cloud providers:

```hcl
# Cross-cloud compatible context configuration
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  # Keep components short for compatibility
  namespace   = "myorg"    # ≤ 10 chars recommended
  environment = "prod"     # ≤ 8 chars recommended  
  name        = "webapp"   # ≤ 15 chars recommended
  
  # Use conservative settings
  id_length_limit = 50     # Well under all limits
  delimiter = "-"          # Supported by all clouds
  
  # Clean up problematic characters
  regex_replace_chars = "/[^a-zA-Z0-9-]/"
  
  # Use lowercase for maximum compatibility
  label_key_case = "lower"
  label_value_case = "lower"
}
```

### Cross-Cloud Tag/Label Strategy

```hcl
locals {
  # Base tags that work across all clouds
  base_tags = {
    project     = "myapp"
    environment = "production"
    owner       = "devteam"
    managed_by  = "terraform"
  }
  
  # Cloud-specific tag additions
  aws_specific_tags = {
    CloudProvider = "AWS"
    BackupPolicy  = "Daily"
  }
  
  azure_specific_tags = {
    CloudProvider = "Azure"
    CostCenter    = "Engineering"
  }
  
  gcp_specific_labels = {
    cloud_provider = "gcp"
    billing_code   = "eng001"
  }
  
  # Merge based on cloud provider
  final_tags = merge(
    local.base_tags,
    local.cloud_provider == "aws" ? local.aws_specific_tags : {},
    local.cloud_provider == "azure" ? local.azure_specific_tags : {},
    local.cloud_provider == "gcp" ? local.gcp_specific_labels : {}
  )
}
```

### Multi-Cloud Validation

```hcl
# Universal validation that works for all clouds
validation {
  condition = alltrue([
    # Name length compatible with all clouds
    length(local.name_prefix) <= 50,
    
    # Name pattern compatible with all clouds (most restrictive)
    can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", lower(local.name_prefix))),
    
    # Tag/label count within all limits
    length(local.tags) <= 50,
    
    # Tag key/value lengths within all limits
    alltrue([
      for key, value in local.tags :
      length(key) <= 63 && length(value) <= 63
    ])
  ])
  error_message = "Configuration must be compatible with AWS, Azure, and GCP constraints."
}
```

## Implementation Patterns

### Cloud Provider Detection

```hcl
# Automatic cloud provider detection
data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" || var.cloud_provider == null ? 1 : 0
}

data "azurerm_client_config" "current" {
  count = var.cloud_provider == "azure" || var.cloud_provider == null ? 1 : 0
}

data "google_client_config" "current" {
  count = var.cloud_provider == "gcp" || var.cloud_provider == null ? 1 : 0
}

locals {
  detected_cloud_provider = (
    length(data.aws_caller_identity.current) > 0 ? "aws" :
    length(data.azurerm_client_config.current) > 0 ? "azure" :
    length(data.google_client_config.current) > 0 ? "gcp" :
    "unknown"
  )
  
  cloud_provider = var.cloud_provider != null ? var.cloud_provider : local.detected_cloud_provider
}
```

### Dynamic Constraint Application

```hcl
locals {
  # Cloud-specific constraints
  constraints = {
    aws = {
      max_name_length = 63
      name_pattern = "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"
      max_tags = 50
      tag_key_max_length = 128
      tag_value_max_length = 256
    }
    azure = {
      max_name_length = 80
      name_pattern = "^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$"
      max_tags = 50
      tag_key_max_length = 512
      tag_value_max_length = 256
    }
    gcp = {
      max_name_length = 63
      name_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
      max_labels = 64
      label_key_max_length = 63
      label_value_max_length = 63
    }
  }
  
  # Apply constraints based on detected cloud provider
  active_constraints = local.constraints[local.cloud_provider]
}

# Dynamic validation
validation {
  condition = can(regex(local.active_constraints.name_pattern, local.name_prefix))
  error_message = "Name '${local.name_prefix}' does not match ${local.cloud_provider} naming pattern: ${local.active_constraints.name_pattern}"
}

validation {
  condition = length(local.name_prefix) <= local.active_constraints.max_name_length
  error_message = "Name '${local.name_prefix}' exceeds ${local.cloud_provider} maximum length of ${local.active_constraints.max_name_length} characters."
}
```

### Resource-Specific Naming Functions

```hcl
locals {
  # Helper functions for resource-specific naming
  naming_functions = {
    # AWS S3 bucket naming
    aws_s3_bucket = "${lower(local.name_prefix)}-bucket-${random_id.suffix.hex}"
    
    # Azure storage account naming
    azure_storage = substr(
      lower(replace("${local.name_prefix}sa${random_id.suffix.hex}", "/[^a-z0-9]/", "")),
      0, 24
    )
    
    # GCP bucket naming
    gcp_bucket = "${lower(local.name_prefix)}-bucket-${random_id.suffix.hex}"
    
    # Generic resource naming
    generic = local.name_prefix
  }
  
  # Select appropriate naming based on resource type and cloud
  resource_names = {
    storage_bucket = (
      local.cloud_provider == "aws" ? local.naming_functions.aws_s3_bucket :
      local.cloud_provider == "azure" ? local.naming_functions.azure_storage :
      local.cloud_provider == "gcp" ? local.naming_functions.gcp_bucket :
      local.naming_functions.generic
    )
  }
}
```

## Validation Examples

### Complete Validation Implementation

```hcl
# Complete validation for all cloud providers
locals {
  validation_results = {
    aws = var.cloud_provider == "aws" ? {
      name_valid = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", local.name_prefix))
      name_length_ok = length(local.name_prefix) <= 63
      tags_count_ok = length(local.tags) <= 50
      tags_valid = alltrue([
        for key, value in local.tags :
        length(key) <= 128 &&
        length(value) <= 256 &&
        !startswith(key, "aws:") &&
        !startswith(key, "AWS:")
      ])
    } : null
    
    azure = var.cloud_provider == "azure" ? {
      name_valid = can(regex("^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$", local.name_prefix))
      name_length_ok = length(local.name_prefix) <= 80
      tags_count_ok = length(local.tags) <= 50
      tags_valid = alltrue([
        for key, value in local.tags :
        length(key) <= 512 &&
        length(value) <= 256 &&
        !contains(["name", "Name", "NAME"], key)
      ])
      storage_name_valid = can(regex("^[a-z0-9]{3,24}$", local.azure_storage_name))
    } : null
    
    gcp = var.cloud_provider == "gcp" ? {
      name_valid = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.name_prefix))
      name_length_ok = length(local.name_prefix) <= 63
      labels_count_ok = length(local.gcp_labels) <= 64
      labels_valid = alltrue([
        for key, value in local.gcp_labels :
        length(key) <= 63 &&
        length(value) <= 63 &&
        can(regex("^[a-z][a-z0-9_-]*$", key)) &&
        can(regex("^[a-z0-9_-]*$", value)) &&
        !startswith(key, "goog-") &&
        !startswith(key, "google-")
      ])
    } : null
  }
}

# Output validation results for debugging
output "validation_results" {
  description = "Validation results for the current cloud provider"
  value = local.validation