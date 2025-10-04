#!/usr/bin/env python3
"""
AI Metadata Template Generator

This script generates ai-metadata.yaml template files for new Terraform modules
based on the defined schema and best practices.
"""

import yaml
import argparse
import sys
from pathlib import Path
from typing import Dict, Any, List


class AIMetadataGenerator:
    """Generates AI metadata templates for Terraform modules."""
    
    def __init__(self):
        """Initialize the generator."""
        self.template_data = {}
    
    def generate_template(self, 
                         module_name: str,
                         module_type: str = "service",
                         complexity: str = "intermediate",
                         cloud_providers: List[str] = None,
                         category: str = "compute") -> Dict[str, Any]:
        """Generate a complete AI metadata template."""
        
        if cloud_providers is None:
            cloud_providers = ["aws"]
        
        template = {
            "schema_version": "1.0",
            "module_info": {
                "name": module_name,
                "type": module_type,
                "complexity_level": complexity,
                "cloud_providers": cloud_providers,
                "category": category,
                "description": f"Multi-cloud {category} module for {module_name}",
                "estimated_deployment_time": "5-10 minutes"
            },
            "generation_templates": self._generate_templates(module_name),
            "validation_rules": self._generate_validation_rules(),
            "common_patterns": self._generate_common_patterns(category),
            "integration_points": self._generate_integration_points(category),
            "cost_estimation": self._generate_cost_estimation(category),
            "testing_scenarios": self._generate_testing_scenarios(module_name)
        }
        
        return template
    
    def _generate_templates(self, module_name: str) -> Dict[str, str]:
        """Generate Jinja2 templates for common usage patterns."""
        return {
            "basic_usage": f'''module "{{{{ module_name }}}}" {{
  source = "{{{{ module_source }}}}"
  
  name_prefix      = "{{{{ name_prefix }}}}"
  environment_type = "{{{{ environment_type | default('Development') }}}}"
  
  # Module-specific configuration
  {module_name}_config = {{
    # Add module-specific variables here
    enabled = {{{{ enabled | default(true) }}}}
  }}
  
  {{% if enable_monitoring %}}
  monitoring_config = {{
    enabled = true
  }}
  {{% endif %}}
  
  {{% if custom_tags %}}
  tags = {{
    {{% for key, value in custom_tags.items() %}}
    {{{{ key }}}} = "{{{{ value }}}}"
    {{% endfor %}}
  }}
  {{% endif %}}
}}''',
            
            "advanced_usage": f'''module "{{{{ module_name }}}}" {{
  source = "{{{{ module_source }}}}"
  
  name_prefix      = "{{{{ name_prefix }}}}"
  environment_type = "{{{{ environment_type | default('Production') }}}}"
  
  # Advanced configuration
  {module_name}_config = {{
    # Add advanced module-specific variables here
    enabled = {{{{ enabled | default(true) }}}}
  }}
  
  encryption_config = {{
    create_kms_key = {{{{ create_kms_key | default(true) }}}}
    kms_key_deletion_window_days = {{{{ kms_deletion_days | default(30) }}}}
  }}
  
  monitoring_config = {{
    enabled = true
  }}
  
  alarms_config = {{
    enabled = true
    create_sns_topic = {{{{ create_sns_topic | default(true) }}}}
  }}
}}''',
            
            "multi_cloud": f'''# AWS Implementation
module "{{{{ module_name }}}}_aws" {{
  source = "{{{{ module_source }}}}/aws"
  
  name_prefix = "{{{{ name_prefix }}}}-aws"
  environment_type = "{{{{ environment_type }}}}"
  
  # AWS-specific configuration
}}

# Azure Implementation  
module "{{{{ module_name }}}}_azure" {{
  source = "{{{{ module_source }}}}/azure"
  
  name_prefix = "{{{{ name_prefix }}}}-az"
  environment_type = "{{{{ environment_type }}}}"
  
  # Azure-specific configuration
}}

# GCP Implementation
module "{{{{ module_name }}}}_gcp" {{
  source = "{{{{ module_source }}}}/gcp"
  
  name_prefix = "{{{{ name_prefix }}}}-gcp"
  environment_type = "{{{{ environment_type }}}}"
  
  # GCP-specific configuration
}}'''
        }
    
    def _generate_validation_rules(self) -> List[Dict[str, Any]]:
        """Generate common validation rules."""
        return [
            {
                "field": "name_prefix",
                "rule_type": "pattern",
                "pattern": "^[a-z][a-z0-9-]{0,22}[a-z0-9]$",
                "error_message": "name_prefix must be 2-24 characters, start with lowercase letter, contain only lowercase letters, numbers, and hyphens",
                "severity": "error",
                "remediation": "Use a shorter name with only lowercase letters, numbers, and hyphens"
            },
            {
                "field": "environment_type",
                "rule_type": "allowed_values",
                "allowed_values": ["None", "Ephemeral", "Development", "Testing", "UAT", "Production", "MissionCritical"],
                "error_message": "environment_type must be a valid environment type",
                "severity": "error",
                "remediation": "Choose from: Development, Testing, UAT, Production, or MissionCritical"
            },
            {
                "field": "enabled",
                "rule_type": "allowed_values",
                "allowed_values": [True, False],
                "error_message": "enabled must be a boolean value",
                "severity": "error",
                "remediation": "Set enabled to true or false"
            }
        ]
    
    def _generate_common_patterns(self, category: str) -> List[Dict[str, Any]]:
        """Generate common usage patterns based on category."""
        base_patterns = [
            {
                "pattern_name": "development_environment",
                "description": "Cost-optimized setup for development and testing",
                "use_case": "Development environments that can be shut down outside business hours",
                "template_variables": {
                    "environment_type": "Development",
                    "enable_monitoring": False,
                    "create_kms_key": False
                },
                "estimated_cost": "low"
            },
            {
                "pattern_name": "production_environment",
                "description": "Production-grade deployment with full monitoring and encryption",
                "use_case": "Production applications requiring high availability and security",
                "template_variables": {
                    "environment_type": "Production",
                    "enable_monitoring": True,
                    "create_kms_key": True
                },
                "estimated_cost": "medium"
            }
        ]
        
        # Add category-specific patterns
        if category == "compute":
            base_patterns.append({
                "pattern_name": "auto_scaling_web_app",
                "description": "Auto-scaling web application with load balancing",
                "use_case": "Web applications with variable traffic patterns",
                "template_variables": {
                    "min_size": 2,
                    "max_size": 10,
                    "enable_monitoring": True
                },
                "estimated_cost": "medium"
            })
        elif category == "storage":
            base_patterns.append({
                "pattern_name": "backup_storage",
                "description": "Cost-effective backup storage with lifecycle policies",
                "use_case": "Long-term data retention and backup",
                "template_variables": {
                    "storage_class": "infrequent_access",
                    "lifecycle_enabled": True
                },
                "estimated_cost": "low"
            })
        
        return base_patterns
    
    def _generate_integration_points(self, category: str) -> List[Dict[str, Any]]:
        """Generate integration points based on category."""
        common_integrations = [
            {
                "module": "networking",
                "connection_type": "dependency",
                "required_outputs": ["vpc_id", "subnet_ids"],
                "integration_example": '''module "network" {
  source = "kbrockhoff/networking/terraform"
  # ... network configuration
}

module "this" {
  source = "kbrockhoff/MODULE_NAME/terraform"
  
  network_config = {
    vpc_id     = module.network.vpc_id
    subnet_ids = module.network.private_subnet_ids
  }
}'''
            }
        ]
        
        # Add category-specific integrations
        if category in ["compute", "database"]:
            common_integrations.append({
                "module": "security",
                "connection_type": "reference",
                "required_outputs": ["security_group_id"],
                "integration_example": "security_group_ids = [module.security.app_security_group_id]"
            })
        
        if category == "storage":
            common_integrations.append({
                "module": "encryption",
                "connection_type": "optional",
                "optional_outputs": ["kms_key_id"],
                "integration_example": "kms_key_id = module.encryption.storage_key_id"
            })
        
        return common_integrations
    
    def _generate_cost_estimation(self, category: str) -> Dict[str, Any]:
        """Generate cost estimation based on category."""
        base_costs = {
            "compute": {"base_cost_per_hour": 0.05, "base_cost_per_month": 36.50},
            "storage": {"base_cost_per_hour": 0.01, "base_cost_per_month": 7.30},
            "networking": {"base_cost_per_hour": 0.02, "base_cost_per_month": 14.60},
            "database": {"base_cost_per_hour": 0.10, "base_cost_per_month": 73.00},
            "monitoring": {"base_cost_per_hour": 0.005, "base_cost_per_month": 3.65}
        }
        
        cost_config = base_costs.get(category, base_costs["compute"])
        
        cost_config.update({
            "scaling_factors": {
                "environment_type": {
                    "Development": 0.5,
                    "Testing": 0.7,
                    "Production": 1.0,
                    "MissionCritical": 1.5
                }
            },
            "cost_variables": [
                {
                    "variable": "enabled",
                    "impact": "step",
                    "multiplier": 1.0
                }
            ],
            "cost_optimization_hints": [
                f"Use appropriate sizing for {category} resources",
                "Enable auto-scaling for variable workloads",
                "Consider reserved instances for predictable usage",
                "Use lifecycle policies to optimize storage costs"
            ]
        })
        
        return cost_config
    
    def _generate_testing_scenarios(self, module_name: str) -> List[Dict[str, Any]]:
        """Generate testing scenarios."""
        return [
            {
                "name": "basic_deployment",
                "description": "Validates basic module deployment with minimal configuration",
                "variables": {
                    "name_prefix": f"test-{module_name}",
                    "environment_type": "Development",
                    "enabled": True
                },
                "expected_outcome": {
                    "resource_count": 3,
                    "success": True,
                    "validation_checks": [
                        "Module resources created successfully",
                        "Tags applied correctly",
                        "Outputs generated"
                    ]
                }
            },
            {
                "name": "production_deployment",
                "description": "Validates production-ready deployment with full features",
                "variables": {
                    "name_prefix": f"prod-{module_name}",
                    "environment_type": "Production",
                    "enabled": True,
                    "monitoring_config": {"enabled": True},
                    "encryption_config": {"create_kms_key": True}
                },
                "expected_outcome": {
                    "resource_count": 8,
                    "success": True,
                    "validation_checks": [
                        "KMS key created",
                        "Monitoring enabled",
                        "Production-grade configuration applied"
                    ]
                }
            },
            {
                "name": "validation_test",
                "description": "Tests validation of invalid input parameters",
                "variables": {
                    "name_prefix": "Invalid-Name!",
                    "environment_type": "InvalidEnv",
                    "enabled": "not_boolean"
                },
                "expected_outcome": {
                    "success": False,
                    "validation_checks": [
                        "name_prefix validation fails",
                        "environment_type validation fails",
                        "enabled type validation fails"
                    ]
                }
            }
        ]
    
    def save_template(self, template: Dict[str, Any], output_file: str) -> None:
        """Save the generated template to a file."""
        with open(output_file, 'w') as f:
            yaml.dump(template, f, default_flow_style=False, sort_keys=False, indent=2)


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description="Generate AI metadata template")
    parser.add_argument("module_name", help="Name of the Terraform module")
    parser.add_argument("--type", choices=["foundation", "service", "composite"], 
                       default="service", help="Module type")
    parser.add_argument("--complexity", choices=["beginner", "intermediate", "advanced", "expert"],
                       default="intermediate", help="Complexity level")
    parser.add_argument("--cloud-providers", nargs="+", choices=["aws", "azure", "gcp"],
                       default=["aws"], help="Supported cloud providers")
    parser.add_argument("--category", choices=["compute", "storage", "networking", "security", "database", "monitoring", "identity"],
                       default="compute", help="Module category")
    parser.add_argument("--output", "-o", default="ai-metadata.yaml", 
                       help="Output file path")
    
    args = parser.parse_args()
    
    try:
        generator = AIMetadataGenerator()
        template = generator.generate_template(
            module_name=args.module_name,
            module_type=args.type,
            complexity=args.complexity,
            cloud_providers=args.cloud_providers,
            category=args.category
        )
        
        generator.save_template(template, args.output)
        print(f"✅ AI metadata template generated: {args.output}")
        print(f"📝 Module: {args.module_name} ({args.type}, {args.complexity})")
        print(f"☁️  Cloud providers: {', '.join(args.cloud_providers)}")
        print(f"📂 Category: {args.category}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()