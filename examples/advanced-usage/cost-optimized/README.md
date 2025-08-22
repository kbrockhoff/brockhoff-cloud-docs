# Cost-Optimized Architecture Example

This example demonstrates how to deploy a production-capable application architecture while minimizing costs through intelligent resource selection, scheduling, and optimization strategies.

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│      Cost-Optimized Load Balancer      │
│    (Shared ALB with path routing)       │
│  - Multiple applications per LB         │
│  - Intelligent health checks           │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│        Spot Instance Fleet              │
│      (Mixed Instance Types)             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │  Spot   │  │  Spot   │  │On-Demand│ │
│  │Instance │  │Instance │  │Instance │ │
│  │(t3.nano)│  │(t3.micro)│ │(t3.small)│ │
│  └─────────┘  └─────────┘  └─────────┘ │
│     Scheduled Auto Scaling              │
│   (Scale down during off-hours)         │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│       Serverless Components             │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Lambda    │  │    DynamoDB     │   │
│  │ Functions   │  │  (On-Demand)    │   │
│  │(Event-driven)│  │                 │   │
│  └─────────────┘  └─────────────────┘   │
│                                         │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │     S3      │  │   CloudWatch    │   │
│  │(Intelligent │  │  (Basic tier)   │   │
│  │  Tiering)   │  │                 │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## Cost Optimization Strategies

### 1. Compute Optimization
- **Spot Instances**: 60-90% cost savings for fault-tolerant workloads
- **Mixed Instance Types**: Diversified spot fleet for availability
- **Scheduled Scaling**: Automatic shutdown during off-hours
- **Right-sizing**: Continuous monitoring and instance type recommendations

### 2. Storage Optimization
- **Intelligent Tiering**: Automatic movement to cheaper storage classes
- **Lifecycle Policies**: Automated deletion of old data
- **Compression**: Reduce storage requirements
- **Deduplication**: Eliminate redundant data

### 3. Network Optimization
- **Shared Load Balancers**: Multiple applications per ALB
- **VPC Endpoints**: Avoid NAT Gateway charges for AWS services
- **CloudFront**: Reduce origin requests and bandwidth costs
- **Regional Optimization**: Deploy in cost-effective regions

### 4. Database Optimization
- **Serverless Databases**: Pay-per-request pricing
- **Read Replicas**: Only where necessary for performance
- **Connection Pooling**: Reduce database instance requirements
- **Query Optimization**: Reduce compute and I/O costs

### 5. Monitoring Optimization
- **Basic Monitoring**: Essential metrics only
- **Log Retention**: Shorter retention periods for non-critical logs
- **Custom Metrics**: Only business-critical metrics
- **Alert Optimization**: Reduce noise and false positives

## Cost Comparison

### Traditional Architecture vs Cost-Optimized

| Component | Traditional | Cost-Optimized | Savings |
|-----------|-------------|----------------|---------|
| **Compute** | $200/month | $60/month | 70% |
| **Database** | $150/month | $45/month | 70% |
| **Storage** | $50/month | $20/month | 60% |
| **Network** | $75/month | $30/month | 60% |
| **Monitoring** | $100/month | $25/month | 75% |
| **Total** | **$575/month** | **$180/month** | **69%** |

### Environment-Specific Costs

#### Development Environment
- **Compute**: Spot instances only, scheduled shutdown
- **Database**: Serverless with minimal capacity
- **Storage**: Standard tier with aggressive lifecycle
- **Monitoring**: Basic CloudWatch only
- **Estimated Cost**: $50-80/month

#### Staging Environment
- **Compute**: 80% spot, 20% on-demand
- **Database**: Small reserved instance
- **Storage**: Intelligent tiering enabled
- **Monitoring**: Enhanced monitoring for testing
- **Estimated Cost**: $120-180/month

#### Production Environment
- **Compute**: 60% spot, 40% on-demand with reserved instances
- **Database**: Reserved instances with read replicas
- **Storage**: Full intelligent tiering and CDN
- **Monitoring**: Comprehensive monitoring with optimization
- **Estimated Cost**: $300-500/month

## Implementation Features

### Spot Instance Management
```hcl
spot_fleet_config = {
  # Mixed instance types for diversification
  instance_types = ["t3.nano", "t3.micro", "t3.small", "t4g.nano", "t4g.micro"]
  
  # Spot allocation strategy
  allocation_strategy = "diversified"
  
  # On-demand base capacity (minimum guaranteed)
  on_demand_base_capacity = 1
  on_demand_percentage   = 20  # 20% on-demand, 80% spot
  
  # Spot interruption handling
  spot_interruption_behavior = "terminate"
  spot_max_price            = "0.05"  # Maximum price per hour
}
```

### Scheduled Scaling
```hcl
scheduled_scaling = {
  # Scale down during nights (assuming US Eastern time)
  night_schedule = {
    recurrence   = "0 22 * * MON-FRI"  # 10 PM weekdays
    min_size     = 0
    max_size     = 2
    desired_capacity = 0
  }
  
  # Scale up for business hours
  morning_schedule = {
    recurrence   = "0 8 * * MON-FRI"   # 8 AM weekdays
    min_size     = 2
    max_size     = 10
    desired_capacity = 3
  }
  
  # Weekend minimal capacity
  weekend_schedule = {
    recurrence   = "0 0 * * SAT"       # Saturday midnight
    min_size     = 0
    max_size     = 2
    desired_capacity = 1
  }
}
```

### Storage Lifecycle Management
```hcl
storage_lifecycle = {
  # Intelligent tiering for automatic cost optimization
  intelligent_tiering = {
    enabled = true
    
    # Archive after 90 days of no access
    archive_transition_days = 90
    
    # Deep archive after 180 days
    deep_archive_transition_days = 180
  }
  
  # Automatic cleanup policies
  cleanup_policies = {
    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload_days = 7
    
    # Delete old versions after 30 days
    noncurrent_version_expiration_days = 30
    
    # Delete expired delete markers
    expired_object_delete_marker = true
  }
}
```

### Database Cost Optimization
```hcl
database_optimization = {
  # Use Aurora Serverless for variable workloads
  engine_mode = "serverless"
  
  scaling_configuration = {
    auto_pause               = true
    max_capacity            = 16
    min_capacity            = 2
    seconds_until_auto_pause = 300  # 5 minutes
  }
  
  # Backup optimization
  backup_retention_period = 7     # Minimum for point-in-time recovery
  preferred_backup_window = "03:00-04:00"  # Low-traffic hours
  
  # Performance Insights (free tier)
  performance_insights_enabled = true
  performance_insights_retention_period = 7  # Free tier limit
}
```

## Monitoring and Cost Control

### Cost Monitoring
```hcl
cost_monitoring = {
  # Budget alerts
  monthly_budget = 200  # USD
  
  alert_thresholds = [
    {
      threshold     = 50   # 50% of budget
      threshold_type = "PERCENTAGE"
      notification_type = "ACTUAL"
    },
    {
      threshold     = 80   # 80% of budget
      threshold_type = "PERCENTAGE"
      notification_type = "FORECASTED"
    },
    {
      threshold     = 100  # 100% of budget
      threshold_type = "PERCENTAGE"
      notification_type = "ACTUAL"
    }
  ]
  
  # Cost allocation tags
  cost_allocation_tags = [
    "Environment",
    "Project",
    "Owner",
    "CostCenter"
  ]
}
```

### Right-Sizing Recommendations
```hcl
rightsizing_config = {
  # Enable AWS Compute Optimizer
  enable_compute_optimizer = true
  
  # CloudWatch metrics for analysis
  metrics_collection = {
    cpu_utilization    = true
    memory_utilization = true
    network_utilization = true
    disk_utilization   = true
  }
  
  # Automated recommendations
  recommendation_frequency = "weekly"
  
  # Thresholds for recommendations
  cpu_threshold_low  = 25  # Recommend smaller instance
  cpu_threshold_high = 80  # Recommend larger instance
  
  memory_threshold_low  = 30
  memory_threshold_high = 85
}
```

## Deployment Strategies

### Blue-Green with Cost Optimization
```hcl
blue_green_config = {
  # Use spot instances for non-production environment
  blue_environment = {
    instance_types = ["t3.micro", "t3.small"]
    spot_percentage = 100
    min_capacity   = 0
  }
  
  green_environment = {
    instance_types = ["t3.small", "t3.medium"]
    spot_percentage = 80
    min_capacity   = 1
  }
  
  # Traffic shifting strategy
  traffic_shifting = {
    initial_green_percentage = 10
    increment_percentage    = 10
    increment_interval     = "5m"
  }
}
```

### Canary Deployment with Cost Control
```hcl
canary_config = {
  # Minimal canary capacity
  canary_capacity = {
    min_size         = 1
    max_size         = 2
    desired_capacity = 1
  }
  
  # Gradual traffic increase
  traffic_increment = {
    initial_percentage = 5
    increment_step    = 5
    increment_interval = 300  # 5 minutes
    max_percentage    = 50
  }
  
  # Automatic rollback on high error rate
  rollback_triggers = {
    error_rate_threshold = 5    # 5% error rate
    latency_threshold   = 2000  # 2 seconds
    evaluation_period   = 300   # 5 minutes
  }
}
```

## Cost Optimization Tools

### AWS Cost Explorer Integration
```hcl
cost_explorer_config = {
  # Automated cost reports
  daily_cost_report = {
    enabled = true
    s3_bucket = module.storage.bucket_name
    s3_prefix = "cost-reports/"
  }
  
  # Reserved Instance recommendations
  ri_recommendations = {
    enabled = true
    lookback_period = "SIXTY_DAYS"
    payment_option = "PARTIAL_UPFRONT"
  }
  
  # Savings Plans recommendations
  savings_plans_recommendations = {
    enabled = true
    lookback_period = "SIXTY_DAYS"
    payment_option = "PARTIAL_UPFRONT"
  }
}
```

### Automated Cost Optimization
```hcl
automation_config = {
  # Lambda function for cost optimization
  cost_optimizer_lambda = {
    schedule = "rate(1 day)"  # Daily execution
    
    actions = [
      "stop_unused_instances",
      "delete_old_snapshots",
      "optimize_storage_classes",
      "cleanup_unused_resources"
    ]
  }
  
  # Trusted Advisor integration
  trusted_advisor = {
    enabled = true
    check_categories = [
      "cost_optimizing",
      "performance",
      "security"
    ]
  }
}
```

## Quick Start

### Prerequisites
1. **AWS Account** with Cost Explorer enabled
2. **Terraform >= 1.0** installed
3. **AWS CLI** configured with appropriate permissions
4. **Budget alerts** configured for cost monitoring

### Deployment Steps

1. **Configure cost parameters**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Set your budget limits and cost thresholds
   ```

2. **Deploy with cost monitoring**:
   ```bash
   terraform init
   terraform plan -var="enable_cost_monitoring=true"
   terraform apply
   ```

3. **Monitor costs**:
   ```bash
   # Check current costs
   aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31 --granularity MONTHLY --metrics BlendedCost

   # Get rightsizing recommendations
   aws ce get-rightsizing-recommendation
   ```

## Best Practices

### Cost Optimization Checklist

- [ ] **Compute**: Use spot instances where appropriate
- [ ] **Storage**: Enable intelligent tiering and lifecycle policies
- [ ] **Database**: Use serverless or right-sized instances
- [ ] **Network**: Implement VPC endpoints and optimize data transfer
- [ ] **Monitoring**: Use basic tier and optimize log retention
- [ ] **Scheduling**: Implement auto-scaling schedules for predictable workloads
- [ ] **Tagging**: Comprehensive cost allocation tagging
- [ ] **Budgets**: Set up budget alerts and automated responses
- [ ] **Reviews**: Regular cost reviews and optimization

### Monitoring and Alerting

- **Daily cost reports** with trend analysis
- **Budget alerts** at 50%, 80%, and 100% thresholds
- **Anomaly detection** for unusual spending patterns
- **Resource utilization** monitoring for right-sizing
- **Automated recommendations** for cost optimization

## Troubleshooting

### Common Cost Issues

1. **Unexpected charges**: Check for unused resources and data transfer costs
2. **Spot interruptions**: Implement proper interruption handling
3. **Storage costs**: Review lifecycle policies and access patterns
4. **Network costs**: Optimize data transfer and use VPC endpoints

### Cost Analysis Tools

```bash
# AWS CLI cost analysis commands
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31 --granularity DAILY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# Get reserved instance recommendations
aws ce get-reservation-recommendations --service EC2-Instance

# Check for unused resources
aws support describe-trusted-advisor-checks --language en
```

## Next Steps

1. **Implement automated cost optimization** using Lambda functions
2. **Set up comprehensive cost monitoring** and alerting
3. **Regular cost reviews** and optimization cycles
4. **Explore advanced cost optimization** techniques
5. **Scale cost optimization** across multiple environments

This cost-optimized architecture can reduce infrastructure costs by 60-80% while maintaining production-level reliability and performance.