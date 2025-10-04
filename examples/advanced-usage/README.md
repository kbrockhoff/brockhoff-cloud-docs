# Advanced Usage Examples

This directory contains complex, multi-module examples that demonstrate advanced patterns and module composition using Brockhoff Cloud Terraform modules across AWS, Azure, and GCP.

## Overview

These examples showcase:
- Complex multi-tier application architectures
- Module composition and integration patterns
- Cost optimization strategies
- Security hardening implementations
- Cross-cloud provider deployment scenarios
- Production-ready configurations

## Examples

### Multi-Tier Web Application
- **Path**: `multi-tier-app/`
- **Resources**: 20-30 resources per cloud
- **Estimated Cost**: $200-500/month
- **Complexity**: Advanced
- **Features**: Load balancer, auto-scaling, database, monitoring

### Microservices Platform
- **Path**: `microservices-platform/`
- **Resources**: 30-50 resources per cloud
- **Estimated Cost**: $300-800/month
- **Complexity**: Expert
- **Features**: Container orchestration, service mesh, CI/CD integration

### Cost-Optimized Architecture
- **Path**: `cost-optimized/`
- **Resources**: 15-25 resources per cloud
- **Estimated Cost**: $100-250/month
- **Complexity**: Advanced
- **Features**: Spot instances, scheduled scaling, storage optimization

### Security-Hardened Deployment
- **Path**: `security-hardened/`
- **Resources**: 25-35 resources per cloud
- **Estimated Cost**: $250-600/month
- **Complexity**: Expert
- **Features**: Zero-trust networking, encryption everywhere, compliance controls

## Architecture Patterns

### Multi-Tier Application Pattern

```
┌─────────────────────────────────────────┐
│              Load Balancer              │
│         (Public Subnet)                 │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Web Tier                      │
│      (Private Subnet)                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Web App │  │ Web App │  │ Web App │ │
│  │ Server  │  │ Server  │  │ Server  │ │
│  └─────────┘  └─────────┘  └─────────┘ │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          Application Tier               │
│      (Private Subnet)                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │   API   │  │   API   │  │   API   │ │
│  │ Server  │  │ Server  │  │ Server  │ │
│  └─────────┘  └─────────┘  └─────────┘ │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Database Tier                 │
│      (Private Subnet)                   │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Primary   │  │    Read         │   │
│  │  Database   │  │   Replicas      │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

### Microservices Platform Pattern

```
┌─────────────────────────────────────────┐
│            API Gateway                  │
│         (Public Access)                 │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│         Service Mesh                    │
│      (Container Platform)               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │Service A│ │Service B│ │Service C│   │
│  │         │ │         │ │         │   │
│  └─────────┘ └─────────┘ └─────────┘   │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          Data Layer                     │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │Database │ │  Cache  │ │ Message │   │
│  │         │ │         │ │  Queue  │   │
│  └─────────┘ └─────────┘ └─────────┘   │
└─────────────────────────────────────────┘
```

## Quick Start

### Running an Advanced Example

1. Choose an example directory
2. Review the architecture documentation
3. Customize the configuration
4. Deploy incrementally

```bash
# Copy example
cp -r examples/advanced-usage/multi-tier-app my-app

# Navigate to your copy
cd my-app

# Review the architecture
cat README.md

# Customize for your cloud provider
cd aws  # or azure, gcp

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy incrementally
terraform init
terraform plan
terraform apply
```

## Configuration Management

### Environment-Specific Configurations

Each advanced example includes configurations for multiple environments:

```
example-name/
├── environments/
│   ├── development/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       ├── terraform.tfvars
│       └── backend.tf
```

### Module Composition

Advanced examples demonstrate proper module composition:

```hcl
# Network foundation
module "networking" {
  source = "../../../modules/foundation/networking"
  # ... configuration
}

# Security layer
module "security" {
  source = "../../../modules/foundation/security"
  
  # Dependency on networking
  vpc_id = module.networking.vpc_id
  # ... configuration
}

# Application services
module "web_tier" {
  source = "../../../modules/services/compute"
  
  # Dependencies on foundation modules
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.security.web_security_group_id
  # ... configuration
}
```

## Cost Optimization Strategies

### Development Environment Optimizations

- **Spot/Preemptible instances**: 60-90% cost savings
- **Scheduled shutdown**: Automatic stop during off-hours
- **Smaller instance sizes**: Right-sized for development workloads
- **Reduced redundancy**: Single AZ deployment for non-critical resources

### Production Environment Optimizations

- **Reserved instances**: 30-60% savings for predictable workloads
- **Auto-scaling**: Dynamic resource allocation based on demand
- **Storage optimization**: Lifecycle policies and intelligent tiering
- **Network optimization**: CDN and traffic routing efficiency

### Cost Monitoring

All advanced examples include cost monitoring:

```hcl
module "cost_monitoring" {
  source = "../../../modules/governance/cost-monitoring"
  
  budget_amount = var.monthly_budget
  alert_thresholds = [50, 80, 100]  # Percentage of budget
  notification_emails = var.cost_alert_emails
}
```

## Security Hardening

### Network Security

- **Zero-trust networking**: Explicit allow rules only
- **Network segmentation**: Isolated subnets for each tier
- **WAF protection**: Web application firewall for public endpoints
- **VPN/Private connectivity**: Secure administrative access

### Data Protection

- **Encryption everywhere**: At rest, in transit, and in processing
- **Key management**: Centralized key rotation and access control
- **Backup encryption**: Encrypted backups with separate key management
- **Data classification**: Automated tagging and protection policies

### Identity and Access

- **Least privilege**: Minimal required permissions
- **Role-based access**: Standardized role definitions
- **Multi-factor authentication**: Required for administrative access
- **Audit logging**: Comprehensive access and change logging

## Testing and Validation

### Automated Testing

Each advanced example includes comprehensive testing:

```bash
# Infrastructure validation
make validate

# Security scanning
make security-scan

# Cost analysis
make cost-analysis

# Performance testing
make performance-test

# Compliance checking
make compliance-check
```

### Testing Scenarios

- **Disaster recovery**: Automated failover testing
- **Load testing**: Performance under expected load
- **Security testing**: Penetration testing and vulnerability scanning
- **Compliance testing**: Automated compliance framework validation

## Monitoring and Observability

### Comprehensive Monitoring Stack

All advanced examples include:

- **Infrastructure monitoring**: Resource utilization and health
- **Application monitoring**: Performance metrics and traces
- **Log aggregation**: Centralized logging with search and alerting
- **Security monitoring**: Threat detection and incident response

### Alerting Strategy

- **Tiered alerting**: Different severity levels and escalation paths
- **Intelligent routing**: Context-aware alert routing
- **Noise reduction**: Alert correlation and suppression
- **Runbook integration**: Automated remediation where possible

## Deployment Strategies

### Blue-Green Deployment

```hcl
module "blue_environment" {
  source = "../../../modules/composite/web-application"
  
  environment_suffix = "blue"
  traffic_weight    = var.blue_traffic_weight
  # ... configuration
}

module "green_environment" {
  source = "../../../modules/composite/web-application"
  
  environment_suffix = "green"
  traffic_weight    = var.green_traffic_weight
  # ... configuration
}
```

### Canary Deployment

```hcl
module "canary_deployment" {
  source = "../../../modules/patterns/canary-deployment"
  
  stable_version = var.stable_version
  canary_version = var.canary_version
  canary_traffic_percentage = var.canary_traffic_percentage
  # ... configuration
}
```

## Available Examples

### Multi-Tier Web Application

**Complexity**: Advanced  
**Resources**: 20-30 per cloud  
**Cost**: $200-500/month  

Complete web application with:
- Load balancer with SSL termination
- Auto-scaling web and application tiers
- Managed database with read replicas
- Redis cache layer
- Comprehensive monitoring and alerting

### Microservices Platform

**Complexity**: Expert  
**Resources**: 30-50 per cloud  
**Cost**: $300-800/month  

Container orchestration platform with:
- Kubernetes/EKS/AKS/GKE cluster
- Service mesh (Istio/Linkerd)
- CI/CD pipeline integration
- Distributed tracing and monitoring
- Secret management and security policies

### Cost-Optimized Architecture

**Complexity**: Advanced  
**Resources**: 15-25 per cloud  
**Cost**: $100-250/month  

Budget-conscious deployment with:
- Spot/preemptible instance usage
- Scheduled auto-scaling
- Storage lifecycle management
- Cost monitoring and alerting
- Resource right-sizing recommendations

### Security-Hardened Deployment

**Complexity**: Expert  
**Resources**: 25-35 per cloud  
**Cost**: $250-600/month  

Security-first architecture with:
- Zero-trust network design
- End-to-end encryption
- Compliance framework implementation
- Security monitoring and SIEM integration
- Automated security scanning and remediation

## Customization Guide

### Adapting for Your Use Case

1. **Start with the closest example** to your requirements
2. **Review the architecture** and understand the component relationships
3. **Customize the variables** for your specific needs
4. **Modify the modules** if additional functionality is required
5. **Test thoroughly** in a development environment first

### Common Customizations

- **Instance sizes**: Adjust based on performance requirements
- **Scaling policies**: Modify based on traffic patterns
- **Security policies**: Adapt to organizational requirements
- **Monitoring configuration**: Customize alerts and dashboards
- **Cost controls**: Adjust budgets and optimization strategies

## Support and Troubleshooting

### Getting Help

- Review example-specific documentation
- Check the troubleshooting guides
- Use the community forums for questions
- Open issues for bugs or improvements

### Common Issues

- **Resource limits**: Check cloud provider quotas
- **Permission errors**: Verify IAM policies and roles
- **Network connectivity**: Review security group and firewall rules
- **Cost overruns**: Monitor and adjust resource configurations

## Contributing

We welcome contributions of new advanced examples! Please:

1. Follow the established patterns and structure
2. Include comprehensive documentation
3. Add cost estimates and security considerations
4. Test across all supported cloud providers
5. Submit a pull request with the example

### Example Template

Use the existing examples as templates for new advanced scenarios.
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