# Azure Basic Compute Example

This example demonstrates a simple Virtual Machine deployment using the Brockhoff Cloud standardized module interface. It showcases the consistent patterns used across all cloud providers while leveraging Azure-specific optimizations.

## Architecture

```
┌─────────────────────────────────────────┐
│            Resource Group               │
│  ┌─────────────────────────────────────┐│
│  │         Virtual Network             ││
│  │  ┌─────────────────────────────────┐││
│  │  │            Subnet               │││
│  │  │  ┌─────────────────────────────┐│││
│  │  │  │      Virtual Machine        ││││
│  │  │  │   - Ubuntu 20.04 LTS        ││││
│  │  │  │   - Standard_B1s (default)  ││││
│  │  │  │   - Managed disk encryption ││││
│  │  │  │   - Azure Monitor           ││││
│  │  │  └─────────────────────────────┘│││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
│                                         │
│  Network Security Group                 │
│  - SSH (22) from private networks       │
│  - HTTP (80) from anywhere             │
│  - HTTPS (443) from anywhere           │
│                                         │
│  Key Vault                             │
│  - Disk encryption keys                │
│  - 7-day soft delete (dev)             │
└─────────────────────────────────────────┘
```

## Resources Created

- **Virtual Machine**: Single compute instance with security hardening
- **Network Security Group**: Network access controls with least-privilege rules
- **Key Vault**: Encryption key management for disks and secrets
- **Public IP**: Optional public IP address for external access
- **Network Interface**: VM network connectivity
- **Managed Disk**: OS and data storage with encryption
- **Azure Monitor Alerts**: Optional monitoring and alerting (disabled by default)

## Prerequisites

1. **Azure CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **Azure permissions** for Compute, Key Vault, and Monitor services
4. **Resource group** (creates new if not specified)

### Required Azure Permissions

```json
{
  "properties": {
    "roleName": "Terraform Basic Compute",
    "description": "Permissions for basic compute deployment",
    "assignableScopes": ["/subscriptions/{subscription-id}"],
    "permissions": [
      {
        "actions": [
          "Microsoft.Compute/*",
          "Microsoft.Network/*",
          "Microsoft.KeyVault/*",
          "Microsoft.Insights/*",
          "Microsoft.Resources/*"
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```

## Quick Start

1. **Copy the example**:
   ```bash
   cp -r examples/basic-usage/azure my-azure-compute
   cd my-azure-compute
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
   ssh azureuser@<public-ip>
   ```

## Configuration Options

### Instance Sizes

| Size | Azure VM Size | vCPUs | Memory | Cost/Month* |
|------|---------------|-------|---------|-------------|
| small | Standard_B1s | 1 | 1 GB | ~$8 |
| medium | Standard_B2s | 2 | 4 GB | ~$30 |
| large | Standard_B4ms | 4 | 16 GB | ~$120 |

*Approximate costs for West US 2 region

### Environment Types

The `environment_type` variable configures resource defaults:

- **Development**: Cost-optimized, 7-day Key Vault retention, minimal monitoring
- **Testing**: Balanced configuration for testing workloads
- **Production**: High availability, 30-day Key Vault retention, full monitoring

### Security Configuration

Default network security group rules:
- **SSH (22)**: Access from private networks only
- **HTTP (80)**: Public access for web applications
- **HTTPS (443)**: Public access for secure web applications

Customize `allowed_cidr_blocks` to restrict access further.

## Cost Optimization

This example is optimized for cost-effectiveness:

- **Standard_B1s VM**: Burstable performance, cost-effective
- **Standard SSD**: Balanced performance and cost
- **Monitoring disabled**: Reduces Azure Monitor costs in development
- **Spot instances**: Optional for non-critical workloads

### Estimated Monthly Costs

**Development Environment**:
- VM (Standard_B1s): $8.00
- Managed disk (32GB): $2.40
- Key Vault: $0.03
- Public IP: $3.65
- **Total**: ~$14.08/month

**Production Environment** (with monitoring):
- VM (Standard_B2s): $30.00
- Managed disk (64GB): $4.80
- Key Vault: $0.03
- Public IP: $3.65
- Azure Monitor: $5.00
- **Total**: ~$43.48/month

## Security Features

- **Encryption at rest**: Managed disks encrypted with Key Vault keys
- **Network security**: Network Security Groups with least-privilege access
- **Identity integration**: Managed identity for secure resource access
- **Patch management**: Automatic OS updates and security patches
- **Monitoring**: Optional Azure Monitor integration for security events

## Monitoring and Alerting

When enabled, the example creates:

- **CPU utilization alerts**: Alert on high CPU usage
- **Disk space alerts**: Alert on low disk space
- **Network alerts**: Alert on unusual network activity
- **VM availability alerts**: Alert on VM health issues

## Customization Examples

### Enable Monitoring
```hcl
monitoring_enabled = true
alarms_enabled    = true
```

### Use Existing Resource Group
```hcl
resource_group_name = "my-existing-rg"
```

### Add SSH Access
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-key"
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

1. **Permission denied**: Ensure Azure credentials have required permissions
2. **VM creation failed**: Check subscription quotas and region capacity
3. **Key Vault access denied**: Verify Key Vault permissions and policies
4. **SSH connection refused**: Check NSG rules and SSH key configuration

### Debug Commands

```bash
# Check Azure credentials
az account show

# Verify subscription and quotas
az vm list-usage --location "West US 2"

# Check VM status
az vm show --resource-group <rg-name> --name <vm-name>
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```

**Note**: Key Vault has soft-delete enabled and requires purging for complete removal.

## Next Steps

- Explore the **AWS** and **GCP** basic examples for cross-cloud consistency
- Try the **advanced usage examples** for complex scenarios
- Learn about **module composition** in the multi-cloud examples
- Review the **compliance reporting** features

## Support

- Check the [main documentation](../../../docs/) for detailed module information
- Review [troubleshooting guides](../../../docs/troubleshooting.md)
- Open an issue for bugs or feature requests
- Join the community discussions for questions