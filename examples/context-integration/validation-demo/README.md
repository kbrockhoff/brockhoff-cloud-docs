# Context Validation Demo

This example demonstrates the multi-cloud context validation module, showing how to validate resource names, tags, and constraints across AWS, Azure, and GCP.

## Features Demonstrated

- **Multi-Cloud Validation**: Validate configurations for AWS, Azure, and GCP
- **Automatic Cloud Provider Detection**: Auto-detect available cloud providers
- **Cross-Cloud Compatibility**: Ensure configurations work across all cloud providers
- **Resource Name Generation**: Generate appropriate resource names for each cloud provider
- **Comprehensive Error Reporting**: Detailed validation errors and recommendations
- **Helper Functions**: Utilities for cloud provider detection and configuration

## Usage

### Basic Usage

```bash
# Initialize Terraform
terraform init

# Plan with default settings (AWS validation only)
terraform plan

# Apply to see validation results
terraform apply
```

### Multi-Cloud Validation

```bash
# Enable validation for all cloud providers
terraform plan -var="enable_aws_validation=true" \
               -var="enable_azure_validation=true" \
               -var="enable_gcp_validation=true"
```

### Cross-Cloud Compatibility Testing

```bash
# Test cross-cloud compatibility
terraform plan -var="enforce_cross_cloud_compatibility=true"
```

### Create Demo Resources

```bash
# Create actual resources to test validation
terraform apply -var="create_demo_resources=true"
```

## Configuration Options

### Provider Selection

```hcl
# Enable specific cloud provider validations
enable_aws_validation   = true
enable_azure_validation = true
enable_gcp_validation   = true
enable_auto_detection   = true
```

### Compatibility Settings

```hcl
# Enforce strict cross-cloud compatibility
enforce_cross_cloud_compatibility = true

# Set environment type for appropriate defaults
environment_type = "Production"
```

### Testing Scenarios

```hcl
# Test with different name scenarios
test_name_scenarios = {
  valid_short   = "app"
  valid_long    = "my-application-name"
  invalid_aws   = "-invalid-name-"
  invalid_gcp   = "Invalid-Name"
  too_long      = "extremely-long-name-that-exceeds-limits"
}
```

## Example Outputs

### Validation Summary

```json
{
  "validation_summary": {
    "all_validations_passed": true,
    "validation_errors": [],
    "enabled_validations": ["aws", "auto"]
  }
}
```

### Resource Names

```json
{
  "generated_resource_names": {
    "aws": {
      "aws_s3_bucket": "demo-dev-validation-bucket-abcd1234",
      "aws_iam_role": "demo-dev-validation-role",
      "aws_rds_instance": "demo-dev-validation"
    }
  }
}
```

### Cross-Cloud Compatibility

```json
{
  "cross_cloud_compatibility": {
    "aws_compatible": true,
    "azure_compatible": true,
    "gcp_compatible": true,
    "all_compatible": true
  }
}
```

## Testing Different Scenarios

### Valid Configuration

```hcl
module "validation_demo" {
  source = "./examples/context-integration/validation-demo"
  
  namespace   = "myorg"
  environment = "prod"
  name        = "webapp"
  
  tags = {
    Project = "WebApp"
    Owner   = "DevTeam"
  }
  
  enable_aws_validation = true
  enforce_cross_cloud_compatibility = true
}
```

### Invalid Configuration (for testing)

```hcl
module "validation_demo" {
  source = "./examples/context-integration/validation-demo"
  
  # This will fail validation
  namespace   = "very-long-organization-name"
  environment = "production-environment"
  name        = "extremely-long-application-name"
  
  enable_aws_validation = true
  enforce_cross_cloud_compatibility = true
}
```

## Integration with terraform-external-context

This example shows how to integrate the validation module with `terraform-external-context`:

```hcl
# Generate consistent context
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace   = "myorg"
  environment = "prod"
  name        = "webapp"
  tags        = var.tags
}

# Validate context for cloud providers
module "validation" {
  source = "../../../modules/context-validation"
  
  name_prefix = module.context.name_prefix
  tags        = module.context.tags
  
  enforce_cross_cloud_compatibility = true
}

# Use validated names in resources
resource "aws_s3_bucket" "example" {
  bucket = module.validation.resource_names.aws_s3_bucket
  tags   = module.validation.tags_for_cloud_provider
}
```

## Validation Rules Tested

### AWS
- Names must start with letter, contain only letters/numbers/hyphens
- Maximum 63 characters for most resources
- S3 buckets must be lowercase, globally unique
- Tags cannot start with 'aws:' or 'AWS:'

### Azure
- Names can contain letters/numbers/hyphens/underscores
- Maximum 80 characters for most resources
- Storage accounts: 3-24 characters, lowercase letters/numbers only
- Cannot use 'name', 'Name', or 'NAME' as tag keys

### GCP
- Names must be lowercase, start with letter
- Maximum 63 characters for most resources
- Labels must match specific patterns
- Cannot use 'goog-' or 'google-' prefixes

## Error Examples

### Name Too Long
```
Error: Generated name 'very-long-organization-name-production-webapp' exceeds aws maximum length of 63 characters.
```

### Invalid Characters
```
Error: Generated name '-invalid-name-' is invalid for aws.
Names must start with a letter, contain only letters, numbers, and hyphens, and end with a letter or number.
```

### Too Many Tags
```
Error: AWS resources support a maximum of 50 tags.
Current count: 55
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |
| azurerm | ~> 3.0 |
| google | ~> 4.0 |
| random | ~> 3.0 |

## Providers

Configure providers as needed:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = "my-project-id"
  region  = "us-central1"
}
```

## Files

- `main.tf` - Main configuration with validation modules
- `variables.tf` - Input variables and validation rules
- `outputs.tf` - Comprehensive outputs showing validation results
- `README.md` - This documentation
- `terraform.tfvars.example` - Example variable values

## Next Steps

After running this example:

1. Review the validation results in the outputs
2. Test with different name and tag combinations
3. Enable multiple cloud providers to see cross-cloud validation
4. Use the generated resource names in your actual infrastructure modules
5. Integrate the validation module into your own Terraform modules