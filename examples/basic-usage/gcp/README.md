# GCP Basic Compute Example

This example demonstrates a simple Compute Engine instance deployment using the Brockhoff Cloud standardized module interface. It showcases the consistent patterns used across all cloud providers while leveraging GCP-specific optimizations.

## Architecture

```
┌─────────────────────────────────────────┐
│              GCP Project                │
│  ┌─────────────────────────────────────┐│
│  │            VPC Network              ││
│  │  ┌─────────────────────────────────┐││
│  │  │            Subnet               │││
│  │  │  ┌─────────────────────────────┐│││
│  │  │  │    Compute Engine Instance  ││││
│  │  │  │   - Ubuntu 20.04 LTS        ││││
│  │  │  │   - e2-micro (default)      ││││
│  │  │  │   - Persistent disk encrypt ││││
│  │  │  │   - Cloud Monitoring        ││││
│  │  │  └─────────────────────────────┘│││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
│                                         │
│  Firewall Rules                         │
│  - SSH (22) from private networks       │
│  - HTTP (80) from anywhere             │
│  - HTTPS (443) from anywhere           │
│                                         │
│  Cloud KMS                             │
│  - Persistent disk encryption          │
│  - 7-day key rotation (dev)            │
└─────────────────────────────────────────┘
```

## Resources Created

- **Compute Engine Instance**: Single VM instance with security hardening
- **Firewall Rules**: Network access controls with least-privilege rules
- **Cloud KMS Key**: Encryption key management for disks and data
- **External IP**: Optional external IP address for public access
- **Persistent Disk**: Boot and data storage with encryption
- **Cloud Monitoring Alerts**: Optional monitoring and alerting (disabled by default)

## Prerequisites

1. **Google Cloud SDK configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **GCP project** with billing enabled
4. **Required APIs enabled**: Compute Engine, Cloud KMS, Cloud Monitoring

### Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable monitoring.googleapis.com
```

### Required GCP Permissions

```json
{
  "bindings": [
    {
      "role": "roles/compute.instanceAdmin.v1",
      "members": ["user:your-email@domain.com"]
    },
    {
      "role": "roles/cloudkms.admin",
      "members": ["user:your-email@domain.com"]
    },
    {
      "role": "roles/monitoring.editor",
      "members": ["user:your-email@domain.com"]
    }
  ]
}
```

## Quick Start

1. **Copy the example**:
   ```bash
   cp -r examples/basic-usage/gcp my-gcp-compute
   cd my-gcp-compute
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your GCP project ID and values
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Connect** (if SSH keys configured):
   ```bash
   gcloud compute ssh instance-name --zone=us-west1-a
   ```

## Configuration Options

### Instance Sizes

| Size | GCP Machine Type | vCPUs | Memory | Cost/Month* |
|------|------------------|-------|---------|-------------|
| small | e2-micro | 2 (shared) | 1 GB | ~$6 |
| medium | e2-small | 2 (shared) | 2 GB | ~$12 |
| large | e2-standard-2 | 2 | 8 GB | ~$49 |

*Approximate costs for us-west1 region

### Environment Types

The `environment_type` variable configures resource defaults:

- **Development**: Cost-optimized, 7-day KMS key rotation, minimal monitoring
- **Testing**: Balanced configuration for testing workloads
- **Production**: High availability, 30-day KMS key rotation, full monitoring

### Security Configuration

Default firewall rules:
- **SSH (22)**: Access from private networks only
- **HTTP (80)**: Public access for web applications
- **HTTPS (443)**: Public access for secure web applications

Customize `allowed_cidr_blocks` to restrict access further.

## Cost Optimization

This example is optimized for cost-effectiveness:

- **e2-micro instance**: Shared-core, cost-effective for light workloads
- **Standard persistent disk**: Balanced performance and cost
- **Monitoring disabled**: Reduces Cloud Monitoring costs in development
- **Preemptible instances**: Optional for non-critical workloads

### Estimated Monthly Costs

**Development Environment**:
- Compute Engine (e2-micro): $6.11
- Persistent disk (10GB): $0.40
- Cloud KMS: $0.06
- External IP: $2.88
- **Total**: ~$9.45/month

**Production Environment** (with monitoring):
- Compute Engine (e2-standard-2): $48.91
- Persistent disk (50GB): $2.00
- Cloud KMS: $0.06
- External IP: $2.88
- Cloud Monitoring: $8.00
- **Total**: ~$61.85/month

## Security Features

- **Encryption at rest**: Persistent disks encrypted with Cloud KMS
- **Network security**: Firewall rules with least-privilege access
- **Service account**: Dedicated service account with minimal permissions
- **OS patching**: Automatic OS updates and security patches
- **Monitoring**: Optional Cloud Monitoring integration for security events

## Monitoring and Alerting

When enabled, the example creates:

- **CPU utilization alerts**: Alert on high CPU usage
- **Disk space alerts**: Alert on low disk space
- **Network alerts**: Alert on unusual network activity
- **Instance availability alerts**: Alert on instance health issues

## Customization Examples

### Enable Monitoring
```hcl
monitoring_enabled = true
alarms_enabled    = true
```

### Use Existing Network
```hcl
network_name = "my-existing-network"
subnet_name  = "my-existing-subnet"
```

### Add SSH Access
```hcl
ssh_public_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAA... user@hostname"
]
allowed_cidr_blocks = ["203.0.113.0/24"]  # Your public IP
```

### Production Configuration
```hcl
environment_type   = "Production"
instance_type     = "large"
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

1. **Permission denied**: Ensure GCP credentials have required permissions
2. **API not enabled**: Enable required APIs in GCP Console
3. **Quota exceeded**: Check compute quotas in your project
4. **SSH connection failed**: Check firewall rules and SSH key configuration

### Debug Commands

```bash
# Check GCP credentials
gcloud auth list

# Verify project and quotas
gcloud compute project-info describe --project=your-project-id

# Check instance status
gcloud compute instances describe instance-name --zone=us-west1-a
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```

**Note**: Cloud KMS keys have a minimum lifecycle and cannot be immediately deleted.

## Next Steps

- Explore the **AWS** and **Azure** basic examples for cross-cloud consistency
- Try the **advanced usage examples** for complex scenarios
- Learn about **module composition** in the multi-cloud examples
- Review the **compliance reporting** features

## Support

- Check the [main documentation](../../../docs/) for detailed module information
- Review [troubleshooting guides](../../../docs/troubleshooting.md)
- Open an issue for bugs or feature requests
- Join the community discussions for questions