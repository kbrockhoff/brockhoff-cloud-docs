# Compliance Framework Mappings

This directory contains well-architected framework compliance mappings for each supported cloud provider. These mappings enable automated compliance assessment and reporting for Terraform modules.

## Framework Files

- **aws-waf.yaml** - AWS Well-Architected Framework compliance mapping
- **azure-waf.yaml** - Azure Well-Architected Framework compliance mapping  
- **gcp-caf.yaml** - Google Cloud Architecture Framework compliance mapping

## Structure

Each compliance mapping file follows a consistent structure:

### Framework Metadata
- Framework name, version, and documentation URL
- Pillar definitions and descriptions

### Controls
Each control includes:
- **ID**: Unique identifier for the control
- **Title**: Human-readable control name
- **Implementation**: Description of how the module implements the control
- **Evidence Fields**: Terraform resource attributes that provide evidence of compliance
- **Validation Checks**: Automated checks to verify compliance

### Assessment Configuration
- **Scoring Method**: How compliance scores are calculated
- **Weights**: Relative importance of each pillar
- **Thresholds**: Minimum scores required for different environments
- **Reporting**: Output format and content configuration

## Usage in Modules

Modules reference these compliance mappings to generate automated compliance reports:

```hcl
# In module outputs.tf
output "compliance_report" {
  description = "Well-architected framework compliance assessment"
  value = {
    framework = "aws-waf"
    assessment_date = timestamp()
    scores = local.compliance_scores
    evidence = local.compliance_evidence
    recommendations = local.compliance_recommendations
  }
}
```

## Evidence Collection

The compliance system automatically collects evidence from Terraform resources:

```hcl
locals {
  compliance_evidence = {
    for control_id, control in local.compliance_controls : control_id => {
      for field in control.evidence_fields : field => try(
        lookup(local.all_resources, field, null), 
        "Not configured"
      )
    }
  }
}
```

## Validation Checks

Automated validation ensures compliance requirements are met:

```hcl
locals {
  compliance_validations = {
    for control_id, control in local.compliance_controls : control_id => {
      passed = alltrue([
        for check in control.validation_checks : 
        local.validation_results[check] == true
      ])
      failed_checks = [
        for check in control.validation_checks : check
        if local.validation_results[check] != true
      ]
    }
  }
}
```

## Environment-Specific Requirements

Different environments have different compliance requirements:

- **Production**: High compliance scores (85%+) with all critical controls
- **Development**: Lower compliance scores (70%+) with essential security controls
- **Testing**: Flexible compliance with focus on security fundamentals

## Integration with CI/CD

Compliance checks can be integrated into CI/CD pipelines:

```yaml
# .github/workflows/compliance.yml
- name: Compliance Assessment
  run: |
    terraform plan -out=plan.out
    terraform show -json plan.out | jq '.planned_values' > resources.json
    python scripts/assess-compliance.py --framework aws-waf --resources resources.json
```

## Reporting

Compliance reports include:
- Overall compliance score
- Per-pillar scores
- Failed controls with remediation guidance
- Evidence collection results
- Recommendations for improvement

Example report structure:
```json
{
  "framework": "aws-waf",
  "assessment_date": "2023-12-01T10:00:00Z",
  "overall_score": 0.87,
  "pillar_scores": {
    "operational_excellence": 0.85,
    "security": 0.92,
    "reliability": 0.83,
    "performance_efficiency": 0.88,
    "cost_optimization": 0.86
  },
  "failed_controls": [
    {
      "id": "OPS02",
      "title": "Implement Application Telemetry",
      "reason": "Custom metrics not configured",
      "remediation": "Enable custom application metrics in monitoring_config"
    }
  ],
  "recommendations": [
    "Consider enabling advanced monitoring for production workloads",
    "Review cost optimization opportunities for development environments"
  ]
}
```

## Extending Compliance Mappings

To add new controls or modify existing ones:

1. Update the appropriate framework YAML file
2. Add evidence fields that reference actual Terraform resources
3. Define validation checks that can be automated
4. Update assessment thresholds if needed
5. Test with example modules to ensure accuracy

## Best Practices

- Keep evidence fields specific and measurable
- Write validation checks that can be automated
- Provide clear remediation guidance for failed controls
- Align control implementations with cloud provider best practices
- Regular review and update of mappings as frameworks evolve