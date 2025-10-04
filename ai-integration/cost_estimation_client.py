#!/usr/bin/env python3
"""
Cost Estimation Client for AI Agents

This module provides a Python client for AI agents to interact with the
Terraform module cost estimation API for budget planning and optimization.
"""

import json
import requests
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, asdict
from datetime import datetime
import logging


@dataclass
class CostEstimationRequest:
    """Request object for cost estimation."""
    module_source: str
    configuration: Dict[str, Any]
    cloud_provider: str
    module_version: Optional[str] = None
    region: Optional[str] = None
    estimation_period: str = "monthly"
    currency: str = "USD"
    optimization_level: str = "basic"
    budget_constraint: Optional[float] = None


@dataclass
class CostItem:
    """Individual cost item in the breakdown."""
    service: str
    resource_type: str
    cost: float
    quantity: float
    resource_name: Optional[str] = None
    unit: Optional[str] = None
    unit_cost: Optional[float] = None
    cost_factors: Optional[List[Dict[str, Any]]] = None
    tags: Optional[Dict[str, str]] = None


@dataclass
class OptimizationSuggestion:
    """Cost optimization suggestion."""
    type: str
    description: str
    potential_savings: float
    savings_percentage: float
    implementation_effort: str
    risk_level: str
    configuration_changes: Optional[Dict[str, Any]] = None
    prerequisites: Optional[List[str]] = None


@dataclass
class BudgetAnalysis:
    """Budget analysis results."""
    budget_limit: Optional[float]
    budget_utilization: Optional[float]
    budget_status: Optional[str]
    overage_amount: Optional[float]
    recommendations: Optional[List[str]]


@dataclass
class ScalingProjection:
    """Cost projection for different scaling scenarios."""
    scenario: str
    scale_factor: float
    projected_cost: float
    configuration_changes: Optional[Dict[str, Any]] = None
    notes: Optional[str] = None


@dataclass
class CostEstimationResponse:
    """Response object for cost estimation."""
    total_cost: float
    currency: str
    period: str
    confidence_level: str
    breakdown: List[CostItem]
    timestamp: str
    optimization_suggestions: Optional[List[OptimizationSuggestion]] = None
    budget_analysis: Optional[BudgetAnalysis] = None
    scaling_projections: Optional[List[ScalingProjection]] = None
    metadata: Optional[Dict[str, Any]] = None


class CostEstimationClient:
    """Client for interacting with the cost estimation API."""
    
    def __init__(self, base_url: str = "https://api.brockhoffcloud.com/v1", 
                 api_key: Optional[str] = None):
        """
        Initialize the cost estimation client.
        
        Args:
            base_url: Base URL for the cost estimation API
            api_key: API key for authentication (if required)
        """
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({"Authorization": f"Bearer {api_key}"})
        
        self.session.headers.update({
            "Content-Type": "application/json",
            "User-Agent": "BrockhoffCloud-AI-Agent/1.0"
        })
        
        self.logger = logging.getLogger(__name__)
    
    def estimate_cost(self, request: CostEstimationRequest) -> CostEstimationResponse:
        """
        Estimate the cost of a Terraform module configuration.
        
        Args:
            request: Cost estimation request object
            
        Returns:
            Cost estimation response with breakdown and suggestions
            
        Raises:
            requests.RequestException: If the API request fails
            ValueError: If the response is invalid
        """
        url = f"{self.base_url}/cost-estimation"
        
        try:
            response = self.session.post(url, json=asdict(request))
            response.raise_for_status()
            
            data = response.json()
            return self._parse_cost_response(data)
            
        except requests.RequestException as e:
            self.logger.error(f"Cost estimation API request failed: {e}")
            raise
        except (KeyError, ValueError) as e:
            self.logger.error(f"Invalid cost estimation response: {e}")
            raise ValueError(f"Invalid API response: {e}")
    
    def compare_configurations(self, configurations: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Compare costs across multiple configurations.
        
        Args:
            configurations: List of configuration dictionaries, each containing
                          'name' and cost estimation request parameters
                          
        Returns:
            Comparison results with recommendations
        """
        url = f"{self.base_url}/cost-comparison"
        
        request_data = {
            "configurations": configurations,
            "comparison_criteria": ["total_cost", "performance", "reliability"]
        }
        
        try:
            response = self.session.post(url, json=request_data)
            response.raise_for_status()
            
            return response.json()
            
        except requests.RequestException as e:
            self.logger.error(f"Cost comparison API request failed: {e}")
            raise
    
    def get_optimization_suggestions(self, 
                                   module_source: str,
                                   configuration: Dict[str, Any],
                                   cloud_provider: str,
                                   budget_limit: Optional[float] = None) -> List[OptimizationSuggestion]:
        """
        Get cost optimization suggestions for a configuration.
        
        Args:
            module_source: Terraform module source
            configuration: Module configuration
            cloud_provider: Target cloud provider
            budget_limit: Optional budget constraint
            
        Returns:
            List of optimization suggestions
        """
        request = CostEstimationRequest(
            module_source=module_source,
            configuration=configuration,
            cloud_provider=cloud_provider,
            optimization_level="aggressive",
            budget_constraint=budget_limit
        )
        
        response = self.estimate_cost(request)
        return response.optimization_suggestions or []
    
    def estimate_scaling_costs(self,
                             module_source: str,
                             base_configuration: Dict[str, Any],
                             cloud_provider: str,
                             scale_factors: List[float]) -> List[ScalingProjection]:
        """
        Estimate costs for different scaling scenarios.
        
        Args:
            module_source: Terraform module source
            base_configuration: Base module configuration
            cloud_provider: Target cloud provider
            scale_factors: List of scaling multipliers (e.g., [0.5, 1.0, 2.0, 5.0])
            
        Returns:
            List of scaling projections with costs
        """
        projections = []
        
        for scale_factor in scale_factors:
            # Create scaled configuration
            scaled_config = self._scale_configuration(base_configuration, scale_factor)
            
            request = CostEstimationRequest(
                module_source=module_source,
                configuration=scaled_config,
                cloud_provider=cloud_provider
            )
            
            response = self.estimate_cost(request)
            
            projection = ScalingProjection(
                scenario=f"{scale_factor}x scale",
                scale_factor=scale_factor,
                projected_cost=response.total_cost,
                configuration_changes=scaled_config
            )
            projections.append(projection)
        
        return projections
    
    def validate_budget(self,
                       module_source: str,
                       configuration: Dict[str, Any],
                       cloud_provider: str,
                       budget_limit: float) -> BudgetAnalysis:
        """
        Validate a configuration against a budget constraint.
        
        Args:
            module_source: Terraform module source
            configuration: Module configuration
            cloud_provider: Target cloud provider
            budget_limit: Budget limit to validate against
            
        Returns:
            Budget analysis with status and recommendations
        """
        request = CostEstimationRequest(
            module_source=module_source,
            configuration=configuration,
            cloud_provider=cloud_provider,
            budget_constraint=budget_limit
        )
        
        response = self.estimate_cost(request)
        return response.budget_analysis
    
    def get_cost_breakdown(self,
                          module_source: str,
                          configuration: Dict[str, Any],
                          cloud_provider: str) -> List[CostItem]:
        """
        Get detailed cost breakdown for a configuration.
        
        Args:
            module_source: Terraform module source
            configuration: Module configuration
            cloud_provider: Target cloud provider
            
        Returns:
            List of cost items with detailed breakdown
        """
        request = CostEstimationRequest(
            module_source=module_source,
            configuration=configuration,
            cloud_provider=cloud_provider
        )
        
        response = self.estimate_cost(request)
        return response.breakdown
    
    def _parse_cost_response(self, data: Dict[str, Any]) -> CostEstimationResponse:
        """Parse API response into CostEstimationResponse object."""
        # Parse cost items
        breakdown = []
        for item_data in data.get("breakdown", []):
            cost_item = CostItem(
                service=item_data["service"],
                resource_type=item_data["resource_type"],
                cost=item_data["cost"],
                quantity=item_data["quantity"],
                resource_name=item_data.get("resource_name"),
                unit=item_data.get("unit"),
                unit_cost=item_data.get("unit_cost"),
                cost_factors=item_data.get("cost_factors"),
                tags=item_data.get("tags")
            )
            breakdown.append(cost_item)
        
        # Parse optimization suggestions
        optimization_suggestions = []
        for suggestion_data in data.get("optimization_suggestions", []):
            suggestion = OptimizationSuggestion(
                type=suggestion_data["type"],
                description=suggestion_data["description"],
                potential_savings=suggestion_data["potential_savings"],
                savings_percentage=suggestion_data["savings_percentage"],
                implementation_effort=suggestion_data["implementation_effort"],
                risk_level=suggestion_data["risk_level"],
                configuration_changes=suggestion_data.get("configuration_changes"),
                prerequisites=suggestion_data.get("prerequisites")
            )
            optimization_suggestions.append(suggestion)
        
        # Parse budget analysis
        budget_analysis = None
        if "budget_analysis" in data:
            budget_data = data["budget_analysis"]
            budget_analysis = BudgetAnalysis(
                budget_limit=budget_data.get("budget_limit"),
                budget_utilization=budget_data.get("budget_utilization"),
                budget_status=budget_data.get("budget_status"),
                overage_amount=budget_data.get("overage_amount"),
                recommendations=budget_data.get("recommendations")
            )
        
        # Parse scaling projections
        scaling_projections = []
        for projection_data in data.get("scaling_projections", []):
            projection = ScalingProjection(
                scenario=projection_data["scenario"],
                scale_factor=projection_data["scale_factor"],
                projected_cost=projection_data["projected_cost"],
                configuration_changes=projection_data.get("configuration_changes"),
                notes=projection_data.get("notes")
            )
            scaling_projections.append(projection)
        
        return CostEstimationResponse(
            total_cost=data["total_cost"],
            currency=data["currency"],
            period=data["period"],
            confidence_level=data["confidence_level"],
            breakdown=breakdown,
            timestamp=data["timestamp"],
            optimization_suggestions=optimization_suggestions,
            budget_analysis=budget_analysis,
            scaling_projections=scaling_projections,
            metadata=data.get("metadata")
        )
    
    def _scale_configuration(self, config: Dict[str, Any], scale_factor: float) -> Dict[str, Any]:
        """Scale a configuration by a given factor."""
        scaled_config = config.copy()
        
        # Common scalable parameters
        scalable_params = [
            "min_size", "max_size", "desired_size", "instance_count",
            "allocated_storage", "max_connections", "worker_count"
        ]
        
        for param in scalable_params:
            if param in scaled_config:
                original_value = scaled_config[param]
                if isinstance(original_value, (int, float)):
                    scaled_config[param] = max(1, int(original_value * scale_factor))
        
        # Scale nested configurations
        for key, value in scaled_config.items():
            if isinstance(value, dict):
                scaled_config[key] = self._scale_configuration(value, scale_factor)
        
        return scaled_config


class AIBudgetPlanner:
    """AI-friendly budget planning utilities."""
    
    def __init__(self, cost_client: CostEstimationClient):
        """Initialize with a cost estimation client."""
        self.cost_client = cost_client
        self.logger = logging.getLogger(__name__)
    
    def plan_within_budget(self,
                          module_source: str,
                          requirements: Dict[str, Any],
                          cloud_provider: str,
                          budget_limit: float) -> Dict[str, Any]:
        """
        Plan a configuration that fits within a budget constraint.
        
        Args:
            module_source: Terraform module source
            requirements: High-level requirements
            cloud_provider: Target cloud provider
            budget_limit: Maximum budget limit
            
        Returns:
            Optimized configuration and cost analysis
        """
        # Start with a basic configuration
        base_config = self._generate_base_configuration(requirements)
        
        # Estimate cost
        try:
            response = self.cost_client.estimate_cost(CostEstimationRequest(
                module_source=module_source,
                configuration=base_config,
                cloud_provider=cloud_provider,
                budget_constraint=budget_limit
            ))
            
            if response.total_cost <= budget_limit:
                return {
                    "configuration": base_config,
                    "estimated_cost": response.total_cost,
                    "budget_utilization": (response.total_cost / budget_limit) * 100,
                    "status": "within_budget",
                    "optimizations_applied": []
                }
            
            # Apply optimizations if over budget
            optimized_config = base_config.copy()
            optimizations_applied = []
            
            for suggestion in response.optimization_suggestions or []:
                if suggestion.configuration_changes:
                    optimized_config.update(suggestion.configuration_changes)
                    optimizations_applied.append(suggestion.description)
                    
                    # Re-estimate with optimizations
                    new_response = self.cost_client.estimate_cost(CostEstimationRequest(
                        module_source=module_source,
                        configuration=optimized_config,
                        cloud_provider=cloud_provider
                    ))
                    
                    if new_response.total_cost <= budget_limit:
                        return {
                            "configuration": optimized_config,
                            "estimated_cost": new_response.total_cost,
                            "budget_utilization": (new_response.total_cost / budget_limit) * 100,
                            "status": "optimized_to_budget",
                            "optimizations_applied": optimizations_applied
                        }
            
            # If still over budget, return the best we can do
            return {
                "configuration": optimized_config,
                "estimated_cost": response.total_cost,
                "budget_utilization": (response.total_cost / budget_limit) * 100,
                "status": "over_budget",
                "optimizations_applied": optimizations_applied,
                "budget_overage": response.total_cost - budget_limit
            }
            
        except Exception as e:
            self.logger.error(f"Budget planning failed: {e}")
            raise
    
    def compare_cloud_providers(self,
                              module_source: str,
                              configuration: Dict[str, Any],
                              providers: List[str] = None) -> Dict[str, Any]:
        """
        Compare costs across different cloud providers.
        
        Args:
            module_source: Terraform module source
            configuration: Module configuration
            providers: List of cloud providers to compare (default: all)
            
        Returns:
            Cost comparison across providers
        """
        if providers is None:
            providers = ["aws", "azure", "gcp"]
        
        comparisons = []
        
        for provider in providers:
            try:
                response = self.cost_client.estimate_cost(CostEstimationRequest(
                    module_source=module_source,
                    configuration=configuration,
                    cloud_provider=provider
                ))
                
                comparisons.append({
                    "provider": provider,
                    "total_cost": response.total_cost,
                    "currency": response.currency,
                    "confidence_level": response.confidence_level,
                    "breakdown": [asdict(item) for item in response.breakdown]
                })
                
            except Exception as e:
                self.logger.warning(f"Cost estimation failed for {provider}: {e}")
                comparisons.append({
                    "provider": provider,
                    "error": str(e)
                })
        
        # Sort by cost (lowest first)
        valid_comparisons = [c for c in comparisons if "error" not in c]
        valid_comparisons.sort(key=lambda x: x["total_cost"])
        
        return {
            "comparisons": comparisons,
            "cheapest_provider": valid_comparisons[0]["provider"] if valid_comparisons else None,
            "cost_savings": (valid_comparisons[-1]["total_cost"] - valid_comparisons[0]["total_cost"]) if len(valid_comparisons) > 1 else 0
        }
    
    def _generate_base_configuration(self, requirements: Dict[str, Any]) -> Dict[str, Any]:
        """Generate a base configuration from high-level requirements."""
        # This is a simplified example - in practice, this would use
        # the AI metadata templates and patterns
        config = {
            "enabled": True,
            "environment_type": requirements.get("environment", "Development")
        }
        
        # Map requirements to configuration
        if "performance" in requirements:
            perf_level = requirements["performance"]
            if perf_level == "high":
                config["instance_type"] = "large"
            elif perf_level == "medium":
                config["instance_type"] = "medium"
            else:
                config["instance_type"] = "small"
        
        if "availability" in requirements:
            if requirements["availability"] == "high":
                config["min_size"] = 2
                config["max_size"] = 10
            else:
                config["min_size"] = 1
                config["max_size"] = 3
        
        return config


# Example usage
if __name__ == "__main__":
    # Initialize client
    client = CostEstimationClient(
        base_url="https://api.brockhoffcloud.com/v1",
        api_key="your-api-key"
    )
    
    # Example cost estimation
    request = CostEstimationRequest(
        module_source="kbrockhoff/compute-instance/terraform",
        configuration={
            "name_prefix": "test-app",
            "environment_type": "Production",
            "instance_config": {
                "instance_type": "medium",
                "min_size": 2,
                "max_size": 10
            }
        },
        cloud_provider="aws",
        region="us-east-1",
        budget_constraint=500.0
    )
    
    try:
        response = client.estimate_cost(request)
        print(f"Estimated monthly cost: ${response.total_cost:.2f}")
        print(f"Confidence level: {response.confidence_level}")
        
        if response.optimization_suggestions:
            print("\nOptimization suggestions:")
            for suggestion in response.optimization_suggestions:
                print(f"- {suggestion.description}: Save ${suggestion.potential_savings:.2f}/month")
        
    except Exception as e:
        print(f"Cost estimation failed: {e}")