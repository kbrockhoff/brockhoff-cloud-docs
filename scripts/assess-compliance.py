#!/usr/bin/env python3
"""
Compliance Assessment Script

This script assesses Terraform module compliance against well-architected frameworks
and generates detailed compliance reports with evidence and recommendations.
"""

import json
import yaml
import argparse
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import re


class ComplianceAssessor:
    """Main class for assessing compliance against well-architected frameworks."""
    
    def __init__(self, framework_path: str, resources_data: Dict[str, Any]):
        """Initialize the compliance assessor.
        
        Args:
            framework_path: Path to the framework YAML file
            resources_data: Terraform resources data from plan or state
        """
        self.framework_path = framework_path
        self.resources_data = resources_data
        self.framework_config = self._load_framework_config()
        self.assessment_results = {}
        
    def _load_framework_config(self) -> Dict[str, Any]:
        """Load the framework configuration from YAML file."""
        try:
            with open(self.framework_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Framework file not found: {self.framework_path}")
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML in framework file: {e}")
    
    def assess_compliance(self) -> Dict[str, Any]:
        """Perform complete compliance assessment."""
        print(f"Assessing compliance against {self.framework_config['framework']['name']}")
        
        # Collect evidence for all controls
        evidence = self._collect_evidence()
        
        # Validate controls
        validation_results = self._validate_controls(evidence)
        
        # Calculate scores
        scores = self._calculate_scores(validation_results)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(validation_results, evidence)
        
        # Compile final report
        report = {
            "framework": {
                "name": self.framework_config['framework']['name'],
                "version": self.framework_config['framework']['version'],
                "url": self.framework_config['framework']['url']
            },
            "assessment": {
                "date": datetime.utcnow().isoformat() + "Z",
                "assessor": "automated-compliance-system",
                "module_metadata": self._extract_module_metadata()
            },
            "scores": scores,
            "evidence": evidence,
            "validation_results": validation_results,
            "recommendations": recommendations,
            "compliance_status": self._determine_compliance_status(scores)
        }
        
        return report
    
    def _collect_evidence(self) -> Dict[str, Dict[str, Any]]:
        """Collect evidence for all controls from Terraform resources."""
        evidence = {}
        
        for pillar_name, pillar in self.framework_config['pillars'].items():
            evidence[pillar_name] = {}
            
            for control in pillar['controls']:
                control_id = control['id']
                evidence[pillar_name][control_id] = {
                    "title": control['title'],
                    "implementation": control['implementation'],
                    "evidence_fields": {},
                    "found_resources": []
                }
                
                # Collect evidence from specified fields
                for field in control.get('evidence_fields', []):
                    field_evidence = self._extract_field_evidence(field)
                    evidence[pillar_name][control_id]["evidence_fields"][field] = field_evidence
                    
                    if field_evidence.get('found'):
                        evidence[pillar_name][control_id]["found_resources"].extend(
                            field_evidence.get('resources', [])
                        )
        
        return evidence
    
    def _extract_field_evidence(self, field_path: str) -> Dict[str, Any]:
        """Extract evidence for a specific field from Terraform resources."""
        evidence = {
            "field": field_path,
            "found": False,
            "resources": [],
            "values": []
        }
        
        # Handle different field path patterns
        if field_path.startswith('module.'):
            # Module output reference
            evidence.update(self._find_module_output(field_path))
        elif field_path.startswith('local.'):
            # Local value reference
            evidence.update(self._find_local_value(field_path))
        elif field_path.startswith('data.'):
            # Data source reference
            evidence.update(self._find_data_source(field_path))
        else:
            # Resource attribute reference
            evidence.update(self._find_resource_attribute(field_path))
        
        return evidence
    
    def _find_resource_attribute(self, field_path: str) -> Dict[str, Any]:
        """Find evidence in resource attributes."""
        evidence = {"found": False, "resources": [], "values": []}
        
        # Parse field path (e.g., "aws_s3_bucket.main.server_side_encryption_configuration")
        parts = field_path.split('.')
        if len(parts) < 2:
            return evidence
        
        resource_type = parts[0]
        resource_name = parts[1]
        attribute_path = '.'.join(parts[2:]) if len(parts) > 2 else None
        
        # Search in planned values
        if 'root_module' in self.resources_data:
            resources = self.resources_data['root_module'].get('resources', [])
            for resource in resources:
                if (resource.get('type') == resource_type and 
                    resource.get('name') == resource_name):
                    
                    evidence["found"] = True
                    evidence["resources"].append({
                        "address": resource.get('address'),
                        "type": resource.get('type'),
                        "name": resource.get('name')
                    })
                    
                    if attribute_path:
                        value = self._get_nested_value(resource.get('values', {}), attribute_path)
                        if value is not None:
                            evidence["values"].append(value)
                    else:
                        evidence["values"].append(resource.get('values', {}))
        
        return evidence
    
    def _find_module_output(self, field_path: str) -> Dict[str, Any]:
        """Find evidence in module outputs."""
        evidence = {"found": False, "resources": [], "values": []}
        
        # Parse module output path (e.g., "module.pricing.monthly_cost_estimate")
        parts = field_path.split('.')
        if len(parts) < 3 or parts[0] != 'module':
            return evidence
        
        module_name = parts[1]
        output_name = parts[2]
        
        # Search in child modules
        if 'root_module' in self.resources_data:
            child_modules = self.resources_data['root_module'].get('child_modules', [])
            for module in child_modules:
                if module.get('address') == f'module.{module_name}':
                    outputs = module.get('outputs', {})
                    if output_name in outputs:
                        evidence["found"] = True
                        evidence["values"].append(outputs[output_name].get('value'))
        
        return evidence
    
    def _find_local_value(self, field_path: str) -> Dict[str, Any]:
        """Find evidence in local values."""
        evidence = {"found": False, "resources": [], "values": []}
        
        # Local values are typically not available in terraform plan JSON
        # This would need to be enhanced to parse .tf files or use terraform show
        # For now, we'll mark as not found but could be extended
        
        return evidence
    
    def _find_data_source(self, field_path: str) -> Dict[str, Any]:
        """Find evidence in data sources."""
        evidence = {"found": False, "resources": [], "values": []}
        
        # Parse data source path (e.g., "data.aws_caller_identity.current.account_id")
        parts = field_path.split('.')
        if len(parts) < 3 or parts[0] != 'data':
            return evidence
        
        data_type = parts[1]
        data_name = parts[2]
        attribute_path = '.'.join(parts[3:]) if len(parts) > 3 else None
        
        # Search in planned values
        if 'root_module' in self.resources_data:
            resources = self.resources_data['root_module'].get('resources', [])
            for resource in resources:
                if (resource.get('type') == data_type and 
                    resource.get('name') == data_name and
                    resource.get('mode') == 'data'):
                    
                    evidence["found"] = True
                    evidence["resources"].append({
                        "address": resource.get('address'),
                        "type": resource.get('type'),
                        "name": resource.get('name')
                    })
                    
                    if attribute_path:
                        value = self._get_nested_value(resource.get('values', {}), attribute_path)
                        if value is not None:
                            evidence["values"].append(value)
                    else:
                        evidence["values"].append(resource.get('values', {}))
        
        return evidence
    
    def _get_nested_value(self, data: Dict[str, Any], path: str) -> Any:
        """Get nested value from dictionary using dot notation."""
        keys = path.split('.')
        current = data
        
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            elif isinstance(current, list) and key.isdigit():
                index = int(key)
                if 0 <= index < len(current):
                    current = current[index]
                else:
                    return None
            else:
                return None
        
        return current
    
    def _validate_controls(self, evidence: Dict[str, Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
        """Validate controls based on evidence and validation checks."""
        validation_results = {}
        
        for pillar_name, pillar in self.framework_config['pillars'].items():
            validation_results[pillar_name] = {}
            
            for control in pillar['controls']:
                control_id = control['id']
                control_evidence = evidence[pillar_name][control_id]
                
                # Basic validation: check if evidence was found
                has_evidence = len(control_evidence['found_resources']) > 0
                
                # Advanced validation: run validation checks
                validation_checks = control.get('validation_checks', [])
                passed_checks = []
                failed_checks = []
                
                for check in validation_checks:
                    # Simple validation logic - can be extended
                    if self._evaluate_validation_check(check, control_evidence):
                        passed_checks.append(check)
                    else:
                        failed_checks.append(check)
                
                validation_results[pillar_name][control_id] = {
                    "has_evidence": has_evidence,
                    "passed_checks": passed_checks,
                    "failed_checks": failed_checks,
                    "compliance_score": self._calculate_control_score(
                        has_evidence, len(passed_checks), len(validation_checks)
                    )
                }
        
        return validation_results
    
    def _evaluate_validation_check(self, check: str, evidence: Dict[str, Any]) -> bool:
        """Evaluate a single validation check against evidence."""
        # Simple heuristic-based validation
        # This could be enhanced with more sophisticated rule evaluation
        
        # Check if evidence exists for the control
        if not evidence['found_resources']:
            return False
        
        # Check for common patterns
        if 'enabled' in check.lower():
            # Look for enabled/true values in evidence
            for value in evidence['evidence_fields'].values():
                if isinstance(value.get('values'), list):
                    for v in value['values']:
                        if isinstance(v, dict) and any(
                            str(val).lower() in ['true', 'enabled', 'yes'] 
                            for val in v.values() if isinstance(val, (str, bool))
                        ):
                            return True
        
        if 'configured' in check.lower():
            # Check if resources are configured (non-empty values)
            return len(evidence['found_resources']) > 0
        
        # Default to true if evidence exists
        return len(evidence['found_resources']) > 0
    
    def _calculate_control_score(self, has_evidence: bool, passed_checks: int, total_checks: int) -> float:
        """Calculate compliance score for a single control."""
        if total_checks == 0:
            return 1.0 if has_evidence else 0.0
        
        evidence_score = 0.3 if has_evidence else 0.0
        checks_score = (passed_checks / total_checks) * 0.7
        
        return evidence_score + checks_score
    
    def _calculate_scores(self, validation_results: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate overall and per-pillar compliance scores."""
        pillar_scores = {}
        
        for pillar_name, pillar_results in validation_results.items():
            if not pillar_results:
                pillar_scores[pillar_name] = 0.0
                continue
            
            control_scores = [
                result['compliance_score'] 
                for result in pillar_results.values()
            ]
            pillar_scores[pillar_name] = sum(control_scores) / len(control_scores)
        
        # Calculate weighted overall score
        assessment_config = self.framework_config.get('assessment', {})
        weights = assessment_config.get('scoring', {}).get('weights', {})
        
        if weights:
            weighted_score = sum(
                pillar_scores.get(pillar, 0.0) * weight
                for pillar, weight in weights.items()
            )
        else:
            # Equal weighting if no weights specified
            weighted_score = sum(pillar_scores.values()) / len(pillar_scores) if pillar_scores else 0.0
        
        return {
            "overall_score": weighted_score,
            "pillar_scores": pillar_scores,
            "control_count": sum(len(results) for results in validation_results.values()),
            "passed_controls": sum(
                1 for pillar_results in validation_results.values()
                for result in pillar_results.values()
                if result['compliance_score'] >= 0.8
            )
        }
    
    def _generate_recommendations(self, validation_results: Dict[str, Dict[str, Any]], 
                                evidence: Dict[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate recommendations based on validation results."""
        recommendations = []
        
        for pillar_name, pillar_results in validation_results.items():
            for control_id, result in pillar_results.items():
                if result['compliance_score'] < 0.8:  # Threshold for recommendations
                    control_info = self._get_control_info(pillar_name, control_id)
                    
                    recommendation = {
                        "pillar": pillar_name,
                        "control_id": control_id,
                        "control_title": control_info.get('title', 'Unknown'),
                        "current_score": result['compliance_score'],
                        "issue": self._diagnose_issue(result, evidence[pillar_name][control_id]),
                        "remediation": self._suggest_remediation(pillar_name, control_id, result),
                        "priority": self._calculate_priority(result['compliance_score'], pillar_name)
                    }
                    
                    recommendations.append(recommendation)
        
        # Sort by priority (high to low)
        recommendations.sort(key=lambda x: x['priority'], reverse=True)
        
        return recommendations
    
    def _get_control_info(self, pillar_name: str, control_id: str) -> Dict[str, Any]:
        """Get control information from framework config."""
        pillar = self.framework_config['pillars'].get(pillar_name, {})
        for control in pillar.get('controls', []):
            if control['id'] == control_id:
                return control
        return {}
    
    def _diagnose_issue(self, result: Dict[str, Any], evidence: Dict[str, Any]) -> str:
        """Diagnose the main issue with a failing control."""
        if not result['has_evidence']:
            return "No evidence found - control may not be implemented"
        elif result['failed_checks']:
            return f"Validation checks failed: {', '.join(result['failed_checks'][:2])}"
        else:
            return "Partial implementation detected"
    
    def _suggest_remediation(self, pillar_name: str, control_id: str, result: Dict[str, Any]) -> str:
        """Suggest remediation steps for a failing control."""
        control_info = self._get_control_info(pillar_name, control_id)
        
        if not result['has_evidence']:
            return f"Implement {control_info.get('implementation', 'the required control')}"
        elif result['failed_checks']:
            return f"Review and fix validation issues: {', '.join(result['failed_checks'][:2])}"
        else:
            return "Complete the implementation and ensure all requirements are met"
    
    def _calculate_priority(self, score: float, pillar_name: str) -> int:
        """Calculate priority for recommendations (1-10 scale)."""
        # Security issues get higher priority
        pillar_priority = {
            'security': 10,
            'reliability': 8,
            'operational_excellence': 6,
            'performance_efficiency': 4,
            'cost_optimization': 2
        }
        
        base_priority = pillar_priority.get(pillar_name, 5)
        score_factor = (1.0 - score) * 5  # 0-5 based on how low the score is
        
        return min(10, int(base_priority + score_factor))
    
    def _determine_compliance_status(self, scores: Dict[str, Any]) -> Dict[str, Any]:
        """Determine overall compliance status."""
        overall_score = scores['overall_score']
        assessment_config = self.framework_config.get('assessment', {})
        thresholds = assessment_config.get('thresholds', {})
        
        # Determine environment (could be passed as parameter)
        environment = 'production'  # Default assumption
        threshold_config = thresholds.get(environment, {})
        minimum_score = threshold_config.get('minimum_score', 0.8)
        required_controls = threshold_config.get('required_controls', [])
        
        status = {
            "compliant": overall_score >= minimum_score,
            "overall_score": overall_score,
            "minimum_required": minimum_score,
            "environment": environment,
            "required_controls_met": True,  # Would need to check specific controls
            "certification_ready": overall_score >= 0.9
        }
        
        return status
    
    def _extract_module_metadata(self) -> Dict[str, Any]:
        """Extract module metadata from Terraform resources."""
        metadata = {
            "terraform_version": "unknown",
            "provider_versions": {},
            "resource_count": 0,
            "module_count": 0
        }
        
        if 'terraform_version' in self.resources_data:
            metadata['terraform_version'] = self.resources_data['terraform_version']
        
        if 'root_module' in self.resources_data:
            root_module = self.resources_data['root_module']
            metadata['resource_count'] = len(root_module.get('resources', []))
            metadata['module_count'] = len(root_module.get('child_modules', []))
        
        return metadata


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description='Assess Terraform module compliance')
    parser.add_argument('--framework', required=True, 
                       help='Path to framework YAML file')
    parser.add_argument('--resources', required=True,
                       help='Path to Terraform resources JSON file')
    parser.add_argument('--output', default='compliance-report.json',
                       help='Output file for compliance report')
    parser.add_argument('--format', choices=['json', 'yaml'], default='json',
                       help='Output format')
    parser.add_argument('--verbose', action='store_true',
                       help='Enable verbose output')
    
    args = parser.parse_args()
    
    try:
        # Load resources data
        with open(args.resources, 'r') as f:
            resources_data = json.load(f)
        
        # Create assessor and run assessment
        assessor = ComplianceAssessor(args.framework, resources_data)
        report = assessor.assess_compliance()
        
        # Output report
        with open(args.output, 'w') as f:
            if args.format == 'yaml':
                yaml.dump(report, f, default_flow_style=False, indent=2)
            else:
                json.dump(report, f, indent=2, default=str)
        
        # Print summary
        scores = report['scores']
        print(f"\nCompliance Assessment Complete")
        print(f"Overall Score: {scores['overall_score']:.2%}")
        print(f"Compliant: {'Yes' if report['compliance_status']['compliant'] else 'No'}")
        print(f"Report saved to: {args.output}")
        
        if args.verbose:
            print(f"\nPillar Scores:")
            for pillar, score in scores['pillar_scores'].items():
                print(f"  {pillar}: {score:.2%}")
        
        # Exit with error code if not compliant
        if not report['compliance_status']['compliant']:
            sys.exit(1)
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()