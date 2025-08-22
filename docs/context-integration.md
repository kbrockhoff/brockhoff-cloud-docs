# terraform-external-context Integration Guide

This guide explains how to integrate the `terraform-external-context` module into all Brockhoff Cloud Terraform modules to ensure consistent naming, tagging, and configuration across multi-cloud deployments.

## Overview

The `terraform-external-context` module provides a standardized approach to:
- Resource naming with organization-specific prefixes
- Consistent tagging across all resources
- Environment-specific configuration defaults
- Cloud provider-specific constraints and validation

## Table of Contents

- [Basic Integration](#basic-integration)
- [Context Variable Passing](#context-variable-passing)
- [Environment-Specific Configuration](#environment-specific-configuration)
- [Cloud Provider-Specific Constraints](#cloud-provider-specific-constraints)
- [Tag Management](#tag-management)
- [Naming Conventions](#naming-conventions)
- [Override Patterns](#override-patterns)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Basic Integration

Every Brockhoff Cloud module must integrate the terraform-external-context module as follows:

### Module Structure

```hcl
# main.tf - Required context module integration
module "context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  # Context passed from parent or set directly
  context = var.context
  
  # Override specific values if needed
  name           = var.name
  environment    = var.environment
  cloud_provider = local.cloud_provider
}

locals {
  # Use context-generated values throughout the module
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
  data_tags   = module.context.data_tags
  
  # Cloud provider detection
  cloud_provider = var.cloud_provider != null ? var.cloud_provider : local.detected_cloud_provider
  
  # Detected cloud provider based on providers
  detected_cloud_provider = (
    can(data.aws_caller_identity.current) ? "aws" :
    can(data.azurerm_client_config.current) ? "azure" :
    can(data.google_client_config.current) ? "gcp" :
    "unknown"
  )
}
```

### Required Variables

```hcl
# variables.tf - Standard context variables
variable "context" {
  description = "Single object for setting entire context at once. See terraform-external-context module for details."
  type = object({
    enabled             = bool
    namespace           = string
    tenant              = string
    environment         = string
    stage               = string
    name                = string
    delimiter           = string
    attributes          = list(string)
    tags                = map(string)
    additional_tag_map  = map(string)
    regex_replace_chars = string
    label_order         = list(string)
    id_length_limit     = number
    label_key_case      = string
    label_value_case    = string
    descriptor_formats  = any
    labels_as_tags      = set(string)
  })
  default = {
    enabled             = true
    namespace           = null
    tenant              = null
    environment         = null
    stage               = null
    name                = null
    delimiter           = null
    attributes          = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = null
    label_order         = []
    id_length_limit     = null
    label_key_case      = null
    label_value_case    = null
    descriptor_formats  = {}
    labels_as_tags      = ["default"]
  }
}

variable "name" {
  description = "ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'."
  type        = string
  default     = null
}

variable "environment" {
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'."
  type        = string
  default     = null
}

variable "cloud_provider" {
  description = "Cloud provider identifier (aws, azure, gcp). Auto-detected if not specified."
  type        = string
  default     = null
  validation {
    condition = var.cloud_provider == null || contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp."
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

variable "tags" {
  description = "Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`)."
  type        = map(string)
  default     = {}
}

variable "data_tags" {
  description = "Additional tags to apply specifically to data storage resources beyond the common tags"
  type        = map(string)
  default     = {}
}
```

## Context Variable Passing

### Parent-Child Module Pattern

When composing modules, pass context from parent to child:

```hcl
# Parent module
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace   = "brockhoff"
  environment = "prod"
  name        = "webapp"
  
  tags = {
    Project = "MyApp"
    Owner   = "DevTeam"
  }
}

# Child modules inherit context
module "networking" {
  source = "kbrockhoff/networking/aws"
  
  context = module.context.context
  
  # Module-specific variables
  vpc_cidr = "10.0.0.0/16"
}

module "compute" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  
  # Module-specific variables
  instance_type = "t3.medium"
  
  # Override specific context values if needed
  name = "web-server"  # This will override the context name for this module only
}
```

### Direct Context Configuration

For standalone module usage:

```hcl
module "database" {
  source = "kbrockhoff/database/aws"
  
  # Direct context configuration
  namespace   = "myorg"
  environment = "staging"
  name        = "userdb"
  
  tags = {
    Project     = "UserService"
    Environment = "staging"
    Owner       = "DataTeam"
  }
  
  # Module-specific configuration
  engine         = "postgres"
  instance_class = "db.t3.micro"
}
```

## Environment-Specific Configuration

The context integration provides environment-specific defaults:

```hcl
locals {
  # Environment-specific configuration matrix
  environment_defaults = {
    None = {
      rpo_hours                    = null
      rto_hours                    = null
      monitoring_enabled           = var.monitoring_config.enabled
      alarms_enabled               = var.alarms_config.enabled
      kms_key_deletion_window_days = var.encryption_config.kms_key_deletion_window_days
      backup_retention_days        = 7
      multi_az                     = false
      instance_size_multiplier     = 1.0
    }
    Ephemeral = {
      rpo_hours                    = null
      rto_hours                    = 48
      monitoring_enabled           = false
      alarms_enabled               = false
      kms_key_deletion_window_days = 7
      backup_retention_days        = 1
      multi_az                     = false
      instance_size_multiplier     = 0.5  # Smaller instances for ephemeral
    }
    Development = {
      rpo_hours                    = 24
      rto_hours                    = 48
      monitoring_enabled           = false
      alarms_enabled               = false
      kms_key_deletion_window_days = 7
      backup_retention_days        = 7
      multi_az                     = false
      instance_size_multiplier     = 0.75  # Smaller instances for dev
    }
    Testing = {
      rpo_hours                    = 12
      rto_hours                    = 24
      monitoring_enabled           = true
      alarms_enabled               = false
      kms_key_deletion_window_days = 14
      backup_retention_days        = 14
      multi_az                     = false
      instance_size_multiplier     = 0.75
    }
    UAT = {
      rpo_hours                    = 4
      rto_hours                    = 8
      monitoring_enabled           = true
      alarms_enabled               = true
      kms_key_deletion_window_days = 21
      backup_retention_days        = 30
      multi_az                     = true
      instance_size_multiplier     = 1.0
    }
    Production = {
      rpo_hours                    = 1
      rto_hours                    = 4
      monitoring_enabled           = true
      alarms_enabled               = true
      kms_key_deletion_window_days = 30
      backup_retention_days        = 90
      multi_az                     = true
      instance_size_multiplier     = 1.0
    }
    MissionCritical = {
      rpo_hours                    = 0.083  # 5 minutes
      rto_hours                    = 1
      monitoring_enabled           = true
      alarms_enabled               = true
      kms_key_deletion_window_days = 30
      backup_retention_days        = 365
      multi_az                     = true
      instance_size_multiplier     = 1.5  # Larger instances for mission critical
    }
  }
  
  # Apply environment-specific configuration
  effective_config = var.environment_type == "None" ? (
    local.environment_defaults.None
  ) : (
    local.environment_defaults[var.environment_type]
  )
}
```

### Using Environment Configuration

```hcl
# Apply environment-specific settings to resources
resource "aws_db_instance" "main" {
  count = var.enabled ? 1 : 0
  
  identifier = local.name_prefix
  
  # Use environment-specific configuration
  backup_retention_period = local.effective_config.backup_retention_days
  multi_az               = local.effective_config.multi_az
  deletion_protection    = var.environment_type == "Production" || var.environment_type == "MissionCritical"
  
  # Apply environment-based instance sizing
  instance_class = local.sized_instance_class
  
  tags = local.common_tags
}

locals {
  # Calculate instance size based on environment
  base_instance_class = var.instance_class != null ? var.instance_class : "db.t3.micro"
  sized_instance_class = local.calculate_instance_size(
    local.base_instance_class,
    local.effective_config.instance_size_multiplier
  )
}
```

## Cloud Provider-Specific Constraints

### AWS Constraints

```hcl
# AWS-specific validation and constraints
locals {
  aws_constraints = {
    # AWS resource naming constraints
    max_name_length = 63
    allowed_name_chars = "a-z0-9-"
    name_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    
    # AWS tag constraints
    max_tags = 50
    max_tag_key_length = 128
    max_tag_value_length = 256
    reserved_tag_prefixes = ["aws:", "AWS:"]
    
    # AWS-specific required tags
    required_tags = ["Environment", "Project", "Owner"]
  }
}

# AWS name validation
validation {
  condition = can(regex(local.aws_constraints.name_pattern, local.name_prefix))
  error_message = "AWS resource names must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
}

# AWS tag validation
validation {
  condition = length(local.common_tags) <= local.aws_constraints.max_tags
  error_message = "AWS resources support a maximum of ${local.aws_constraints.max_tags} tags."
}

validation {
  condition = alltrue([
    for key, value in local.common_tags :
    length(key) <= local.aws_constraints.max_tag_key_length &&
    length(value) <= local.aws_constraints.max_tag_value_length &&
    !startswith(key, "aws:") &&
    !startswith(key, "AWS:")
  ])
  error_message = "AWS tag keys must be ≤128 chars, values ≤256 chars, and keys cannot start with 'aws:' or 'AWS:'."
}
```

### Azure Constraints

```hcl
# Azure-specific validation and constraints
locals {
  azure_constraints = {
    # Azure resource naming constraints
    max_name_length = 80
    allowed_name_chars = "a-zA-Z0-9-_"
    name_pattern = "^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$"
    
    # Azure tag constraints
    max_tags = 50
    max_tag_key_length = 512
    max_tag_value_length = 256
    
    # Azure-specific required tags
    required_tags = ["Environment", "Project", "CostCenter"]
  }
}

# Azure name validation
validation {
  condition = can(regex(local.azure_constraints.name_pattern, local.name_prefix))
  error_message = "Azure resource names must start with a letter, contain only letters, numbers, hyphens, and underscores, and end with a letter or number."
}

# Azure tag validation
validation {
  condition = length(local.common_tags) <= local.azure_constraints.max_tags
  error_message = "Azure resources support a maximum of ${local.azure_constraints.max_tags} tags."
}
```

### GCP Constraints

```hcl
# GCP-specific validation and constraints
locals {
  gcp_constraints = {
    # GCP resource naming constraints (labels are used for tagging)
    max_name_length = 63
    allowed_name_chars = "a-z0-9-"
    name_pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
    
    # GCP label constraints
    max_labels = 64
    max_label_key_length = 63
    max_label_value_length = 63
    label_pattern = "^[a-z][a-z0-9_-]*$"
    
    # GCP-specific required labels
    required_labels = ["environment", "project", "team"]
  }
}

# GCP name validation
validation {
  condition = can(regex(local.gcp_constraints.name_pattern, local.name_prefix))
  error_message = "GCP resource names must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
}

# GCP label validation
validation {
  condition = length(local.common_labels) <= local.gcp_constraints.max_labels
  error_message = "GCP resources support a maximum of ${local.gcp_constraints.max_labels} labels."
}

validation {
  condition = alltrue([
    for key, value in local.common_labels :
    can(regex(local.gcp_constraints.label_pattern, key)) &&
    can(regex(local.gcp_constraints.label_pattern, value)) &&
    length(key) <= local.gcp_constraints.max_label_key_length &&
    length(value) <= local.gcp_constraints.max_label_value_length
  ])
  error_message = "GCP label keys and values must start with lowercase letter, contain only lowercase letters, numbers, underscores, and hyphens, and be ≤63 characters."
}

# Convert tags to GCP labels (lowercase)
locals {
  common_labels = {
    for key, value in local.common_tags :
    lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
  }
}
```

## Tag Management

### Standard Tag Structure

```hcl
locals {
  # Base tags from context module
  base_tags = module.context.tags
  
  # Module-specific tags
  module_tags = {
    ModuleName    = "kbrockhoff/${local.module_name}/${local.cloud_provider}"
    ModuleVersion = local.module_version
    ModuleEnvType = var.environment_type
  }
  
  # Compliance and governance tags
  governance_tags = {
    CreatedBy     = "terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    LastModified  = formatdate("YYYY-MM-DD", timestamp())
    BackupPolicy  = local.effective_config.backup_retention_days > 0 ? "enabled" : "disabled"
    MonitoringEnabled = local.effective_config.monitoring_enabled ? "true" : "false"
  }
  
  # Cost allocation tags
  cost_tags = var.environment_type != "None" ? {
    CostCenter    = var.cost_center != null ? var.cost_center : "unknown"
    BillingCode   = var.billing_code != null ? var.billing_code : "default"
    Environment   = var.environment_type
  } : {}
  
  # Combine all tags
  common_tags = merge(
    local.base_tags,
    local.module_tags,
    local.governance_tags,
    local.cost_tags,
    var.tags
  )
  
  # Data-specific tags (for storage resources)
  common_data_tags = merge(
    local.common_tags,
    var.data_tags,
    {
      DataClassification = var.data_classification != null ? var.data_classification : "internal"
      RetentionPolicy    = "${local.effective_config.backup_retention_days}days"
    }
  )
}
```

### Cloud Provider Tag Application

```hcl
# AWS - Apply tags to resources
resource "aws_instance" "main" {
  count = var.enabled ? 1 : 0
  
  # Resource configuration...
  
  tags = local.common_tags
  
  # Volume tags
  volume_tags = local.common_data_tags
}

# Azure - Apply tags to resources
resource "azurerm_virtual_machine" "main" {
  count = var.enabled ? 1 : 0
  
  # Resource configuration...
  
  tags = local.common_tags
}

# GCP - Apply labels to resources
resource "google_compute_instance" "main" {
  count = var.enabled ? 1 : 0
  
  # Resource configuration...
  
  labels = local.common_labels
}
```

## Naming Conventions

### Name Generation Pattern

```hcl
locals {
  # Module identification
  module_name = "compute"  # Set per module
  module_version = "1.0.0"  # From version.tf or CI
  
  # Generated names using context
  resource_names = {
    # Primary resource name
    primary = local.name_prefix
    
    # Secondary resource names with suffixes
    security_group = "${local.name_prefix}-sg"
    load_balancer  = "${local.name_prefix}-lb"
    database       = "${local.name_prefix}-db"
    
    # Cloud provider specific naming
    aws = {
      iam_role   = "${local.name_prefix}-role"
      kms_key    = "${local.name_prefix}-key"
      s3_bucket  = "${local.name_prefix}-${random_id.bucket_suffix.hex}"
    }
    
    azure = {
      resource_group = "${local.name_prefix}-rg"
      key_vault      = "${local.name_prefix}-kv-${random_id.vault_suffix.hex}"
      storage_account = replace("${local.name_prefix}sa${random_id.storage_suffix.hex}", "-", "")
    }
    
    gcp = {
      project_id = "${local.name_prefix}-${random_id.project_suffix.hex}"
      bucket     = "${local.name_prefix}-bucket-${random_id.bucket_suffix.hex}"
    }
  }
}

# Random suffixes for globally unique names
resource "random_id" "bucket_suffix" {
  count       = var.enabled ? 1 : 0
  byte_length = 4
  
  keepers = {
    name_prefix = local.name_prefix
  }
}
```

### Name Validation

```hcl
# Validate generated names against cloud provider constraints
locals {
  name_validations = {
    aws = {
      valid_primary_name = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", local.name_prefix))
      valid_s3_name      = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.resource_names.aws.s3_bucket))
      name_length_ok     = length(local.name_prefix) <= 63
    }
    
    azure = {
      valid_primary_name = can(regex("^[a-zA-Z][a-zA-Z0-9-_]*[a-zA-Z0-9]$", local.name_prefix))
      valid_storage_name = can(regex("^[a-z0-9]{3,24}$", local.resource_names.azure.storage_account))
      name_length_ok     = length(local.name_prefix) <= 80
    }
    
    gcp = {
      valid_primary_name = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.name_prefix))
      valid_project_name = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.resource_names.gcp.project_id))
      name_length_ok     = length(local.name_prefix) <= 63
    }
  }
}

# Validation checks
validation {
  condition = local.name_validations[local.cloud_provider].valid_primary_name
  error_message = "Generated name '${local.name_prefix}' does not meet ${local.cloud_provider} naming requirements."
}

validation {
  condition = local.name_validations[local.cloud_provider].name_length_ok
  error_message = "Generated name '${local.name_prefix}' exceeds maximum length for ${local.cloud_provider}."
}
```

## Override Patterns

### Context Override Examples

```hcl
# Example 1: Override specific context values
module "special_database" {
  source = "kbrockhoff/database/aws"
  
  # Inherit most context from parent
  context = module.context.context
  
  # Override specific values
  name = "analytics-db"  # Different name for this specific database
  
  # Add additional tags
  tags = {
    Purpose = "Analytics"
    DataRetention = "7years"
  }
}

# Example 2: Environment-specific overrides
module "production_compute" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  
  # Override environment type for specific requirements
  environment_type = "MissionCritical"  # Even if parent context is "Production"
  
  # Production-specific configuration
  instance_type = "m5.xlarge"
  monitoring_config = {
    enabled = true
    detailed_monitoring = true
  }
}

# Example 3: Multi-region deployment with context inheritance
module "primary_region" {
  source = "kbrockhoff/web-app/aws"
  
  providers = {
    aws = aws.us_east_1
  }
  
  context = module.context.context
  environment = "us-east-1"  # Override environment for region
}

module "secondary_region" {
  source = "kbrockhoff/web-app/aws"
  
  providers = {
    aws = aws.us_west_2
  }
  
  context = module.context.context
  environment = "us-west-2"  # Override environment for region
  
  # Disaster recovery specific configuration
  environment_type = "Production"  # Maintain production standards
  
  tags = {
    Purpose = "DisasterRecovery"
    PrimaryRegion = "us-east-1"
  }
}
```

### Variable Override Hierarchy

The override hierarchy follows this precedence (highest to lowest):

1. **Direct variable assignment** - `name = "override-value"`
2. **Module-level context override** - Values in the `context` object
3. **Parent context inheritance** - Context passed from parent modules
4. **Default values** - Variable defaults and context module defaults

```hcl
# Example showing override hierarchy
module "example" {
  source = "kbrockhoff/compute/aws"
  
  # 3. Parent context (lowest precedence)
  context = module.parent_context.context  # namespace = "parent"
  
  # 2. Module context override (medium precedence)
  context = {
    namespace = "override"  # This overrides parent context
    tags = {
      Team = "DevOps"
    }
  }
  
  # 1. Direct variable (highest precedence)
  name = "special-server"  # This overrides any context name
  
  tags = {
    Purpose = "Testing"  # This merges with context tags
  }
}
```

## Examples

### Example 1: Basic Single Module

```hcl
# Simple standalone module usage
module "web_server" {
  source = "kbrockhoff/compute/aws"
  version = "~> 1.0"
  
  # Direct context configuration
  namespace   = "mycompany"
  environment = "production"
  name        = "web-server"
  
  # Standard tags
  tags = {
    Project = "WebApp"
    Owner   = "DevTeam"
    Purpose = "WebServer"
  }
  
  # Module-specific configuration
  instance_type = "t3.medium"
  environment_type = "Production"
  
  encryption_config = {
    create_kms_key = true
    kms_key_deletion_window_days = 30
  }
  
  monitoring_config = {
    enabled = true
  }
}
```

### Example 2: Multi-Module Composition

```hcl
# Parent context for consistent naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  namespace   = "brockhoff"
  tenant      = "platform"
  environment = "prod"
  stage       = "web"
  name        = "ecommerce"
  
  tags = {
    Project     = "ECommerce"
    Owner       = "PlatformTeam"
    Environment = "Production"
    CostCenter  = "Engineering"
  }
}

# Networking foundation
module "networking" {
  source = "kbrockhoff/networking/aws"
  version = "~> 1.0"
  
  context = module.context.context
  name    = "network"  # Override name for this component
  
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  environment_type = "Production"
}

# Security groups
module "security" {
  source = "kbrockhoff/security/aws"
  version = "~> 1.0"
  
  context = module.context.context
  name    = "security"
  
  vpc_id = module.networking.vpc_id
  
  # Security-specific tags
  tags = {
    SecurityLevel = "High"
    Compliance    = "SOC2"
  }
}

# Application load balancer
module "load_balancer" {
  source = "kbrockhoff/load-balancer/aws"
  version = "~> 1.0"
  
  context = module.context.context
  name    = "alb"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  
  environment_type = "Production"
}

# Web servers
module "web_servers" {
  source = "kbrockhoff/compute/aws"
  version = "~> 1.0"
  
  context = module.context.context
  name    = "web"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.security.web_security_group_id]
  
  instance_type    = "t3.medium"
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  environment_type = "Production"
  
  # Web server specific tags
  tags = {
    Tier = "Web"
    AutoScaling = "Enabled"
  }
}

# Database
module "database" {
  source = "kbrockhoff/database/aws"
  version = "~> 1.0"
  
  context = module.context.context
  name    = "db"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.database_subnet_ids
  security_group_ids = [module.security.db_security_group_id]
  
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  
  environment_type = "Production"
  
  # Database-specific data tags
  data_tags = {
    DataClassification = "Confidential"
    BackupFrequency   = "Hourly"
    EncryptionLevel   = "AES256"
  }
}
```

### Example 3: Multi-Cloud Deployment

```hcl
# Shared context for multi-cloud consistency
module "global_context" {
  source = "kbrockhoff/external-context/terraform"
  version = "~> 1.0"
  
  namespace   = "brockhoff"
  environment = "prod"
  name        = "global-app"
  
  tags = {
    Project      = "GlobalApp"
    Owner        = "CloudTeam"
    MultiCloud   = "true"
    Architecture = "Distributed"
  }
}

# AWS deployment (primary)
module "aws_deployment" {
  source = "kbrockhoff/web-app/aws"
  version = "~> 1.0"
  
  providers = {
    aws = aws.us_east_1
  }
  
  context = module.global_context.context
  environment = "aws-us-east-1"  # Cloud-specific environment
  
  # AWS-specific configuration
  instance_type = "t3.medium"
  environment_type = "Production"
  
  tags = {
    CloudProvider = "AWS"
    Region        = "us-east-1"
    Role          = "Primary"
  }
}

# Azure deployment (secondary)
module "azure_deployment" {
  source = "kbrockhoff/web-app/azurerm"
  version = "~> 1.0"
  
  providers = {
    azurerm = azurerm.east_us
  }
  
  context = module.global_context.context
  environment = "azure-east-us"  # Cloud-specific environment
  
  # Azure-specific configuration
  vm_size = "Standard_B2s"
  environment_type = "Production"
  
  tags = {
    CloudProvider = "Azure"
    Region        = "East US"
    Role          = "Secondary"
  }
}

# GCP deployment (tertiary)
module "gcp_deployment" {
  source = "kbrockhoff/web-app/google"
  version = "~> 1.0"
  
  providers = {
    google = google.us_central1
  }
  
  context = module.global_context.context
  environment = "gcp-us-central1"  # Cloud-specific environment
  
  # GCP-specific configuration
  machine_type = "e2-medium"
  environment_type = "Production"
  
  # GCP uses labels instead of tags
  labels = {
    cloud_provider = "gcp"
    region         = "us-central1"
    role           = "tertiary"
  }
}
```

## Best Practices

### 1. Always Use Context Module

```hcl
# ✅ GOOD: Always integrate context module
module "context" {
  source = "kbrockhoff/external-context/terraform"
  # ... configuration
}

locals {
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
}

# ❌ BAD: Manual naming and tagging
locals {
  name_prefix = "${var.namespace}-${var.environment}-${var.name}"
  tags = {
    Name = var.name
    Environment = var.environment
  }
}
```

### 2. Consistent Variable Naming

```hcl
# ✅ GOOD: Use standard context variables
variable "context" { ... }
variable "name" { ... }
variable "environment" { ... }
variable "tags" { ... }

# ❌ BAD: Non-standard variable names
variable "app_name" { ... }
variable "env" { ... }
variable "labels" { ... }
```

### 3. Environment-Specific Configuration

```hcl
# ✅ GOOD: Use environment_type for configuration
locals {
  backup_enabled = var.environment_type == "Production" || var.environment_type == "MissionCritical"
  monitoring_enabled = contains(["Production", "MissionCritical", "UAT"], var.environment_type)
}

# ❌ BAD: Hard-coded environment checks
locals {
  backup_enabled = var.environment == "prod"
  monitoring_enabled = var.environment != "dev"
}
```

### 4. Cloud Provider Detection

```hcl
# ✅ GOOD: Automatic cloud provider detection
locals {
  cloud_provider = var.cloud_provider != null ? var.cloud_provider : (
    can(data.aws_caller_identity.current) ? "aws" :
    can(data.azurerm_client_config.current) ? "azure" :
    can(data.google_client_config.current) ? "gcp" :
    "unknown"
  )
}

# ❌ BAD: Hard-coded cloud provider
locals {
  cloud_provider = "aws"
}
```

### 5. Tag Inheritance and Merging

```hcl
# ✅ GOOD: Proper tag merging with precedence
locals {
  common_tags = merge(
    module.context.tags,      # Base tags
    local.module_tags,        # Module-specific tags
    var.tags                  # User override tags
  )
}

# ❌ BAD: Overwriting tags
locals {
  common_tags = var.tags
}
```

### 6. Validation and Error Messages

```hcl
# ✅ GOOD: Clear validation with helpful error messages
validation {
  condition = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.name_prefix))
  error_message = <<-EOT
    Generated name '${local.name_prefix}' is invalid for ${local.cloud_provider}.
    Names must start with a lowercase letter, contain only lowercase letters, 
    numbers, and hyphens, and end with a letter or number.
  EOT
}

# ❌ BAD: Vague error messages
validation {
  condition = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.name_prefix))
  error_message = "Invalid name format."
}
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Name Too Long

**Error:**
```
Error: Generated name 'very-long-organization-name-production-web-application-server' exceeds maximum length for aws.
```

**Solution:**
```hcl
# Use shorter namespace or name components
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace = "org"        # Instead of "very-long-organization-name"
  environment = "prod"     # Instead of "production"
  name = "web-app"         # Instead of "web-application-server"
}

# Or use id_length_limit
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace = "myorg"
  environment = "production"
  name = "web-application-server"
  
  id_length_limit = 50  # Truncate to 50 characters
}
```

#### Issue 2: Invalid Characters for Cloud Provider

**Error:**
```
Error: Azure resource names must start with a letter, contain only letters, numbers, hyphens, and underscores, and end with a letter or number.
```

**Solution:**
```hcl
# Use regex_replace_chars to clean up names
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace = "my.org"
  environment = "prod"
  name = "web_app"
  
  # Replace dots and other invalid characters
  regex_replace_chars = "/[^a-zA-Z0-9-_]/"
}
```

#### Issue 3: Tag Limit Exceeded

**Error:**
```
Error: AWS resources support a maximum of 50 tags.
```

**Solution:**
```hcl
# Reduce the number of tags or use labels_as_tags selectively
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  # ... other configuration
  
  # Only include essential labels as tags
  labels_as_tags = ["namespace", "environment", "name"]
  
  # Use additional_tag_map sparingly
  additional_tag_map = {
    # Only essential additional tags
    Project = "MyApp"
    Owner   = "DevTeam"
  }
}
```

#### Issue 4: Context Not Propagating

**Error:**
```
Error: The argument "context" is required, but no definition was found.
```

**Solution:**
```hcl
# Ensure context is properly passed to child modules
module "parent" {
  source = "kbrockhoff/external-context/terraform"
  # ... configuration
}

module "child" {
  source = "kbrockhoff/compute/aws"
  
  # ✅ Pass context from parent
  context = module.parent.context
  
  # ❌ Don't forget to pass context
  # name = "my-server"  # This alone is not enough
}
```

#### Issue 5: Cloud Provider Auto-Detection Failing

**Error:**
```
Error: Cloud provider detection returned 'unknown'.
```

**Solution:**
```hcl
# Explicitly set cloud provider
module "compute" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  cloud_provider = "aws"  # Explicitly set
  
  # Or ensure provider data sources are available
}

# Make sure provider data sources are defined
data "aws_caller_identity" "current" {}
# or
data "azurerm_client_config" "current" {}
# or  
data "google_client_config" "current" {}
```

### Debug Information

Add debug outputs to troubleshoot context integration:

```hcl
# Debug outputs (remove in production)
output "debug_context" {
  description = "Debug information for context integration"
  value = {
    name_prefix     = local.name_prefix
    cloud_provider  = local.cloud_provider
    environment_type = var.environment_type
    effective_config = local.effective_config
    common_tags     = local.common_tags
    validation_results = local.name_validations[local.cloud_provider]
  }
}
```

### Testing Context Integration

```bash
# Test context integration with terraform plan
terraform init
terraform plan -var="name=test" -var="environment=dev"

# Validate generated names and tags
terraform plan -out=plan.out
terraform show -json plan.out | jq '.planned_values.root_module.resources[].values.tags'

# Test with different environment types
terraform plan -var="environment_type=Production"
terraform plan -var="environment_type=Development"
```

This comprehensive integration guide ensures consistent and proper usage of the terraform-external-context module across all Brockhoff Cloud Terraform modules, providing standardized naming, tagging, and configuration patterns for multi-cloud deployments.