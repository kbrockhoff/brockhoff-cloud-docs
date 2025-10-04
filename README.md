# Brockhoff Cloud Terraform Modules

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CI](https://github.com/kbrockhoff/brockhoff-cloud-docs/workflows/Continuous%20Integration/badge.svg)](https://github.com/kbrockhoff/brockhoff-cloud-docs/actions)
[![Security](https://github.com/kbrockhoff/brockhoff-cloud-docs/workflows/Security/badge.svg)](https://github.com/kbrockhoff/brockhoff-cloud-docs/actions)

A comprehensive suite of Terraform modules for multi-cloud infrastructure deployment across AWS, Azure, and GCP. These modules follow well-architected framework principles, emphasize cost optimization, and provide consistent interfaces for teams with varying levels of cloud expertise.

## 🌟 Features

- **Multi-Cloud Support**: Consistent modules across AWS, Azure, and GCP
- **Cost-Optimized**: Budget-aware configurations and cost estimation
- **Security-First**: Well-architected framework compliance and security best practices
- **Self-Service Ready**: Integration with internal developer portals
- **AI-Friendly**: Machine-readable metadata for AI code generation
- **Compliance Built-In**: Automated compliance reporting and governance
- **Open Source**: ASL2 licensed and published to Terraform Registry

## 🏗️ Architecture

The module suite follows a three-tier architecture:

1. **Foundation Modules**: Core infrastructure (networking, security, identity)
2. **Service Modules**: Application-specific services (compute, storage, databases)  
3. **Composite Modules**: Complete solutions combining multiple modules

### Design Principles

- **Consistent Interfaces**: Common variable names and output structures
- **Provider-Specific Optimization**: Leveraging each cloud's strengths
- **Shared Design Patterns**: Common approaches to security, monitoring, and cost optimization
- **Composability**: Modules work together to build complex systems
- **Backward Compatibility**: Stable interfaces with semantic versioning

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.11.0
- Cloud provider CLI tools (AWS CLI, Azure CLI, or gcloud)
- Appropriate cloud provider credentials

### Basic Usage

```hcl
# Example: AWS compute module
module "web_server" {
  source = "kbrockhoff/compute/aws"
  version = "~> 1.0"

  name         = "my-web-server"
  environment  = "production"
  instance_type = "t3.medium"

  # Standard configuration objects
  encryption_config = {
    create_kms_key = true
    kms_key_deletion_window_days = 30
  }

  monitoring_config = {
    enabled = true
  }

  alarms_config = {
    enabled = true
    create_sns_topic = true
  }

  tags = {
    Project = "MyApp"
    Owner   = "DevTeam"
  }
}
```

### Multi-Cloud Example

```hcl
# Deploy similar infrastructure across multiple clouds
module "aws_compute" {
  source = "kbrockhoff/compute/aws"
  version = "~> 1.0"
  
  name = "myapp-aws"
  # ... configuration
}

module "azure_compute" {
  source = "kbrockhoff/compute/azurerm"
  version = "~> 1.0"
  
  name = "myapp-azure"
  # ... similar configuration
}

module "gcp_compute" {
  source = "kbrockhoff/compute/google"
  version = "~> 1.0"
  
  name = "myapp-gcp"
  # ... similar configuration
}
```

## 📚 Documentation

### Module Categories

- **Foundation Modules**
  - [Networking](./modules/networking/) - VPCs, subnets, routing
  - [Security](./modules/security/) - Security groups, NACLs, WAF
  - [Identity](./modules/identity/) - IAM roles, policies, RBAC

- **Service Modules**
  - [Compute](./modules/compute/) - Virtual machines, containers
  - [Storage](./modules/storage/) - Object storage, block storage
  - [Database](./modules/database/) - Managed databases, caching

- **Composite Modules**
  - [Web Application](./modules/web-app/) - Complete web application stack
  - [Data Pipeline](./modules/data-pipeline/) - ETL and analytics infrastructure
  - [Microservices](./modules/microservices/) - Container orchestration platform

### Integration Guides

- [terraform-external-context Integration](./docs/context-integration.md)
- [Self-Service Portal Setup](./docs/portal-integration.md)
- [AI Agent Integration](./docs/ai-integration.md)
- [Compliance Framework](./docs/compliance.md)

## 🛠️ Development

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/kbrockhoff/brockhoff-cloud-docs.git
cd brockhoff-cloud-docs

# Install development tools
make install-tools

# Initialize and validate
make init
make validate

# Run tests
make test

# Generate documentation
make docs
```

### Available Commands

```bash
make help          # Show all available commands
make init          # Initialize terraform modules
make validate      # Validate terraform configuration
make format        # Format terraform files
make test          # Run all tests
make docs          # Generate documentation
make lint          # Run linting and validation
make security      # Run security scans
make clean         # Clean up temporary files
make ci            # Run all CI checks
```

## 🔒 Security

Security is a top priority. All modules include:

- **Encryption**: At-rest and in-transit encryption by default
- **Access Control**: Least-privilege IAM policies
- **Network Security**: Secure networking configurations
- **Monitoring**: Security event logging and alerting
- **Compliance**: Well-architected framework alignment

### Security Scanning

We use multiple security scanning tools:
- **Trivy**: Vulnerability scanning
- **TFSec**: Terraform security analysis
- **Checkov**: Infrastructure security scanning

## 💰 Cost Optimization

All modules are designed with cost optimization in mind:

- **Smart Defaults**: Cost-effective instance types and configurations
- **Budget Awareness**: Cost estimation and budget alerts
- **Right-Sizing**: Automated recommendations for resource optimization
- **Scheduling**: Development environment shutdown scheduling
- **Reserved Instances**: Recommendations for long-term workloads

## 🤖 AI Integration

Modules are designed for AI code generation with:

- **Machine-Readable Metadata**: Structured schemas for AI consumption
- **Generation Templates**: Common patterns for AI agents
- **Validation Rules**: Clear error messages and guidance
- **Testing Scenarios**: Automated validation for AI-generated code

## 🏢 Enterprise Features

### Self-Service Portal Integration

- Form-based configuration interfaces
- Difficulty and cost estimation
- Clear validation and error messages
- Sensible defaults for inexperienced users

### Compliance and Governance

- Automated compliance reporting
- Well-architected framework mappings
- Security control documentation
- Cost allocation and resource tagging

### Multi-Environment Support

- Environment-specific configurations
- Promotion pipelines
- Disaster recovery patterns
- Cross-region deployments

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code of conduct
- Development setup
- Coding standards
- Testing requirements
- Pull request process

### Quick Contribution Checklist

- [ ] Follow the coding standards
- [ ] Add tests for new functionality
- [ ] Update documentation
- [ ] Ensure all CI checks pass
- [ ] Use the pull request template

## 📋 Requirements

### Terraform Versions

- Terraform >= 1.11.0
- Provider versions as specified in each module's `versions.tf`

### Cloud Provider Support

| Provider | Minimum Version | Status |
|----------|----------------|--------|
| AWS      | ~> 5.0         | ✅ Active |
| Azure    | ~> 3.0         | ✅ Active |
| GCP      | ~> 4.0         | ✅ Active |

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [docs](./docs/) directory
- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: Join GitHub Discussions for questions and community support
- **Security**: Report security issues privately to the maintainers

## 🗺️ Roadmap

### Current Focus (Q1 2024)

- [ ] Foundation module implementations
- [ ] AWS provider modules
- [ ] Testing framework
- [ ] Documentation site

### Upcoming (Q2 2024)

- [ ] Azure provider modules
- [ ] GCP provider modules
- [ ] Self-service portal integration
- [ ] AI agent enhancements

### Future

- [ ] Advanced compliance features
- [ ] Cost optimization automation
- [ ] Multi-cloud disaster recovery
- [ ] Kubernetes integration

## 📊 Metrics

- **Modules**: 0 (in development)
- **Cloud Providers**: 3 (AWS, Azure, GCP)
- **Contributors**: 1
- **License**: Apache 2.0
- **Test Coverage**: TBD

---

**Built with ❤️ by the Brockhoff Cloud team**
