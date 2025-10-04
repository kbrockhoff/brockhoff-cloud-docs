#!/usr/bin/env python3
"""
AI Testing Framework

This framework provides automated validation for AI-generated Terraform configurations,
feedback mechanisms for improving AI code generation, and structured testing scenarios.
"""

import json
import yaml
import tempfile
import subprocess
import shutil
import os
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple, Union
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import re


@dataclass
class TestScenario:
    """Represents a test scenario for AI-generated configurations."""
    name: str
    description: str
    module_source: str
    variables: Dict[str, Any]
    expected_outcome: Dict[str, Any]
    cloud_provider: str = "aws"
    timeout_seconds: int = 300


@dataclass
class ValidationResult:
    """Result of a validation test."""
    scenario_name: str
    success: bool
    execution_time: float
    terraform_plan_success: bool
    resource_count: Optional[int] = None
    validation_errors: List[str] = None
    warnings: List[str] = None
    cost_estimate: Optional[float] = None
    security_issues: List[str] = None
    performance_metrics: Dict[str, Any] = None


@dataclass
class FeedbackReport:
    """Feedback report for AI code generation improvement."""
    timestamp: str
    ai_agent_id: str
    module_source: str
    generated_configuration: Dict[str, Any]
    validation_results: List[ValidationResult]
    success_rate: float
    common_errors: List[str]
    improvement_suggestions: List[str]
    performance_score: float


class TerraformValidator:
    """Validates Terraform configurations using terraform plan."""
    
    def __init__(self, terraform_binary: str = "terraform"):
        """Initialize the validator."""
        self.terraform_binary = terraform_binary
        self.logger = logging.getLogger(__name__)
    
    def validate_configuration(self, 
                             module_source: str,
                             variables: Dict[str, Any],
                             cloud_provider: str = "aws",
                             timeout: int = 300) -> ValidationResult:
        """
        Validate a Terraform configuration by running terraform plan.
        
        Args:
            module_source: Terraform module source
            variables: Module variables
            cloud_provider: Target cloud provider
            timeout: Timeout in seconds
            
        Returns:
            Validation result
        """
        start_time = datetime.now()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            try:
                # Create Terraform configuration
                config_content = self._generate_terraform_config(module_source, variables)
                config_file = Path(temp_dir) / "main.tf"
                
                with open(config_file, 'w') as f:
                    f.write(config_content)
                
                # Create terraform.tfvars
                tfvars_file = Path(temp_dir) / "terraform.tfvars"
                with open(tfvars_file, 'w') as f:
                    for key, value in variables.items():
                        if isinstance(value, str):
                            f.write(f'{key} = "{value}"\n')
                        elif isinstance(value, bool):
                            f.write(f'{key} = {str(value).lower()}\n')
                        elif isinstance(value, (int, float)):
                            f.write(f'{key} = {value}\n')
                        elif isinstance(value, dict):
                            f.write(f'{key} = {json.dumps(value)}\n')
                        elif isinstance(value, list):
                            f.write(f'{key} = {json.dumps(value)}\n')
                
                # Run terraform init
                init_result = self._run_terraform_command(
                    ["init"], temp_dir, timeout
                )
                
                if not init_result["success"]:
                    return ValidationResult(
                        scenario_name="validation",
                        success=False,
                        execution_time=(datetime.now() - start_time).total_seconds(),
                        terraform_plan_success=False,
                        validation_errors=[f"Terraform init failed: {init_result['error']}"]
                    )
                
                # Run terraform plan
                plan_result = self._run_terraform_command(
                    ["plan", "-out=plan.out"], temp_dir, timeout
                )
                
                execution_time = (datetime.now() - start_time).total_seconds()
                
                if plan_result["success"]:
                    # Parse plan output for resource count
                    resource_count = self._extract_resource_count(plan_result["output"])
                    
                    # Check for warnings
                    warnings = self._extract_warnings(plan_result["output"])
                    
                    return ValidationResult(
                        scenario_name="validation",
                        success=True,
                        execution_time=execution_time,
                        terraform_plan_success=True,
                        resource_count=resource_count,
                        warnings=warnings
                    )
                else:
                    # Parse errors from plan output
                    errors = self._extract_errors(plan_result["error"])
                    
                    return ValidationResult(
                        scenario_name="validation",
                        success=False,
                        execution_time=execution_time,
                        terraform_plan_success=False,
                        validation_errors=errors
                    )
            
            except Exception as e:
                execution_time = (datetime.now() - start_time).total_seconds()
                return ValidationResult(
                    scenario_name="validation",
                    success=False,
                    execution_time=execution_time,
                    terraform_plan_success=False,
                    validation_errors=[f"Validation exception: {str(e)}"]
                )
    
    def _generate_terraform_config(self, module_source: str, variables: Dict[str, Any]) -> str:
        """Generate Terraform configuration for testing."""
        config = f'''
terraform {{
  required_providers {{
    aws = {{
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }}
    azurerm = {{
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }}
    google = {{
      source  = "hashicorp/google"
      version = "~> 4.0"
    }}
  }}
}}

module "test_module" {{
  source = "{module_source}"
  
'''
        
        # Add variable declarations
        for key, value in variables.items():
            if isinstance(value, str):
                config += f'  {key} = var.{key}\n'
            elif isinstance(value, bool):
                config += f'  {key} = var.{key}\n'
            elif isinstance(value, (int, float)):
                config += f'  {key} = var.{key}\n'
            elif isinstance(value, (dict, list)):
                config += f'  {key} = var.{key}\n'
        
        config += '}\n\n'
        
        # Add variable definitions
        for key, value in variables.items():
            if isinstance(value, str):
                var_type = "string"
            elif isinstance(value, bool):
                var_type = "bool"
            elif isinstance(value, (int, float)):
                var_type = "number"
            elif isinstance(value, dict):
                var_type = "object({})"
            elif isinstance(value, list):
                var_type = "list(any)"
            else:
                var_type = "any"
            
            config += f'''
variable "{key}" {{
  type = {var_type}
}}
'''
        
        return config
    
    def _run_terraform_command(self, 
                             args: List[str], 
                             working_dir: str, 
                             timeout: int) -> Dict[str, Any]:
        """Run a terraform command and return the result."""
        try:
            cmd = [self.terraform_binary] + args
            result = subprocess.run(
                cmd,
                cwd=working_dir,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr,
                "return_code": result.returncode
            }
        
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "output": "",
                "error": f"Command timed out after {timeout} seconds",
                "return_code": -1
            }
        except Exception as e:
            return {
                "success": False,
                "output": "",
                "error": str(e),
                "return_code": -1
            }
    
    def _extract_resource_count(self, plan_output: str) -> int:
        """Extract the number of resources from terraform plan output."""
        # Look for "Plan: X to add, Y to change, Z to destroy"
        pattern = r"Plan: (\d+) to add"
        match = re.search(pattern, plan_output)
        
        if match:
            return int(match.group(1))
        
        # Fallback: count resource blocks in output
        resource_pattern = r"# module\.test_module\."
        matches = re.findall(resource_pattern, plan_output)
        return len(matches)
    
    def _extract_warnings(self, plan_output: str) -> List[str]:
        """Extract warnings from terraform plan output."""
        warnings = []
        
        # Look for warning patterns
        warning_patterns = [
            r"Warning: (.+)",
            r"│ Warning: (.+)",
        ]
        
        for pattern in warning_patterns:
            matches = re.findall(pattern, plan_output, re.MULTILINE)
            warnings.extend(matches)
        
        return warnings
    
    def _extract_errors(self, error_output: str) -> List[str]:
        """Extract errors from terraform plan error output."""
        errors = []
        
        # Split by lines and filter error messages
        lines = error_output.split('\n')
        for line in lines:
            line = line.strip()
            if line and not line.startswith('│'):
                errors.append(line)
        
        return errors


class AITestingFramework:
    """Main testing framework for AI-generated configurations."""
    
    def __init__(self, 
                 terraform_validator: Optional[TerraformValidator] = None,
                 cost_estimation_client = None):
        """Initialize the testing framework."""
        self.validator = terraform_validator or TerraformValidator()
        self.cost_client = cost_estimation_client
        self.logger = logging.getLogger(__name__)
        self.test_results: List[ValidationResult] = []
    
    def run_test_scenario(self, scenario: TestScenario) -> ValidationResult:
        """
        Run a single test scenario.
        
        Args:
            scenario: Test scenario to run
            
        Returns:
            Validation result
        """
        self.logger.info(f"Running test scenario: {scenario.name}")
        
        # Validate the configuration
        result = self.validator.validate_configuration(
            module_source=scenario.module_source,
            variables=scenario.variables,
            cloud_provider=scenario.cloud_provider,
            timeout=scenario.timeout_seconds
        )
        
        result.scenario_name = scenario.name
        
        # Validate against expected outcome
        self._validate_expected_outcome(result, scenario.expected_outcome)
        
        # Add cost estimation if available
        if self.cost_client:
            try:
                from .cost_estimation_client import CostEstimationRequest
                
                cost_request = CostEstimationRequest(
                    module_source=scenario.module_source,
                    configuration=scenario.variables,
                    cloud_provider=scenario.cloud_provider
                )
                
                cost_response = self.cost_client.estimate_cost(cost_request)
                result.cost_estimate = cost_response.total_cost
                
            except Exception as e:
                self.logger.warning(f"Cost estimation failed: {e}")
        
        self.test_results.append(result)
        return result
    
    def run_test_suite(self, scenarios: List[TestScenario]) -> List[ValidationResult]:
        """
        Run a suite of test scenarios.
        
        Args:
            scenarios: List of test scenarios
            
        Returns:
            List of validation results
        """
        results = []
        
        for scenario in scenarios:
            try:
                result = self.run_test_scenario(scenario)
                results.append(result)
                
                if result.success:
                    self.logger.info(f"✅ {scenario.name}: PASSED")
                else:
                    self.logger.error(f"❌ {scenario.name}: FAILED")
                    for error in result.validation_errors or []:
                        self.logger.error(f"   Error: {error}")
            
            except Exception as e:
                self.logger.error(f"❌ {scenario.name}: EXCEPTION - {e}")
                results.append(ValidationResult(
                    scenario_name=scenario.name,
                    success=False,
                    execution_time=0,
                    terraform_plan_success=False,
                    validation_errors=[f"Test framework exception: {str(e)}"]
                ))
        
        return results
    
    def load_scenarios_from_metadata(self, metadata_file: str) -> List[TestScenario]:
        """
        Load test scenarios from AI metadata file.
        
        Args:
            metadata_file: Path to ai-metadata.yaml file
            
        Returns:
            List of test scenarios
        """
        scenarios = []
        
        try:
            with open(metadata_file, 'r') as f:
                metadata = yaml.safe_load(f)
            
            module_source = f"kbrockhoff/{metadata['module_info']['name']}/terraform"
            
            for scenario_data in metadata.get('testing_scenarios', []):
                scenario = TestScenario(
                    name=scenario_data['name'],
                    description=scenario_data['description'],
                    module_source=module_source,
                    variables=scenario_data['variables'],
                    expected_outcome=scenario_data['expected_outcome'],
                    cloud_provider=scenario_data.get('cloud_provider', 'aws')
                )
                scenarios.append(scenario)
        
        except Exception as e:
            self.logger.error(f"Failed to load scenarios from {metadata_file}: {e}")
        
        return scenarios
    
    def generate_feedback_report(self, 
                               ai_agent_id: str,
                               module_source: str,
                               generated_configuration: Dict[str, Any],
                               results: List[ValidationResult]) -> FeedbackReport:
        """
        Generate a feedback report for AI code generation improvement.
        
        Args:
            ai_agent_id: Identifier for the AI agent
            module_source: Terraform module source
            generated_configuration: Configuration generated by AI
            results: Validation results
            
        Returns:
            Feedback report
        """
        # Calculate success rate
        successful_tests = sum(1 for r in results if r.success)
        success_rate = successful_tests / len(results) if results else 0
        
        # Collect common errors
        all_errors = []
        for result in results:
            if result.validation_errors:
                all_errors.extend(result.validation_errors)
        
        common_errors = self._find_common_patterns(all_errors)
        
        # Generate improvement suggestions
        improvement_suggestions = self._generate_improvement_suggestions(
            results, generated_configuration
        )
        
        # Calculate performance score
        performance_score = self._calculate_performance_score(results)
        
        return FeedbackReport(
            timestamp=datetime.now().isoformat(),
            ai_agent_id=ai_agent_id,
            module_source=module_source,
            generated_configuration=generated_configuration,
            validation_results=results,
            success_rate=success_rate,
            common_errors=common_errors,
            improvement_suggestions=improvement_suggestions,
            performance_score=performance_score
        )
    
    def _validate_expected_outcome(self, 
                                 result: ValidationResult, 
                                 expected: Dict[str, Any]) -> None:
        """Validate result against expected outcome."""
        if not result.validation_errors:
            result.validation_errors = []
        
        # Check expected success
        expected_success = expected.get('success', True)
        if result.terraform_plan_success != expected_success:
            if expected_success:
                result.validation_errors.append(
                    f"Expected successful plan but got failure"
                )
            else:
                result.validation_errors.append(
                    f"Expected plan failure but got success"
                )
        
        # Check expected resource count
        expected_resources = expected.get('resource_count')
        if expected_resources and result.resource_count:
            if result.resource_count != expected_resources:
                result.validation_errors.append(
                    f"Expected {expected_resources} resources but got {result.resource_count}"
                )
        
        # Check validation checks
        expected_checks = expected.get('validation_checks', [])
        # This would require more sophisticated plan parsing to validate specific checks
        # For now, we'll just log them as informational
        if expected_checks:
            self.logger.info(f"Expected validation checks: {expected_checks}")
        
        # Update overall success based on validation
        if result.validation_errors:
            result.success = False
    
    def _find_common_patterns(self, errors: List[str]) -> List[str]:
        """Find common error patterns."""
        if not errors:
            return []
        
        # Group similar errors
        error_patterns = {}
        
        for error in errors:
            # Normalize error message
            normalized = re.sub(r'"[^"]*"', '""', error)  # Replace quoted strings
            normalized = re.sub(r'\d+', 'N', normalized)  # Replace numbers
            
            if normalized in error_patterns:
                error_patterns[normalized] += 1
            else:
                error_patterns[normalized] = 1
        
        # Return patterns that occur more than once
        common_patterns = [
            pattern for pattern, count in error_patterns.items() 
            if count > 1
        ]
        
        return common_patterns[:5]  # Top 5 most common
    
    def _generate_improvement_suggestions(self, 
                                        results: List[ValidationResult],
                                        configuration: Dict[str, Any]) -> List[str]:
        """Generate suggestions for improving AI code generation."""
        suggestions = []
        
        # Analyze common failure patterns
        failed_results = [r for r in results if not r.success]
        
        if failed_results:
            # Check for validation errors
            all_errors = []
            for result in failed_results:
                if result.validation_errors:
                    all_errors.extend(result.validation_errors)
            
            # Common suggestions based on error patterns
            error_text = ' '.join(all_errors).lower()
            
            if 'required' in error_text and 'missing' in error_text:
                suggestions.append(
                    "Ensure all required variables are provided in the configuration"
                )
            
            if 'invalid' in error_text or 'validation' in error_text:
                suggestions.append(
                    "Review variable validation rules and ensure values meet constraints"
                )
            
            if 'dependency' in error_text or 'reference' in error_text:
                suggestions.append(
                    "Check module dependencies and ensure required resources exist"
                )
            
            if 'provider' in error_text:
                suggestions.append(
                    "Verify cloud provider configuration and credentials"
                )
        
        # Performance suggestions
        avg_execution_time = sum(r.execution_time for r in results) / len(results)
        if avg_execution_time > 60:  # More than 1 minute
            suggestions.append(
                "Consider simplifying configuration to reduce validation time"
            )
        
        # Cost suggestions
        if any(r.cost_estimate and r.cost_estimate > 1000 for r in results):
            suggestions.append(
                "Review configuration for cost optimization opportunities"
            )
        
        return suggestions
    
    def _calculate_performance_score(self, results: List[ValidationResult]) -> float:
        """Calculate overall performance score (0-100)."""
        if not results:
            return 0.0
        
        # Base score from success rate
        success_rate = sum(1 for r in results if r.success) / len(results)
        base_score = success_rate * 70  # 70% weight for success
        
        # Performance bonus (faster is better)
        avg_time = sum(r.execution_time for r in results) / len(results)
        time_score = max(0, 30 - (avg_time / 10))  # 30% weight for speed
        
        return min(100, base_score + time_score)


class AITestRunner:
    """Command-line test runner for AI testing framework."""
    
    def __init__(self):
        """Initialize the test runner."""
        self.framework = AITestingFramework()
        self.logger = logging.getLogger(__name__)
    
    def run_from_metadata(self, metadata_file: str) -> Dict[str, Any]:
        """Run tests from AI metadata file."""
        scenarios = self.framework.load_scenarios_from_metadata(metadata_file)
        
        if not scenarios:
            return {
                "success": False,
                "error": "No test scenarios found in metadata file"
            }
        
        results = self.framework.run_test_suite(scenarios)
        
        # Generate summary
        total_tests = len(results)
        passed_tests = sum(1 for r in results if r.success)
        
        return {
            "success": passed_tests == total_tests,
            "total_tests": total_tests,
            "passed_tests": passed_tests,
            "failed_tests": total_tests - passed_tests,
            "results": [asdict(r) for r in results]
        }
    
    def run_single_test(self, 
                       module_source: str,
                       variables: Dict[str, Any],
                       cloud_provider: str = "aws") -> Dict[str, Any]:
        """Run a single test with provided configuration."""
        scenario = TestScenario(
            name="single_test",
            description="Single test run",
            module_source=module_source,
            variables=variables,
            expected_outcome={"success": True},
            cloud_provider=cloud_provider
        )
        
        result = self.framework.run_test_scenario(scenario)
        
        return {
            "success": result.success,
            "result": asdict(result)
        }


def main():
    """Main function for command-line usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description="AI Testing Framework")
    parser.add_argument("--metadata", help="AI metadata file to test")
    parser.add_argument("--module", help="Module source for single test")
    parser.add_argument("--variables", help="Variables JSON for single test")
    parser.add_argument("--cloud-provider", default="aws", 
                       choices=["aws", "azure", "gcp"],
                       help="Cloud provider for testing")
    parser.add_argument("--output", help="Output file for results")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Verbose logging")
    
    args = parser.parse_args()
    
    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')
    
    runner = AITestRunner()
    
    try:
        if args.metadata:
            # Run tests from metadata file
            results = runner.run_from_metadata(args.metadata)
        elif args.module and args.variables:
            # Run single test
            variables = json.loads(args.variables)
            results = runner.run_single_test(
                args.module, variables, args.cloud_provider
            )
        else:
            print("Error: Must provide either --metadata or --module with --variables")
            return 1
        
        # Output results
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"Results written to {args.output}")
        else:
            print(json.dumps(results, indent=2))
        
        return 0 if results["success"] else 1
        
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main())