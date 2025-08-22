package helpers

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v3"
)

// ComplianceValidator provides methods for validating compliance
type ComplianceValidator struct {
	Framework    string
	CloudProvider string
	ModulePath   string
}

// NewComplianceValidator creates a new compliance validator
func NewComplianceValidator(framework, cloudProvider, modulePath string) *ComplianceValidator {
	return &ComplianceValidator{
		Framework:    framework,
		CloudProvider: cloudProvider,
		ModulePath:   modulePath,
	}
}

// ValidateWellArchitectedPillars validates well-architected framework pillars
func (cv *ComplianceValidator) ValidateWellArchitectedPillars(t *testing.T) map[string]float64 {
	scores := make(map[string]float64)
	
	switch cv.Framework {
	case "aws-waf":
		scores["operational_excellence"] = cv.validateOperationalExcellence(t)
		scores["security"] = cv.validateSecurity(t)
		scores["reliability"] = cv.validateReliability(t)
		scores["performance"] = cv.validatePerformance(t)
		scores["cost_optimization"] = cv.validateCostOptimization(t)
	case "azure-waf":
		scores["operational_excellence"] = cv.validateOperationalExcellence(t)
		scores["security"] = cv.validateSecurity(t)
		scores["reliability"] = cv.validateReliability(t)
		scores["performance_efficiency"] = cv.validatePerformance(t)
		scores["cost_optimization"] = cv.validateCostOptimization(t)
	case "gcp-caf":
		scores["operational_excellence"] = cv.validateOperationalExcellence(t)
		scores["security_privacy_compliance"] = cv.validateSecurity(t)
		scores["reliability"] = cv.validateReliability(t)
		scores["performance_optimization"] = cv.validatePerformance(t)
		scores["cost_optimization"] = cv.validateCostOptimization(t)
	}
	
	return scores
}

// validateOperationalExcellence validates operational excellence pillar
func (cv *ComplianceValidator) validateOperationalExcellence(t *testing.T) float64 {
	score := 0.0
	checks := 0
	
	// Check for monitoring and observability
	if cv.hasMonitoring() {
		score += 0.25
		t.Logf("✓ Monitoring implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Monitoring missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for automation
	if cv.hasAutomation() {
		score += 0.25
		t.Logf("✓ Automation implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Automation missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for documentation
	if cv.hasDocumentation() {
		score += 0.25
		t.Logf("✓ Documentation present in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Documentation missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for version control
	if cv.hasVersionControl() {
		score += 0.25
		t.Logf("✓ Version control implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Version control missing in %s", cv.ModulePath)
	}
	checks++
	
	return score
}

// validateSecurity validates security pillar
func (cv *ComplianceValidator) validateSecurity(t *testing.T) float64 {
	score := 0.0
	checks := 0
	
	// Check for encryption
	if cv.hasEncryption() {
		score += 0.3
		t.Logf("✓ Encryption implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Encryption missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for access controls
	if cv.hasAccessControls() {
		score += 0.3
		t.Logf("✓ Access controls implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Access controls missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for network security
	if cv.hasNetworkSecurity() {
		score += 0.2
		t.Logf("✓ Network security implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Network security missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for security monitoring
	if cv.hasSecurityMonitoring() {
		score += 0.2
		t.Logf("✓ Security monitoring implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Security monitoring missing in %s", cv.ModulePath)
	}
	checks++
	
	return score
}

// validateReliability validates reliability pillar
func (cv *ComplianceValidator) validateReliability(t *testing.T) float64 {
	score := 0.0
	checks := 0
	
	// Check for fault tolerance
	if cv.hasFaultTolerance() {
		score += 0.3
		t.Logf("✓ Fault tolerance implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Fault tolerance missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for backup and recovery
	if cv.hasBackupRecovery() {
		score += 0.3
		t.Logf("✓ Backup and recovery implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Backup and recovery missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for health monitoring
	if cv.hasHealthMonitoring() {
		score += 0.2
		t.Logf("✓ Health monitoring implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Health monitoring missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for auto-scaling
	if cv.hasAutoScaling() {
		score += 0.2
		t.Logf("✓ Auto-scaling implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Auto-scaling missing in %s", cv.ModulePath)
	}
	checks++
	
	return score
}

// validatePerformance validates performance pillar
func (cv *ComplianceValidator) validatePerformance(t *testing.T) float64 {
	score := 0.0
	checks := 0
	
	// Check for performance monitoring
	if cv.hasPerformanceMonitoring() {
		score += 0.3
		t.Logf("✓ Performance monitoring implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Performance monitoring missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for resource optimization
	if cv.hasResourceOptimization() {
		score += 0.3
		t.Logf("✓ Resource optimization implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Resource optimization missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for caching
	if cv.hasCaching() {
		score += 0.2
		t.Logf("✓ Caching implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Caching missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for load balancing
	if cv.hasLoadBalancing() {
		score += 0.2
		t.Logf("✓ Load balancing implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Load balancing missing in %s", cv.ModulePath)
	}
	checks++
	
	return score
}

// validateCostOptimization validates cost optimization pillar
func (cv *ComplianceValidator) validateCostOptimization(t *testing.T) float64 {
	score := 0.0
	checks := 0
	
	// Check for cost monitoring
	if cv.hasCostMonitoring() {
		score += 0.3
		t.Logf("✓ Cost monitoring implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Cost monitoring missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for right-sizing
	if cv.hasRightSizing() {
		score += 0.3
		t.Logf("✓ Right-sizing implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Right-sizing missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for cost allocation
	if cv.hasCostAllocation() {
		score += 0.2
		t.Logf("✓ Cost allocation implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Cost allocation missing in %s", cv.ModulePath)
	}
	checks++
	
	// Check for resource scheduling
	if cv.hasResourceScheduling() {
		score += 0.2
		t.Logf("✓ Resource scheduling implemented in %s", cv.ModulePath)
	} else {
		t.Logf("✗ Resource scheduling missing in %s", cv.ModulePath)
	}
	checks++
	
	return score
}

// Helper methods to check for specific implementations

func (cv *ComplianceValidator) hasMonitoring() bool {
	return cv.findInFiles([]string{"cloudwatch", "monitoring", "metrics", "alarms"})
}

func (cv *ComplianceValidator) hasAutomation() bool {
	return cv.findInFiles([]string{"automation", "lambda", "function", "workflow"})
}

func (cv *ComplianceValidator) hasDocumentation() bool {
	return cv.fileExists("README.md") && cv.fileExists("variables.tf")
}

func (cv *ComplianceValidator) hasVersionControl() bool {
	return cv.findInFiles([]string{"versions.tf", "required_version"})
}

func (cv *ComplianceValidator) hasEncryption() bool {
	return cv.findInFiles([]string{"kms", "encryption", "server_side_encryption", "encrypt"})
}

func (cv *ComplianceValidator) hasAccessControls() bool {
	return cv.findInFiles([]string{"iam", "policy", "role", "rbac", "access"})
}

func (cv *ComplianceValidator) hasNetworkSecurity() bool {
	return cv.findInFiles([]string{"security_group", "network_acl", "firewall", "vpc"})
}

func (cv *ComplianceValidator) hasSecurityMonitoring() bool {
	return cv.findInFiles([]string{"security_monitoring", "threat_detection", "audit"})
}

func (cv *ComplianceValidator) hasFaultTolerance() bool {
	return cv.findInFiles([]string{"multi_az", "availability_zone", "redundancy", "failover"})
}

func (cv *ComplianceValidator) hasBackupRecovery() bool {
	return cv.findInFiles([]string{"backup", "snapshot", "recovery", "restore"})
}

func (cv *ComplianceValidator) hasHealthMonitoring() bool {
	return cv.findInFiles([]string{"health_check", "status", "probe"})
}

func (cv *ComplianceValidator) hasAutoScaling() bool {
	return cv.findInFiles([]string{"auto_scaling", "scaling_policy", "scale"})
}

func (cv *ComplianceValidator) hasPerformanceMonitoring() bool {
	return cv.findInFiles([]string{"performance", "metrics", "cpu", "memory"})
}

func (cv *ComplianceValidator) hasResourceOptimization() bool {
	return cv.findInFiles([]string{"instance_type", "size", "optimization", "right_size"})
}

func (cv *ComplianceValidator) hasCaching() bool {
	return cv.findInFiles([]string{"cache", "redis", "memcached", "cdn"})
}

func (cv *ComplianceValidator) hasLoadBalancing() bool {
	return cv.findInFiles([]string{"load_balancer", "elb", "alb", "nlb"})
}

func (cv *ComplianceValidator) hasCostMonitoring() bool {
	return cv.findInFiles([]string{"cost", "budget", "billing", "pricing"})
}

func (cv *ComplianceValidator) hasRightSizing() bool {
	return cv.findInFiles([]string{"instance_type", "size", "right_size", "optimization"})
}

func (cv *ComplianceValidator) hasCostAllocation() bool {
	return cv.findInFiles([]string{"tags", "cost_center", "project", "allocation"})
}

func (cv *ComplianceValidator) hasResourceScheduling() bool {
	return cv.findInFiles([]string{"schedule", "start_stop", "lifecycle"})
}

// findInFiles searches for patterns in terraform files
func (cv *ComplianceValidator) findInFiles(patterns []string) bool {
	files, err := filepath.Glob(filepath.Join(cv.ModulePath, "*.tf"))
	if err != nil {
		return false
	}

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			continue
		}

		contentStr := strings.ToLower(string(content))
		for _, pattern := range patterns {
			if strings.Contains(contentStr, strings.ToLower(pattern)) {
				return true
			}
		}
	}

	return false
}

// fileExists checks if a file exists in the module path
func (cv *ComplianceValidator) fileExists(filename string) bool {
	_, err := os.Stat(filepath.Join(cv.ModulePath, filename))
	return err == nil
}

// ValidateComplianceFramework validates a compliance framework file
func ValidateComplianceFramework(t *testing.T, frameworkPath string) {
	// Check if framework file exists
	assert.FileExists(t, frameworkPath, "Compliance framework file should exist")

	// Load and validate framework structure
	data, err := os.ReadFile(frameworkPath)
	assert.NoError(t, err, "Should be able to read compliance framework file")

	var framework map[string]interface{}
	err = yaml.Unmarshal(data, &framework)
	assert.NoError(t, err, "Compliance framework should be valid YAML")

	// Validate required fields
	assert.Contains(t, framework, "name", "Framework should have a name")
	assert.Contains(t, framework, "version", "Framework should have a version")
	assert.Contains(t, framework, "pillars", "Framework should have pillars")

	// Validate pillars structure
	pillars, ok := framework["pillars"].(map[string]interface{})
	assert.True(t, ok, "Pillars should be a map")
	assert.NotEmpty(t, pillars, "Framework should have at least one pillar")

	for pillarName, pillarData := range pillars {
		t.Run(fmt.Sprintf("pillar-%s", pillarName), func(t *testing.T) {
			controls, ok := pillarData.([]interface{})
			assert.True(t, ok, "Pillar %s should contain a list of controls", pillarName)
			assert.NotEmpty(t, controls, "Pillar %s should have at least one control", pillarName)

			for i, controlData := range controls {
				control, ok := controlData.(map[string]interface{})
				assert.True(t, ok, "Control %d in pillar %s should be a map", i, pillarName)
				
				// Validate required control fields
				assert.Contains(t, control, "id", "Control should have an ID")
				assert.Contains(t, control, "title", "Control should have a title")
				assert.Contains(t, control, "description", "Control should have a description")
			}
		})
	}
}

// GenerateComplianceReport generates a comprehensive compliance report
func GenerateComplianceReport(t *testing.T, modulePath string, frameworks []string) {
	report := map[string]interface{}{
		"module_path": modulePath,
		"timestamp":   "2024-01-01T00:00:00Z",
		"frameworks":  make(map[string]interface{}),
	}

	for _, framework := range frameworks {
		frameworkPath := filepath.Join("../compliance", framework+".yaml")
		if _, err := os.Stat(frameworkPath); err == nil {
			// Assess framework compliance
			validator := NewComplianceValidator(framework, "aws", modulePath)
			scores := validator.ValidateWellArchitectedPillars(t)
			
			report["frameworks"].(map[string]interface{})[framework] = map[string]interface{}{
				"pillar_scores": scores,
				"overall_score": calculateOverallScore(scores),
			}
		}
	}

	// Save report
	reportData, err := json.MarshalIndent(report, "", "  ")
	if err == nil {
		reportPath := filepath.Join("compliance-reports", 
			fmt.Sprintf("%s-compliance.json", strings.ReplaceAll(modulePath, "/", "-")))
		os.MkdirAll("compliance-reports", 0755)
		os.WriteFile(reportPath, reportData, 0644)
		t.Logf("Compliance report saved to %s", reportPath)
	}
}

// calculateOverallScore calculates the overall compliance score
func calculateOverallScore(scores map[string]float64) float64 {
	if len(scores) == 0 {
		return 0.0
	}

	total := 0.0
	for _, score := range scores {
		total += score
	}

	return total / float64(len(scores))
}

// ValidateSecurityControls validates security controls implementation
func ValidateSecurityControls(t *testing.T, modulePath string) {
	validator := NewComplianceValidator("security", "multi-cloud", modulePath)

	// Test encryption implementation
	assert.True(t, validator.hasEncryption(), 
		"Module %s should implement encryption", modulePath)

	// Test access controls
	assert.True(t, validator.hasAccessControls(), 
		"Module %s should implement access controls", modulePath)

	// Test network security
	assert.True(t, validator.hasNetworkSecurity(), 
		"Module %s should implement network security", modulePath)

	// Test monitoring
	assert.True(t, validator.hasMonitoring(), 
		"Module %s should implement monitoring", modulePath)
}

// ValidateCostControls validates cost optimization controls
func ValidateCostControls(t *testing.T, modulePath string) {
	validator := NewComplianceValidator("cost", "multi-cloud", modulePath)

	// Test cost monitoring
	assert.True(t, validator.hasCostMonitoring(), 
		"Module %s should implement cost monitoring", modulePath)

	// Test right-sizing
	assert.True(t, validator.hasRightSizing(), 
		"Module %s should implement right-sizing", modulePath)

	// Test cost allocation
	assert.True(t, validator.hasCostAllocation(), 
		"Module %s should implement cost allocation", modulePath)
}

// ValidateGovernanceControls validates governance controls implementation
func ValidateGovernanceControls(t *testing.T, modulePath string) {
	validator := NewComplianceValidator("governance", "multi-cloud", modulePath)

	// Test tagging
	assert.True(t, validator.findInFiles([]string{"tags", "labels"}), 
		"Module %s should implement proper tagging", modulePath)

	// Test documentation
	assert.True(t, validator.hasDocumentation(), 
		"Module %s should have proper documentation", modulePath)

	// Test version control
	assert.True(t, validator.hasVersionControl(), 
		"Module %s should implement version control", modulePath)
}