#!/usr/bin/env python3
"""
AI Feedback Collector

This module collects feedback from AI-generated Terraform configurations
to improve future code generation and identify common patterns and issues.
"""

import json
import sqlite3
import hashlib
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
import logging
import statistics


@dataclass
class GenerationAttempt:
    """Represents an AI code generation attempt."""
    id: str
    timestamp: str
    ai_agent_id: str
    module_source: str
    user_requirements: Dict[str, Any]
    generated_configuration: Dict[str, Any]
    validation_success: bool
    execution_time: float
    error_messages: List[str]
    warnings: List[str]
    cost_estimate: Optional[float] = None
    user_feedback_score: Optional[int] = None  # 1-5 rating
    user_feedback_comments: Optional[str] = None


@dataclass
class PatternAnalysis:
    """Analysis of patterns in AI generation attempts."""
    pattern_type: str
    pattern_description: str
    frequency: int
    success_rate: float
    common_configurations: List[Dict[str, Any]]
    improvement_suggestions: List[str]


@dataclass
class PerformanceMetrics:
    """Performance metrics for AI code generation."""
    total_attempts: int
    success_rate: float
    average_execution_time: float
    common_errors: List[Tuple[str, int]]  # (error, frequency)
    cost_accuracy: Optional[float] = None
    user_satisfaction: Optional[float] = None


class FeedbackDatabase:
    """SQLite database for storing AI generation feedback."""
    
    def __init__(self, db_path: str = "ai_feedback.db"):
        """Initialize the feedback database."""
        self.db_path = db_path
        self.logger = logging.getLogger(__name__)
        self._init_database()
    
    def _init_database(self):
        """Initialize the database schema."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS generation_attempts (
                    id TEXT PRIMARY KEY,
                    timestamp TEXT NOT NULL,
                    ai_agent_id TEXT NOT NULL,
                    module_source TEXT NOT NULL,
                    user_requirements TEXT NOT NULL,
                    generated_configuration TEXT NOT NULL,
                    validation_success BOOLEAN NOT NULL,
                    execution_time REAL NOT NULL,
                    error_messages TEXT,
                    warnings TEXT,
                    cost_estimate REAL,
                    user_feedback_score INTEGER,
                    user_feedback_comments TEXT
                )
            ''')
            
            conn.execute('''
                CREATE TABLE IF NOT EXISTS pattern_analysis (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    pattern_type TEXT NOT NULL,
                    pattern_description TEXT NOT NULL,
                    frequency INTEGER NOT NULL,
                    success_rate REAL NOT NULL,
                    common_configurations TEXT NOT NULL,
                    improvement_suggestions TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
            ''')
            
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_timestamp 
                ON generation_attempts(timestamp)
            ''')
            
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_module_source 
                ON generation_attempts(module_source)
            ''')
            
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_ai_agent 
                ON generation_attempts(ai_agent_id)
            ''')
    
    def store_attempt(self, attempt: GenerationAttempt) -> None:
        """Store a generation attempt in the database."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT OR REPLACE INTO generation_attempts 
                (id, timestamp, ai_agent_id, module_source, user_requirements,
                 generated_configuration, validation_success, execution_time,
                 error_messages, warnings, cost_estimate, user_feedback_score,
                 user_feedback_comments)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                attempt.id,
                attempt.timestamp,
                attempt.ai_agent_id,
                attempt.module_source,
                json.dumps(attempt.user_requirements),
                json.dumps(attempt.generated_configuration),
                attempt.validation_success,
                attempt.execution_time,
                json.dumps(attempt.error_messages),
                json.dumps(attempt.warnings),
                attempt.cost_estimate,
                attempt.user_feedback_score,
                attempt.user_feedback_comments
            ))
    
    def get_attempts(self, 
                    ai_agent_id: Optional[str] = None,
                    module_source: Optional[str] = None,
                    since: Optional[datetime] = None,
                    limit: Optional[int] = None) -> List[GenerationAttempt]:
        """Retrieve generation attempts from the database."""
        query = "SELECT * FROM generation_attempts WHERE 1=1"
        params = []
        
        if ai_agent_id:
            query += " AND ai_agent_id = ?"
            params.append(ai_agent_id)
        
        if module_source:
            query += " AND module_source = ?"
            params.append(module_source)
        
        if since:
            query += " AND timestamp >= ?"
            params.append(since.isoformat())
        
        query += " ORDER BY timestamp DESC"
        
        if limit:
            query += " LIMIT ?"
            params.append(limit)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            
            attempts = []
            for row in cursor.fetchall():
                attempt = GenerationAttempt(
                    id=row['id'],
                    timestamp=row['timestamp'],
                    ai_agent_id=row['ai_agent_id'],
                    module_source=row['module_source'],
                    user_requirements=json.loads(row['user_requirements']),
                    generated_configuration=json.loads(row['generated_configuration']),
                    validation_success=bool(row['validation_success']),
                    execution_time=row['execution_time'],
                    error_messages=json.loads(row['error_messages'] or '[]'),
                    warnings=json.loads(row['warnings'] or '[]'),
                    cost_estimate=row['cost_estimate'],
                    user_feedback_score=row['user_feedback_score'],
                    user_feedback_comments=row['user_feedback_comments']
                )
                attempts.append(attempt)
        
        return attempts
    
    def store_pattern_analysis(self, analysis: PatternAnalysis) -> None:
        """Store pattern analysis results."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO pattern_analysis 
                (pattern_type, pattern_description, frequency, success_rate,
                 common_configurations, improvement_suggestions, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                analysis.pattern_type,
                analysis.pattern_description,
                analysis.frequency,
                analysis.success_rate,
                json.dumps(analysis.common_configurations),
                json.dumps(analysis.improvement_suggestions),
                datetime.now().isoformat()
            ))


class FeedbackCollector:
    """Collects and analyzes feedback from AI code generation."""
    
    def __init__(self, database: Optional[FeedbackDatabase] = None):
        """Initialize the feedback collector."""
        self.db = database or FeedbackDatabase()
        self.logger = logging.getLogger(__name__)
    
    def record_generation_attempt(self,
                                ai_agent_id: str,
                                module_source: str,
                                user_requirements: Dict[str, Any],
                                generated_configuration: Dict[str, Any],
                                validation_result: Dict[str, Any]) -> str:
        """
        Record an AI code generation attempt.
        
        Args:
            ai_agent_id: Identifier for the AI agent
            module_source: Terraform module source
            user_requirements: Original user requirements
            generated_configuration: AI-generated configuration
            validation_result: Result from validation testing
            
        Returns:
            Unique ID for the generation attempt
        """
        # Generate unique ID
        content_hash = hashlib.sha256(
            f"{ai_agent_id}{module_source}{json.dumps(generated_configuration)}".encode()
        ).hexdigest()[:16]
        
        attempt_id = f"{ai_agent_id}_{content_hash}"
        
        attempt = GenerationAttempt(
            id=attempt_id,
            timestamp=datetime.now().isoformat(),
            ai_agent_id=ai_agent_id,
            module_source=module_source,
            user_requirements=user_requirements,
            generated_configuration=generated_configuration,
            validation_success=validation_result.get('success', False),
            execution_time=validation_result.get('execution_time', 0),
            error_messages=validation_result.get('validation_errors', []),
            warnings=validation_result.get('warnings', []),
            cost_estimate=validation_result.get('cost_estimate')
        )
        
        self.db.store_attempt(attempt)
        self.logger.info(f"Recorded generation attempt: {attempt_id}")
        
        return attempt_id
    
    def add_user_feedback(self,
                         attempt_id: str,
                         score: int,
                         comments: Optional[str] = None) -> None:
        """
        Add user feedback to a generation attempt.
        
        Args:
            attempt_id: ID of the generation attempt
            score: User satisfaction score (1-5)
            comments: Optional user comments
        """
        attempts = self.db.get_attempts()
        
        for attempt in attempts:
            if attempt.id == attempt_id:
                attempt.user_feedback_score = score
                attempt.user_feedback_comments = comments
                self.db.store_attempt(attempt)
                self.logger.info(f"Added user feedback to attempt: {attempt_id}")
                return
        
        self.logger.warning(f"Attempt not found: {attempt_id}")
    
    def analyze_patterns(self, 
                        ai_agent_id: Optional[str] = None,
                        module_source: Optional[str] = None,
                        days_back: int = 30) -> List[PatternAnalysis]:
        """
        Analyze patterns in AI code generation.
        
        Args:
            ai_agent_id: Optional filter by AI agent
            module_source: Optional filter by module
            days_back: Number of days to analyze
            
        Returns:
            List of pattern analyses
        """
        since = datetime.now() - timedelta(days=days_back)
        attempts = self.db.get_attempts(
            ai_agent_id=ai_agent_id,
            module_source=module_source,
            since=since
        )
        
        if not attempts:
            return []
        
        analyses = []
        
        # Analyze error patterns
        error_analysis = self._analyze_error_patterns(attempts)
        if error_analysis:
            analyses.append(error_analysis)
        
        # Analyze configuration patterns
        config_analysis = self._analyze_configuration_patterns(attempts)
        if config_analysis:
            analyses.append(config_analysis)
        
        # Analyze performance patterns
        performance_analysis = self._analyze_performance_patterns(attempts)
        if performance_analysis:
            analyses.append(performance_analysis)
        
        # Store analyses in database
        for analysis in analyses:
            self.db.store_pattern_analysis(analysis)
        
        return analyses
    
    def get_performance_metrics(self,
                              ai_agent_id: Optional[str] = None,
                              module_source: Optional[str] = None,
                              days_back: int = 30) -> PerformanceMetrics:
        """
        Get performance metrics for AI code generation.
        
        Args:
            ai_agent_id: Optional filter by AI agent
            module_source: Optional filter by module
            days_back: Number of days to analyze
            
        Returns:
            Performance metrics
        """
        since = datetime.now() - timedelta(days=days_back)
        attempts = self.db.get_attempts(
            ai_agent_id=ai_agent_id,
            module_source=module_source,
            since=since
        )
        
        if not attempts:
            return PerformanceMetrics(
                total_attempts=0,
                success_rate=0.0,
                average_execution_time=0.0,
                common_errors=[]
            )
        
        # Calculate metrics
        total_attempts = len(attempts)
        successful_attempts = sum(1 for a in attempts if a.validation_success)
        success_rate = successful_attempts / total_attempts
        
        execution_times = [a.execution_time for a in attempts]
        average_execution_time = statistics.mean(execution_times)
        
        # Collect and count errors
        error_counts = {}
        for attempt in attempts:
            for error in attempt.error_messages:
                # Normalize error message
                normalized_error = self._normalize_error_message(error)
                error_counts[normalized_error] = error_counts.get(normalized_error, 0) + 1
        
        # Sort errors by frequency
        common_errors = sorted(error_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        # Calculate user satisfaction if available
        user_scores = [a.user_feedback_score for a in attempts if a.user_feedback_score]
        user_satisfaction = statistics.mean(user_scores) if user_scores else None
        
        return PerformanceMetrics(
            total_attempts=total_attempts,
            success_rate=success_rate,
            average_execution_time=average_execution_time,
            common_errors=common_errors,
            user_satisfaction=user_satisfaction
        )
    
    def generate_improvement_recommendations(self,
                                           ai_agent_id: Optional[str] = None,
                                           module_source: Optional[str] = None) -> List[str]:
        """
        Generate recommendations for improving AI code generation.
        
        Args:
            ai_agent_id: Optional filter by AI agent
            module_source: Optional filter by module
            
        Returns:
            List of improvement recommendations
        """
        metrics = self.get_performance_metrics(ai_agent_id, module_source)
        patterns = self.analyze_patterns(ai_agent_id, module_source)
        
        recommendations = []
        
        # Success rate recommendations
        if metrics.success_rate < 0.8:
            recommendations.append(
                f"Success rate is {metrics.success_rate:.1%}. Focus on improving "
                "validation accuracy and handling edge cases."
            )
        
        # Performance recommendations
        if metrics.average_execution_time > 60:
            recommendations.append(
                f"Average execution time is {metrics.average_execution_time:.1f}s. "
                "Consider optimizing configuration complexity."
            )
        
        # Error-based recommendations
        if metrics.common_errors:
            top_error = metrics.common_errors[0]
            recommendations.append(
                f"Most common error: '{top_error[0]}' ({top_error[1]} occurrences). "
                "Focus on preventing this error pattern."
            )
        
        # User satisfaction recommendations
        if metrics.user_satisfaction and metrics.user_satisfaction < 3.5:
            recommendations.append(
                f"User satisfaction is {metrics.user_satisfaction:.1f}/5. "
                "Review user feedback and improve configuration quality."
            )
        
        # Pattern-based recommendations
        for pattern in patterns:
            recommendations.extend(pattern.improvement_suggestions)
        
        return recommendations[:10]  # Top 10 recommendations
    
    def _analyze_error_patterns(self, attempts: List[GenerationAttempt]) -> Optional[PatternAnalysis]:
        """Analyze error patterns in generation attempts."""
        failed_attempts = [a for a in attempts if not a.validation_success]
        
        if not failed_attempts:
            return None
        
        # Group errors by type
        error_groups = {}
        for attempt in failed_attempts:
            for error in attempt.error_messages:
                error_type = self._categorize_error(error)
                if error_type not in error_groups:
                    error_groups[error_type] = []
                error_groups[error_type].append(attempt)
        
        # Find most common error type
        most_common_error = max(error_groups.keys(), key=lambda k: len(error_groups[k]))
        error_attempts = error_groups[most_common_error]
        
        # Generate improvement suggestions
        suggestions = self._generate_error_suggestions(most_common_error, error_attempts)
        
        return PatternAnalysis(
            pattern_type="error_pattern",
            pattern_description=f"Common error: {most_common_error}",
            frequency=len(error_attempts),
            success_rate=0.0,  # These are all failed attempts
            common_configurations=[a.generated_configuration for a in error_attempts[:5]],
            improvement_suggestions=suggestions
        )
    
    def _analyze_configuration_patterns(self, attempts: List[GenerationAttempt]) -> Optional[PatternAnalysis]:
        """Analyze configuration patterns in generation attempts."""
        successful_attempts = [a for a in attempts if a.validation_success]
        
        if not successful_attempts:
            return None
        
        # Find common configuration patterns
        config_patterns = {}
        for attempt in successful_attempts:
            pattern_key = self._extract_config_pattern(attempt.generated_configuration)
            if pattern_key not in config_patterns:
                config_patterns[pattern_key] = []
            config_patterns[pattern_key].append(attempt)
        
        # Find most common pattern
        most_common_pattern = max(config_patterns.keys(), key=lambda k: len(config_patterns[k]))
        pattern_attempts = config_patterns[most_common_pattern]
        
        success_rate = len(pattern_attempts) / len(attempts)
        
        return PatternAnalysis(
            pattern_type="configuration_pattern",
            pattern_description=f"Common configuration pattern: {most_common_pattern}",
            frequency=len(pattern_attempts),
            success_rate=success_rate,
            common_configurations=[a.generated_configuration for a in pattern_attempts[:5]],
            improvement_suggestions=[
                f"Pattern '{most_common_pattern}' has {success_rate:.1%} success rate",
                "Consider using this pattern as a template for similar configurations"
            ]
        )
    
    def _analyze_performance_patterns(self, attempts: List[GenerationAttempt]) -> Optional[PatternAnalysis]:
        """Analyze performance patterns in generation attempts."""
        if not attempts:
            return None
        
        # Group by execution time ranges
        fast_attempts = [a for a in attempts if a.execution_time < 30]
        medium_attempts = [a for a in attempts if 30 <= a.execution_time < 60]
        slow_attempts = [a for a in attempts if a.execution_time >= 60]
        
        # Analyze which configurations are faster
        if fast_attempts:
            fast_success_rate = sum(1 for a in fast_attempts if a.validation_success) / len(fast_attempts)
            
            return PatternAnalysis(
                pattern_type="performance_pattern",
                pattern_description="Fast execution configurations",
                frequency=len(fast_attempts),
                success_rate=fast_success_rate,
                common_configurations=[a.generated_configuration for a in fast_attempts[:5]],
                improvement_suggestions=[
                    "Fast configurations tend to be simpler with fewer nested objects",
                    "Consider reducing configuration complexity for better performance"
                ]
            )
        
        return None
    
    def _normalize_error_message(self, error: str) -> str:
        """Normalize error message for pattern matching."""
        # Remove specific values and paths
        normalized = error
        normalized = re.sub(r'"[^"]*"', '""', normalized)  # Remove quoted strings
        normalized = re.sub(r'\d+', 'N', normalized)  # Replace numbers
        normalized = re.sub(r'[a-f0-9]{8,}', 'HASH', normalized)  # Replace hashes
        return normalized.strip()
    
    def _categorize_error(self, error: str) -> str:
        """Categorize error message by type."""
        error_lower = error.lower()
        
        if 'required' in error_lower and 'missing' in error_lower:
            return "missing_required_field"
        elif 'invalid' in error_lower or 'validation' in error_lower:
            return "validation_error"
        elif 'provider' in error_lower:
            return "provider_error"
        elif 'dependency' in error_lower or 'reference' in error_lower:
            return "dependency_error"
        elif 'timeout' in error_lower:
            return "timeout_error"
        else:
            return "other_error"
    
    def _generate_error_suggestions(self, error_type: str, attempts: List[GenerationAttempt]) -> List[str]:
        """Generate suggestions based on error type."""
        suggestions = {
            "missing_required_field": [
                "Ensure all required variables are included in generated configurations",
                "Review module interface schema for required fields",
                "Add validation to check for required fields before generation"
            ],
            "validation_error": [
                "Review variable validation rules and constraints",
                "Ensure generated values meet module requirements",
                "Add pre-validation checks for common constraints"
            ],
            "provider_error": [
                "Verify cloud provider configuration is correct",
                "Check provider version constraints",
                "Ensure proper provider authentication"
            ],
            "dependency_error": [
                "Review module dependencies and integration points",
                "Ensure dependent modules are created first",
                "Validate module output references"
            ],
            "timeout_error": [
                "Reduce configuration complexity to improve performance",
                "Consider breaking large configurations into smaller modules",
                "Optimize provider operations"
            ]
        }
        
        return suggestions.get(error_type, ["Review error patterns and improve generation logic"])
    
    def _extract_config_pattern(self, config: Dict[str, Any]) -> str:
        """Extract a pattern key from configuration."""
        # Simple pattern extraction based on top-level keys
        keys = sorted(config.keys())
        return "_".join(keys[:5])  # Use first 5 keys as pattern


def main():
    """Main function for command-line usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description="AI Feedback Collector")
    parser.add_argument("--analyze", action="store_true", 
                       help="Analyze patterns in stored feedback")
    parser.add_argument("--metrics", action="store_true",
                       help="Show performance metrics")
    parser.add_argument("--recommendations", action="store_true",
                       help="Generate improvement recommendations")
    parser.add_argument("--ai-agent", help="Filter by AI agent ID")
    parser.add_argument("--module", help="Filter by module source")
    parser.add_argument("--days", type=int, default=30,
                       help="Number of days to analyze")
    parser.add_argument("--output", help="Output file for results")
    
    args = parser.parse_args()
    
    collector = FeedbackCollector()
    
    try:
        results = {}
        
        if args.analyze:
            patterns = collector.analyze_patterns(
                ai_agent_id=args.ai_agent,
                module_source=args.module,
                days_back=args.days
            )
            results["patterns"] = [asdict(p) for p in patterns]
        
        if args.metrics:
            metrics = collector.get_performance_metrics(
                ai_agent_id=args.ai_agent,
                module_source=args.module,
                days_back=args.days
            )
            results["metrics"] = asdict(metrics)
        
        if args.recommendations:
            recommendations = collector.generate_improvement_recommendations(
                ai_agent_id=args.ai_agent,
                module_source=args.module
            )
            results["recommendations"] = recommendations
        
        # Output results
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"Results written to {args.output}")
        else:
            print(json.dumps(results, indent=2))
        
        return 0
        
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main())