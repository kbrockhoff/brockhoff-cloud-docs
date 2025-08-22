#!/usr/bin/env python3
"""
AI Metadata Validation Script

This script validates ai-metadata.yaml files against the defined schema
to ensure they conform to the AI agent integration standards.
"""

import yaml
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional


class AIMetadataValidator:
    """Validates AI metadata files against the schema."""
    
    def __init__(self, schema_file: str = "ai-metadata-schema.yaml"):
        """Initialize validator with schema file."""
        self.schema = self._load_schema(schema_file)
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def _load_schema(self, schema_file: str) -> Dict[str, Any]:
        """Load the AI metadata schema."""
        try:
            with open(schema_file, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Schema file not found: {schema_file}")
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML in schema file: {e}")
    
    def validate_file(self, metadata_file: str) -> bool:
        """Validate a single AI metadata file."""
        self.errors.clear()
        self.warnings.clear()
        
        try:
            with open(metadata_file, 'r') as f:
                metadata = yaml.safe_load(f)
        except FileNotFoundError:
            self.errors.append(f"Metadata file not found: {metadata_file}")
            return False
        except yaml.YAMLError as e:
            self.errors.append(f"Invalid YAML in metadata file: {e}")
            return False
        
        # Validate against schema
        self._validate_structure(metadata)
        self._validate_fields(metadata)
        self._validate_templates(metadata.get('generation_templates', {}))
        self._validate_rules(metadata.get('validation_rules', []))
        self._validate_integration_points(metadata.get('integration_points', []))
        self._validate_cost_estimation(metadata.get('cost_estimation', {}))
        self._validate_testing_scenarios(metadata.get('testing_scenarios', []))
        
        return len(self.errors) == 0
    
    def _validate_structure(self, metadata: Dict[str, Any]) -> None:
        """Validate the overall structure of the metadata."""
        schema_def = self.schema['metadata_schema']
        
        # Check required fields
        for field in schema_def['required_fields']:
            if field not in metadata:
                self.errors.append(f"Missing required field: {field}")
        
        # Check for unknown fields
        allowed_fields = schema_def['required_fields'] + schema_def['optional_fields']
        for field in metadata.keys():
            if field not in allowed_fields:
                self.warnings.append(f"Unknown field: {field}")
    
    def _validate_fields(self, metadata: Dict[str, Any]) -> None:
        """Validate individual fields against their definitions."""
        field_defs = self.schema['field_definitions']
        
        for field_name, field_def in field_defs.items():
            if field_name not in metadata:
                continue
            
            field_value = metadata[field_name]
            self._validate_field_type(field_name, field_value, field_def)
            
            if 'pattern' in field_def:
                self._validate_pattern(field_name, field_value, field_def['pattern'])
            
            if 'enum' in field_def:
                self._validate_enum(field_name, field_value, field_def['enum'])
    
    def _validate_field_type(self, field_name: str, value: Any, field_def: Dict[str, Any]) -> None:
        """Validate field type."""
        expected_type = field_def.get('type')
        
        if expected_type == 'string' and not isinstance(value, str):
            self.errors.append(f"Field '{field_name}' must be a string")
        elif expected_type == 'number' and not isinstance(value, (int, float)):
            self.errors.append(f"Field '{field_name}' must be a number")
        elif expected_type == 'array' and not isinstance(value, list):
            self.errors.append(f"Field '{field_name}' must be an array")
        elif expected_type == 'object' and not isinstance(value, dict):
            self.errors.append(f"Field '{field_name}' must be an object")
    
    def _validate_pattern(self, field_name: str, value: Any, pattern: str) -> None:
        """Validate field against regex pattern."""
        if isinstance(value, str) and not re.match(pattern, value):
            self.errors.append(f"Field '{field_name}' does not match pattern: {pattern}")
    
    def _validate_enum(self, field_name: str, value: Any, allowed_values: List[Any]) -> None:
        """Validate field against allowed values."""
        if value not in allowed_values:
            self.errors.append(f"Field '{field_name}' must be one of: {allowed_values}")
    
    def _validate_templates(self, templates: Dict[str, str]) -> None:
        """Validate generation templates."""
        if 'basic_usage' not in templates:
            self.errors.append("Missing required template: basic_usage")
        
        template_validation = self.schema['template_validation']
        required_vars = template_validation['required_variables']
        
        for template_name, template_content in templates.items():
            # Check for required variables
            for var in required_vars:
                if var not in template_content:
                    self.warnings.append(f"Template '{template_name}' missing recommended variable: {var}")
            
            # Check for security issues
            security_patterns = [
                r'password\s*=\s*["\'][^"\']+["\']',
                r'secret\s*=\s*["\'][^"\']+["\']',
                r'key\s*=\s*["\'][^"\']+["\']',
                r'arn:aws:[^"\']*["\']'
            ]
            
            for pattern in security_patterns:
                if re.search(pattern, template_content, re.IGNORECASE):
                    self.errors.append(f"Template '{template_name}' contains potential hardcoded secrets")
    
    def _validate_rules(self, rules: List[Dict[str, Any]]) -> None:
        """Validate validation rules."""
        for i, rule in enumerate(rules):
            if 'field' not in rule:
                self.errors.append(f"Validation rule {i} missing 'field'")
            if 'rule_type' not in rule:
                self.errors.append(f"Validation rule {i} missing 'rule_type'")
            if 'error_message' not in rule:
                self.errors.append(f"Validation rule {i} missing 'error_message'")
            
            rule_type = rule.get('rule_type')
            if rule_type == 'pattern' and 'pattern' not in rule:
                self.errors.append(f"Pattern rule {i} missing 'pattern'")
            elif rule_type == 'allowed_values' and 'allowed_values' not in rule:
                self.errors.append(f"Allowed values rule {i} missing 'allowed_values'")
            elif rule_type == 'range' and ('min_value' not in rule or 'max_value' not in rule):
                self.errors.append(f"Range rule {i} missing min_value or max_value")
    
    def _validate_integration_points(self, integration_points: List[Dict[str, Any]]) -> None:
        """Validate integration points."""
        for i, point in enumerate(integration_points):
            if 'module' not in point:
                self.errors.append(f"Integration point {i} missing 'module'")
            if 'connection_type' not in point:
                self.errors.append(f"Integration point {i} missing 'connection_type'")
            
            connection_type = point.get('connection_type')
            valid_types = ['dependency', 'reference', 'composition', 'optional']
            if connection_type not in valid_types:
                self.errors.append(f"Integration point {i} has invalid connection_type: {connection_type}")
    
    def _validate_cost_estimation(self, cost_est: Dict[str, Any]) -> None:
        """Validate cost estimation configuration."""
        if not cost_est:
            self.warnings.append("No cost estimation provided")
            return
        
        # Check for at least one base cost
        if 'base_cost_per_hour' not in cost_est and 'base_cost_per_month' not in cost_est:
            self.warnings.append("No base cost provided (per_hour or per_month)")
        
        # Validate scaling factors
        if 'scaling_factors' in cost_est:
            factors = cost_est['scaling_factors']
            if not isinstance(factors, dict):
                self.errors.append("scaling_factors must be an object")
    
    def _validate_testing_scenarios(self, scenarios: List[Dict[str, Any]]) -> None:
        """Validate testing scenarios."""
        if not scenarios:
            self.warnings.append("No testing scenarios provided")
            return
        
        for i, scenario in enumerate(scenarios):
            required_fields = ['name', 'variables', 'expected_outcome']
            for field in required_fields:
                if field not in scenario:
                    self.errors.append(f"Testing scenario {i} missing '{field}'")
    
    def get_validation_report(self) -> str:
        """Generate a validation report."""
        report = []
        
        if self.errors:
            report.append("ERRORS:")
            for error in self.errors:
                report.append(f"  ❌ {error}")
        
        if self.warnings:
            report.append("WARNINGS:")
            for warning in self.warnings:
                report.append(f"  ⚠️  {warning}")
        
        if not self.errors and not self.warnings:
            report.append("✅ Validation passed successfully!")
        
        return "\n".join(report)


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description="Validate AI metadata files")
    parser.add_argument("metadata_file", help="Path to ai-metadata.yaml file")
    parser.add_argument("--schema", default="ai-metadata-schema.yaml", 
                       help="Path to schema file")
    parser.add_argument("--strict", action="store_true", 
                       help="Treat warnings as errors")
    
    args = parser.parse_args()
    
    try:
        validator = AIMetadataValidator(args.schema)
        is_valid = validator.validate_file(args.metadata_file)
        
        print(validator.get_validation_report())
        
        if args.strict and validator.warnings:
            is_valid = False
        
        sys.exit(0 if is_valid else 1)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()