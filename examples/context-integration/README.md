# Context Integration Examples

This directory contains practical examples demonstrating how to integrate the `terraform-external-context` module across different scenarios and cloud providers.

## Examples Overview

- **[basic-usage/](./basic-usage/)** - Simple single-module context integration
- **[multi-module/](./multi-module/)** - Context inheritance across multiple modules
- **[multi-cloud/](./multi-cloud/)** - Consistent context across AWS, Azure, and GCP
- **[environment-overrides/](./environment-overrides/)** - Environment-specific configuration patterns
- **[advanced-composition/](./advanced-composition/)** - Complex module composition with context

## Quick Start

Each example includes:
- `main.tf` - Primary Terraform configuration
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variable values
- `README.md` - Specific usage instructions

## Running Examples

```bash
# Navigate to any example directory
cd basic-usage/

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and plan
terraform init
terraform plan

# Apply (optional)
terraform apply
```

## Common Patterns

### 1. Basic Context Setup
```hcl
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  namespace   = "myorg"
  environment = "dev"
  name        = "webapp"
  
  tags = {
    Project = "MyProject"
    Owner   = "DevTeam"
  }
}
```

### 2. Context Inheritance
```hcl
module "child_module" {
  source = "kbrockhoff/compute/aws"
  
  context = module.context.context
  
  # Module-specific overrides
  name = "web-server"
}
```

### 3. Environment-Specific Configuration
```hcl
module "production_app" {
  source = "kbrockhoff/web-app/aws"
  
  context = module.context.context
  environment_type = "Production"
  
  # Production-specific settings applied automatically
}
```

## Best Practices Demonstrated

- ✅ Consistent naming across all resources
- ✅ Proper tag inheritance and merging
- ✅ Environment-specific configuration
- ✅ Cloud provider-specific constraints
- ✅ Context variable passing patterns
- ✅ Override hierarchies and precedence

## Validation

Each example includes validation to ensure:
- Names meet cloud provider requirements
- Tags comply with provider limits
- Context is properly propagated
- Environment configurations are applied correctly
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->