#!/usr/bin/env python3
"""
Module Interface Generator

This script generates structured input/output schemas from Terraform modules
to enable AI agents to understand and use modules programmatically.
"""

import json
import re
import os
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
import hcl2
import logging


class TerraformModuleAnalyzer:
    """Analyzes Terraform modules to extract interface information."""
    
    def __init__(self):
        """Initialize the analyzer."""
        self.logger = logging.getLogger(__name__)
    
    def analyze_module(self, module_path: str) -> Dict[str, Any]:
        """
        Analyze a Terraform module and extract interface information.
        
        Args:
            module_path: Path to the Terraform module directory
            
        Returns:
            Module interface schema
        """
        module_path = Path(module_path)
        
        if not module_path.exists():
            raise FileNotFoundError(f"Module path does not exist: {module_path}")
        
        # Extract module information
        module_info = self._extract_module_info(module_path)
        
        # Analyze variables
        inputs = self._analyze_variables(module_path)
        
        # Analyze outputs
        outputs = self._analyze_outputs(module_path)
        
        # Analyze dependencies
        dependencies = self._analyze_dependencies(module_path)
        
        # Generate examples
        examples = self._generate_examples(module_path, inputs)
        
        return {
            "schema_version": "1.0.0",
            "module_info": module_info,
            "inputs": inputs,
            "outputs": outputs,
            "dependencies": dependencies,
            "examples": examples
        }
    
    def _extract_module_info(self, module_path: Path) -> Dict[str, Any]:
        """Extract basic module information."""
        # Try to get info from README
        readme_path = module_path / "README.md"
        description = ""
        
        if readme_path.exists():
            with open(readme_path, 'r') as f:
                content = f.read()
                # Extract first paragraph as description
                lines = content.split('\n')
                for line in lines:
                    if line.strip() and not line.startswith('#'):
                        description = line.strip()
                        break
        
        # Try to get version from versions.tf
        version = "1.0.0"
        versions_file = module_path / "versions.tf"
        if versions_file.exists():
            # This is simplified - in practice, you'd parse the Terraform version constraints
            version = "1.0.0"
        
        # Determine cloud providers from provider requirements
        cloud_providers = self._detect_cloud_providers(module_path)
        
        # Determine category from module name or content
        category = self._determine_category(module_path)
        
        return {
            "name": module_path.name,
            "version": version,
            "source": f"kbrockhoff/{module_path.name}/terraform",
            "cloud_providers": cloud_providers,
            "description": description or f"Terraform module for {module_path.name}",
            "category": category
        }
    
    def _analyze_variables(self, module_path: Path) -> Dict[str, Any]:
        """Analyze module variables from variables.tf."""
        variables_file = module_path / "variables.tf"
        inputs = {}
        
        if not variables_file.exists():
            return inputs
        
        try:
            with open(variables_file, 'r') as f:
                content = f.read()
            
            # Parse HCL content
            parsed = hcl2.loads(content)
            
            for variable_block in parsed.get('variable', []):
                for var_name, var_config in variable_block.items():
                    inputs[var_name] = self._parse_variable_definition(var_name, var_config)
        
        except Exception as e:
            self.logger.warning(f"Failed to parse variables.tf: {e}")
            # Fallback to regex parsing
            inputs = self._parse_variables_with_regex(variables_file)
        
        return inputs
    
    def _analyze_outputs(self, module_path: Path) -> Dict[str, Any]:
        """Analyze module outputs from outputs.tf."""
        outputs_file = module_path / "outputs.tf"
        outputs = {}
        
        if not outputs_file.exists():
            return outputs
        
        try:
            with open(outputs_file, 'r') as f:
                content = f.read()
            
            # Parse HCL content
            parsed = hcl2.loads(content)
            
            for output_block in parsed.get('output', []):
                for output_name, output_config in output_block.items():
                    outputs[output_name] = self._parse_output_definition(output_name, output_config)
        
        except Exception as e:
            self.logger.warning(f"Failed to parse outputs.tf: {e}")
            # Fallback to regex parsing
            outputs = self._parse_outputs_with_regex(outputs_file)
        
        return outputs
    
    def _analyze_dependencies(self, module_path: Path) -> List[Dict[str, Any]]:
        """Analyze module dependencies from main.tf and other files."""
        dependencies = []
        
        # Look for module calls in all .tf files
        for tf_file in module_path.glob("*.tf"):
            try:
                with open(tf_file, 'r') as f:
                    content = f.read()
                
                # Find module blocks
                module_pattern = r'module\s+"([^"]+)"\s*\{[^}]*source\s*=\s*"([^"]+)"'
                matches = re.findall(module_pattern, content, re.MULTILINE | re.DOTALL)
                
                for module_name, source in matches:
                    dependency = {
                        "module": source,
                        "type": "required",  # Assume required unless proven otherwise
                        "required_outputs": self._extract_required_outputs(content, module_name)
                    }
                    dependencies.append(dependency)
            
            except Exception as e:
                self.logger.warning(f"Failed to analyze dependencies in {tf_file}: {e}")
        
        return dependencies
    
    def _generate_examples(self, module_path: Path, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Generate usage examples based on the module interface."""
        examples = {}
        
        # Check for existing examples
        examples_dir = module_path / "examples"
        if examples_dir.exists():
            for example_dir in examples_dir.iterdir():
                if example_dir.is_dir():
                    example = self._parse_existing_example(example_dir, inputs)
                    if example:
                        examples[example_dir.name] = example
        
        # Generate basic example if none exist
        if not examples:
            examples["basic"] = self._generate_basic_example(inputs)
        
        return examples
    
    def _parse_variable_definition(self, var_name: str, var_config: Dict[str, Any]) -> Dict[str, Any]:
        """Parse a variable definition into the interface schema format."""
        definition = {
            "type": self._parse_terraform_type(var_config.get("type", "string")),
            "description": var_config.get("description", ""),
            "required": "default" not in var_config,
            "sensitive": var_config.get("sensitive", False)
        }
        
        if "default" in var_config:
            definition["default"] = var_config["default"]
        
        # Parse validation blocks
        if "validation" in var_config:
            validations = var_config["validation"]
            if not isinstance(validations, list):
                validations = [validations]
            
            definition["validation"] = []
            for validation in validations:
                definition["validation"].append({
                    "condition": validation.get("condition", ""),
                    "error_message": validation.get("error_message", "")
                })
        
        # Add AI hints based on variable name and type
        definition["ai_hints"] = self._generate_ai_hints(var_name, definition)
        
        return definition
    
    def _parse_output_definition(self, output_name: str, output_config: Dict[str, Any]) -> Dict[str, Any]:
        """Parse an output definition into the interface schema format."""
        return {
            "description": output_config.get("description", ""),
            "sensitive": output_config.get("sensitive", False),
            "ai_usage": self._determine_ai_usage(output_name)
        }
    
    def _parse_terraform_type(self, tf_type: Any) -> Any:
        """Parse Terraform type into schema format."""
        if isinstance(tf_type, str):
            if tf_type in ["string", "number", "bool"]:
                return tf_type
            else:
                return "string"  # Default fallback
        
        elif isinstance(tf_type, dict):
            # Handle complex types like list(string), map(string), object({...})
            if len(tf_type) == 1:
                type_name, type_args = next(iter(tf_type.items()))
                
                if type_name in ["list", "set"]:
                    return {
                        "complex_type": type_name,
                        "element_type": self._parse_terraform_type(type_args)
                    }
                elif type_name == "map":
                    return {
                        "complex_type": "map",
                        "element_type": self._parse_terraform_type(type_args)
                    }
                elif type_name == "object":
                    attributes = {}
                    if isinstance(type_args, dict):
                        for attr_name, attr_type in type_args.items():
                            attributes[attr_name] = {
                                "type": self._parse_terraform_type(attr_type),
                                "required": True  # Assume required unless optional() is used
                            }
                    
                    return {
                        "complex_type": "object",
                        "attributes": attributes
                    }
        
        return "string"  # Fallback
    
    def _generate_ai_hints(self, var_name: str, definition: Dict[str, Any]) -> Dict[str, Any]:
        """Generate AI hints based on variable name and definition."""
        hints = {
            "generation_priority": "optional",
            "context_dependent": False,
            "cost_impact": "none",
            "security_impact": "none"
        }
        
        # Determine priority based on variable name
        if var_name in ["name", "name_prefix", "environment_type"]:
            hints["generation_priority"] = "required"
        elif var_name in ["enabled", "tags"]:
            hints["generation_priority"] = "recommended"
        elif "config" in var_name or "settings" in var_name:
            hints["generation_priority"] = "recommended"
        
        # Determine cost impact
        if any(keyword in var_name.lower() for keyword in ["instance", "size", "count", "storage", "capacity"]):
            hints["cost_impact"] = "high"
        elif any(keyword in var_name.lower() for keyword in ["monitoring", "backup", "encryption"]):
            hints["cost_impact"] = "medium"
        
        # Determine security impact
        if any(keyword in var_name.lower() for keyword in ["security", "encryption", "key", "password", "secret"]):
            hints["security_impact"] = "high"
        elif any(keyword in var_name.lower() for keyword in ["public", "private", "access", "policy"]):
            hints["security_impact"] = "medium"
        
        # Context dependency
        if any(keyword in var_name.lower() for keyword in ["vpc", "subnet", "network", "dependency"]):
            hints["context_dependent"] = True
        
        # Common values based on type and name
        if definition["type"] == "string":
            if "environment" in var_name.lower():
                hints["common_values"] = ["Development", "Testing", "Production"]
            elif "instance_type" in var_name.lower():
                hints["common_values"] = ["small", "medium", "large"]
        
        return hints
    
    def _determine_ai_usage(self, output_name: str) -> str:
        """Determine how AI agents should use an output."""
        if any(keyword in output_name.lower() for keyword in ["id", "arn", "name"]):
            return "Use as input to dependent modules"
        elif any(keyword in output_name.lower() for keyword in ["url", "endpoint", "connection"]):
            return "Use for application configuration"
        elif any(keyword in output_name.lower() for keyword in ["cost", "estimate"]):
            return "Use for budget planning and reporting"
        else:
            return "General purpose output value"
    
    def _detect_cloud_providers(self, module_path: Path) -> List[str]:
        """Detect supported cloud providers from provider requirements."""
        providers = []
        
        # Check versions.tf for required providers
        versions_file = module_path / "versions.tf"
        if versions_file.exists():
            try:
                with open(versions_file, 'r') as f:
                    content = f.read()
                
                if "aws" in content.lower():
                    providers.append("aws")
                if "azurerm" in content.lower():
                    providers.append("azure")
                if "google" in content.lower():
                    providers.append("gcp")
            
            except Exception as e:
                self.logger.warning(f"Failed to detect providers from versions.tf: {e}")
        
        # Fallback: check all .tf files for provider usage
        if not providers:
            for tf_file in module_path.glob("*.tf"):
                try:
                    with open(tf_file, 'r') as f:
                        content = f.read().lower()
                    
                    if "aws_" in content and "aws" not in providers:
                        providers.append("aws")
                    if "azurerm_" in content and "azure" not in providers:
                        providers.append("azure")
                    if "google_" in content and "gcp" not in providers:
                        providers.append("gcp")
                
                except Exception:
                    continue
        
        return providers or ["aws"]  # Default to AWS if none detected
    
    def _determine_category(self, module_path: Path) -> str:
        """Determine module category from name and content."""
        name = module_path.name.lower()
        
        if any(keyword in name for keyword in ["compute", "instance", "vm", "ec2", "server"]):
            return "compute"
        elif any(keyword in name for keyword in ["storage", "s3", "blob", "disk", "volume"]):
            return "storage"
        elif any(keyword in name for keyword in ["network", "vpc", "subnet", "lb", "alb", "nlb"]):
            return "networking"
        elif any(keyword in name for keyword in ["security", "iam", "policy", "role", "group"]):
            return "security"
        elif any(keyword in name for keyword in ["database", "db", "rds", "sql", "nosql"]):
            return "database"
        elif any(keyword in name for keyword in ["monitor", "log", "metric", "alarm", "dashboard"]):
            return "monitoring"
        elif any(keyword in name for keyword in ["identity", "auth", "sso", "directory"]):
            return "identity"
        else:
            return "compute"  # Default category
    
    def _parse_variables_with_regex(self, variables_file: Path) -> Dict[str, Any]:
        """Fallback regex-based variable parsing."""
        inputs = {}
        
        try:
            with open(variables_file, 'r') as f:
                content = f.read()
            
            # Simple regex to extract variable blocks
            var_pattern = r'variable\s+"([^"]+)"\s*\{([^}]+)\}'
            matches = re.findall(var_pattern, content, re.MULTILINE | re.DOTALL)
            
            for var_name, var_body in matches:
                # Extract description
                desc_match = re.search(r'description\s*=\s*"([^"]*)"', var_body)
                description = desc_match.group(1) if desc_match else ""
                
                # Extract type
                type_match = re.search(r'type\s*=\s*(\w+)', var_body)
                var_type = type_match.group(1) if type_match else "string"
                
                # Check for default
                has_default = "default" in var_body
                
                inputs[var_name] = {
                    "type": var_type,
                    "description": description,
                    "required": not has_default,
                    "ai_hints": self._generate_ai_hints(var_name, {"type": var_type})
                }
        
        except Exception as e:
            self.logger.error(f"Regex parsing of variables failed: {e}")
        
        return inputs
    
    def _parse_outputs_with_regex(self, outputs_file: Path) -> Dict[str, Any]:
        """Fallback regex-based output parsing."""
        outputs = {}
        
        try:
            with open(outputs_file, 'r') as f:
                content = f.read()
            
            # Simple regex to extract output blocks
            output_pattern = r'output\s+"([^"]+)"\s*\{([^}]+)\}'
            matches = re.findall(output_pattern, content, re.MULTILINE | re.DOTALL)
            
            for output_name, output_body in matches:
                # Extract description
                desc_match = re.search(r'description\s*=\s*"([^"]*)"', output_body)
                description = desc_match.group(1) if desc_match else ""
                
                # Check for sensitive
                sensitive = "sensitive" in output_body and "true" in output_body
                
                outputs[output_name] = {
                    "description": description,
                    "sensitive": sensitive,
                    "ai_usage": self._determine_ai_usage(output_name)
                }
        
        except Exception as e:
            self.logger.error(f"Regex parsing of outputs failed: {e}")
        
        return outputs
    
    def _extract_required_outputs(self, content: str, module_name: str) -> List[str]:
        """Extract required outputs from module usage in content."""
        outputs = []
        
        # Look for references to module outputs
        pattern = rf'module\.{re.escape(module_name)}\.(\w+)'
        matches = re.findall(pattern, content)
        
        return list(set(matches))  # Remove duplicates
    
    def _parse_existing_example(self, example_dir: Path, inputs: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Parse an existing example directory."""
        main_tf = example_dir / "main.tf"
        if not main_tf.exists():
            return None
        
        try:
            with open(main_tf, 'r') as f:
                content = f.read()
            
            # Extract module configuration
            module_pattern = r'module\s+"[^"]+"\s*\{([^}]+)\}'
            match = re.search(module_pattern, content, re.MULTILINE | re.DOTALL)
            
            if match:
                module_body = match.group(1)
                configuration = self._parse_module_configuration(module_body)
                
                # Read README for description
                readme_file = example_dir / "README.md"
                description = f"Example usage of the module"
                if readme_file.exists():
                    with open(readme_file, 'r') as f:
                        readme_content = f.read()
                        # Extract first line as description
                        lines = readme_content.split('\n')
                        for line in lines:
                            if line.strip() and not line.startswith('#'):
                                description = line.strip()
                                break
                
                return {
                    "description": description,
                    "configuration": configuration,
                    "use_case": f"Demonstrates {example_dir.name} usage pattern",
                    "complexity": "intermediate"
                }
        
        except Exception as e:
            self.logger.warning(f"Failed to parse example {example_dir}: {e}")
        
        return None
    
    def _parse_module_configuration(self, module_body: str) -> Dict[str, Any]:
        """Parse module configuration from HCL body."""
        config = {}
        
        # Simple parsing - extract key = value pairs
        lines = module_body.split('\n')
        for line in lines:
            line = line.strip()
            if '=' in line and not line.startswith('#'):
                try:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().rstrip(',')
                    
                    # Remove quotes if present
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    
                    config[key] = value
                except ValueError:
                    continue
        
        return config
    
    def _generate_basic_example(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Generate a basic example configuration."""
        config = {}
        
        # Include required variables with sensible defaults
        for var_name, var_def in inputs.items():
            if var_def.get("required", True):
                if var_name == "name_prefix":
                    config[var_name] = "example-app"
                elif var_name == "environment_type":
                    config[var_name] = "Development"
                elif var_def["type"] == "string":
                    config[var_name] = f"example-{var_name}"
                elif var_def["type"] == "bool":
                    config[var_name] = True
                elif var_def["type"] == "number":
                    config[var_name] = 1
        
        return {
            "description": "Basic usage example with minimal configuration",
            "configuration": config,
            "use_case": "Getting started with the module",
            "complexity": "beginner"
        }


def main():
    """Main function for command-line usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate module interface schema")
    parser.add_argument("module_path", help="Path to Terraform module directory")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--format", choices=["json", "yaml"], default="json", 
                       help="Output format")
    
    args = parser.parse_args()
    
    try:
        analyzer = TerraformModuleAnalyzer()
        interface = analyzer.analyze_module(args.module_path)
        
        if args.output:
            output_file = args.output
        else:
            module_name = Path(args.module_path).name
            ext = "yaml" if args.format == "yaml" else "json"
            output_file = f"{module_name}-interface.{ext}"
        
        with open(output_file, 'w') as f:
            if args.format == "yaml":
                yaml.dump(interface, f, default_flow_style=False, sort_keys=False, indent=2)
            else:
                json.dump(interface, f, indent=2)
        
        print(f"✅ Module interface generated: {output_file}")
        print(f"📊 Found {len(interface['inputs'])} inputs and {len(interface['outputs'])} outputs")
        print(f"☁️  Cloud providers: {', '.join(interface['module_info']['cloud_providers'])}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())