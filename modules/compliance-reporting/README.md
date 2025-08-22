# Compliance Reporting Module

This module provides automated compliance assessment and reporting capabilities for Terraform modules against well-architected frameworks (AWS WAF, Azure WAF, Google Cloud Architecture Framework).

## Features

- **Automated Compliance Assessment**: Evaluates module compliance against cloud provider frameworks
- **Evidence Collection**: Gathers evidence from Terraform resources to support compliance claims
- **Security Controls Documentation**: Generates detailed security control implementation documentation
- **Governance Metadata**: Provides structured metadata for audit and governance purposes
- **Multi-Cloud Support**: Works with AWS, Azure, and Google Cloud frameworks
- **Flexible Reporting**: Generates JSON reports and Markdown documentation

## Usage

### Basic Usage

```hcl
module "compliance_reporting" {
  source = "./modules/compliance-reporting"
  
  module_name    = "my-terraform-module"
  module_version = "1.0.0"
  cloud_provider = "aws"  # or "azure", "gcp"
  environment_type = "Production"
  
  # Provide evidence from your module's resources
  resource_evidence = {
    "aws_s3_bucket.main.server_side_encryption_configuration" = {
      found   = true
      value   = aws_s3_bucket.main.server_side_encryption_configuration
      message = "S3 bucket encryption configured"
    }
    "aws_kms_key.main.arn" = {
      found   = true
      value   = aws_kms_key.main.arn
      message = "KMS key created for encryption"
    }
    # Add more evidence fields as needed
  }
  
  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### Advanced Usage with External Assessment

```hcl
module "compliance_reporting" {
  source = "./modules/compliance-reporting"
  
  module_name    = "my-terraform-module"
  module_version = "1.0.0"
  cloud_provider = "aws"
  environment_type = "Production"
  
  # Enable advanced assessment using external script
  run_advanced_assessment = true
  terraform_plan_file    = "plan.json"  # Generated with: terraform show -json plan.out > plan.json
  
  # Generate additional documentation
  generate_security_docs = true
  output_path           = "./compliance-reports"
  
  resource_evidence = local.compliance_evidence
}
```

### Integration with Main Module

```hcl
# In your main module
locals {
  # Collect evidence from your resources
  compliance_evidence = {
    # Security controls
    "aws_kms_key.main.arn" = {
      found   = var.encryption_config.create_kms_key
      value   = var.encryption_config.create_kms_key ? aws_kms_key.main[0].arn : null
      message = var.encryption_config.create_kms_key ? "KMS key created" : "KMS key not created"
    }
    
    "aws_cloudwatch_log_group.main.arn" = {
      found   = var.monitoring_config.enabled
      value   = var.monitoring_config.enabled ? aws_cloudwatch_log_group.main[0].arn : null
      message = var.monitoring_config.enabled ? "CloudWatch logging enabled" : "CloudWatch logging disabled"
    }
    
    # Add more evidence fields based on your module's resources
  }
}

module "compliance_reporting" {
  source = "./modules/compliance-reporting"
  
  module_name       = "my-module"
  module_version    = "1.0.0"
  environment_type  = var.environment_type
  resource_evidence = local.compliance_evidence
  
  context = module.context
  tags    = local.tags
}

# Output compliance information
output "compliance_report" {
  description = "Compliance assessment report"
  value       = module.compliance_reporting.compliance_report
}

output "compliance_score" {
  description = "Overall compliance score"
  value       = module.compliance_reporting.compliance_score
}

output "governance_metadata" {
  description = "Governance metadata for audit purposes"
  value       = module.compliance_reporting.governance_metadata
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable compliance reporting and assessment | `bool` | `true` | no |
| module_name | Name of the module being assessed | `string` | n/a | yes |
| module_version | Version of the module being assessed | `string` | `"1.0.0"` | no |
| cloud_provider | Cloud provider (aws, azure, gcp) | `string` | `""` | no |
| environment_type | Environment type for compliance thresholds | `string` | `"Development"` | no |
| context | Context object from terraform-external-context module | `object` | `{}` | no |
| resource_evidence | Evidence data from Terraform resources | `map(object)` | `{}` | no |
| generate_report_file | Generate compliance report as JSON file | `bool` | `true` | no |
| generate_security_docs | Generate security controls documentation | `bool` | `true` | no |
| output_path | Path for generated reports and documentation | `string` | `"./compliance-reports"` | no |
| run_advanced_assessment | Run advanced assessment using external script | `bool` | `false` | no |
| terraform_plan_file | Path to Terraform plan JSON file | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| compliance_report | Complete compliance assessment report |
| compliance_score | Overall compliance score (0.0 to 1.0) |
| pillar_scores | Compliance scores by framework pillar |
| compliance_status | Overall compliance status and details |
| security_controls | Security controls implementation status |
| recommendations | Compliance improvement recommendations |
| governance_metadata | Governance and audit metadata |
| compliance_tags | Tags for compliance tracking |
| framework_info | Information about the compliance framework |
| evidence_summary | Summary of evidence collection results |
| report_files | Paths to generated report files |

## Evidence Collection

The module requires evidence data to assess compliance. Evidence should be collected from your module's resources:

```hcl
locals {
  compliance_evidence = {
    # Format: "resource_type.resource_name.attribute_path" = evidence_object
    "aws_s3_bucket.main.server_side_encryption_configuration" = {
      found   = length(aws_s3_bucket.main.server_side_encryption_configuration) > 0
      value   = aws_s3_bucket.main.server_side_encryption_configuration
      message = "S3 bucket encryption configuration"
    }
    
    "module.monitoring.cloudwatch_dashboard_url" = {
      found   = var.monitoring_config.enabled
      value   = var.monitoring_config.enabled ? module.monitoring[0].dashboard_url : null
      message = var.monitoring_config.enabled ? "Monitoring dashboard created" : "Monitoring disabled"
    }
  }
}
```

## Compliance Frameworks

The module supports multiple compliance frameworks:

- **AWS Well-Architected Framework** (`aws-waf.yaml`)
- **Azure Well-Architected Framework** (`azure-waf.yaml`)
- **Google Cloud Architecture Framework** (`gcp-caf.yaml`)

Each framework defines:
- Pillars (operational excellence, security, reliability, etc.)
- Controls within each pillar
- Evidence requirements for each control
- Validation checks and scoring criteria

## Generated Reports

### JSON Compliance Report

```json
{
  "framework": {
    "name": "AWS Well-Architected Framework",
    "version": "2023"
  },
  "assessment": {
    "date": "2023-12-01T10:00:00Z",
    "module": {
      "name": "my-module",
      "version": "1.0.0"
    }
  },
  "scores": {
    "overall_score": 0.87,
    "pillar_scores": {
      "security": 0.92,
      "reliability": 0.83
    }
  },
  "compliance_status": {
    "compliant": true,
    "total_controls": 25,
    "implemented_controls": 22
  }
}
```

### Security Controls Documentation

Markdown documentation is generated showing:
- Security control implementation status
- Evidence requirements
- Validation checks
- Remediation guidance for missing controls

## Environment-Specific Thresholds

Different environments have different compliance requirements:

- **Production/MissionCritical**: 85% minimum score, all critical controls required
- **UAT/Testing**: 80% minimum score, security controls required
- **Development**: 70% minimum score, basic security controls required
- **Ephemeral**: 60% minimum score, minimal requirements

## Integration with CI/CD

```yaml
# .github/workflows/compliance.yml
name: Compliance Assessment

on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Plan
        run: |
          terraform init
          terraform plan -out=plan.out
          terraform show -json plan.out > plan.json
          
      - name: Compliance Assessment
        run: |
          python3 scripts/assess-compliance.py \
            --framework compliance/aws-waf.yaml \
            --resources plan.json \
            --output compliance-report.json
            
      - name: Upload Compliance Report
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance-report.json
```

## Requirements

- Terraform >= 1.0
- Python 3.7+ (for advanced assessment)
- PyYAML library (for advanced assessment)

## License

This module is released under the Apache 2.0 License.