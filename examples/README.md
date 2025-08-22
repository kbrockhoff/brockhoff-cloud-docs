# Examples

This directory contains comprehensive examples demonstrating how to use the Brockhoff Cloud Terraform modules across different scenarios and cloud providers.

## Example Categories

### Basic Examples
Simple, single-module examples perfect for getting started:
- `basic-compute/` - Simple virtual machine deployment
- `basic-storage/` - Object storage bucket creation
- `basic-networking/` - VPC and subnet setup

### Advanced Examples
Complex scenarios showing module composition and advanced features:
- `multi-tier-app/` - Complete web application with database
- `microservices-platform/` - Container orchestration setup
- `data-analytics/` - ETL pipeline and data warehouse

### Multi-Cloud Examples
Demonstrations of consistent patterns across cloud providers:
- `cross-cloud-backup/` - Disaster recovery across providers
- `hybrid-deployment/` - Workloads spanning multiple clouds
- `cloud-migration/` - Migration patterns and strategies

### Integration Examples
Showing integration with external systems and tools:
- `portal-integration/` - Self-service developer portal setup
- `ai-generated/` - Examples of AI-generated infrastructure
- `compliance-reporting/` - Automated compliance and governance

## Example Structure

Each example follows this structure:
```
example-name/
├── main.tf              # Primary configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Example variable values
├── README.md            # Usage instructions
├── .terraform-docs.yml  # Documentation config
└── diagrams/            # Architecture diagrams
    └── architecture.png
```

## Quick Start

### Running an Example

1. Choose an example directory
2. Copy the example to your workspace
3. Customize the variables
4. Initialize and apply

```bash
# Copy example
cp -r examples/basic-compute my-infrastructure

# Navigate to your copy
cd my-infrastructure

# Customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### Example Variables

Most examples include these common variables:
```hcl
# terraform.tfvars
name         = "my-project"
environment  = "development"
region       = "us-west-2"

tags = {
  Project = "MyProject"
  Owner   = "DevTeam"
  Environment = "development"
}
```

## Available Examples

### Basic Examples

#### basic-compute
Simple virtual machine deployment with monitoring and security.

**Providers**: AWS, Azure, GCP  
**Resources**: 3-5  
**Complexity**: Beginner  
**Cost**: $20-50/month  

```hcl
module "compute" {
  source = "../../modules/services/compute/aws"
  
  name         = var.name
  environment  = var.environment
  instance_type = "t3.micro"
}
```

#### basic-storage
Object storage bucket with encryption and lifecycle policies.

**Providers**: AWS, Azure, GCP  
**Resources**: 2-3  
**Complexity**: Beginner  
**Cost**: $5-15/month  

#### basic-networking
VPC with public and private subnets, NAT gateway, and security groups.

**Providers**: AWS, Azure, GCP  
**Resources**: 8-12  
**Complexity**: Intermediate  
**Cost**: $30-60/month  

### Advanced Examples

#### multi-tier-app
Complete web application with load balancer, application servers, and database.

**Providers**: AWS, Azure, GCP  
**Resources**: 15-25  
**Complexity**: Advanced  
**Cost**: $200-500/month  

#### microservices-platform
Container orchestration platform with service mesh and monitoring.

**Providers**: AWS (EKS), Azure (AKS), GCP (GKE)  
**Resources**: 20-35  
**Complexity**: Expert  
**Cost**: $300-800/month  

### Multi-Cloud Examples

#### cross-cloud-backup
Primary workload in one cloud with backup and disaster recovery in another.

**Providers**: AWS + Azure, AWS + GCP, Azure + GCP  
**Resources**: 10-20  
**Complexity**: Advanced  
**Cost**: $150-400/month  

## Testing Examples

All examples include automated testing:

```bash
# Test all examples
make test-examples

# Test specific example
cd examples/basic-compute
terraform init
terraform plan
```

## Cost Estimation

Each example includes cost estimates:
- **Development**: Minimal resources for testing
- **Staging**: Production-like but smaller scale
- **Production**: Full-scale production deployment

Cost estimates are provided for:
- Monthly recurring costs
- One-time setup costs
- Scaling cost implications

## Security Considerations

All examples follow security best practices:
- Encryption at rest and in transit
- Least-privilege access policies
- Network security controls
- Monitoring and alerting
- Compliance framework alignment

## Customization Guide

### Adapting Examples

1. **Copy the example** to your workspace
2. **Review the README** for specific requirements
3. **Customize variables** in `terraform.tfvars`
4. **Modify resources** as needed for your use case
5. **Test thoroughly** before production use

### Common Customizations

- **Instance sizes**: Adjust for your performance needs
- **Regions**: Change to your preferred region
- **Naming**: Update naming conventions
- **Tags**: Add your organization's required tags
- **Security**: Adjust security groups and policies

## Contributing Examples

We welcome example contributions! Please:

1. Follow the standard example structure
2. Include comprehensive documentation
3. Add cost estimates and security notes
4. Test across all supported providers
5. Submit a pull request with the example template

### Example Template

Use this template for new examples:
```
examples/your-example/
├── main.tf
├── variables.tf  
├── outputs.tf
├── terraform.tfvars.example
├── README.md
└── diagrams/
```

## Support

- Check example-specific README files for detailed instructions
- Review the main documentation for module details
- Open issues for bugs or improvements
- Join discussions for questions and community support