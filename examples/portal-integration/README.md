# Portal Integration Examples

This directory contains examples demonstrating the user-friendly portal integration features for Terraform modules.

## Overview

The portal integration system provides a comprehensive solution for creating developer-friendly interfaces for Terraform modules. It includes:

- **Schema-driven form generation** - Automatically generate forms from metadata
- **User experience optimizations** - Sensible defaults, validation, and guidance
- **Cost estimation** - Real-time cost feedback and optimization tips
- **Difficulty assessment** - Help users choose appropriate modules
- **Prerequisites checking** - Validate requirements before deployment
- **Terraform preview** - Show generated code before deployment

## Files

### Core Components

- `user-friendly-demo.html` - Interactive demonstration of the portal interface
- `../../templates/portal-form-generator.js` - Form generation engine
- `../../templates/portal-form-styles.css` - User-friendly CSS styles
- `../../templates/portal-form-utils.js` - JavaScript utilities and validation
- `../../schemas/portal-metadata-schema.json` - JSON schema for metadata validation
- `../../portal-metadata-example.yaml` - Example metadata configuration

### Documentation

- `../../docs/portal-metadata-schema.md` - Comprehensive documentation
- `../../scripts/validate-portal-metadata.py` - Validation script

## Quick Start

1. **View the Demo**
   ```bash
   # Open the demo in your browser
   open examples/portal-integration/user-friendly-demo.html
   ```

2. **Try the Interface**
   - Fill out the form fields
   - See real-time validation feedback
   - Check cost estimation updates
   - Preview generated Terraform code
   - Simulate deployment process

## Key Features Demonstrated

### 1. User-Friendly Form Generation

The interface automatically generates forms with:
- **Clear visual hierarchy** - Organized sections and field grouping
- **Helpful descriptions** - Context and guidance for each field
- **Smart defaults** - Sensible values to minimize user input
- **Progressive disclosure** - Advanced options are collapsible
- **Responsive design** - Works on desktop and mobile devices

### 2. Real-Time Validation

- **Immediate feedback** - Validation as users type
- **Clear error messages** - Specific, actionable guidance
- **Visual indicators** - Color-coded validation states
- **Pattern matching** - Regex validation for formats
- **Cross-field validation** - Dependencies between fields

### 3. Cost Transparency

- **Cost categories** - Quick assessment (free, low, medium, high)
- **Detailed estimates** - Min/max/typical monthly costs
- **Cost factors** - What drives pricing changes
- **Optimization tips** - How to reduce costs
- **Real-time updates** - Cost changes as configuration changes

### 4. Difficulty Assessment

- **Skill requirements** - What knowledge is needed
- **Complexity factors** - What makes it challenging
- **Star ratings** - Quick difficulty overview
- **Learning guidance** - Suggestions for skill development

### 5. Prerequisites Management

- **Automated checking** - Validate requirements before deployment
- **Clear instructions** - How to set up prerequisites
- **Status indicators** - Visual feedback on readiness
- **Dependency resolution** - Understand module relationships

### 6. Enhanced User Experience

- **Conditional fields** - Show/hide based on selections
- **Dynamic editors** - List and map value editors
- **JSON validation** - Real-time JSON syntax checking
- **Auto-save** - Preserve work automatically
- **Keyboard navigation** - Full accessibility support

## Integration Guide

### 1. Create Portal Metadata

Create a `portal-metadata.yaml` file for your module:

```yaml
schema_version: "1.0"
module_info:
  name: "my-module"
  version: "1.0.0"
  description: "Module description"
  category: "compute"
  cloud_providers: ["aws", "azure", "gcp"]

portal_config:
  deployment_time: "5-10 minutes"
  complexity_level: "beginner"

form_schema:
  sections:
    - title: "Basic Configuration"
      fields:
        - name: "app_name"
          type: "string"
          label: "Application Name"
          required: true
          validation:
            pattern: "^[a-z0-9-]+$"

cost_estimation:
  base_cost_category: "low"
  estimated_monthly_cost:
    typical: 50

difficulty_assessment:
  overall_difficulty: 2
  skill_requirements:
    terraform_experience: "basic"
```

### 2. Generate Form Interface

```javascript
// Load metadata
const metadata = await loadPortalMetadata('portal-metadata.yaml');

// Generate form
const generator = new PortalFormGenerator(metadata);
const formHtml = generator.generateForm();

// Add to page
document.getElementById('form-container').innerHTML = formHtml;

// Initialize utilities
const form = document.getElementById('module-form');
const utils = new PortalFormUtils(form, metadata);
```

### 3. Handle Form Submission

```javascript
form.addEventListener('portalFormSubmit', (event) => {
  const { formData, metadata } = event.detail;
  
  // Generate Terraform configuration
  const terraformCode = generateTerraformCode(formData, metadata);
  
  // Deploy infrastructure
  deployInfrastructure(terraformCode);
});
```

## Customization Options

### Themes and Styling

The CSS uses CSS custom properties for easy theming:

```css
:root {
  --primary-color: #2563eb;
  --success-color: #059669;
  --warning-color: #d97706;
  --error-color: #dc2626;
}
```

### Form Generator Options

```javascript
const generator = new PortalFormGenerator(metadata, {
  theme: 'dark',           // Theme variant
  showAdvanced: true,      // Show advanced sections by default
  enableTooltips: false,   // Disable tooltip help
  autoSave: false         // Disable auto-save
});
```

### Validation Customization

Add custom validation functions:

```javascript
// Custom validation function
window.validateDomainName = function(value, field) {
  if (!value.includes('.')) {
    return 'Domain must include a dot';
  }
  return true; // Valid
};

// Reference in metadata
{
  "name": "domain",
  "validation": {
    "custom": "validateDomainName"
  }
}
```

## Best Practices

### 1. Form Design

- **Group related fields** into logical sections
- **Use clear, descriptive labels** and help text
- **Provide sensible defaults** to minimize user input
- **Show advanced options** in collapsible sections
- **Use appropriate field types** for better UX

### 2. Validation

- **Validate early and often** with real-time feedback
- **Provide specific error messages** with remediation steps
- **Use visual indicators** for validation states
- **Consider field dependencies** and conditional logic

### 3. Cost Transparency

- **Be realistic** with cost estimates
- **Explain cost factors** clearly
- **Provide optimization tips** for budget-conscious users
- **Update estimates** based on configuration changes

### 4. Accessibility

- **Use semantic HTML** for screen readers
- **Provide keyboard navigation** for all interactions
- **Include ARIA labels** for complex components
- **Support high contrast** and reduced motion preferences

### 5. Performance

- **Debounce validation** to avoid excessive API calls
- **Lazy load** advanced sections and features
- **Optimize for mobile** with responsive design
- **Cache form data** to preserve user work

## Testing

### Validate Metadata

```bash
# Validate portal metadata against schema
python scripts/validate-portal-metadata.py portal-metadata.yaml

# Validate with strict mode (warnings as errors)
python scripts/validate-portal-metadata.py --strict portal-metadata.yaml
```

### Test Form Generation

```javascript
// Unit test example
describe('PortalFormGenerator', () => {
  it('should generate valid form HTML', () => {
    const generator = new PortalFormGenerator(testMetadata);
    const html = generator.generateForm();
    
    expect(html).toContain('form');
    expect(html).toContain('module-form');
  });
});
```

### Integration Testing

```javascript
// Test form submission
const form = document.getElementById('module-form');
const utils = new PortalFormUtils(form, metadata);

// Simulate user input
utils.setFormData({
  app_name: 'test-app',
  environment: 'Development'
});

// Validate
const isValid = utils.validateForm();
expect(isValid).toBe(true);
```

## Troubleshooting

### Common Issues

1. **Form not rendering**
   - Check metadata schema validation
   - Verify JavaScript console for errors
   - Ensure all required files are loaded

2. **Validation not working**
   - Check field `data-validation` attributes
   - Verify validation rules in metadata
   - Test custom validation functions

3. **Styling issues**
   - Check CSS file loading
   - Verify CSS custom properties support
   - Test responsive design breakpoints

4. **Performance problems**
   - Enable debouncing for validation
   - Optimize large forms with lazy loading
   - Check for memory leaks in event listeners

### Debug Mode

Enable debug logging:

```javascript
const utils = new PortalFormUtils(form, metadata, {
  debug: true
});
```

This will log validation events, form changes, and other debugging information to the console.

## Contributing

When adding new features to the portal integration:

1. **Update the schema** if adding new metadata fields
2. **Add validation** for new field types or options
3. **Include examples** demonstrating the feature
4. **Update documentation** with usage instructions
5. **Add tests** for new functionality

## Support

For questions or issues with portal integration:

1. Check the [documentation](../../docs/portal-metadata-schema.md)
2. Review [example implementations](user-friendly-demo.html)
3. Validate metadata with the [validation script](../../scripts/validate-portal-metadata.py)
4. Open an issue with reproduction steps and metadata files
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->