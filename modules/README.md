# Terraform Modules

This directory contains the Brockhoff Cloud Terraform module suite organized by category and cloud provider.

## Module Organization

### Directory Structure

```
modules/
├── foundation/          # Core infrastructure modules
│   ├── networking/      # VPC, subnets, routing
│   ├── security/        # Security groups, WAF, policies
│   └── identity/        # IAM, RBAC, service accounts
├── services/            # Application service modules
│   ├── compute/         # Virtual machines, containers
│   ├── storage/         # Object storage, block storage
│   └── database/        # Managed databases, caching
└── composite/           # Complete solution modules
    ├── web-app/         # Full web application stack
    ├── data-pipeline/   # ETL and analytics infrastructure
    └── microservices/   # Container orchestration platform
```

### Cloud Provider Support

Each module category supports multiple cloud providers:

- **AWS**: Amazon Web Services modules
- **Azure**: Microsoft Azure modules  
- **GCP**: Google Cloud Platform modules

### Module Naming Convention

Modules follow this naming pattern:
```
{category}/{service}/{provider}
```

Examples:
- `foundation/networking/aws` - AWS VPC and networking
- `services/compute/azure` - Azure virtual machines
- `composite/web-app/gcp` - GCP web application stack

## Module Standards

All modules in this suite follow consistent standards:

### Required Files
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variables with validation
- `outputs.tf` - Standardized outputs
- `versions.tf` - Provider version constraints
- `README.md` - Usage documentation
- `LICENSE` - Apache 2.0 license

### Standard Configuration Objects
- `encryption_config` - KMS key management
- `monitoring_config` - Observability settings
- `alarms_config` - Alerting configuration

### Integration Points
- terraform-external-context for naming and tagging
- Consistent variable interfaces across providers
- Standardized output formats
- Common compliance and governance metadata

## Getting Started

### Using a Module

```hcl
module "example" {
  source = "./modules/services/compute/aws"
  
  name         = "my-application"
  environment  = "production"
  instance_type = "t3.medium"
  
  # Standard configuration objects
  encryption_config = {
    create_kms_key = true
  }
  
  monitoring_config = {
    enabled = true
  }
}
```

### Module Development

1. Choose the appropriate category and provider
2. Follow the standard module structure
3. Implement required interfaces
4. Add comprehensive tests
5. Update documentation

## Module Status

| Category | AWS | Azure | GCP | Status |
|----------|-----|-------|-----|--------|
| Foundation/Networking | 🚧 | 🚧 | 🚧 | In Development |
| Foundation/Security | 🚧 | 🚧 | 🚧 | In Development |
| Foundation/Identity | 🚧 | 🚧 | 🚧 | In Development |
| Services/Compute | 🚧 | 🚧 | 🚧 | In Development |
| Services/Storage | 🚧 | 🚧 | 🚧 | In Development |
| Services/Database | 🚧 | 🚧 | 🚧 | In Development |
| Composite/Web-App | 🚧 | 🚧 | 🚧 | Planned |
| Composite/Data-Pipeline | 🚧 | 🚧 | 🚧 | Planned |
| Composite/Microservices | 🚧 | 🚧 | 🚧 | Planned |

Legend:
- ✅ Available
- 🚧 In Development  
- 📋 Planned
- ❌ Not Supported

## Contributing

See the [Contributing Guide](../CONTRIBUTING.md) for details on:
- Module development standards
- Testing requirements
- Documentation expectations
- Pull request process

## Support

- Check module-specific README files for usage details
- Review examples in each module directory
- Open issues for bugs or feature requests
- Join discussions for questions and community support