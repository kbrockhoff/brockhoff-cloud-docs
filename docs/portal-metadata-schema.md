# Portal Metadata Schema Documentation

## Overview

The Portal Metadata Schema provides a standardized way to describe Terraform modules for integration with developer portals and self-service platforms. This schema enables automatic form generation, cost estimation, difficulty assessment, and dependency management.

## Schema Structure

### Core Components

1. **Module Information** - Basic module metadata
2. **Portal Configuration** - Portal-specific settings
3. **Form Schema** - UI form generation definitions
4. **Cost Estimation** - Cost analysis and optimization
5. **Difficulty Assessment** - Complexity evaluation
6. **Prerequisites** - Required dependencies and setup
7. **Dependencies** - Module relationships and deployment order
8. **Validation** - Pre and post-deployment checks

## Usage Guide

### Creating Portal Metadata

Each Terraform module should include a `portal-metadata.yaml` file in its root directory:

```yaml
schema_version: "1.0"
module_info:
  name: "my-module"
  version: "1.0.0"
  description: "Module description"
  category: "compute"
# ... rest of configuration
```

### Form Schema Definition

The form schema defines how the developer portal should render input forms:

#### Field Types

- **string** - Text input
- **number** - Numeric input with validation
- **boolean** - Checkbox or toggle
- **select** - Dropdown with predefined options
- **multiselect** - Multiple selection dropdown
- **textarea** - Multi-line text input
- **password** - Masked text input
- **file** - File upload
- **json** - JSON editor
- **list** - Dynamic list of values
- **map** - Key-value pair editor

#### Field Properties

```yaml
fields:
  - name: "field_name"           # Maps to Terraform variable
    type: "string"               # Field input type
    label: "Display Label"       # Human-readable label
    description: "Field help"    # Description and help text
    required: true               # Whether field is required
    default: "default_value"     # Default value
    placeholder: "hint text"     # Placeholder text
    help_text: "Additional help" # Extended help information
```

#### Validation Rules

```yaml
validation:
  pattern: "^[a-z0-9-]+$"       # Regex pattern
  min: 1                        # Minimum value (numbers)
  max: 100                      # Maximum value (numbers)
  minLength: 3                  # Minimum string length
  maxLength: 50                 # Maximum string length
  custom: "validate_function"   # Custom validation function
```

#### Conditional Fields

Fields can be shown/hidden based on other field values:

```yaml
conditional:
  field: "enable_feature"       # Field to check
  operator: "equals"            # Comparison operator
  value: true                   # Value to compare against
```

### Cost Estimation

Provide cost guidance to help users make informed decisions:

```yaml
cost_estimation:
  base_cost_category: "medium"  # Quick cost category
  estimated_monthly_cost:
    min: 50                     # Minimum monthly cost
    max: 500                    # Maximum monthly cost
    typical: 150                # Typical monthly cost
  cost_factors:
    - factor: "Instance Size"
      impact: "high"
      description: "Larger instances cost more"
  cost_optimization_tips:
    - "Use smaller instances for development"
    - "Enable auto-scaling to optimize costs"
```

### Difficulty Assessment

Help users understand the complexity level:

```yaml
difficulty_assessment:
  overall_difficulty: 3         # 1-5 scale
  skill_requirements:
    terraform_experience: "basic"
    cloud_experience: "intermediate"
    networking_knowledge: "basic"
    security_knowledge: "basic"
  complexity_factors:
    - factor: "Multi-cloud Support"
      level: "medium"
      description: "Understanding provider differences"
```

### Prerequisites and Dependencies

Define what's needed before deployment:

```yaml
prerequisites:
  required_modules:
    - module_name: "kbrockhoff/networking/terraform"
      version_constraint: ">= 1.0.0"
      description: "Provides network infrastructure"
  
  cloud_resources:
    - resource_type: "VPC"
      provider: "aws"
      description: "Virtual Private Cloud"
      setup_instructions: "Create VPC or use existing"
  
  permissions:
    - permission: "EC2FullAccess"
      provider: "aws"
      description: "Required for EC2 operations"

dependencies:
  module_dependencies:
    - module_name: "kbrockhoff/networking/terraform"
      relationship_type: "required"
      integration_points: ["vpc_id", "subnet_ids"]
  
  deployment_order:
    - step: 1
      modules: ["kbrockhoff/networking/terraform"]
      description: "Create network infrastructure"
    - step: 2
      modules: ["kbrockhoff/web-application/terraform"]
      description: "Deploy application"
```

### Validation Rules

Define checks to run before and after deployment:

```yaml
validation:
  pre_deployment:
    - name: "Check Credentials"
      type: "cloud_api"
      description: "Verify cloud authentication"
      command: "aws sts get-caller-identity"
      expected_result: "account_id"
      error_message: "AWS credentials not configured"
      remediation: "Run 'aws configure'"
  
  post_deployment:
    - name: "Health Check"
      type: "custom"
      description: "Verify application is running"
      command: "curl -f ${app_url}/health"
      expected_result: "HTTP 200"
      error_message: "Application not responding"
      remediation: "Check application logs"
```

## Integration with Developer Portals

### Form Generation

Portal platforms can use the form schema to automatically generate user interfaces:

1. Parse the `form_schema.sections` array
2. Render form sections with appropriate field types
3. Apply validation rules and conditional logic
4. Handle form submission and variable mapping

### Cost Display

Portals can show cost information to users:

1. Display `base_cost_category` for quick assessment
2. Show `estimated_monthly_cost` ranges
3. List `cost_factors` that affect pricing
4. Provide `cost_optimization_tips`

### Difficulty Indicators

Help users choose appropriate modules:

1. Show `overall_difficulty` rating
2. Display required `skill_requirements`
3. Explain `complexity_factors`
4. Suggest learning resources for skill gaps

### Dependency Management

Automate dependency resolution:

1. Check `prerequisites` before allowing deployment
2. Resolve `module_dependencies` automatically
3. Follow `deployment_order` for multi-module deployments
4. Run `validation` checks at appropriate times

## Best Practices

### Form Design

1. **Group Related Fields** - Use sections to organize related configuration
2. **Provide Clear Labels** - Use descriptive labels and help text
3. **Set Sensible Defaults** - Minimize required user input
4. **Use Conditional Logic** - Show/hide fields based on context
5. **Validate Input** - Provide immediate feedback on invalid input

### Cost Transparency

1. **Be Realistic** - Provide accurate cost estimates
2. **Explain Factors** - Help users understand what drives costs
3. **Offer Alternatives** - Suggest cost optimization strategies
4. **Update Regularly** - Keep cost estimates current

### Difficulty Assessment

1. **Be Honest** - Accurately assess complexity levels
2. **Explain Requirements** - Clearly state needed skills
3. **Provide Guidance** - Suggest learning resources
4. **Consider Audience** - Tailor to your user base

### Documentation

1. **Keep Current** - Update metadata with module changes
2. **Test Thoroughly** - Validate form generation and validation
3. **Get Feedback** - Iterate based on user experience
4. **Version Control** - Track metadata changes with module versions

## Schema Validation

Use the JSON schema to validate portal metadata files:

```bash
# Install a JSON schema validator
npm install -g ajv-cli

# Validate your metadata file
ajv validate -s schemas/portal-metadata-schema.json -d portal-metadata.yaml
```

## Examples

See `portal-metadata-example.yaml` for a complete example of a web application module with comprehensive portal integration metadata.

## Integration Examples

### React Portal Component

```jsx
import { PortalForm } from './PortalForm';
import portalMetadata from './portal-metadata.yaml';

function ModuleDeployment({ moduleName }) {
  return (
    <PortalForm
      metadata={portalMetadata}
      onSubmit={handleDeployment}
      onValidate={validateConfiguration}
    />
  );
}
```

### Backend Integration

```python
import yaml
from jsonschema import validate

def load_portal_metadata(module_path):
    with open(f"{module_path}/portal-metadata.yaml") as f:
        metadata = yaml.safe_load(f)
    
    # Validate against schema
    validate(metadata, portal_schema)
    
    return metadata

def generate_terraform_vars(metadata, user_input):
    # Map form values to Terraform variables
    terraform_vars = {}
    for section in metadata['form_schema']['sections']:
        for field in section['fields']:
            if field['name'] in user_input:
                terraform_vars[field['name']] = user_input[field['name']]
    
    return terraform_vars
```

This schema provides a comprehensive foundation for integrating Terraform modules with developer portals, enabling self-service infrastructure deployment with appropriate guardrails and guidance.