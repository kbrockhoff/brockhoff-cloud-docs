# Multi-Tier Web Application Example

This example demonstrates a production-ready, scalable web application architecture using Brockhoff Cloud Terraform modules. The architecture follows a three-tier pattern with load balancing, auto-scaling, and managed database services.

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│          Load Balancer                  │
│     (Public Subnet - DMZ)              │
│  - SSL Termination                      │
│  - Health Checks                        │
│  - DDoS Protection                      │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Web Tier                      │
│      (Private Subnet)                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Web     │  │ Web     │  │ Web     │ │
│  │ Server  │  │ Server  │  │ Server  │ │
│  │ (Nginx) │  │ (Nginx) │  │ (Nginx) │ │
│  └─────────┘  └─────────┘  └─────────┘ │
│           Auto Scaling Group            │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│        Application Tier                 │
│      (Private Subnet)                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │   API   │  │   API   │  │   API   │ │
│  │ Server  │  │ Server  │  │ Server  │ │
│  │(Node.js)│  │(Node.js)│  │(Node.js)│ │
│  └─────────┘  └─────────┘  └─────────┘ │
│           Auto Scaling Group            │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          Data Tier                      │
│      (Private Subnet)                   │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Primary   │  │    Read         │   │
│  │  Database   │  │   Replicas      │   │
│  │ (PostgreSQL)│  │ (PostgreSQL)    │   │
│  └─────────────┘  └─────────────────┘   │
│                                         │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │    Redis    │  │   File Storage  │   │
│  │    Cache    │  │   (S3/Blob)     │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## Features

### High Availability
- Multi-AZ deployment across 3 availability zones
- Auto-scaling groups for web and application tiers
- Database read replicas for improved performance
- Health checks and automatic failover

### Security
- Private subnets for application and data tiers
- WAF protection for web applications
- Encryption at rest and in transit
- Network ACLs and security groups
- Secrets management for database credentials

### Performance
- CDN integration for static content
- Redis caching layer
- Database connection pooling
- Auto-scaling based on CPU and memory metrics

### Monitoring
- Application performance monitoring
- Infrastructure monitoring with dashboards
- Log aggregation and analysis
- Custom alerts and notifications

## Cloud Provider Implementations

### AWS Implementation
- **Load Balancer**: Application Load Balancer (ALB)
- **Compute**: EC2 Auto Scaling Groups
- **Database**: RDS PostgreSQL with Multi-AZ
- **Cache**: ElastiCache Redis
- **Storage**: S3 with CloudFront CDN
- **Monitoring**: CloudWatch with custom dashboards

### Azure Implementation
- **Load Balancer**: Azure Load Balancer + Application Gateway
- **Compute**: Virtual Machine Scale Sets
- **Database**: Azure Database for PostgreSQL
- **Cache**: Azure Cache for Redis
- **Storage**: Blob Storage with Azure CDN
- **Monitoring**: Azure Monitor with Log Analytics

### GCP Implementation
- **Load Balancer**: Google Cloud Load Balancing
- **Compute**: Managed Instance Groups
- **Database**: Cloud SQL PostgreSQL
- **Cache**: Memorystore for Redis
- **Storage**: Cloud Storage with Cloud CDN
- **Monitoring**: Cloud Monitoring with custom dashboards

## Resource Estimates

### Development Environment
| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Load Balancer | $16/month | $18/month | $15/month |
| Web Tier (2 instances) | $35/month | $40/month | $30/month |
| App Tier (2 instances) | $35/month | $40/month | $30/month |
| Database | $25/month | $30/month | $25/month |
| Cache | $15/month | $20/month | $15/month |
| Storage + CDN | $10/month | $12/month | $10/month |
| Monitoring | $20/month | $25/month | $20/month |
| **Total** | **~$156/month** | **~$185/month** | **~$145/month** |

### Production Environment
| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Load Balancer | $25/month | $30/month | $25/month |
| Web Tier (6 instances) | $180/month | $200/month | $160/month |
| App Tier (6 instances) | $180/month | $200/month | $160/month |
| Database (Multi-AZ) | $150/month | $180/month | $140/month |
| Cache (HA) | $80/month | $100/month | $75/month |
| Storage + CDN | $50/month | $60/month | $45/month |
| Monitoring | $75/month | $90/month | $70/month |
| **Total** | **~$740/month** | **~$860/month** | **~$675/month** |

## Quick Start

### Prerequisites

1. **Cloud provider account** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **Domain name** for SSL certificate (optional)
4. **SSH key pair** for instance access

### Deployment Steps

1. **Choose your cloud provider**:
   ```bash
   cd examples/advanced-usage/multi-tier-app/aws  # or azure, gcp
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Deploy application** (optional):
   ```bash
   # Use the provided deployment scripts
   ./scripts/deploy-application.sh
   ```

## Configuration Options

### Environment Types

Configure different environments using the `environment_type` variable:

```hcl
# Development - Cost optimized
environment_type = "Development"
web_tier_min_size = 1
web_tier_max_size = 3
app_tier_min_size = 1
app_tier_max_size = 3
database_instance_class = "small"

# Production - Performance optimized
environment_type = "Production"
web_tier_min_size = 3
web_tier_max_size = 10
app_tier_min_size = 3
app_tier_max_size = 10
database_instance_class = "large"
```

### Scaling Configuration

```hcl
# Auto-scaling policies
web_tier_scaling = {
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  scale_up_threshold   = 70  # CPU percentage
  scale_down_threshold = 30  # CPU percentage
  
  scale_up_cooldown   = 300  # seconds
  scale_down_cooldown = 300  # seconds
}

app_tier_scaling = {
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  scale_up_threshold   = 70  # CPU percentage
  scale_down_threshold = 30  # CPU percentage
  
  scale_up_cooldown   = 300  # seconds
  scale_down_cooldown = 300  # seconds
}
```

### Database Configuration

```hcl
database_config = {
  engine_version     = "13.7"
  instance_class     = "medium"  # small, medium, large, xlarge
  allocated_storage  = 100       # GB
  max_allocated_storage = 1000   # GB (auto-scaling)
  
  backup_retention_period = 7    # days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  read_replica_count     = 2
  
  performance_insights_enabled = true
  monitoring_interval         = 60
}
```

## Security Configuration

### Network Security

```hcl
security_config = {
  # WAF rules
  enable_waf = true
  waf_rules = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet"
  ]
  
  # Network access
  allowed_cidr_blocks = [
    "0.0.0.0/0"  # Public access for load balancer
  ]
  
  admin_cidr_blocks = [
    "203.0.113.0/24"  # Your office IP range
  ]
  
  # SSL/TLS
  ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
  ssl_policy         = "ELBSecurityPolicy-TLS-1-2-2017-01"
}
```

### Data Protection

```hcl
encryption_config = {
  # Database encryption
  database_encrypted = true
  kms_key_id        = ""  # Uses default if empty
  
  # Storage encryption
  s3_encryption = "AES256"
  
  # Cache encryption
  redis_encryption_at_rest    = true
  redis_encryption_in_transit = true
}
```

## Monitoring and Alerting

### Key Metrics

The example monitors these critical metrics:

- **Application Performance**: Response time, error rate, throughput
- **Infrastructure Health**: CPU, memory, disk, network utilization
- **Database Performance**: Connection count, query performance, replication lag
- **Cache Performance**: Hit ratio, memory usage, eviction rate
- **Load Balancer**: Request count, target health, latency

### Alert Configuration

```hcl
alerts_config = {
  # Application alerts
  high_error_rate_threshold    = 5   # percentage
  high_response_time_threshold = 2000 # milliseconds
  
  # Infrastructure alerts
  high_cpu_threshold    = 80  # percentage
  high_memory_threshold = 85  # percentage
  low_disk_space_threshold = 90  # percentage used
  
  # Database alerts
  high_connection_threshold = 80  # percentage of max
  high_cpu_threshold       = 75  # percentage
  replication_lag_threshold = 300 # seconds
  
  # Notification settings
  notification_emails = ["ops-team@company.com"]
  slack_webhook_url  = "https://hooks.slack.com/..."
}
```

## Application Deployment

### Sample Application

The example includes a sample Node.js application that demonstrates:

- **Health checks**: `/health` endpoint for load balancer checks
- **Database connectivity**: PostgreSQL connection with connection pooling
- **Cache integration**: Redis for session storage and caching
- **Logging**: Structured logging with correlation IDs
- **Metrics**: Custom application metrics for monitoring

### Deployment Scripts

```bash
# Deploy application code
./scripts/deploy-application.sh

# Run database migrations
./scripts/run-migrations.sh

# Update application configuration
./scripts/update-config.sh

# Rolling deployment
./scripts/rolling-deploy.sh
```

## Testing

### Load Testing

```bash
# Install dependencies
npm install -g artillery

# Run load tests
artillery run tests/load-test.yml

# Generate load test report
artillery report tests/results.json
```

### Integration Testing

```bash
# Run integration tests
npm test

# Run end-to-end tests
npm run test:e2e

# Run security tests
npm run test:security
```

## Troubleshooting

### Common Issues

1. **High latency**: Check database connection pooling and cache hit rates
2. **Auto-scaling not working**: Verify CloudWatch metrics and scaling policies
3. **Database connection errors**: Check security groups and connection limits
4. **SSL certificate issues**: Verify certificate validation and domain configuration

### Debug Commands

```bash
# Check application logs
aws logs tail /aws/ec2/application --follow

# Check database performance
aws rds describe-db-log-files --db-instance-identifier myapp-db

# Check load balancer health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check auto-scaling activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name>
```

## Cost Optimization

### Development Environment Optimizations

- Use smaller instance types
- Reduce auto-scaling group sizes
- Use single-AZ database deployment
- Disable expensive monitoring features
- Use scheduled scaling to shut down during off-hours

### Production Environment Optimizations

- Use reserved instances for predictable workloads
- Implement intelligent auto-scaling policies
- Use database read replicas strategically
- Optimize storage classes and lifecycle policies
- Monitor and right-size resources regularly

## Next Steps

1. **Customize the application** for your specific use case
2. **Implement CI/CD pipelines** for automated deployments
3. **Add additional monitoring** and observability tools
4. **Implement disaster recovery** procedures
5. **Scale to multiple regions** for global availability

## Support

- Review the [troubleshooting guide](../../../docs/troubleshooting.md)
- Check the [monitoring best practices](../../../docs/monitoring.md)
- Open an issue for bugs or feature requests
- Join the community discussions for questions