# Multi-Tier Web Application - AWS

This example demonstrates a production-ready, scalable multi-tier web application infrastructure on AWS using Brockhoff Cloud Terraform modules.

## Architecture

The example creates a complete multi-tier application stack including:

- **Web Tier**: CloudFront CDN for global content delivery
- **Load Balancer**: Application Load Balancer for high availability
- **Application Tier**: ElastiCache Redis for caching
- **Database Tier**: RDS MySQL for persistent data storage
- **Networking**: VPC with public, private, and database subnets across multiple AZs
- **Security**: Security groups with least-privilege access

## Components

### Networking
- VPC with CIDR `10.0.0.0/16`
- Public subnets for load balancer
- Private subnets for application components
- Database subnets for RDS
- NAT Gateway for outbound internet access

### Security
- Load balancer security group (ports 80, 443)
- Application security group (ports 80, 8080)
- Database security group (port 3306)
- All security groups follow least-privilege principles

### Load Balancing
- Application Load Balancer in public subnets
- Health checks configured for backend instances
- Target groups for application routing

### Content Delivery
- CloudFront distribution for global content delivery
- Origin pointing to Application Load Balancer
- HTTPS redirect for security

### Database
- RDS MySQL 8.0 with managed master password
- Multi-AZ deployment for high availability
- Automated backups and monitoring
- Enhanced monitoring enabled

### Caching
- ElastiCache Redis cluster
- Encryption at rest and in transit
- Located in private subnets

## Usage

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Customize the variables** in `terraform.tfvars`:
   ```hcl
   name             = "my-web-app"
   environment      = "prod"
   environment_type = "Production"
   cidr_primary     = "10.0.0.0/16"
   availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Outputs

The configuration provides several useful outputs:

- `application_url`: CloudFront URL for accessing the application
- `load_balancer_dns_name`: Direct load balancer access
- `database_endpoint`: RDS endpoint for application configuration
- `redis_endpoint`: ElastiCache endpoint for caching
- `vpc_id`: VPC identifier for additional resources

## Cost Considerations

This example is designed for production use and will incur AWS charges:

- **VPC**: NAT Gateway (~$45/month)
- **Load Balancer**: Application Load Balancer (~$20/month)
- **CloudFront**: Pay per use (varies by traffic)
- **RDS**: db.t3.micro (~$15/month)
- **ElastiCache**: cache.t3.micro (~$15/month)

For development/testing, consider:
- Setting `environment_type = "Development"` for cost optimizations
- Using smaller instance types
- Reducing backup retention periods

## Security Features

- All traffic encrypted in transit
- Database encryption at rest
- Security groups with minimal required access
- No direct internet access to application or database tiers
- IAM database authentication enabled
- Enhanced monitoring for security events

## High Availability

- Multi-AZ deployment across 3 availability zones
- Auto-scaling capable load balancer
- Database with automated failover capability
- CloudFront for global availability

## Monitoring

- Enhanced RDS monitoring
- CloudWatch integration
- Application Load Balancer access logs
- ElastiCache monitoring

## Customization

The example can be extended with:

- Auto Scaling Groups for application instances
- ECS/EKS for containerized applications
- Additional security layers (WAF, Shield)
- Custom domain names and SSL certificates
- Backup and disaster recovery solutions

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- Appropriate AWS permissions for creating VPC, RDS, ALB, CloudFront, and ElastiCache resources

## Clean Up

To avoid ongoing charges, destroy the infrastructure when no longer needed:

```bash
terraform destroy
```

**Note**: This will permanently delete all resources including databases. Ensure you have backups if needed.