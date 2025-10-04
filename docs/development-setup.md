# Development Setup Guide

This guide provides detailed instructions for setting up a development environment for contributing to Brockhoff Cloud Terraform modules.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Tool Installation](#tool-installation)
3. [Repository Setup](#repository-setup)
4. [Development Workflow](#development-workflow)
5. [Testing Setup](#testing-setup)
6. [IDE Configuration](#ide-configuration)
7. [Troubleshooting](#troubleshooting)

## System Requirements

### Supported Operating Systems

- **macOS** 10.15+ (Catalina or later)
- **Linux** (Ubuntu 20.04+, RHEL 8+, or equivalent)
- **Windows** 10+ with WSL2 (recommended) or native Windows

### Hardware Requirements

- **CPU**: 2+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space for tools and repositories
- **Network**: Reliable internet connection for downloading providers and modules

## Tool Installation

### Core Tools

#### 1. Terraform

**macOS (Homebrew)**:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux (Ubuntu/Debian)**:
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Windows (Chocolatey)**:
```powershell
choco install terraform
```

**Verify Installation**:
```bash
terraform version
# Should show: Terraform v1.11.0 or later
```

#### 2. Go (for testing)

**macOS**:
```bash
brew install go
```

**Linux**:
```bash
# Download and install Go
wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
```

**Windows**:
Download installer from https://golang.org/dl/

**Verify Installation**:
```bash
go version
# Should show: go version go1.21.0 or later
```

#### 3. Git

**macOS**:
```bash
# Usually pre-installed, or:
brew install git
```

**Linux**:
```bash
sudo apt install git  # Ubuntu/Debian
sudo yum install git  # RHEL/CentOS
```

**Configure Git**:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Development Tools

#### 1. terraform-docs

**macOS**:
```bash
brew install terraform-docs
```

**Linux**:
```bash
curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/
rm terraform-docs.tar.gz
```

**Verify**:
```bash
terraform-docs --version
```

#### 2. tflint

**macOS**:
```bash
brew install tflint
```

**Linux**:
```bash
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
```

**Verify**:
```bash
tflint --version
```

#### 3. Make

**macOS**:
```bash
# Usually pre-installed with Xcode Command Line Tools
xcode-select --install
```

**Linux**:
```bash
sudo apt-get install build-essential  # Ubuntu/Debian
sudo yum groupinstall "Development Tools"  # RHEL/CentOS
```

**Windows**:
```powershell
choco install make
```

### Optional Tools

#### 1. pre-commit (Git Hooks)

```bash
# Install via pip
pip install pre-commit

# Or via Homebrew (macOS)
brew install pre-commit
```

#### 2. trivy (Security Scanning)

**macOS**:
```bash
brew install aquasecurity/trivy/trivy
```

**Linux**:
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

#### 3. checkov (Infrastructure Security)

```bash
pip install checkov
```

#### 4. AWS CLI (for AWS modules)

**macOS**:
```bash
brew install awscli
```

**Linux**:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Configure**:
```bash
aws configure
```

#### 5. Azure CLI (for Azure modules)

**macOS**:
```bash
brew install azure-cli
```

**Linux**:
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Login**:
```bash
az login
```

#### 6. Google Cloud SDK (for GCP modules)

**macOS**:
```bash
brew install google-cloud-sdk
```

**Linux**:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Initialize**:
```bash
gcloud init
```

## Repository Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/brockhoff-cloud-docs.git
cd brockhoff-cloud-docs

# Add upstream remote
git remote add upstream https://github.com/kbrockhoff/brockhoff-cloud-docs.git
```

### 2. Install Development Dependencies

```bash
# Install all development tools
make install-tools

# Initialize Terraform
make init

# Verify setup
make validate
```

### 3. Set Up Pre-commit Hooks (Optional)

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks on all files (first time)
pre-commit run --all-files
```

### 4. Environment Variables

Create a `.env` file for local development:

```bash
# .env (add to .gitignore)
export TF_LOG=INFO
export TF_LOG_PATH=./terraform.log

# AWS (if working with AWS modules)
export AWS_PROFILE=default
export AWS_REGION=us-west-2

# Azure (if working with Azure modules)
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# GCP (if working with GCP modules)
export GOOGLE_PROJECT="your-project-id"
export GOOGLE_REGION="us-west2"
```

Load environment variables:
```bash
source .env
```

## Development Workflow

### Daily Workflow

#### 1. Start Development

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/my-new-feature
```

#### 2. Make Changes

```bash
# Edit files
# ... make your changes ...

# Format code
make format

# Validate syntax
make validate

# Run tests
make test

# Generate documentation
make docs
```

#### 3. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add new compute module for AWS"

# Or for bug fixes
git commit -m "fix: resolve security group rule conflict"
```

#### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/my-new-feature

# Create pull request on GitHub
```

### Makefile Commands

The project includes a comprehensive Makefile with these commands:

```bash
# Show all available commands
make help

# Development commands
make init          # Initialize Terraform modules
make validate      # Validate Terraform configuration
make format        # Format all Terraform files
make test          # Run all tests
make docs          # Generate documentation
make lint          # Run linting and validation
make security      # Run security scans
make clean         # Clean up temporary files

# CI/CD commands
make ci            # Run all CI checks
make install-tools # Install development tools
make check-tools   # Verify all tools are installed
```

### Module Development

#### Creating a New Module

```bash
# Use the module template
cp -r terraform-module modules/my-new-module
cd modules/my-new-module

# Update module-specific files
# - main.tf
# - variables.tf
# - outputs.tf
# - README.md
# - examples/

# Test the module
make test

# Generate documentation
make docs
```

#### Module Structure

Follow this structure for all modules:

```
modules/my-module/
├── main.tf                 # Primary resource definitions
├── variables.tf            # Input variables with validation
├── outputs.tf             # Standardized outputs
├── versions.tf            # Provider version constraints
├── locals.tf              # Local value computations
├── data.tf                # Data source definitions
├── kms.tf                 # KMS key resources
├── alarms.tf              # Monitoring alarms
├── pricing.tf             # Cost estimation logic
├── README.md              # Usage documentation
├── CHANGELOG.md           # Version history
├── LICENSE                # ASL2 license
├── Makefile               # Build automation
├── .terraform-docs.yml    # Documentation config
├── .tflint.hcl           # Linting config
├── examples/              # Usage examples
│   ├── basic/
│   ├── advanced/
│   └── multi-cloud/
├── modules/               # Sub-modules
│   ├── pricing/
│   └── deployer/
├── test/                  # Tests
│   └── plan_test.go
├── templates/             # Template files
├── compliance/            # Compliance mappings
│   ├── aws-waf.yaml
│   ├── azure-waf.yaml
│   └── gcp-caf.yaml
└── ai-metadata.yaml       # AI integration metadata
```

## Testing Setup

### Test Framework

We use Go-based testing with Terratest for plan validation:

#### 1. Install Test Dependencies

```bash
# Initialize Go module (if not exists)
go mod init test

# Install Terratest
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert
```

#### 2. Write Tests

Create `test/plan_test.go`:

```go
package test

import (
    "testing"
    "path/filepath"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraformPlanExamples(t *testing.T) {
    examples := []string{"basic", "advanced", "multi-cloud"}
    
    for _, example := range examples {
        t.Run(example, func(t *testing.T) {
            exampleDir := filepath.Join("../examples", example)
            
            terraformOptions := &terraform.Options{
                TerraformDir: exampleDir,
                PlanFilePath: filepath.Join(exampleDir, "plan.out"),
            }
            
            // Run terraform init and plan
            terraform.Init(t, terraformOptions)
            terraform.Plan(t, terraformOptions)
            
            // Test passes if plan succeeds
            assert.True(t, true, "Terraform plan completed successfully")
        })
    }
}
```

#### 3. Run Tests

```bash
# Run all tests
make test

# Run specific test
cd test && go test -v -run TestTerraformPlanExamples
```

### Continuous Integration

Tests run automatically on:
- Pull requests
- Pushes to main branch
- Scheduled runs (daily)

Local CI simulation:
```bash
# Run all CI checks
make ci
```

## IDE Configuration

### Visual Studio Code

#### Recommended Extensions

Install these extensions for the best development experience:

```json
{
  "recommendations": [
    "hashicorp.terraform",
    "ms-vscode.vscode-go",
    "redhat.vscode-yaml",
    "ms-vscode.vscode-json",
    "davidanson.vscode-markdownlint",
    "streetsidesoftware.code-spell-checker",
    "ms-vscode.vscode-github-pullrequest"
  ]
}
```

#### Settings Configuration

Create `.vscode/settings.json`:

```json
{
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.experimentalFeatures.prefillRequiredFields": true,
  "terraform.format.enable": true,
  "go.formatTool": "goimports",
  "go.lintTool": "golangci-lint",
  "files.associations": {
    "*.tf": "terraform",
    "*.tfvars": "terraform"
  },
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  }
}
```

#### Tasks Configuration

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "terraform-init",
      "type": "shell",
      "command": "make init",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "terraform-validate",
      "type": "shell",
      "command": "make validate",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "run-tests",
      "type": "shell",
      "command": "make test",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    }
  ]
}
```

### IntelliJ IDEA / GoLand

#### Plugins

Install these plugins:
- Terraform and HCL
- Go (if using IntelliJ IDEA)
- Markdown
- YAML/Ansible Support

#### Configuration

1. **File Types**: Associate `.tf` files with Terraform
2. **Code Style**: Import Terraform formatting rules
3. **External Tools**: Configure Make commands
4. **Version Control**: Set up Git integration

### Vim/Neovim

#### Plugins (using vim-plug)

```vim
" .vimrc or init.vim
Plug 'hashivim/vim-terraform'
Plug 'fatih/vim-go'
Plug 'plasticboy/vim-markdown'
Plug 'stephpy/vim-yaml'
```

#### Configuration

```vim
" Terraform settings
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1

" Go settings
let g:go_fmt_command = "goimports"
let g:go_auto_type_info = 1
```

## Troubleshooting

### Common Issues

#### 1. Terraform Provider Download Issues

**Problem**: Providers fail to download
```bash
Error: Failed to install provider
```

**Solution**:
```bash
# Clear provider cache
rm -rf .terraform
terraform init

# Or use specific provider source
terraform init -upgrade
```

#### 2. Go Module Issues

**Problem**: Go dependencies not found
```bash
go: module not found
```

**Solution**:
```bash
# Initialize Go module
go mod init test
go mod tidy

# Download dependencies
go get github.com/gruntwork-io/terratest/modules/terraform
```

#### 3. Make Command Not Found

**Problem**: `make` command not available

**Solution**:
```bash
# macOS
xcode-select --install

# Linux
sudo apt-get install build-essential

# Windows
choco install make
```

#### 4. Permission Issues

**Problem**: Permission denied errors

**Solution**:
```bash
# Fix file permissions
chmod +x scripts/*.sh
chmod +x Makefile

# Fix directory permissions
chmod -R 755 .
```

#### 5. AWS Credentials Issues

**Problem**: AWS authentication failures

**Solution**:
```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-west-2"

# Verify credentials
aws sts get-caller-identity
```

### Getting Help

#### Documentation

- [User Guide](./user-guide.md)
- [Architecture Decisions](./architecture-decisions.md)
- [API Documentation](./api-reference.md)

#### Community Support

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Stack Overflow**: Tag questions with `brockhoff-cloud`

#### Professional Support

For enterprise customers:
- Email: support@brockhoff.cloud
- Slack: #brockhoff-cloud (enterprise customers only)

### Debug Mode

Enable debug logging for troubleshooting:

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Enable Go test verbose output
go test -v

# Enable Make debug output
make -d
```

### Performance Optimization

#### Terraform Performance

```bash
# Use parallelism for faster operations
terraform plan -parallelism=10
terraform apply -parallelism=10

# Enable provider plugin cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p $TF_PLUGIN_CACHE_DIR
```

#### Test Performance

```bash
# Run tests in parallel
go test -parallel 4

# Use test caching
go test -cache
```

## Next Steps

After completing the development setup:

1. **Read the [User Guide](./user-guide.md)** to understand module usage
2. **Review [Coding Standards](../CONTRIBUTING.md#coding-standards)** for consistency
3. **Explore [Examples](../../examples/)** to see module implementations
4. **Join the Community** through GitHub Discussions
5. **Start Contributing** by picking up a "good first issue"

Happy coding! 🚀