# Contributing to Brockhoff Cloud Terraform Modules

Thank you for your interest in contributing to the Brockhoff Cloud Terraform module suite! This document provides comprehensive guidelines and information for contributors.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How to Contribute](#how-to-contribute)
3. [Development Setup](#development-setup)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Documentation Requirements](#documentation-requirements)
7. [Release Process](#release-process)
8. [Getting Help](#getting-help)

## Code of Conduct

This project adheres to a code of conduct based on the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code:

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project maintainers. All complaints will be reviewed and investigated promptly and fairly.

## How to Contribute

### Types of Contributions

We welcome several types of contributions:

#### 🐛 Bug Reports
- Use the bug report template
- Include steps to reproduce
- Provide Terraform configuration examples
- Include error messages and logs

#### 💡 Feature Requests
- Use the feature request template
- Describe the use case and benefits
- Consider implementation complexity
- Discuss alternatives you've considered

#### 📖 Documentation Improvements
- Fix typos and grammatical errors
- Improve clarity and examples
- Add missing documentation
- Update outdated information

#### 🔧 Code Contributions
- New modules or submodules
- Bug fixes and improvements
- Performance optimizations
- Security enhancements

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the appropriate template** (bug report, feature request, etc.)
3. **Provide detailed information**:
   - Terraform version
   - Provider versions
   - Operating system
   - Complete error messages
   - Minimal reproduction case

#### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Create configuration with '...'
2. Run 'terraform apply'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Configuration**
```hcl
# Your Terraform configuration here
```

**Error Output**
```
# Complete error message here
```

**Environment**
- Terraform version: [e.g. 1.11.4]
- Provider version: [e.g. aws 5.0.0]
- OS: [e.g. macOS 13.0]
- Module version: [e.g. 1.2.3]

**Additional context**
Add any other context about the problem here.
```

### Submitting Changes

#### Pull Request Process

1. **Fork the repository** and create your branch from `main`
2. **Create a feature branch**: `git checkout -b feature/my-new-feature`
3. **Follow coding standards** outlined below
4. **Add tests** for any new functionality
5. **Update documentation** as needed
6. **Ensure all tests pass**: `make test`
7. **Run linting**: `make lint`
8. **Generate documentation**: `make docs`
9. **Commit with clear messages** following [conventional commits](https://www.conventionalcommits.org/)
10. **Submit a pull request** using the provided template

#### Pull Request Template

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tests pass locally with my changes
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Documentation
- [ ] I have updated the documentation accordingly
- [ ] I have added/updated examples if needed
- [ ] I have updated the CHANGELOG.md

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] Any dependent changes have been merged and published in downstream modules
```

## Development Setup

### Prerequisites

Install the following tools:

#### Required Tools

1. **Terraform** >= 1.11.0
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_linux_amd64.zip
   unzip terraform_1.11.4_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Go** >= 1.21 (for testing)
   ```bash
   # macOS
   brew install go
   
   # Linux
   wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

3. **terraform-docs** (for documentation generation)
   ```bash
   # macOS
   brew install terraform-docs
   
   # Linux
   curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
   tar -xzf terraform-docs.tar.gz
   chmod +x terraform-docs
   sudo mv terraform-docs /usr/local/bin/
   ```

4. **tflint** (for Terraform linting)
   ```bash
   # macOS
   brew install tflint
   
   # Linux
   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
   ```

5. **Make** (build automation)
   ```bash
   # macOS (usually pre-installed)
   xcode-select --install
   
   # Linux
   sudo apt-get install build-essential  # Ubuntu/Debian
   sudo yum groupinstall "Development Tools"  # RHEL/CentOS
   ```

#### Optional Tools

1. **pre-commit** (for git hooks)
   ```bash
   pip install pre-commit
   ```

2. **trivy** (for security scanning)
   ```bash
   # macOS
   brew install trivy
   
   # Linux
   sudo apt-get install wget apt-transport-https gnupg lsb-release
   wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
   echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
   sudo apt-get update
   sudo apt-get install trivy
   ```

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/kbrockhoff/brockhoff-cloud-docs.git
   cd brockhoff-cloud-docs
   ```

2. **Install development dependencies**:
   ```bash
   make install-tools
   ```

3. **Initialize Terraform**:
   ```bash
   make init
   ```

4. **Run tests to verify setup**:
   ```bash
   make test
   ```

5. **Generate documentation**:
   ```bash
   make docs
   ```

### Development Workflow

#### Daily Development

```bash
# Start development
git checkout main
git pull origin main
git checkout -b feature/my-feature

# Make changes
# ... edit files ...

# Test changes
make validate
make test
make lint

# Generate documentation
make docs

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/my-feature
```

#### Available Make Commands

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
make install-tools # Install development tools
```

## Coding Standards

### Terraform Code Style

- Use `terraform fmt` to format all `.tf` files
- Follow HashiCorp's [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use meaningful variable and resource names
- Include descriptions for all variables and outputs
- Add validation rules for input variables where appropriate

### Module Structure

Each module must follow this structure:
```
module-name/
├── main.tf                 # Primary resource definitions
├── variables.tf            # Input variables with validation
├── outputs.tf             # Standardized outputs
├── versions.tf            # Provider version constraints
├── locals.tf              # Local value computations
├── data.tf                # Data source definitions
├── dependencies.tf        # External dependencies
├── kms.tf                 # KMS key resources
├── alarms.tf              # CloudWatch/monitoring alarms
├── pricing.tf             # Cost estimation logic
├── README.md              # Usage documentation
├── CHANGELOG.md           # Version history
├── LICENSE                # ASL2 license
├── Makefile               # Build and test automation
├── examples/              # Usage examples
├── modules/               # Sub-modules
├── test/                  # Tests
├── templates/             # Template files
├── compliance/            # Compliance mappings
└── ai-metadata.yaml       # AI agent integration metadata
```

### Variable Naming

- Use snake_case for variable names
- Use descriptive names that clearly indicate purpose
- Group related variables using consistent prefixes
- Follow existing patterns from terraform-external-context integration

### Documentation

- All variables must have descriptions
- All outputs must have descriptions
- Include usage examples in README.md
- Document any breaking changes in CHANGELOG.md
- Use terraform-docs format for consistency

### Testing

- Write tests for all new functionality
- Use the simplified plan-based testing approach
- Test all examples to ensure they work
- Include both positive and negative test cases
- Ensure tests run quickly (< 30 seconds per test)

## Multi-Cloud Considerations

### Cloud Provider Support

When adding features:
- Implement for all three cloud providers (AWS, Azure, GCP) when possible
- Use provider-specific best practices
- Maintain consistent interfaces across providers
- Document any provider-specific limitations

### Well-Architected Framework Compliance

Ensure all modules follow:
- **AWS Well-Architected Framework** principles
- **Azure Well-Architected Framework** principles  
- **Google Cloud Architecture Framework** principles

### Cost Optimization

- Use cost-effective defaults
- Provide cost estimation where possible
- Include budget-aware configurations
- Document cost implications of different options

## AI Agent Integration

When developing modules:
- Include comprehensive ai-metadata.yaml files
- Use structured, predictable interfaces
- Provide clear validation rules and error messages
- Include generation templates for common patterns
- Test with AI code generation scenarios

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

Before releasing:
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version is bumped appropriately
- [ ] Examples are tested
- [ ] Security scan passes
- [ ] Compliance validation passes

## Getting Help

- Check existing documentation and examples
- Search existing issues
- Join our community discussions
- Contact maintainers for complex questions

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- GitHub contributors list
- Release notes for significant contributions

Thank you for contributing to Brockhoff Cloud!