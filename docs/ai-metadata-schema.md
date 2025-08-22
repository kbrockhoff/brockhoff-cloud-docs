# AI Metadata Schema Documentation

## Overview

The AI Metadata Schema enables AI agents to understand, generate, and validate Terraform module configurations programmatically. Each Terraform module includes an `ai-metadata.yaml` file that provides machine-readable information about the module's capabilities, usage patterns, validation rules, and integration points.

## Schema Version 1.0

### Purpose

The AI metadata schema serves several key purposes:

1. **Code Generation**: Provides templates and patterns for AI agents to generate Terraform configurations
2. **Validation**: Defines rules for validating AI-generated configurations
3. **Integration**: Documents how modules connect with other modules in the ecosystem
4. **Cost Estimation**: Enables AI agents to estimate and optimize infrastructure costs
5. **Testing**: Provides scenarios for automated validation of generated configurations

### File Structure

Every `ai-metadata.yaml` file follows this structure:

```yaml
schema_version: "1.0"
module_info: { ... }
generation_templates: { ... }
validation_rules: [ ... ]
common_patterns: [ ... ]
integration_points: [ ... ]
cost_estimation: { ... }
testing_scenarios: [ ... ]
```

## Field Definitions

### schema_version (required)

**Type**: `string`  
**Pattern**: `^\d+\.\d+$`  
**Example**: `"1.0"`

Specifies the version of the AI metadata schema being used. This allows for future schema evolution while maintaining backward compatibility.

### module_info (required)

**Type**: `object`

Contains basic information about the Terraform module:

```yaml
module_info:
  name: "compute-instance"                    # Module name in kebab-case
  type: "service"                            # foundation | service | composite
  complexity_level: "intermediate"           # beginner | intermediate | advanced | expert
  cloud_providers: ["aws", "azure", "gcp"]  # Supported cloud providers
  category: "compute"                        # Primary infrastructure category
  description: "Multi-cloud compute instance with auto-scaling"
  estimated_deployment_time: "5-10 minutes" # Expected deployment duration
```

#### Module Types

- **foundation**: Core infrastructure (networking, security, identity)
- **service**: Application-specific services (compute, storage, databases)  
- **composite**: Complete solutions combining multiple modules

#### Complexity Levels

- **beginner**: Simple modules with minimal configuration
- **intermediate**: Standard modules with moderate complexity
- **advanced**: Complex modules requiring deep understanding
- **expert**: Highly specialized modules for specific use cases

#### Categories

- `compute`: Virtual machines, containers, serverless functions
- `storage`: Object storage, block storage, file systems
- `networking`: VPCs, load balancers, DNS, CDN
- `security`: IAM, encryption, firewalls, certificates
- `database`: Relational and NoSQL databases
- `monitoring`: Logging, metrics, alerting, dashboards
- `identity`: Authentication, authorization, directory services

### generation_templates (required)

**Type**: `object`

Jinja2 templates for generating Terraform configurations. At minimum, must include `basic_usage`:

```yaml
generation_templates:
  basic_usage: |
    module "{{ module_name }}" {
      source = "{{ module_source }}"
      
      name_prefix = "{{ name_prefix }}"
      environment_type = "{{ environment_type | default('Development') }}"
      
      # Module-specific configuration
      instance_config = {
        instance_type = "{{ instance_type | default('small') }}"
      }
    }
  
  advanced_usage: |
    # Template for production-grade deployment
    
  multi_cloud: |
    # Template for multi-cloud deployment
```

#### Template Variables

Templates support these standard variables:

- `{{ module_name }}`: Name for the module instance
- `{{ module_source }}`: Terraform registry source path
- `{{ name_prefix }}`: Organization-specific resource prefix
- `{{ environment_type }}`: Environment (Development, Production, etc.)

#### Template Filters

Supported Jinja2 filters:

- `default(value)`: Provide default value if variable is undefined
- `terraform_format`: Format complex objects for Terraform syntax
- `upper`, `lower`: Case conversion
- `replace(old, new)`: String replacement

### validation_rules (required)

**Type**: `array`

Defines validation rules for input parameters:

```yaml
validation_rules:
  - field: "name_prefix"
    rule_type: "pattern"
    pattern: "^[a-z][a-z0-9-]{0,22}[a-z0-9]$"
    error_message: "name_prefix must be 2-24 characters, start with lowercase letter"
    severity: "error"
    remediation: "Use only lowercase letters, numbers, and hyphens"
  
  - field: "environment_type"
    rule_type: "allowed_values"
    allowed_values: ["Development", "Testing", "Production"]
    error_message: "Invalid environment type"
    severity: "error"
    remediation: "Choose from: Development, Testing, Production"
  
  - field: "instance_count"
    rule_type: "range"
    min_value: 1
    max_value: 100
    error_message: "Instance count must be between 1 and 100"
    severity: "warning"
```

#### Rule Types

- **pattern**: Validate against regex pattern
- **allowed_values**: Validate against list of allowed values
- **range**: Validate numeric ranges
- **dependency**: Validate field dependencies
- **custom**: Custom validation logic

#### Severity Levels

- **error**: Prevents deployment, must be fixed
- **warning**: Should be addressed but doesn't block deployment
- **info**: Informational guidance

### common_patterns (optional)

**Type**: `array`

Pre-defined configuration patterns for common use cases:

```yaml
common_patterns:
  - pattern_name: "web_application"
    description: "Standard web application with load balancing"
    use_case: "Public-facing web applications requiring high availability"
    template_variables:
      instance_type: "medium"
      min_size: 2
      max_size: 10
      enable_monitoring: true
    estimated_cost: "medium"
  
  - pattern_name: "development_environment"
    description: "Cost-optimized setup for development"
    use_case: "Development environments with minimal requirements"
    template_variables:
      instance_type: "small"
      min_size: 1
      max_size: 2
      enable_monitoring: false
    estimated_cost: "low"
```

### integration_points (optional)

**Type**: `array`

Documents how this module integrates with other modules:

```yaml
integration_points:
  - module: "networking"
    connection_type: "dependency"
    required_outputs: ["vpc_id", "subnet_ids"]
    optional_outputs: ["security_group_id"]
    integration_example: |
      module "network" {
        source = "kbrockhoff/networking/terraform"
      }
      
      module "compute" {
        source = "kbrockhoff/compute/terraform"
        vpc_id = module.network.vpc_id
        subnet_ids = module.network.private_subnet_ids
      }
```

#### Connection Types

- **dependency**: This module requires outputs from another module
- **reference**: This module can use outputs from another module
- **composition**: This module is composed of other modules
- **optional**: Integration provides additional functionality but isn't required

### cost_estimation (optional)

**Type**: `object`

Provides cost estimation parameters for AI budget planning:

```yaml
cost_estimation:
  base_cost_per_hour: 0.05
  base_cost_per_month: 36.50
  scaling_factors:
    instance_type:
      small: 1.0
      medium: 2.0
      large: 4.0
    environment_type:
      Development: 0.5
      Production: 1.0
      MissionCritical: 1.5
  cost_variables:
    - variable: "instance_count"
      impact: "linear"
      multiplier: 1.0
    - variable: "enable_monitoring"
      impact: "step"
      multiplier: 1.2
  cost_optimization_hints:
    - "Use 'small' instance type for development"
    - "Enable auto-scaling for variable workloads"
```

### testing_scenarios (optional)

**Type**: `array`

Defines test scenarios for validating AI-generated configurations:

```yaml
testing_scenarios:
  - name: "basic_deployment"
    description: "Validates basic module deployment"
    variables:
      name_prefix: "test-app"
      environment_type: "Development"
      instance_type: "small"
    expected_outcome:
      resource_count: 5
      success: true
      validation_checks:
        - "Auto-scaling group created"
        - "Security group configured"
  
  - name: "invalid_configuration"
    description: "Tests validation of invalid inputs"
    variables:
      name_prefix: "Invalid-Name!"
      environment_type: "InvalidEnv"
    expected_outcome:
      success: false
      validation_checks:
        - "name_prefix validation fails"
        - "environment_type validation fails"
```

## Usage Examples

### Generating AI Metadata

Use the provided generator script:

```bash
# Generate metadata for a new compute module
python3 scripts/generate-ai-metadata.py compute-instance \
  --type service \
  --complexity intermediate \
  --cloud-providers aws azure gcp \
  --category compute \
  --output ai-metadata.yaml
```

### Validating AI Metadata

Use the validation script:

```bash
# Validate an existing metadata file
python3 scripts/validate-ai-metadata.py ai-metadata.yaml

# Strict validation (warnings as errors)
python3 scripts/validate-ai-metadata.py ai-metadata.yaml --strict
```

### AI Agent Integration

AI agents can use the metadata to:

1. **Understand module capabilities**:
   ```python
   with open('ai-metadata.yaml') as f:
       metadata = yaml.safe_load(f)
   
   complexity = metadata['module_info']['complexity_level']
   cloud_providers = metadata['module_info']['cloud_providers']
   ```

2. **Generate configurations**:
   ```python
   from jinja2 import Template
   
   template = Template(metadata['generation_templates']['basic_usage'])
   config = template.render(
       module_name="my_app",
       module_source="kbrockhoff/compute/terraform",
       name_prefix="myorg-app",
       instance_type="medium"
   )
   ```

3. **Validate inputs**:
   ```python
   for rule in metadata['validation_rules']:
       if rule['field'] == 'name_prefix':
           pattern = rule['pattern']
           if not re.match(pattern, user_input):
               print(rule['error_message'])
   ```

4. **Estimate costs**:
   ```python
   cost_config = metadata['cost_estimation']
   base_cost = cost_config['base_cost_per_month']
   
   # Apply scaling factors
   instance_factor = cost_config['scaling_factors']['instance_type']['medium']
   estimated_cost = base_cost * instance_factor
   ```

## Best Practices

### Template Design

1. **Use descriptive variable names**: `{{ instance_type }}` not `{{ type }}`
2. **Provide sensible defaults**: `{{ environment_type | default('Development') }}`
3. **Include conditional blocks**: Use `{% if %}` for optional features
4. **Avoid hardcoded values**: Use variables for all configurable parameters

### Validation Rules

1. **Be specific**: Provide clear error messages and remediation steps
2. **Use appropriate severity**: Reserve errors for blocking issues
3. **Consider user experience**: Validation should guide, not frustrate
4. **Test thoroughly**: Ensure rules catch common mistakes

### Cost Estimation

1. **Be realistic**: Base estimates on actual cloud provider pricing
2. **Include all costs**: Don't forget data transfer, storage, monitoring
3. **Provide optimization hints**: Help users reduce costs
4. **Update regularly**: Cloud pricing changes frequently

### Testing Scenarios

1. **Cover common cases**: Include typical deployment scenarios
2. **Test edge cases**: Validate error handling and edge conditions
3. **Include negative tests**: Verify validation rules work correctly
4. **Keep scenarios simple**: Focus on specific functionality

## Schema Evolution

The AI metadata schema is versioned to support evolution:

- **Patch versions** (1.0 → 1.1): Add optional fields, maintain compatibility
- **Minor versions** (1.0 → 2.0): Add required fields, may break compatibility
- **Major versions** (1.0 → 2.0): Significant structural changes

AI agents should check `schema_version` and handle different versions appropriately.

## Troubleshooting

### Common Issues

1. **Invalid YAML syntax**: Use a YAML validator to check syntax
2. **Missing required fields**: Ensure all required fields are present
3. **Invalid template syntax**: Test Jinja2 templates separately
4. **Validation rule conflicts**: Check for contradictory rules

### Debugging Tips

1. **Use the validation script**: Run validation before committing changes
2. **Test templates manually**: Render templates with sample data
3. **Validate against real modules**: Test metadata with actual Terraform modules
4. **Check examples**: Review existing metadata files for patterns

## Related Documentation

- [Terraform Module Standards](terraform-module-standards.md)
- [Multi-Cloud Design Patterns](multi-cloud-patterns.md)
- [Cost Optimization Guide](cost-optimization.md)
- [AI Agent Integration Guide](ai-agent-integration.md)