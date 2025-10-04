# User Guide

This comprehensive guide helps you get started with Brockhoff Cloud Terraform modules and provides detailed usage instructions for common scenarios.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Usage](#basic-usage)
3. [Advanced Patterns](#advanced-patterns)
4. [Multi-Cloud Deployment](#multi-cloud-deployment)
5. [Cost Optimization](#cost-optimization)
6. [Security Best Practices](#security-best-practices)
7. [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

Before using Brockhoff Cloud modules, ensure you have:

- **Terraform** >= 1.5.0 installed
- **Cloud Provider CLI** tools configured:
  - AWS CLI with valid credentials
  - Azure CLI with valid subscription
  - Google Cloud SDK with valid project access
- **Basic Terraform Knowledge**: Understanding of Terraform concepts

### Installation

Brockhoff Cloud modules are published to the Terraform Registry. No installation is required - simply reference them in your Terraform configuration:

```hcl
module "example" {
  source  = "kbrockhoff/compute/aws"
  version = "~> 1.0"
  
  # Configuration here
}
```

### Your First Module

Let's deploy a simple web server on AWS:

```hcl
# main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Context module for consistent naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = "my-web-app"
  environment  = "development"
  organization = "my-company"
  
  tags = {
    Project = "WebApp"
    Owner   = "DevTeam"
  }
}

# Web server module
module "web_server" {
  source = "kbrockhoff/compute/aws"
  version = "~> 1.0"
  
  # Pass context for consistent naming
  context = module.context.context
  
  # Instance configuration
  instance_type = "t3.small"
  
  # Standard configuration objects
  encryption_config = {
    create_kms_key = true
    kms_key_deletion_window_days = 7  # Short window for dev
  }
  
  monitoring_config = {
    enabled = false  # Disabled for development
  }
  
  alarms_config = {
    enabled = false  # Disabled for development
  }
}

# Output important information
output "instance_id" {
  description = "ID of the created instance"
  value       = module.web_server.instance_id
}

output "public_ip" {
  description = "Public IP address"
  value       = module.web_server.public_ip
}

output "cost_estimate" {
  description = "Monthly cost estimate"
  value       = module.web_server.monthly_cost_estimate
}
```

Deploy with:

```bash
terraform init
terraform plan
terraform apply
```

## Basic Usage

### Understanding Module Structure

All Brockhoff Cloud modules follow consistent patterns:

#### Standard Variables

Every module includes these standard variables:

```hcl
variable "context" {
  description = "Context object from terraform-external-context module"
  type = object({
    name_prefix = string
    tags        = map(string)
    data_tags   = map(string)
  })
}

variable "environment_type" {
  description = "Environment type for resource configuration"
  type        = string
  default     = "Development"
  # Options: None, Ephemeral, Development, Testing, UAT, Production, MissionCritical
}

variable "encryption_config" {
  description = "Encryption configuration"
  type = object({
    create_kms_key               = bool
    kms_key_id                   = string
    kms_key_deletion_window_days = number
  })
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enabled = bool
  })
}

variable "alarms_config" {
  description = "Alarms configuration"
  type = object({
    enabled          = bool
    create_sns_topic = bool
    sns_topic_arn    = string
  })
}
```

#### Standard Outputs

Every module provides these standard outputs:

```hcl
output "resource_id" {
  description = "Primary resource identifier"
  value       = "..."
}

output "resource_arn" {
  description = "Resource ARN/URI/ID"
  value       = "..."
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = "..."
}

output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value       = "..."
}

output "compliance_report" {
  description = "Well-architected framework compliance"
  value       = "..."
}
```

### Environment-Specific Configuration

Modules automatically adjust based on `environment_type`:

```hcl
# Development environment - cost-optimized
module "dev_server" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  environment_type = "Development"
  
  # Automatically gets:
  # - Shorter KMS key deletion window (7 days)
  # - Monitoring disabled
  # - Alarms disabled
  # - Cost-optimized instance types
}

# Production environment - reliability-focused
module "prod_server" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  environment_type = "Production"
  
  # Automatically gets:
  # - Longer KMS key deletion window (30 days)
  # - Monitoring enabled
  # - Alarms enabled
  # - High-availability configuration
}
```

### Working with Context

The terraform-external-context module provides consistent naming and tagging:

```hcl
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  # Required fields
  name         = "my-application"
  environment  = "production"
  organization = "acme-corp"
  
  # Optional customization
  name_format = "{organization}-{environment}-{name}"
  
  # Additional tags
  tags = {
    Project     = "WebApp"
    Owner       = "DevTeam"
    CostCenter  = "Engineering"
  }
  
  # Data-specific tags (for storage resources)
  data_tags = {
    DataClass      = "Internal"
    RetentionDays  = "90"
  }
}

# Use context in multiple modules
module "compute" {
  source = "kbrockhoff/compute/aws"
  context = module.context.context
  # ...
}

module "storage" {
  source = "kbrockhoff/storage/aws"
  context = module.context.context
  # ...
}
```

## Advanced Patterns

### Module Composition

Build complex systems by composing multiple modules:

```hcl
# Complete web application stack
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = "web-app"
  environment  = "production"
  organization = "acme"
}

# Networking foundation
module "networking" {
  source = "kbrockhoff/networking/aws"
  
  context = module.context.context
  
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# Security layer
module "security" {
  source = "kbrockhoff/security/aws"
  
  context = module.context.context
  vpc_id  = module.networking.vpc_id
  
  allowed_cidr_blocks = ["0.0.0.0/0"]  # Adjust for your needs
}

# Application load balancer
module "load_balancer" {
  source = "kbrockhoff/load-balancer/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids
  
  security_group_ids = [module.security.alb_security_group_id]
}

# Auto-scaling compute
module "compute" {
  source = "kbrockhoff/auto-scaling/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  target_group_arn   = module.load_balancer.target_group_arn
  security_group_ids = [module.security.instance_security_group_id]
  
  min_size = 2
  max_size = 10
}

# Database
module "database" {
  source = "kbrockhoff/rds/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.database_subnet_ids
  
  security_group_ids = [module.security.database_security_group_id]
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"
}
```

### Custom Configuration Objects

Customize module behavior with configuration objects:

```hcl
module "web_server" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  
  # Custom encryption configuration
  encryption_config = {
    create_kms_key               = true
    kms_key_id                   = ""  # Will create new key
    kms_key_deletion_window_days = 30
  }
  
  # Enable comprehensive monitoring
  monitoring_config = {
    enabled = true
  }
  
  # Configure alarms with custom SNS topic
  alarms_config = {
    enabled          = true
    create_sns_topic = false
    sns_topic_arn    = aws_sns_topic.alerts.arn
  }
  
  # Custom backup configuration
  backup_config = {
    enabled           = true
    retention_days    = 30
    backup_window     = "03:00-04:00"
    maintenance_window = "sun:04:00-sun:05:00"
  }
}
```

## Multi-Cloud Deployment

Deploy similar infrastructure across multiple cloud providers:

```hcl
# Shared context
locals {
  app_name = "multi-cloud-app"
  environment = "production"
}

# AWS deployment
module "aws_context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = local.app_name
  environment  = local.environment
  organization = "acme"
  
  cloud_provider = "aws"
  region        = "us-west-2"
}

module "aws_compute" {
  source = "kbrockhoff/compute/aws"
  
  context = module.aws_context.context
  
  instance_type = "t3.medium"
  # ... other AWS-specific configuration
}

# Azure deployment
module "azure_context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = local.app_name
  environment  = local.environment
  organization = "acme"
  
  cloud_provider = "azure"
  region        = "West US 2"
}

module "azure_compute" {
  source = "kbrockhoff/compute/azurerm"
  
  context = module.azure_context.context
  
  vm_size = "Standard_B2s"  # Equivalent to AWS t3.medium
  # ... other Azure-specific configuration
}

# GCP deployment
module "gcp_context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = local.app_name
  environment  = local.environment
  organization = "acme"
  
  cloud_provider = "gcp"
  region        = "us-west2"
}

module "gcp_compute" {
  source = "kbrockhoff/compute/google"
  
  context = module.gcp_context.context
  
  machine_type = "e2-medium"  # Equivalent to AWS t3.medium
  # ... other GCP-specific configuration
}

# Outputs for comparison
output "deployments" {
  value = {
    aws = {
      instance_id = module.aws_compute.instance_id
      cost_estimate = module.aws_compute.monthly_cost_estimate
    }
    azure = {
      vm_id = module.azure_compute.vm_id
      cost_estimate = module.azure_compute.monthly_cost_estimate
    }
    gcp = {
      instance_id = module.gcp_compute.instance_id
      cost_estimate = module.gcp_compute.monthly_cost_estimate
    }
  }
}
```

## Cost Optimization

### Understanding Cost Estimates

All modules provide cost estimation:

```hcl
module "web_server" {
  source = "kbrockhoff/compute/aws"
  # ... configuration
}

# View cost breakdown
output "cost_analysis" {
  value = {
    monthly_total = module.web_server.monthly_cost_estimate
    breakdown     = module.web_server.cost_breakdown
    
    # Cost breakdown includes:
    # - compute_cost
    # - storage_cost
    # - network_cost
    # - monitoring_cost
    # - backup_cost
  }
}
```

### Environment-Based Cost Optimization

```hcl
# Development - cost-optimized
module "dev_app" {
  source = "kbrockhoff/web-app/aws"
  
  context = module.dev_context.context
  environment_type = "Development"
  
  # Automatically gets:
  # - Smaller instance types
  # - Reduced backup retention
  # - Minimal monitoring
  # - Scheduled shutdown (weekends)
  
  cost_optimization = {
    enable_scheduling = true
    shutdown_schedule = "0 18 * * 1-5"  # Weekdays 6 PM
    startup_schedule  = "0 8 * * 1-5"   # Weekdays 8 AM
  }
}

# Production - balanced cost and performance
module "prod_app" {
  source = "kbrockhoff/web-app/aws"
  
  context = module.prod_context.context
  environment_type = "Production"
  
  # Gets production defaults with cost awareness:
  # - Right-sized instances
  # - Reserved instance recommendations
  # - Cost monitoring and alerts
  
  cost_optimization = {
    enable_reserved_instance_recommendations = true
    cost_alert_threshold_percent = 80
  }
}
```

### Budget Integration

```hcl
# Set up budget monitoring
resource "aws_budgets_budget" "monthly" {
  name         = "${module.context.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = {
      "Project" = [module.context.tags.Project]
    }
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["team@company.com"]
  }
}

# Reference budget in modules
module "web_server" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  
  budget_config = {
    budget_name = aws_budgets_budget.monthly.name
    alert_on_forecast = true
  }
}
```

## Security Best Practices

### Encryption Configuration

```hcl
# Custom KMS key for sensitive workloads
resource "aws_kms_key" "app_key" {
  description             = "Application encryption key"
  deletion_window_in_days = 30
  
  tags = module.context.tags
}

module "secure_storage" {
  source = "kbrockhoff/storage/aws"
  
  context = module.context.context
  
  encryption_config = {
    create_kms_key               = false
    kms_key_id                   = aws_kms_key.app_key.id
    kms_key_deletion_window_days = 30
  }
  
  # Additional security settings
  security_config = {
    enable_versioning = true
    enable_mfa_delete = true
    block_public_access = true
  }
}
```

### Network Security

```hcl
module "secure_networking" {
  source = "kbrockhoff/networking/aws"
  
  context = module.context.context
  
  # Private subnets only
  create_public_subnets = false
  
  # Enable VPC Flow Logs
  enable_flow_logs = true
  
  # Network ACLs for additional security
  enable_network_acls = true
  
  security_config = {
    enable_vpc_endpoints = true
    enable_nat_gateway   = true
    enable_vpn_gateway   = false
  }
}
```

### IAM Best Practices

```hcl
# Use the deployer module for least-privilege policies
module "deployment_role" {
  source = "kbrockhoff/deployer/aws"
  
  context = module.context.context
  
  # Specify exactly what resources this role can manage
  managed_resources = [
    "ec2:instances",
    "s3:buckets",
    "rds:db-instances"
  ]
  
  # Restrict to specific regions
  allowed_regions = ["us-west-2", "us-east-1"]
  
  # Time-based access
  max_session_duration = 3600  # 1 hour
}
```

## Troubleshooting

### Common Issues

#### 1. Context Module Not Found

**Error:**
```
Module not found: kbrockhoff/external-context/terraform
```

**Solution:**
```bash
terraform init  # Ensure modules are downloaded
```

#### 2. Invalid Environment Type

**Error:**
```
Invalid value for variable "environment_type"
```

**Solution:**
Use one of the valid environment types:
- `None`
- `Ephemeral` 
- `Development`
- `Testing`
- `UAT`
- `Production`
- `MissionCritical`

#### 3. KMS Key Permissions

**Error:**
```
Access denied when using KMS key
```

**Solution:**
```hcl
# Ensure your IAM role has KMS permissions
data "aws_iam_policy_document" "kms_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
```

#### 4. Cost Estimation Failures

**Error:**
```
Unable to estimate costs
```

**Solution:**
- Ensure you have internet connectivity for pricing API calls
- Check that your region is supported for cost estimation
- Verify instance types are valid for the selected region

### Getting Help

1. **Check Documentation**: Review module-specific README files
2. **Search Issues**: Look for similar problems in GitHub issues
3. **Enable Debug Logging**: Set `TF_LOG=DEBUG` for detailed output
4. **Community Support**: Use GitHub Discussions for questions
5. **Professional Support**: Contact maintainers for enterprise support

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform plan
```

Review the log file for detailed error information and API calls.

## Next Steps

- Explore [Advanced Patterns](./advanced-patterns.md)
- Learn about [AI Integration](./ai-integration.md)
- Set up [Self-Service Portals](./portal-integration.md)
- Review [Security Guidelines](./security.md)
- Understand [Cost Optimization](./cost-optimization.md)