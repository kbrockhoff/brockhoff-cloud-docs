# Getting Started Tutorial

This step-by-step tutorial will guide you through deploying your first infrastructure using Brockhoff Cloud Terraform modules. By the end, you'll have a complete web application stack running on AWS.

## What You'll Build

- A VPC with public and private subnets
- An Application Load Balancer
- Auto-scaling web servers
- An RDS PostgreSQL database
- Proper security groups and encryption
- Cost monitoring and compliance reporting

## Prerequisites

### Required Tools

1. **Terraform** >= 1.11.0
   ```bash
   # Install via Homebrew (macOS)
   brew install terraform
   
   # Or download from https://www.terraform.io/downloads.html
   ```

2. **AWS CLI** configured with credentials
   ```bash
   # Install AWS CLI
   brew install awscli
   
   # Configure credentials
   aws configure
   ```

3. **Git** for version control
   ```bash
   brew install git
   ```

### AWS Setup

1. **Create an AWS Account** if you don't have one
2. **Create an IAM User** with programmatic access
3. **Attach Policies**: `PowerUserAccess` (for this tutorial)
4. **Configure AWS CLI** with your credentials

## Step 1: Project Setup

Create a new directory for your project:

```bash
mkdir my-web-app
cd my-web-app
```

Create the basic project structure:

```bash
# Create directories
mkdir -p {environments/dev,environments/prod,modules}

# Create main files
touch main.tf variables.tf outputs.tf terraform.tfvars.example
```

Your project structure should look like:
```
my-web-app/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── environments/
│   ├── dev/
│   └── prod/
└── modules/
```

## Step 2: Define Variables

Create `variables.tf` with the configuration options:

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "application_name" {
  description = "Name of the application"
  type        = string
  default     = "my-web-app"
}

variable "organization" {
  description = "Organization name"
  type        = string
  default     = "my-company"
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Free tier eligible
}

variable "min_servers" {
  description = "Minimum number of web servers"
  type        = number
  default     = 1
}

variable "max_servers" {
  description = "Maximum number of web servers"
  type        = number
  default     = 3
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: Open to internet - restrict in production
}
```

## Step 3: Main Configuration

Create `main.tf` with your infrastructure definition:

```hcl
# main.tf
terraform {
  required_version = ">= 1.11"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Application   = var.application_name
      Organization  = var.organization
      ManagedBy     = "Terraform"
      Tutorial      = "BrockhoffCloud"
    }
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Context module for consistent naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  name         = var.application_name
  environment  = var.environment
  organization = var.organization
  
  # Additional tags
  tags = {
    Project    = "WebAppTutorial"
    Owner      = "DevTeam"
    CostCenter = "Engineering"
  }
  
  # Data-specific tags for storage resources
  data_tags = {
    DataClass     = "Internal"
    RetentionDays = "90"
  }
}

# Networking foundation
module "networking" {
  source = "kbrockhoff/networking/aws"
  
  context = module.context.context
  
  # VPC configuration
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Subnet configuration
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  
  # Enable NAT Gateway for private subnet internet access
  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev" ? true : false  # Cost optimization for dev
  
  # Enable VPC Flow Logs for security
  enable_flow_logs = true
  
  # Environment-specific settings
  environment_type = var.environment == "prod" ? "Production" : "Development"
}

# Security groups
module "security" {
  source = "kbrockhoff/security/aws"
  
  context = module.context.context
  vpc_id  = module.networking.vpc_id
  
  # Allow HTTP/HTTPS from specified CIDR blocks
  allowed_cidr_blocks = var.allowed_cidr_blocks
  
  # Enable additional security features for production
  enable_waf = var.environment == "prod"
  
  environment_type = var.environment == "prod" ? "Production" : "Development"
}

# Application Load Balancer
module "load_balancer" {
  source = "kbrockhoff/load-balancer/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids
  
  # Security configuration
  security_group_ids = [module.security.alb_security_group_id]
  
  # SSL/TLS configuration (you can add your own certificate)
  enable_https = false  # Set to true and provide certificate_arn for production
  
  # Health check configuration
  health_check = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
  
  environment_type = var.environment == "prod" ? "Production" : "Development"
}

# Auto Scaling Group with Launch Template
module "web_servers" {
  source = "kbrockhoff/auto-scaling/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  # Instance configuration
  instance_type = var.instance_type
  
  # Auto scaling configuration
  min_size         = var.min_servers
  max_size         = var.max_servers
  desired_capacity = var.min_servers
  
  # Load balancer integration
  target_group_arn = module.load_balancer.target_group_arn
  
  # Security
  security_group_ids = [module.security.instance_security_group_id]
  
  # User data script for web server setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    database_endpoint = module.database.endpoint
    database_name     = module.database.database_name
  }))
  
  # Environment-specific configuration
  environment_type = var.environment == "prod" ? "Production" : "Development"
  
  # Enable detailed monitoring for production
  enable_monitoring = var.environment == "prod"
}

# RDS PostgreSQL Database
module "database" {
  source = "kbrockhoff/rds/aws"
  
  context    = module.context.context
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.database_subnet_ids
  
  # Database configuration
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.database_instance_class
  
  # Database settings
  database_name = "webapp"
  username      = "webapp_user"
  
  # Security
  security_group_ids = [module.security.database_security_group_id]
  
  # Backup configuration (environment-specific)
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # High availability for production
  multi_az = var.environment == "prod"
  
  # Environment-specific settings
  environment_type = var.environment == "prod" ? "Production" : "Development"
  
  # Enable encryption
  encryption_config = {
    create_kms_key               = true
    kms_key_id                   = ""
    kms_key_deletion_window_days = var.environment == "prod" ? 30 : 7
  }
}

# Cost monitoring (optional but recommended)
module "cost_monitoring" {
  source = "kbrockhoff/cost-monitoring/aws"
  
  context = module.context.context
  
  # Budget configuration
  monthly_budget_limit = var.environment == "prod" ? 500 : 100  # USD
  
  # Alert thresholds
  alert_thresholds = [50, 80, 100]  # Percentages
  
  # Notification email (replace with your email)
  notification_emails = ["admin@${var.organization}.com"]
  
  # Cost optimization features
  enable_rightsizing_recommendations = true
  enable_reserved_instance_recommendations = var.environment == "prod"
}
```

## Step 4: Create User Data Script

Create `user-data.sh` for web server initialization:

```bash
#!/bin/bash
# user-data.sh

# Update system
yum update -y

# Install Apache web server
yum install -y httpd

# Install PostgreSQL client
yum install -y postgresql15

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Web App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .info { background-color: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Welcome to My Web App!</h1>
        
        <div class="status success">
            <h3>✅ Web Server Status</h3>
            <p>Your web server is running successfully!</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
        </div>
        
        <div class="status info">
            <h3>📊 Infrastructure Details</h3>
            <p><strong>Environment:</strong> ${var.environment}</p>
            <p><strong>Database Endpoint:</strong> ${database_endpoint}</p>
            <p><strong>Database Name:</strong> ${database_name}</p>
        </div>
        
        <div class="status info">
            <h3>🏗️ Built with Brockhoff Cloud Modules</h3>
            <ul>
                <li>Multi-AZ VPC with public and private subnets</li>
                <li>Application Load Balancer with health checks</li>
                <li>Auto Scaling Group for high availability</li>
                <li>RDS PostgreSQL database with encryption</li>
                <li>Security groups with least-privilege access</li>
                <li>Cost monitoring and optimization</li>
            </ul>
        </div>
    </div>
    
    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(error => document.getElementById('instance-id').textContent = 'Unable to fetch');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(error => document.getElementById('az').textContent = 'Unable to fetch');
    </script>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.html
chmod 644 /var/www/html/index.html

# Configure Apache to start on boot
systemctl enable httpd

# Create a simple health check endpoint
echo "OK" > /var/www/html/health

# Log completion
echo "Web server setup completed at $(date)" >> /var/log/user-data.log
```

Make the script executable:
```bash
chmod +x user-data.sh
```

## Step 5: Define Outputs

Create `outputs.tf` to display important information:

```hcl
# outputs.tf

# Application URL
output "application_url" {
  description = "URL to access the web application"
  value       = "http://${module.load_balancer.dns_name}"
}

# Load Balancer Information
output "load_balancer" {
  description = "Load balancer details"
  value = {
    dns_name = module.load_balancer.dns_name
    zone_id  = module.load_balancer.zone_id
    arn      = module.load_balancer.arn
  }
}

# Database Information
output "database" {
  description = "Database connection information"
  value = {
    endpoint = module.database.endpoint
    port     = module.database.port
    name     = module.database.database_name
  }
  sensitive = true
}

# VPC Information
output "vpc" {
  description = "VPC details"
  value = {
    id               = module.networking.vpc_id
    cidr_block       = module.networking.vpc_cidr_block
    public_subnets   = module.networking.public_subnet_ids
    private_subnets  = module.networking.private_subnet_ids
    database_subnets = module.networking.database_subnet_ids
  }
}

# Cost Estimates
output "cost_estimates" {
  description = "Monthly cost estimates for all resources"
  value = {
    networking     = module.networking.monthly_cost_estimate
    load_balancer  = module.load_balancer.monthly_cost_estimate
    web_servers    = module.web_servers.monthly_cost_estimate
    database       = module.database.monthly_cost_estimate
    total_estimate = format("$%.2f", 
      module.networking.monthly_cost_estimate +
      module.load_balancer.monthly_cost_estimate +
      module.web_servers.monthly_cost_estimate +
      module.database.monthly_cost_estimate
    )
  }
}

# Security Information
output "security" {
  description = "Security group IDs"
  value = {
    alb_security_group      = module.security.alb_security_group_id
    instance_security_group = module.security.instance_security_group_id
    database_security_group = module.security.database_security_group_id
  }
}

# Compliance Report
output "compliance_report" {
  description = "Well-architected framework compliance summary"
  value = {
    networking_compliance = module.networking.compliance_report
    security_compliance   = module.security.compliance_report
    database_compliance   = module.database.compliance_report
  }
}

# Resource Tags
output "resource_tags" {
  description = "Tags applied to all resources"
  value = module.context.tags
}
```

## Step 6: Create Configuration File

Create `terraform.tfvars.example` as a template:

```hcl
# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize the values

# Basic Configuration
aws_region       = "us-west-2"
environment      = "dev"
application_name = "my-web-app"
organization     = "my-company"

# Instance Configuration
instance_type            = "t3.micro"    # Free tier eligible
database_instance_class  = "db.t3.micro" # Free tier eligible

# Scaling Configuration
min_servers = 1
max_servers = 3

# Security Configuration (IMPORTANT: Restrict this in production!)
allowed_cidr_blocks = ["0.0.0.0/0"]  # WARNING: Open to internet
```

Copy the example file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values.

## Step 7: Deploy Your Infrastructure

### Initialize Terraform

```bash
terraform init
```

This downloads the required providers and modules.

### Plan the Deployment

```bash
terraform plan
```

Review the plan to see what resources will be created. You should see:
- VPC with subnets across multiple AZs
- Internet Gateway and NAT Gateway
- Security Groups
- Application Load Balancer
- Launch Template and Auto Scaling Group
- RDS PostgreSQL instance
- Cost monitoring resources

### Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. The deployment will take 10-15 minutes.

### Verify the Deployment

Once complete, Terraform will output important information:

```bash
# View outputs
terraform output

# Get the application URL
terraform output application_url
```

Visit the application URL in your browser to see your web application!

## Step 8: Test Your Application

### Access the Web Application

1. **Get the URL**: `terraform output application_url`
2. **Open in Browser**: You should see the welcome page
3. **Check Health**: Visit `<url>/health` to see the health check endpoint

### Verify Infrastructure Components

1. **AWS Console**: Log into AWS and verify resources were created
2. **Load Balancer**: Check that targets are healthy
3. **Auto Scaling**: Verify the instance is running
4. **Database**: Confirm RDS instance is available
5. **Cost Monitoring**: Check AWS Budgets for cost tracking

### Test Auto Scaling (Optional)

Generate some load to test auto scaling:

```bash
# Install Apache Bench (if not already installed)
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Generate load (replace URL with your application URL)
ab -n 1000 -c 10 http://your-load-balancer-url/
```

Monitor the Auto Scaling Group in the AWS Console to see if new instances are launched.

## Step 9: Monitor Costs

### View Cost Estimates

```bash
terraform output cost_estimates
```

This shows estimated monthly costs for each component.

### Set Up Budget Alerts

The cost monitoring module automatically creates:
- Monthly budget with your specified limit
- Alerts at 50%, 80%, and 100% of budget
- Email notifications (update the email in your configuration)

### Monitor in AWS Console

1. Go to **AWS Budgets** in the console
2. View your budget and current spending
3. Check **Cost Explorer** for detailed cost analysis

## Step 10: Clean Up (Optional)

When you're done experimenting, clean up to avoid charges:

```bash
# Destroy all resources
terraform destroy
```

Type `yes` when prompted. This will remove all created resources.

## Next Steps

Congratulations! You've successfully deployed a complete web application infrastructure using Brockhoff Cloud modules. Here's what you can explore next:

### 1. Production Deployment

Modify your configuration for production:

```hcl
# In terraform.tfvars
environment = "prod"
instance_type = "t3.medium"
database_instance_class = "db.t3.small"
min_servers = 2
max_servers = 10

# Restrict access
allowed_cidr_blocks = ["10.0.0.0/8"]  # Your corporate network
```

### 2. Add HTTPS/SSL

```hcl
# In main.tf, update load_balancer module
module "load_balancer" {
  # ... existing configuration
  
  enable_https = true
  certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
}
```

### 3. Multi-Environment Setup

Create separate configurations for different environments:

```bash
# Create environment-specific directories
mkdir -p environments/{dev,staging,prod}

# Move configuration to environment directories
# Use Terraform workspaces or separate state files
```

### 4. Add Monitoring and Logging

```hcl
# Add monitoring module
module "monitoring" {
  source = "kbrockhoff/monitoring/aws"
  
  context = module.context.context
  
  # Monitor your application
  application_name = var.application_name
  load_balancer_arn = module.load_balancer.arn
  auto_scaling_group_name = module.web_servers.auto_scaling_group_name
}
```

### 5. Implement CI/CD

Set up automated deployments with GitHub Actions:

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### 6. Explore Other Modules

- **Container Orchestration**: Deploy with ECS or EKS
- **Serverless**: Use Lambda and API Gateway
- **Data Pipeline**: Set up ETL with Glue and Redshift
- **Multi-Cloud**: Deploy the same application on Azure or GCP

## Troubleshooting

### Common Issues

1. **Module Not Found**: Run `terraform init` to download modules
2. **Permission Denied**: Check AWS credentials and IAM permissions
3. **Resource Limits**: Verify AWS service limits in your region
4. **Cost Concerns**: Monitor the cost estimates and set up budgets

### Getting Help

- **Documentation**: Check the [User Guide](../user-guide.md)
- **Examples**: Review the [examples](../../examples/) directory
- **Issues**: Search [GitHub Issues](https://github.com/kbrockhoff/brockhoff-cloud-docs/issues)
- **Community**: Join [GitHub Discussions](https://github.com/kbrockhoff/brockhoff-cloud-docs/discussions)

## Summary

You've learned how to:
- ✅ Set up a Terraform project with Brockhoff Cloud modules
- ✅ Deploy a complete web application infrastructure
- ✅ Configure networking, security, and databases
- ✅ Implement cost monitoring and optimization
- ✅ Follow security and compliance best practices
- ✅ Use consistent naming and tagging patterns

The infrastructure you built includes enterprise-grade features like auto-scaling, load balancing, encryption, monitoring, and cost optimization - all with just a few hundred lines of configuration!

Happy building! 🚀