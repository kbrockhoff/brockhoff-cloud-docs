# AWS Basic Compute Example

This example demonstrates a simple EC2 instance deployment using the Brockhoff Cloud standardized module interface. It showcases the consistent patterns used across all cloud providers while leveraging AWS-specific optimizations.

## Architecture

```
┌─────────────────────────────────────────┐
│                AWS VPC                  │
│  ┌─────────────────────────────────────┐│
│  │            Subnet               │    ││
│  │  ┌─────────────────────────────┐│    ││
│  │  │       EC2 Instance          ││    ││
│  │  │   - Amazon Linux 2          ││    ││
│  │  │   - t3.micro (default)      ││    ││
│  │  │   - EBS encryption          ││    ││
│  │  │   - CloudWatch monitoring   ││    ││
│  │  └─────────────────────────────┘│    ││
│  └─────────────────────────────────────┘│
│                                         │
│  Security Group                         │
│  - SSH (22) from private networks       │
│  - HTTP (80) from anywhere             │
│  - HTTPS (443) from anywhere           │
│                                         │
│  KMS Key                               │
│  - EBS volume encryption               │
│  - 7-day deletion window (dev)         │
└─────────────────────────────────────────┘
```

## Resources Created

- **EC2 Instance**: Single compute instance with security hardening
- **Security Group**: Network access controls with least-privilege rules
- **KMS Key**: Encryption key for EBS volumes and snapshots
- **CloudWatch Alarms**: Optional monitoring and alerting (disabled by default)
- **SNS Topic**: Optional notification endpoint for alarms

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **AWS permissions** for EC2, KMS, and CloudWatch services
4. **VPC and subnet** (uses default VPC if not specified)

### Required AWS Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "kms:*",
        "cloudwatch:*",
        "sns:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

1. **Copy the example**:
   ```bash
   cp -r examples/basic-usage/aws my-aws-compute
   cd my-aws-compute
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Connect** (if SSH key configured):
   ```bash
   ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
   ```

## Configuration Options

### Instance Sizes

| Size | AWS Instance Type | vCPUs | Memory | Cost/Month* |
|------|------------------|-------|---------|-------------|
| small | t3.micro | 2 | 1 GB | ~$8 |
| medium | t3.small | 2 | 2 GB | ~$17 |
| large | t3.medium | 2 | 4 GB | ~$34 |

*Approximate costs for us-west-2 region

### Environment Types

The `environment_type` variable configures resource defaults:

- **Development**: Cost-optimized, 7-day KMS key deletion, minimal monitoring
- **Testing**: Balanced configuration for testing workloads
- **Production**: High availability, 30-day KMS key deletion, full monitoring

### Security Configuration

Default security group rules:
- **SSH (22)**: Access from private networks only
- **HTTP (80)**: Public access for web applications
- **HTTPS (443)**: Public access for secure web applications

Customize `allowed_cidr_blocks` to restrict access further.

## Cost Optimization

This example is optimized for cost-effectiveness:

- **t3.micro instance**: AWS Free Tier eligible
- **gp3 EBS volumes**: Cost-effective storage
- **Monitoring disabled**: Reduces CloudWatch costs in development
- **Spot instances**: Optional for non-critical workloads

### Estimated Monthly Costs

**Development Environment**:
- EC2 instance (t3.micro): $8.50
- EBS storage (8GB): $0.80
- KMS key: $1.00
- **Total**: ~$10.30/month

**Production Environment** (with monitoring):
- EC2 instance (t3.small): $17.00
- EBS storage (20GB): $2.00
- KMS key: $1.00
- CloudWatch: $3.00
- **Total**: ~$23.00/month

## Security Features

- **Encryption at rest**: EBS volumes encrypted with KMS
- **Network security**: Security groups with least-privilege access
- **IAM integration**: Instance profile with minimal required permissions
- **Patch management**: Amazon Linux 2 with automatic security updates
- **Monitoring**: Optional CloudWatch integration for security events

## Monitoring and Alerting

When enabled, the example creates:

- **CPU utilization alarms**: Alert on high CPU usage
- **Disk space alarms**: Alert on low disk space
- **Network alarms**: Alert on unusual network activity
- **Instance status alarms**: Alert on instance health issues

## Customization Examples

### Enable Monitoring
```hcl
monitoring_enabled = true
alarms_enabled    = true
```

### Use Existing VPC
```hcl
vpc_id    = "vpc-12345678"
subnet_id = "subnet-87654321"
```

### Add SSH Access
```hcl
ssh_key_name = "my-key-pair"
allowed_cidr_blocks = ["203.0.113.0/24"]  # Your public IP
```

### Production Configuration
```hcl
environment_type   = "Production"
instance_type     = "medium"
monitoring_enabled = true
alarms_enabled    = true
```

## Testing

Validate the configuration:

```bash
# Syntax validation
terraform validate

# Plan review
terraform plan

# Automated testing
make test
```

## Troubleshooting

### Common Issues

1. **Permission denied**: Ensure AWS credentials have required permissions
2. **Instance launch failed**: Check subnet capacity and instance limits
3. **KMS key access denied**: Verify KMS permissions in IAM policy
4. **SSH connection refused**: Check security group rules and key pair

### Debug Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify region and availability zones
aws ec2 describe-availability-zones --region us-west-2

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```

**Note**: KMS keys have a deletion window (7-30 days) and cannot be immediately deleted.

## Next Steps

- Explore the **Azure** and **GCP** basic examples for cross-cloud consistency
- Try the **advanced usage examples** for complex scenarios
- Learn about **module composition** in the multi-cloud examples
- Review the **compliance reporting** features

## Support

- Check the [main documentation](../../../docs/) for detailed module information
- Review [troubleshooting guides](../../../docs/troubleshooting.md)
- Open an issue for bugs or feature requests
- Join the community discussions for questions