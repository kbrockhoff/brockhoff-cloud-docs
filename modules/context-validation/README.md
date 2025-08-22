# Multi-Cloud Context Validation Module

This module provides comprehensive validation logic for cloud provider-specific constraints and helper functions for cloud provider detection and configuration. It ensures that resource names, tags, and other metadata comply with AWS, Azure, and GCP requirements.

## Features

- **Automatic Cloud Provider Detection**: Detects the active cloud provider based on available data sources
- **Multi-Cloud Validation**: Validates names, tags, and resource-specific constraints for AWS, Azure, and GCP
- **Resource-Specific Naming**: Generates appropriate resource names following cloud provider conventions
- **Cross-Cloud Compatibility**: Optional validation for configurations that work across all cloud providers
- **Comprehensive Error Messages**: Detailed validation errors with remediation suggestions

## Usage

### Basic Usage

```hcl
module "context_validation" {
  source = "./modules/context-validation"
  
  name_prefix = "myorg-prod-webapp"
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Owner       = "DevTeam"
  }
}

# Use validation results
output "validation_status" {
  value = module.context_validation.validation_results.all_valid
}

output "cloud_provider" {
  value = module.context_validation.cloud_provider
}
```

### With Terraform External Context Integration

```hcl
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace   = "myorg"
  environment = "prod"
  name        = "webapp"
  
  tags = {
    Project = "WebApp"
    Owner   = "DevTeam"
  }
}

module "context_validation" {
  source = "./modules/context-validation"
  
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
  
  # Optional: enforce cross-cloud compatibility
  enforce_cross_cloud_compatibility = true
}

# Use validated resource names
resource "aws_s3_bucket" "example" {
  count = module.context_validation.cloud_provider == "aws" ? 1 : 0
  
  bucket = module.context_validation.resource_names.aws_s3_bucket
  tags   = module.context_validation.tags_for_cloud_provider
}

resource "azurerm_storage_account" "example" {
  count = module.context_validation.cloud_provider == "azure" ? 1 : 0
  
  name                = module.context_validation.resource_names.azure_storage_account
  resource_group_name = azurerm_resource_group.example[0].name
  location           = "East US"
  
  tags = module.context_validation.tags_for_cloud_provider
}

resource "google_storage_bucket" "example" {
  count = module.context_validation.cloud_provider == "gcp" ? 1 : 0
  
  name     = module.context_validation.resource_names.gcp_storage_bucket
  location = "US"
  
  labels = module.context_validation.tags_for_cloud_provider
}
```

### Cloud Provider-Specific Validation

```hcl
# AWS-specific validation
module "aws_validation" {
  source = "./modules/context-validation"
  
  name_prefix    = "MyOrg-Prod-WebApp"
  cloud_provider = "aws"
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Owner       = "DevTeam"
    CostCenter  = "Engineering"
  }
  
  random_suffix = random_id.suffix.hex
}

# Azure-specific validation
module "azure_validation" {
  source = "./modules/context-validation"
  
  name_prefix    = "MyOrg_Prod_WebApp"
  cloud_provider = "azure"
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    CostCenter  = "Engineering"
  }
  
  random_suffix = random_id.suffix.hex
}

# GCP-specific validation
module "gcp_validation" {
  source = "./modules/context-validation"
  
  name_prefix    = "myorg-prod-webapp"
  cloud_provider = "gcp"
  
  tags = {
    environment = "production"
    project     = "webapp"
    team        = "devteam"
  }
  
  random_suffix = random_id.suffix.hex
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

## Validation Rules

### AWS Constraints

- **Names**: Must start with letter, contain only letters/numbers/hyphens, end with letter/number
- **Max Length**: 63 characters (most resources)
- **Tags**: Maximum 50 tags, keys ≤128 chars, values ≤256 chars
- **Reserved**: Tag keys cannot start with 'aws:' or 'AWS:'
- **S3 Buckets**: Lowercase only, globally unique, 3-63 characters
- **IAM Roles**: Can contain letters, numbers, and +=,.@_- characters

### Azure Constraints

- **Names**: Must start with letter, can contain letters/numbers/hyphens/underscores
- **Max Length**: 80 characters (most resources)
- **Tags**: Maximum 50 tags, keys ≤512 chars, values ≤256 chars
- **Reserved**: Cannot use 'name', 'Name', or 'NAME' as tag keys
- **Storage Accounts**: 3-24 characters, lowercase letters and numbers only
- **Resource Groups**: Can contain parentheses, periods, hyphens, underscores

### GCP Constraints

- **Names**: Must start with lowercase letter, contain only lowercase/numbers/hyphens
- **Max Length**: 63 characters (most resources)
- **Labels**: Maximum 64 labels, keys and values ≤63 chars each
- **Reserved**: Label keys cannot start with 'goog-' or 'google-'
- **Pattern**: Keys must match `^[a-z][a-z0-9_-]*$`, values `^[a-z0-9_-]*$`
- **Service Accounts**: 6-30 characters, specific naming requirements

## Outputs

### Primary Outputs

- `cloud_provider`: Detected or specified cloud provider
- `validation_results`: Comprehensive validation status and details
- `resource_names`: Generated resource names for each cloud provider
- `tags_for_cloud_provider`: Tags/labels formatted for the cloud provider

### Helper Outputs

- `helper_functions`: Utilities for cloud detection and naming
- `recommendations`: Suggestions for improving compatibility
- `validation_errors`: List of validation errors (if any)
- `cross_cloud_compatible`: Whether config works across all clouds

## Examples

See the `examples/context-integration/` directory for complete examples:

- `basic-usage/`: Simple single-cloud validation
- `multi-cloud/`: Cross-cloud validation and resource creation
- `advanced/`: Complex scenarios with custom constraints

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |
| azurerm | ~> 3.0 |
| google | ~> 4.0 |

## Providers

The module uses configuration aliases to support optional provider configurations:

```hcl
providers = {
  aws    = aws.main
  azurerm = azurerm.main  
  google = google.main
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable validation | `bool` | `true` | no |
| name_prefix | Resource name prefix | `string` | n/a | yes |
| tags | Tags/labels map | `map(string)` | `{}` | no |
| cloud_provider | Cloud provider (aws/azure/gcp) | `string` | `null` | no |
| random_suffix | Random suffix for unique names | `string` | `"12345678"` | no |
| enforce_cross_cloud_compatibility | Enforce cross-cloud constraints | `bool` | `false` | no |

## Integration with terraform-external-context

This module is designed to work seamlessly with the `terraform-external-context` module:

```hcl
module "context" {
  source = "kbrockhoff/external-context/terraform"
  # ... configuration
}

module "validation" {
  source = "./modules/context-validation"
  
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
}
```

## Testing

The module includes comprehensive tests in the `test/` directory:

```bash
# Run validation tests
make test

# Test specific cloud provider
go test -run TestAWSValidation
go test -run TestAzureValidation  
go test -run TestGCPValidation
```

## Contributing

Please see [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines on contributing to this module.

## License

This module is licensed under the Apache Software License 2.0. See [LICENSE](../../LICENSE) for details.