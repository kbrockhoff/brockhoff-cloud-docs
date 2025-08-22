#!/usr/bin/env python3
"""
Governance Metadata Collection Script

This script collects governance and audit metadata from Terraform modules
and infrastructure deployments for compliance reporting and tracking.
"""

import json
import yaml
import argparse
import sys
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any, Optional
import subprocess
import re


class GovernanceMetadataCollector:
    """Collects governance metadata from Terraform modules and deployments."""
    
    def __init__(self, workspace_path: str = "."):
        """Initialize the governance metadata collector.
        
        Args:
            workspace_path: Path to the Terraform workspace
        """
        self.workspace_path = Path(workspace_path)
        self.metadata = {}
        
    def collect_all_metadata(self) -> Dict[str, Any]:
        """Collect all governance metadata."""
        print("Collecting governance metadata...")
        
        # Basic module information
        self.metadata.update(self._collect_module_info())
        
        # Terraform configuration metadata
        self.metadata.update(self._collect_terraform_metadata())
        
        # Resource inventory
        self.metadata.update(self._collect_resource_inventory())
        
        # Cost allocation metadata
        self.metadata.update(self._collect_cost_metadata())
        
        # Security and compliance metadata
        self.metadata.update(self._collect_security_metadata())
        
        # Deployment and lifecycle metadata
        self.metadata.update(self._collect_deployment_metadata())
        
        # Governance tags and labels
        self.metadata.update(self._collect_governance_tags())
        
        return self.metadata
    
    def _collect_module_info(self) -> Dict[str, Any]:
        """Collect basic module information."""
        module_info = {
            "module": {
                "name": self._extract_module_name(),
                "version": self._extract_module_version(),
                "description": self._extract_module_description(),
                "source": self._extract_module_source(),
                "license": self._extract_license_info(),
                "maintainers": self._extract_maintainers(),
                "repository": self._extract_repository_info()
            }
        }
        
        return module_info
    
    def _collect_terraform_metadata(self) -> Dict[str, Any]:
        """Collect Terraform configuration metadata."""
        terraform_metadata = {
            "terraform": {
                "version": self._get_terraform_version(),
                "required_version": self._get_required_terraform_version(),
                "providers": self._get_provider_requirements(),
                "backend": self._get_backend_configuration(),
                "workspace": self._get_current_workspace(),
                "state_location": self._get_state_location()
            }
        }
        
        return terraform_metadata
    
    def _collect_resource_inventory(self) -> Dict[str, Any]:
        """Collect resource inventory and classification."""
        try:
            # Get current state
            state_data = self._get_terraform_state()
            
            resources = []
            resource_counts = {}
            
            if state_data and 'values' in state_data:
                root_module = state_data['values'].get('root_module', {})
                
                # Process resources
                for resource in root_module.get('resources', []):
                    resource_type = resource.get('type', 'unknown')
                    resource_name = resource.get('name', 'unknown')
                    
                    # Count resources by type
                    resource_counts[resource_type] = resource_counts.get(resource_type, 0) + 1
                    
                    # Collect resource metadata
                    resource_metadata = {
                        "address": resource.get('address'),
                        "type": resource_type,
                        "name": resource_name,
                        "provider": resource.get('provider_name'),
                        "mode": resource.get('mode', 'managed'),
                        "classification": self._classify_resource(resource_type),
                        "tags": self._extract_resource_tags(resource),
                        "cost_center": self._extract_cost_center(resource),
                        "data_classification": self._classify_data_sensitivity(resource)
                    }
                    
                    resources.append(resource_metadata)
                
                # Process child modules
                for child_module in root_module.get('child_modules', []):
                    module_resources = self._process_child_module_resources(child_module)
                    resources.extend(module_resources)
            
            inventory = {
                "resource_inventory": {
                    "total_resources": len(resources),
                    "resource_counts": resource_counts,
                    "resources": resources,
                    "last_updated": datetime.now(timezone.utc).isoformat()
                }
            }
            
            return inventory
            
        except Exception as e:
            print(f"Warning: Could not collect resource inventory: {e}")
            return {"resource_inventory": {"error": str(e)}}
    
    def _collect_cost_metadata(self) -> Dict[str, Any]:
        """Collect cost allocation and budgeting metadata."""
        cost_metadata = {
            "cost_management": {
                "cost_center": self._extract_default_cost_center(),
                "budget_owner": self._extract_budget_owner(),
                "cost_allocation_tags": self._get_cost_allocation_tags(),
                "billing_account": self._extract_billing_account(),
                "cost_optimization": {
                    "rightsizing_enabled": self._check_rightsizing_config(),
                    "scheduled_scaling": self._check_scheduled_scaling(),
                    "reserved_instances": self._check_reserved_instances()
                }
            }
        }
        
        return cost_metadata
    
    def _collect_security_metadata(self) -> Dict[str, Any]:
        """Collect security and compliance metadata."""
        security_metadata = {
            "security": {
                "data_classification": self._get_data_classification(),
                "encryption_at_rest": self._check_encryption_at_rest(),
                "encryption_in_transit": self._check_encryption_in_transit(),
                "access_controls": self._analyze_access_controls(),
                "network_security": self._analyze_network_security(),
                "compliance_frameworks": self._get_compliance_frameworks(),
                "security_scanning": {
                    "enabled": self._check_security_scanning(),
                    "last_scan": self._get_last_security_scan()
                }
            }
        }
        
        return security_metadata
    
    def _collect_deployment_metadata(self) -> Dict[str, Any]:
        """Collect deployment and lifecycle metadata."""
        deployment_metadata = {
            "deployment": {
                "environment": self._get_environment_type(),
                "deployment_method": "terraform",
                "ci_cd_pipeline": self._detect_cicd_pipeline(),
                "last_deployment": self._get_last_deployment_time(),
                "deployment_frequency": self._calculate_deployment_frequency(),
                "rollback_capability": self._check_rollback_capability(),
                "disaster_recovery": {
                    "enabled": self._check_dr_enabled(),
                    "rto_hours": self._get_rto_requirement(),
                    "rpo_hours": self._get_rpo_requirement(),
                    "backup_strategy": self._get_backup_strategy()
                }
            }
        }
        
        return deployment_metadata
    
    def _collect_governance_tags(self) -> Dict[str, Any]:
        """Collect governance tags and labels."""
        governance_tags = {
            "governance": {
                "tags": self._get_standard_governance_tags(),
                "labels": self._get_governance_labels(),
                "policies": self._get_applied_policies(),
                "compliance_status": self._get_compliance_status(),
                "audit_trail": {
                    "enabled": self._check_audit_trail(),
                    "retention_days": self._get_audit_retention(),
                    "log_location": self._get_audit_log_location()
                }
            }
        }
        
        return governance_tags
    
    # Helper methods for extracting specific metadata
    
    def _extract_module_name(self) -> str:
        """Extract module name from various sources."""
        # Try to get from terraform.tf or main.tf
        for tf_file in ['terraform.tf', 'main.tf', 'versions.tf']:
            file_path = self.workspace_path / tf_file
            if file_path.exists():
                content = file_path.read_text()
                # Look for module name in comments or locals
                name_match = re.search(r'#\s*Module:\s*([^\n]+)', content)
                if name_match:
                    return name_match.group(1).strip()
        
        # Fallback to directory name
        return self.workspace_path.name
    
    def _extract_module_version(self) -> str:
        """Extract module version."""
        # Try to get from VERSION file
        version_file = self.workspace_path / 'VERSION'
        if version_file.exists():
            return version_file.read_text().strip()
        
        # Try to get from git tags
        try:
            result = subprocess.run(
                ['git', 'describe', '--tags', '--abbrev=0'],
                cwd=self.workspace_path,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        
        return "unknown"
    
    def _get_terraform_version(self) -> str:
        """Get Terraform version."""
        try:
            result = subprocess.run(
                ['terraform', 'version', '-json'],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                version_data = json.loads(result.stdout)
                return version_data.get('terraform_version', 'unknown')
        except:
            pass
        
        return "unknown"
    
    def _get_terraform_state(self) -> Optional[Dict[str, Any]]:
        """Get Terraform state data."""
        try:
            result = subprocess.run(
                ['terraform', 'show', '-json'],
                cwd=self.workspace_path,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return json.loads(result.stdout)
        except Exception as e:
            print(f"Warning: Could not get Terraform state: {e}")
        
        return None
    
    def _classify_resource(self, resource_type: str) -> str:
        """Classify resource by type."""
        compute_resources = ['aws_instance', 'aws_ecs_service', 'aws_lambda_function', 
                           'azurerm_virtual_machine', 'google_compute_instance']
        storage_resources = ['aws_s3_bucket', 'aws_ebs_volume', 'azurerm_storage_account',
                           'google_storage_bucket']
        network_resources = ['aws_vpc', 'aws_subnet', 'aws_security_group',
                           'azurerm_virtual_network', 'google_compute_network']
        database_resources = ['aws_db_instance', 'aws_dynamodb_table',
                            'azurerm_sql_database', 'google_sql_database_instance']
        
        if resource_type in compute_resources:
            return "compute"
        elif resource_type in storage_resources:
            return "storage"
        elif resource_type in network_resources:
            return "network"
        elif resource_type in database_resources:
            return "database"
        else:
            return "other"
    
    def _get_standard_governance_tags(self) -> Dict[str, str]:
        """Get standard governance tags."""
        return {
            "Environment": self._get_environment_type(),
            "Owner": self._extract_owner(),
            "CostCenter": self._extract_default_cost_center(),
            "Project": self._extract_project_name(),
            "ManagedBy": "terraform",
            "LastUpdated": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "ComplianceRequired": self._check_compliance_required(),
            "DataClassification": self._get_data_classification(),
            "BackupRequired": str(self._check_backup_required()),
            "MonitoringEnabled": str(self._check_monitoring_enabled())
        }
    
    def _get_environment_type(self) -> str:
        """Determine environment type."""
        # Try to get from terraform workspace
        try:
            result = subprocess.run(
                ['terraform', 'workspace', 'show'],
                cwd=self.workspace_path,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                workspace = result.stdout.strip()
                if 'prod' in workspace.lower():
                    return "Production"
                elif 'staging' in workspace.lower() or 'uat' in workspace.lower():
                    return "UAT"
                elif 'test' in workspace.lower():
                    return "Testing"
                elif 'dev' in workspace.lower():
                    return "Development"
        except:
            pass
        
        return "Development"  # Default
    
    # Placeholder methods for various checks (to be implemented based on specific requirements)
    
    def _extract_module_description(self) -> str:
        return "Terraform module"
    
    def _extract_module_source(self) -> str:
        return "local"
    
    def _extract_license_info(self) -> str:
        license_file = self.workspace_path / 'LICENSE'
        if license_file.exists():
            content = license_file.read_text()
            if 'Apache' in content:
                return "Apache-2.0"
            elif 'MIT' in content:
                return "MIT"
        return "unknown"
    
    def _extract_maintainers(self) -> List[str]:
        return ["terraform-team"]
    
    def _extract_repository_info(self) -> Dict[str, str]:
        return {"type": "git", "url": "unknown"}
    
    def _get_required_terraform_version(self) -> str:
        return ">= 1.0"
    
    def _get_provider_requirements(self) -> Dict[str, str]:
        return {}
    
    def _get_backend_configuration(self) -> Dict[str, Any]:
        return {"type": "local"}
    
    def _get_current_workspace(self) -> str:
        return "default"
    
    def _get_state_location(self) -> str:
        return "local"
    
    def _process_child_module_resources(self, child_module: Dict[str, Any]) -> List[Dict[str, Any]]:
        return []
    
    def _extract_resource_tags(self, resource: Dict[str, Any]) -> Dict[str, str]:
        return {}
    
    def _extract_cost_center(self, resource: Dict[str, Any]) -> str:
        return "default"
    
    def _classify_data_sensitivity(self, resource: Dict[str, Any]) -> str:
        return "internal"
    
    def _extract_default_cost_center(self) -> str:
        return "platform"
    
    def _extract_budget_owner(self) -> str:
        return "platform-team"
    
    def _get_cost_allocation_tags(self) -> List[str]:
        return ["Environment", "Owner", "CostCenter", "Project"]
    
    def _extract_billing_account(self) -> str:
        return "default"
    
    def _check_rightsizing_config(self) -> bool:
        return False
    
    def _check_scheduled_scaling(self) -> bool:
        return False
    
    def _check_reserved_instances(self) -> bool:
        return False
    
    def _get_data_classification(self) -> str:
        return "internal"
    
    def _check_encryption_at_rest(self) -> bool:
        return True
    
    def _check_encryption_in_transit(self) -> bool:
        return True
    
    def _analyze_access_controls(self) -> Dict[str, Any]:
        return {"iam_enabled": True, "rbac_enabled": True}
    
    def _analyze_network_security(self) -> Dict[str, Any]:
        return {"firewall_enabled": True, "vpc_enabled": True}
    
    def _get_compliance_frameworks(self) -> List[str]:
        return ["aws-waf"]
    
    def _check_security_scanning(self) -> bool:
        return False
    
    def _get_last_security_scan(self) -> Optional[str]:
        return None
    
    def _detect_cicd_pipeline(self) -> str:
        if (self.workspace_path / '.github' / 'workflows').exists():
            return "github-actions"
        elif (self.workspace_path / '.gitlab-ci.yml').exists():
            return "gitlab-ci"
        return "manual"
    
    def _get_last_deployment_time(self) -> Optional[str]:
        return None
    
    def _calculate_deployment_frequency(self) -> str:
        return "unknown"
    
    def _check_rollback_capability(self) -> bool:
        return True
    
    def _check_dr_enabled(self) -> bool:
        return False
    
    def _get_rto_requirement(self) -> Optional[int]:
        return None
    
    def _get_rpo_requirement(self) -> Optional[int]:
        return None
    
    def _get_backup_strategy(self) -> str:
        return "none"
    
    def _get_governance_labels(self) -> Dict[str, str]:
        return {}
    
    def _get_applied_policies(self) -> List[str]:
        return []
    
    def _get_compliance_status(self) -> str:
        return "unknown"
    
    def _check_audit_trail(self) -> bool:
        return False
    
    def _get_audit_retention(self) -> int:
        return 90
    
    def _get_audit_log_location(self) -> str:
        return "none"
    
    def _extract_owner(self) -> str:
        return "platform-team"
    
    def _extract_project_name(self) -> str:
        return self._extract_module_name()
    
    def _check_compliance_required(self) -> str:
        env = self._get_environment_type()
        return "true" if env in ["Production", "MissionCritical"] else "false"
    
    def _check_backup_required(self) -> bool:
        return True
    
    def _check_monitoring_enabled(self) -> bool:
        return True


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description='Collect governance metadata from Terraform modules')
    parser.add_argument('--workspace', default='.',
                       help='Path to Terraform workspace')
    parser.add_argument('--output', default='governance-metadata.json',
                       help='Output file for governance metadata')
    parser.add_argument('--format', choices=['json', 'yaml'], default='json',
                       help='Output format')
    parser.add_argument('--verbose', action='store_true',
                       help='Enable verbose output')
    
    args = parser.parse_args()
    
    try:
        # Create collector and collect metadata
        collector = GovernanceMetadataCollector(args.workspace)
        metadata = collector.collect_all_metadata()
        
        # Add collection timestamp
        metadata['collection'] = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'collector_version': '1.0.0',
            'workspace_path': str(Path(args.workspace).resolve())
        }
        
        # Output metadata
        with open(args.output, 'w') as f:
            if args.format == 'yaml':
                yaml.dump(metadata, f, default_flow_style=False, indent=2)
            else:
                json.dump(metadata, f, indent=2, default=str)
        
        # Print summary
        print(f"\nGovernance Metadata Collection Complete")
        print(f"Module: {metadata['module']['name']}")
        print(f"Environment: {metadata['deployment']['environment']}")
        print(f"Resources: {metadata.get('resource_inventory', {}).get('total_resources', 0)}")
        print(f"Metadata saved to: {args.output}")
        
        if args.verbose:
            print(f"\nMetadata Summary:")
            for section, data in metadata.items():
                if isinstance(data, dict):
                    print(f"  {section}: {len(data)} items")
                else:
                    print(f"  {section}: {data}")
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()