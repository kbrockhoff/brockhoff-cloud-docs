#!/usr/bin/env python3
"""
Comprehensive Test Runner for AI Testing Framework

This script runs comprehensive test suites for AI-generated Terraform configurations,
providing detailed reporting and feedback collection.
"""

import yaml
import json
import time
import concurrent.futures
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import argparse

from ai_testing_framework import AITestingFramework, TestScenario, ValidationResult
from feedback_collector import FeedbackCollector


@dataclass
class TestSuiteResult:
    """Result of running a test suite."""
    suite_name: str
    description: str
    total_scenarios: int
    passed_scenarios: int
    failed_scenarios: int
    execution_time: float
    scenario_results: List[ValidationResult]
    performance_score: float
    meets_benchmark: bool


@dataclass
class ComprehensiveTestReport:
    """Comprehensive test report."""
    timestamp: str
    total_suites: int
    total_scenarios: int
    overall_success_rate: float
    total_execution_time: float
    suite_results: List[TestSuiteResult]
    performance_summary: Dict[str, Any]
    recommendations: List[str]


class ComprehensiveTestRunner:
    """Runs comprehensive test suites for AI testing framework."""
    
    def __init__(self, 
                 config_file: str = "test_scenarios.yaml",
                 feedback_collector: Optional[FeedbackCollector] = None):
        """Initialize the comprehensive test runner."""
        self.config_file = config_file
        self.feedback_collector = feedback_collector or FeedbackCollector()
        self.framework = AITestingFramework()
        self.logger = logging.getLogger(__name__)
        
        # Load test configuration
        self.config = self._load_test_config()
        
    def _load_test_config(self) -> Dict[str, Any]:
        """Load test configuration from YAML file."""
        try:
            with open(self.config_file, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            self.logger.error(f"Failed to load test config: {e}")
            raise
    
    def run_all_suites(self, 
                      suite_filter: Optional[List[str]] = None,
                      parallel: bool = False) -> ComprehensiveTestReport:
        """
        Run all test suites.
        
        Args:
            suite_filter: Optional list of suite names to run
            parallel: Whether to run suites in parallel
            
        Returns:
            Comprehensive test report
        """
        start_time = time.time()
        
        test_suites = self.config.get('test_suites', {})
        performance_benchmarks = self.config.get('performance_benchmarks', {})
        
        # Filter suites if requested
        if suite_filter:
            test_suites = {k: v for k, v in test_suites.items() if k in suite_filter}
        
        suite_results = []
        
        if parallel and len(test_suites) > 1:
            # Run suites in parallel
            with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
                future_to_suite = {
                    executor.submit(self._run_test_suite, suite_name, suite_config, performance_benchmarks.get(suite_name, {})): suite_name
                    for suite_name, suite_config in test_suites.items()
                }
                
                for future in concurrent.futures.as_completed(future_to_suite):
                    suite_name = future_to_suite[future]
                    try:
                        result = future.result()
                        suite_results.append(result)
                        self.logger.info(f"Completed suite: {suite_name}")
                    except Exception as e:
                        self.logger.error(f"Suite {suite_name} failed: {e}")
        else:
            # Run suites sequentially
            for suite_name, suite_config in test_suites.items():
                try:
                    result = self._run_test_suite(
                        suite_name, 
                        suite_config, 
                        performance_benchmarks.get(suite_name, {})
                    )
                    suite_results.append(result)
                    self.logger.info(f"Completed suite: {suite_name}")
                except Exception as e:
                    self.logger.error(f"Suite {suite_name} failed: {e}")
        
        total_execution_time = time.time() - start_time
        
        # Calculate overall metrics
        total_scenarios = sum(r.total_scenarios for r in suite_results)
        total_passed = sum(r.passed_scenarios for r in suite_results)
        overall_success_rate = total_passed / total_scenarios if total_scenarios > 0 else 0
        
        # Generate performance summary
        performance_summary = self._generate_performance_summary(suite_results)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(suite_results)
        
        return ComprehensiveTestReport(
            timestamp=datetime.now().isoformat(),
            total_suites=len(suite_results),
            total_scenarios=total_scenarios,
            overall_success_rate=overall_success_rate,
            total_execution_time=total_execution_time,
            suite_results=suite_results,
            performance_summary=performance_summary,
            recommendations=recommendations
        )
    
    def _run_test_suite(self, 
                       suite_name: str, 
                       suite_config: Dict[str, Any],
                       benchmark: Dict[str, Any]) -> TestSuiteResult:
        """Run a single test suite."""
        self.logger.info(f"Running test suite: {suite_name}")
        
        start_time = time.time()
        
        # Convert scenarios to TestScenario objects
        scenarios = []
        for scenario_config in suite_config.get('scenarios', []):
            scenario = TestScenario(
                name=scenario_config['name'],
                description=scenario_config['description'],
                module_source=scenario_config['module_source'],
                variables=scenario_config['variables'],
                expected_outcome=scenario_config['expected_outcome'],
                cloud_provider=scenario_config.get('cloud_provider', 'aws'),
                timeout_seconds=scenario_config.get('timeout_seconds', 300)
            )
            scenarios.append(scenario)
        
        # Run scenarios
        results = self.framework.run_test_suite(scenarios)
        
        execution_time = time.time() - start_time
        
        # Calculate metrics
        total_scenarios = len(results)
        passed_scenarios = sum(1 for r in results if r.success)
        failed_scenarios = total_scenarios - passed_scenarios
        
        # Calculate performance score
        performance_score = self._calculate_suite_performance_score(results, execution_time)
        
        # Check if meets benchmark
        meets_benchmark = self._check_benchmark(results, execution_time, benchmark)
        
        # Record feedback for failed scenarios
        for result in results:
            if not result.success:
                self._record_failure_feedback(suite_name, result)
        
        return TestSuiteResult(
            suite_name=suite_name,
            description=suite_config.get('description', ''),
            total_scenarios=total_scenarios,
            passed_scenarios=passed_scenarios,
            failed_scenarios=failed_scenarios,
            execution_time=execution_time,
            scenario_results=results,
            performance_score=performance_score,
            meets_benchmark=meets_benchmark
        )
    
    def _calculate_suite_performance_score(self, 
                                         results: List[ValidationResult], 
                                         execution_time: float) -> float:
        """Calculate performance score for a test suite."""
        if not results:
            return 0.0
        
        # Success rate component (70% weight)
        success_rate = sum(1 for r in results if r.success) / len(results)
        success_score = success_rate * 70
        
        # Speed component (20% weight)
        avg_time = sum(r.execution_time for r in results) / len(results)
        speed_score = max(0, 20 - (avg_time / 30))  # Penalty for slow tests
        
        # Resource efficiency component (10% weight)
        avg_resources = sum(r.resource_count or 0 for r in results) / len(results)
        efficiency_score = max(0, 10 - (avg_resources / 20))  # Penalty for too many resources
        
        return min(100, success_score + speed_score + efficiency_score)
    
    def _check_benchmark(self, 
                        results: List[ValidationResult], 
                        execution_time: float, 
                        benchmark: Dict[str, Any]) -> bool:
        """Check if results meet performance benchmark."""
        if not benchmark:
            return True
        
        # Check success rate
        success_rate = sum(1 for r in results if r.success) / len(results) if results else 0
        expected_success_rate = benchmark.get('expected_success_rate', 0.9)
        
        if success_rate < expected_success_rate:
            return False
        
        # Check execution time
        max_execution_time = benchmark.get('max_execution_time', 300)
        if execution_time > max_execution_time:
            return False
        
        return True
    
    def _record_failure_feedback(self, suite_name: str, result: ValidationResult) -> None:
        """Record feedback for failed test scenarios."""
        try:
            attempt_id = self.feedback_collector.record_generation_attempt(
                ai_agent_id="test_runner",
                module_source=f"test_suite_{suite_name}",
                user_requirements={"test_scenario": result.scenario_name},
                generated_configuration={"test": "configuration"},
                validation_result={
                    "success": result.success,
                    "execution_time": result.execution_time,
                    "validation_errors": result.validation_errors or [],
                    "warnings": result.warnings or []
                }
            )
            
            # Add negative feedback for failures
            self.feedback_collector.add_user_feedback(
                attempt_id=attempt_id,
                score=1,  # Low score for failures
                comments=f"Test scenario failed: {result.scenario_name}"
            )
            
        except Exception as e:
            self.logger.warning(f"Failed to record feedback: {e}")
    
    def _generate_performance_summary(self, suite_results: List[TestSuiteResult]) -> Dict[str, Any]:
        """Generate performance summary across all suites."""
        if not suite_results:
            return {}
        
        # Overall metrics
        total_scenarios = sum(r.total_scenarios for r in suite_results)
        total_passed = sum(r.passed_scenarios for r in suite_results)
        overall_success_rate = total_passed / total_scenarios if total_scenarios > 0 else 0
        
        # Performance scores
        performance_scores = [r.performance_score for r in suite_results]
        avg_performance_score = sum(performance_scores) / len(performance_scores)
        
        # Execution times
        execution_times = [r.execution_time for r in suite_results]
        total_execution_time = sum(execution_times)
        avg_execution_time = total_execution_time / len(execution_times)
        
        # Benchmark compliance
        benchmark_compliance = sum(1 for r in suite_results if r.meets_benchmark) / len(suite_results)
        
        # Suite-by-suite breakdown
        suite_breakdown = []
        for result in suite_results:
            suite_breakdown.append({
                "suite_name": result.suite_name,
                "success_rate": result.passed_scenarios / result.total_scenarios if result.total_scenarios > 0 else 0,
                "performance_score": result.performance_score,
                "execution_time": result.execution_time,
                "meets_benchmark": result.meets_benchmark
            })
        
        return {
            "overall_success_rate": overall_success_rate,
            "average_performance_score": avg_performance_score,
            "total_execution_time": total_execution_time,
            "average_execution_time": avg_execution_time,
            "benchmark_compliance_rate": benchmark_compliance,
            "suite_breakdown": suite_breakdown
        }
    
    def _generate_recommendations(self, suite_results: List[TestSuiteResult]) -> List[str]:
        """Generate recommendations based on test results."""
        recommendations = []
        
        # Overall success rate recommendations
        total_scenarios = sum(r.total_scenarios for r in suite_results)
        total_passed = sum(r.passed_scenarios for r in suite_results)
        overall_success_rate = total_passed / total_scenarios if total_scenarios > 0 else 0
        
        if overall_success_rate < 0.8:
            recommendations.append(
                f"Overall success rate is {overall_success_rate:.1%}. "
                "Focus on improving AI configuration generation accuracy."
            )
        
        # Performance recommendations
        avg_performance_score = sum(r.performance_score for r in suite_results) / len(suite_results)
        if avg_performance_score < 70:
            recommendations.append(
                f"Average performance score is {avg_performance_score:.1f}/100. "
                "Optimize for speed and resource efficiency."
            )
        
        # Suite-specific recommendations
        for result in suite_results:
            if result.failed_scenarios > result.passed_scenarios:
                recommendations.append(
                    f"Suite '{result.suite_name}' has high failure rate. "
                    "Review test scenarios and AI generation logic."
                )
            
            if not result.meets_benchmark:
                recommendations.append(
                    f"Suite '{result.suite_name}' does not meet performance benchmarks. "
                    "Optimize execution time and success rate."
                )
        
        # Common error pattern recommendations
        all_errors = []
        for result in suite_results:
            for scenario_result in result.scenario_results:
                if scenario_result.validation_errors:
                    all_errors.extend(scenario_result.validation_errors)
        
        if all_errors:
            # Find most common error pattern
            error_counts = {}
            for error in all_errors:
                # Normalize error for pattern matching
                normalized = error.lower()
                if 'required' in normalized:
                    error_counts['missing_required_fields'] = error_counts.get('missing_required_fields', 0) + 1
                elif 'validation' in normalized:
                    error_counts['validation_errors'] = error_counts.get('validation_errors', 0) + 1
                elif 'timeout' in normalized:
                    error_counts['timeout_errors'] = error_counts.get('timeout_errors', 0) + 1
            
            if error_counts:
                most_common_error = max(error_counts.keys(), key=lambda k: error_counts[k])
                recommendations.append(
                    f"Most common error type: {most_common_error}. "
                    "Focus on preventing this error pattern in AI generation."
                )
        
        return recommendations[:10]  # Top 10 recommendations
    
    def generate_detailed_report(self, report: ComprehensiveTestReport) -> str:
        """Generate a detailed text report."""
        lines = []
        
        # Header
        lines.append("=" * 80)
        lines.append("COMPREHENSIVE AI TESTING FRAMEWORK REPORT")
        lines.append("=" * 80)
        lines.append(f"Generated: {report.timestamp}")
        lines.append(f"Total Test Suites: {report.total_suites}")
        lines.append(f"Total Test Scenarios: {report.total_scenarios}")
        lines.append(f"Overall Success Rate: {report.overall_success_rate:.1%}")
        lines.append(f"Total Execution Time: {report.total_execution_time:.1f} seconds")
        lines.append("")
        
        # Performance Summary
        lines.append("PERFORMANCE SUMMARY")
        lines.append("-" * 40)
        perf = report.performance_summary
        lines.append(f"Average Performance Score: {perf.get('average_performance_score', 0):.1f}/100")
        lines.append(f"Benchmark Compliance Rate: {perf.get('benchmark_compliance_rate', 0):.1%}")
        lines.append(f"Average Execution Time: {perf.get('average_execution_time', 0):.1f} seconds")
        lines.append("")
        
        # Suite Results
        lines.append("TEST SUITE RESULTS")
        lines.append("-" * 40)
        
        for suite_result in report.suite_results:
            status = "✅ PASS" if suite_result.meets_benchmark else "❌ FAIL"
            success_rate = suite_result.passed_scenarios / suite_result.total_scenarios if suite_result.total_scenarios > 0 else 0
            
            lines.append(f"{status} {suite_result.suite_name}")
            lines.append(f"    Description: {suite_result.description}")
            lines.append(f"    Scenarios: {suite_result.passed_scenarios}/{suite_result.total_scenarios} passed ({success_rate:.1%})")
            lines.append(f"    Performance Score: {suite_result.performance_score:.1f}/100")
            lines.append(f"    Execution Time: {suite_result.execution_time:.1f}s")
            lines.append(f"    Meets Benchmark: {'Yes' if suite_result.meets_benchmark else 'No'}")
            
            # Show failed scenarios
            failed_scenarios = [r for r in suite_result.scenario_results if not r.success]
            if failed_scenarios:
                lines.append("    Failed Scenarios:")
                for scenario in failed_scenarios[:3]:  # Show first 3 failures
                    lines.append(f"      - {scenario.scenario_name}")
                    if scenario.validation_errors:
                        for error in scenario.validation_errors[:2]:  # Show first 2 errors
                            lines.append(f"        Error: {error}")
                if len(failed_scenarios) > 3:
                    lines.append(f"      ... and {len(failed_scenarios) - 3} more")
            
            lines.append("")
        
        # Recommendations
        if report.recommendations:
            lines.append("RECOMMENDATIONS")
            lines.append("-" * 40)
            for i, recommendation in enumerate(report.recommendations, 1):
                lines.append(f"{i}. {recommendation}")
            lines.append("")
        
        # Footer
        lines.append("=" * 80)
        lines.append("End of Report")
        lines.append("=" * 80)
        
        return "\n".join(lines)


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description="Comprehensive AI Testing Framework Runner")
    parser.add_argument("--config", default="test_scenarios.yaml",
                       help="Test configuration file")
    parser.add_argument("--suites", nargs="+",
                       help="Specific test suites to run")
    parser.add_argument("--parallel", action="store_true",
                       help="Run test suites in parallel")
    parser.add_argument("--output", help="Output file for results")
    parser.add_argument("--format", choices=["json", "yaml", "text"], default="json",
                       help="Output format")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Verbose logging")
    
    args = parser.parse_args()
    
    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    try:
        # Initialize test runner
        runner = ComprehensiveTestRunner(config_file=args.config)
        
        # Run tests
        print("Starting comprehensive AI testing framework...")
        report = runner.run_all_suites(
            suite_filter=args.suites,
            parallel=args.parallel
        )
        
        # Generate output
        if args.format == "json":
            output_data = asdict(report)
        elif args.format == "yaml":
            output_data = yaml.dump(asdict(report), default_flow_style=False)
        else:  # text
            output_data = runner.generate_detailed_report(report)
        
        # Save or print results
        if args.output:
            with open(args.output, 'w') as f:
                if args.format in ["json"]:
                    json.dump(output_data, f, indent=2)
                else:
                    f.write(output_data if isinstance(output_data, str) else str(output_data))
            print(f"Results saved to {args.output}")
        else:
            if args.format == "json":
                print(json.dumps(output_data, indent=2))
            else:
                print(output_data)
        
        # Print summary
        print(f"\n📊 Test Summary:")
        print(f"   Total Suites: {report.total_suites}")
        print(f"   Total Scenarios: {report.total_scenarios}")
        print(f"   Success Rate: {report.overall_success_rate:.1%}")
        print(f"   Execution Time: {report.total_execution_time:.1f}s")
        
        # Exit with appropriate code
        return 0 if report.overall_success_rate >= 0.8 else 1
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main())