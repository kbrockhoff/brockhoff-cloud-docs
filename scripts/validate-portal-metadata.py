#!/usr/bin/env python3
"""
Portal Metadata Validation Script

Validates portal metadata files against the schema and performs additional
business logic validation for developer portal integration.
"""

import json
import yaml
import sys
import os
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional
import jsonschema
from jsonschema import validate, ValidationError


class PortalMetadataValidator:
    """Validates portal metadata files for Terraform modules."""
    
    def __init__(self, schema_path: str):
        """Initialize validator with schema file."""
        with open(schema_path, 'r') as f:
            self.schema = json.load(f)
    
    def validate_file(self, metadata_path: str) -> Dict[str, Any]:
        """Validate a single portal metadata file."""
        try:
            # Load metadata file
            with open(metadata_path, 'r') as f:
                if metadata_path.endswith('.yaml') or metadata_path.endswith('.yml'):
                    metadata = yaml.safe_load(f)
                else:
                    metadata = json.load(f)
            
            # Schema validation
            validate(instance=metadata, schema=self.schema)
            
            # Business logic validation
            validation_results = {
                'file': metadata_path,
                'valid': True,
                'errors': [],
                'warnings': [],
                'suggestions': []
            }
            
            self._validate_business_logic(metadata, validation_results)
            
            return validation_results
            
        except ValidationError as e:
            return {
                'file': metadata_path,
                'valid': False,
                'errors': [f"Schema validation error: {e.message}"],
                'warnings': [],
                'suggestions': []
            }
        except Exception as e:
            return {
                'file': metadata_path,
                'valid': False,
                'errors': [f"Error loading file: {str(e)}"],
                'warnings': [],
                'suggestions': []
            }
    
    def _validate_business_logic(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Perform business logic validation beyond schema."""
        
        # Validate form schema consistency
        self._validate_form_schema(metadata, results)
        
        # Validate cost estimation reasonableness
        self._validate_cost_estimation(metadata, results)
        
        # Validate difficulty assessment
        self._validate_difficulty_assessment(metadata, results)
        
        # Validate prerequisites and dependencies
        self._validate_dependencies(metadata, results)
        
        # Validate deployment order
        self._validate_deployment_order(metadata, results)
    
    def _validate_form_schema(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Validate form schema for consistency and usability."""
        form_schema = metadata.get('form_schema', {})
        sections = form_schema.get('sections', [])
        
        all_fields = []
        field_names = set()
        
        for section in sections:
            for field in section.get('fields', []):
                field_name = field.get('name')
                all_fields.append(field)
                
                if field_name in field_names:
                    results['errors'].append(f"Duplicate field name: {field_name}")
                field_names.add(field_name)
                
                # Validate conditional fields reference existing fields
                conditional = field.get('conditional')
                if conditional:
                    ref_field = conditional.get('field')
                    if ref_field not in field_names:
                        # Check if it's defined later (warning, not error)
                        results['warnings'].append(
                            f"Field '{field_name}' references '{ref_field}' which may not be defined yet"
                        )
                
                # Validate select field options
                if field.get('type') in ['select', 'multiselect']:
                    options = field.get('options', [])
                    if not options:
                        results['errors'].append(
                            f"Select field '{field_name}' must have options"
                        )
                    
                    # Check for duplicate option values
                    option_values = [opt.get('value') for opt in options]
                    if len(option_values) != len(set(option_values)):
                        results['errors'].append(
                            f"Select field '{field_name}' has duplicate option values"
                        )
                
                # Validate default values against field type
                default = field.get('default')
                field_type = field.get('type')
                if default is not None:
                    if field_type == 'number' and not isinstance(default, (int, float)):
                        results['errors'].append(
                            f"Field '{field_name}' has non-numeric default for number type"
                        )
                    elif field_type == 'boolean' and not isinstance(default, bool):
                        results['errors'].append(
                            f"Field '{field_name}' has non-boolean default for boolean type"
                        )
        
        # Check for required fields without defaults
        required_fields = [f for f in all_fields if f.get('required', False)]
        for field in required_fields:
            if field.get('default') is None and field.get('type') != 'boolean':
                results['warnings'].append(
                    f"Required field '{field.get('name')}' has no default value"
                )
    
    def _validate_cost_estimation(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Validate cost estimation for reasonableness."""
        cost_est = metadata.get('cost_estimation', {})
        
        # Check cost range consistency
        monthly_cost = cost_est.get('estimated_monthly_cost', {})
        min_cost = monthly_cost.get('min')
        max_cost = monthly_cost.get('max')
        typical_cost = monthly_cost.get('typical')
        
        if min_cost is not None and max_cost is not None:
            if min_cost > max_cost:
                results['errors'].append("Minimum cost cannot be greater than maximum cost")
            
            if typical_cost is not None:
                if typical_cost < min_cost or typical_cost > max_cost:
                    results['errors'].append("Typical cost must be between minimum and maximum")
        
        # Validate cost category alignment
        base_category = cost_est.get('base_cost_category')
        if base_category and typical_cost is not None:
            category_ranges = {
                'free': (0, 0),
                'low': (0, 50),
                'medium': (50, 200),
                'high': (200, 1000),
                'variable': (0, float('inf'))
            }
            
            if base_category in category_ranges:
                min_range, max_range = category_ranges[base_category]
                if not (min_range <= typical_cost <= max_range):
                    results['warnings'].append(
                        f"Typical cost ${typical_cost} doesn't align with '{base_category}' category"
                    )
        
        # Check for cost optimization tips
        if not cost_est.get('cost_optimization_tips'):
            results['suggestions'].append("Consider adding cost optimization tips")
    
    def _validate_difficulty_assessment(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Validate difficulty assessment for consistency."""
        difficulty = metadata.get('difficulty_assessment', {})
        
        overall = difficulty.get('overall_difficulty')
        skill_reqs = difficulty.get('skill_requirements', {})
        
        # Map skill levels to numeric values for comparison
        skill_levels = {'none': 0, 'basic': 1, 'intermediate': 2, 'advanced': 3}
        
        # Calculate average skill requirement
        skill_values = []
        for skill, level in skill_reqs.items():
            if level in skill_levels:
                skill_values.append(skill_levels[level])
        
        if skill_values and overall is not None:
            avg_skill = sum(skill_values) / len(skill_values)
            expected_difficulty = min(5, max(1, int(avg_skill * 1.5) + 1))
            
            if abs(overall - expected_difficulty) > 1:
                results['warnings'].append(
                    f"Overall difficulty ({overall}) may not align with skill requirements"
                )
    
    def _validate_dependencies(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Validate prerequisites and dependencies."""
        prereqs = metadata.get('prerequisites', {})
        deps = metadata.get('dependencies', {})
        
        # Check for circular dependencies
        module_deps = deps.get('module_dependencies', [])
        required_modules = prereqs.get('required_modules', [])
        
        all_module_names = set()
        for mod in module_deps + required_modules:
            all_module_names.add(mod.get('module_name'))
        
        # Validate integration points are specified for dependencies
        for dep in module_deps:
            if dep.get('relationship_type') == 'required':
                if not dep.get('integration_points'):
                    results['warnings'].append(
                        f"Required dependency '{dep.get('module_name')}' should specify integration points"
                    )
    
    def _validate_deployment_order(self, metadata: Dict[str, Any], results: Dict[str, Any]):
        """Validate deployment order consistency."""
        deps = metadata.get('dependencies', {})
        deployment_order = deps.get('deployment_order', [])
        
        if not deployment_order:
            return
        
        # Check step numbering
        steps = [step.get('step') for step in deployment_order]
        expected_steps = list(range(1, len(deployment_order) + 1))
        
        if sorted(steps) != expected_steps:
            results['errors'].append("Deployment order steps must be consecutive starting from 1")
        
        # Validate modules in deployment order exist in dependencies
        module_deps = deps.get('module_dependencies', [])
        dep_module_names = {dep.get('module_name') for dep in module_deps}
        
        for step in deployment_order:
            for module in step.get('modules', []):
                if module not in dep_module_names:
                    results['warnings'].append(
                        f"Module '{module}' in deployment order not found in module dependencies"
                    )


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description='Validate portal metadata files')
    parser.add_argument('files', nargs='+', help='Portal metadata files to validate')
    parser.add_argument('--schema', default='schemas/portal-metadata-schema.json',
                       help='Path to portal metadata schema file')
    parser.add_argument('--strict', action='store_true',
                       help='Treat warnings as errors')
    parser.add_argument('--quiet', action='store_true',
                       help='Only show errors')
    
    args = parser.parse_args()
    
    # Check if schema file exists
    if not os.path.exists(args.schema):
        print(f"Error: Schema file not found: {args.schema}")
        sys.exit(1)
    
    validator = PortalMetadataValidator(args.schema)
    
    all_valid = True
    total_files = 0
    total_errors = 0
    total_warnings = 0
    
    for file_path in args.files:
        if not os.path.exists(file_path):
            print(f"Error: File not found: {file_path}")
            all_valid = False
            continue
        
        total_files += 1
        results = validator.validate_file(file_path)
        
        if not results['valid']:
            all_valid = False
        
        total_errors += len(results['errors'])
        total_warnings += len(results['warnings'])
        
        # Print results
        if not args.quiet or results['errors'] or (args.strict and results['warnings']):
            print(f"\n📄 {file_path}")
            
            if results['valid'] and not results['errors'] and not results['warnings']:
                print("  ✅ Valid")
            else:
                for error in results['errors']:
                    print(f"  ❌ Error: {error}")
                
                for warning in results['warnings']:
                    print(f"  ⚠️  Warning: {warning}")
                
                if not args.quiet:
                    for suggestion in results['suggestions']:
                        print(f"  💡 Suggestion: {suggestion}")
        
        if args.strict and results['warnings']:
            all_valid = False
    
    # Summary
    print(f"\n📊 Summary:")
    print(f"  Files processed: {total_files}")
    print(f"  Errors: {total_errors}")
    print(f"  Warnings: {total_warnings}")
    
    if all_valid:
        print("  ✅ All files valid")
        sys.exit(0)
    else:
        print("  ❌ Validation failed")
        sys.exit(1)


if __name__ == '__main__':
    main()