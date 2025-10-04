package test

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v3"
)

// ComplianceFramework represents a compliance framework configuration
type ComplianceFramework struct {
	Name     string                 `yaml:"name"`
	Version  string                 `yaml:"version"`
	Pillars  map[string][]Control   `yaml:"pillars"`
	Metadata map[string]interface{} `yaml:"metadata"`
}

// Control represents a compliance control
type Control struct {
	ID             string `yaml:"id"`
	Title          string `yaml:"title"`
	Description    string `yaml:"description"`
	Implementation string `yaml:"implementation"`
	Evidence       string `yaml:"evidence"`
	Required       bool   `yaml:"required"`
	Automated      bool   `yaml:"automated"`
}

// ComplianceReport represents the results of a compliance assessment
type ComplianceReport struct {
	Framework    string                    `json:"framework"`
	ModulePath   string                    `json:"module_path"`
	Timestamp    string                    `json:"timestamp"`
	OverallScore float64                   `json:"overall_score"`
	Pillars      map[string]PillarResults  `json:"pillars"`
	Summary      ComplianceSummary         `json:"summary"`
}

// PillarResults represents results for a specific pillar
type PillarResults struct {
	Score    float64          `json:"score"`
	Controls []ControlResults `json:"controls"`
}

// ControlResults represents results for a specific control
type ControlResults struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Status       string `json:"status"` // "pass", "fail", "warning", "not_applicable"
	Evidence     string `json:"evidence"`
	Message      string `json:"message"`
	Automated    bool   `json:"automated"`
	ManualReview bool   `json:"manual_review"`
}

// ComplianceSummary provides a summary of compliance results
type ComplianceSummary struct {
	TotalControls    int `json:"total_controls"`
	PassedControls   int `json:"passed_controls"`
	FailedControls   int `json:"failed_controls"`
	WarningControls  int `json:"warning_controls"`
	SkippedControls  int `json:"skipped_controls"`
}

// TestAWSWellArchitectedCompliance tests AWS Well-Architected Framework compliance
func TestAWSWellArchitectedCompliance(t *testing.T) {
	t.Parallel()

	// Load AWS WAF compliance framework
	framework, err := loadComplianceFramework("../compliance/aws-waf.yaml")
	if err != nil {
		t.Skipf("AWS WAF compliance framework not found: %v", err)
		return
	}

	// Test modules for AWS WAF compliance
	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-aws-waf", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			report := assessModuleCompliance(t, moduleDir, framework, "aws")
			
			// Validate compliance report
			assert.NotNil(t, report, "Compliance report should not be nil")
			assert.GreaterOrEqual(t, report.OverallScore, 0.7, 
				"Module %s should achieve at least 70%% AWS WAF compliance", module)
			
			// Save compliance report
			saveComplianceReport(t, report, fmt.Sprintf("aws-waf-%s.json", 
				strings.ReplaceAll(module, "/", "-")))
		})
	}
}

// TestAzureWellArchitectedCompliance tests Azure Well-Architected Framework compliance
func TestAzureWellArchitectedCompliance(t *testing.T) {
	t.Parallel()

	// Load Azure WAF compliance framework
	framework, err := loadComplianceFramework("../compliance/azure-waf.yaml")
	if err != nil {
		t.Skipf("Azure WAF compliance framework not found: %v", err)
		return
	}

	// Test modules for Azure WAF compliance
	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-azure-waf", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			report := assessModuleCompliance(t, moduleDir, framework, "azure")
			
			// Validate compliance report
			assert.NotNil(t, report, "Compliance report should not be nil")
			assert.GreaterOrEqual(t, report.OverallScore, 0.7, 
				"Module %s should achieve at least 70%% Azure WAF compliance", module)
			
			// Save compliance report
			saveComplianceReport(t, report, fmt.Sprintf("azure-waf-%s.json", 
				strings.ReplaceAll(module, "/", "-")))
		})
	}
}

// TestGCPCloudArchitectureFrameworkCompliance tests GCP Cloud Architecture Framework compliance
func TestGCPCloudArchitectureFrameworkCompliance(t *testing.T) {
	t.Parallel()

	// Load GCP CAF compliance framework
	framework, err := loadComplianceFramework("../compliance/gcp-caf.yaml")
	if err != nil {
		t.Skipf("GCP CAF compliance framework not found: %v", err)
		return
	}

	// Test modules for GCP CAF compliance
	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-gcp-caf", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			report := assessModuleCompliance(t, moduleDir, framework, "gcp")
			
			// Validate compliance report
			assert.NotNil(t, report, "Compliance report should not be nil")
			assert.GreaterOrEqual(t, report.OverallScore, 0.7, 
				"Module %s should achieve at least 70%% GCP CAF compliance", module)
			
			// Save compliance report
			saveComplianceReport(t, report, fmt.Sprintf("gcp-caf-%s.json", 
				strings.ReplaceAll(module, "/", "-")))
		})
	}
}

// TestCostOptimizationCompliance tests cost optimization compliance
func TestCostOptimizationCompliance(t *testing.T) {
	t.Parallel()

	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-cost-optimization", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			
			// Test cost optimization features
			costReport := assessCostOptimization(t, moduleDir)
			
			// Validate cost optimization
			assert.NotNil(t, costReport, "Cost optimization report should not be nil")
			assert.True(t, costReport.HasCostEstimation, 
				"Module %s should include cost estimation", module)
			assert.True(t, costReport.HasBudgetControls, 
				"Module %s should include budget controls", module)
		})
	}
}

// TestSecurityCompliance tests security compliance across all frameworks
func TestSecurityCompliance(t *testing.T) {
	t.Parallel()

	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-security", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			
			// Test security compliance
			securityReport := assessSecurityCompliance(t, moduleDir)
			
			// Validate security compliance
			assert.NotNil(t, securityReport, "Security report should not be nil")
			assert.True(t, securityReport.HasEncryption, 
				"Module %s should implement encryption", module)
			assert.True(t, securityReport.HasAccessControls, 
				"Module %s should implement access controls", module)
			assert.True(t, securityReport.HasMonitoring, 
				"Module %s should implement monitoring", module)
		})
	}
}

// TestGovernanceCompliance tests governance and audit compliance
func TestGovernanceCompliance(t *testing.T) {
	t.Parallel()

	modules := discoverModules(t)
	
	for _, module := range modules {
		module := module // capture range variable
		t.Run(fmt.Sprintf("%s-governance", module), func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)
			
			// Test governance compliance
			govReport := assessGovernanceCompliance(t, moduleDir)
			
			// Validate governance compliance
			assert.NotNil(t, govReport, "Governance report should not be nil")
			assert.True(t, govReport.HasTagging, 
				"Module %s should implement proper tagging", module)
			assert.True(t, govReport.HasAuditTrail, 
				"Module %s should implement audit trails", module)
			assert.True(t, govReport.HasComplianceReporting, 
				"Module %s should generate compliance reports", module)
		})
	}
}

// loadComplianceFramework loads a compliance framework from a YAML file
func loadComplianceFramework(frameworkPath string) (*ComplianceFramework, error) {
	data, err := os.ReadFile(frameworkPath)
	if err != nil {
		return nil, err
	}

	var framework ComplianceFramework
	err = yaml.Unmarshal(data, &framework)
	if err != nil {
		return nil, err
	}

	return &framework, nil
}

// assessModuleCompliance assesses a module against a compliance framework
func assessModuleCompliance(t *testing.T, moduleDir string, framework *ComplianceFramework, cloudProvider string) *ComplianceReport {
	report := &ComplianceReport{
		Framework:  framework.Name,
		ModulePath: moduleDir,
		Timestamp:  "2024-01-01T00:00:00Z", // Use current timestamp in real implementation
		Pillars:    make(map[string]PillarResults),
	}

	totalControls := 0
	passedControls := 0

	// Assess each pillar
	for pillarName, controls := range framework.Pillars {
		pillarResults := PillarResults{
			Controls: make([]ControlResults, 0),
		}

		pillarPassed := 0
		pillarTotal := len(controls)

		for _, control := range controls {
			result := assessControl(t, moduleDir, control, cloudProvider)
			pillarResults.Controls = append(pillarResults.Controls, result)

			if result.Status == "pass" {
				pillarPassed++
				passedControls++
			}
			totalControls++
		}

		if pillarTotal > 0 {
			pillarResults.Score = float64(pillarPassed) / float64(pillarTotal)
		}
		report.Pillars[pillarName] = pillarResults
	}

	// Calculate overall score
	if totalControls > 0 {
		report.OverallScore = float64(passedControls) / float64(totalControls)
	}

	// Generate summary
	report.Summary = ComplianceSummary{
		TotalControls:  totalControls,
		PassedControls: passedControls,
		FailedControls: totalControls - passedControls,
	}

	return report
}

// assessControl assesses a single control against a module
func assessControl(t *testing.T, moduleDir string, control Control, cloudProvider string) ControlResults {
	result := ControlResults{
		ID:        control.ID,
		Title:     control.Title,
		Status:    "not_applicable",
		Evidence:  "",
		Message:   "",
		Automated: control.Automated,
	}

	// Check if control applies to this cloud provider
	if !strings.Contains(strings.ToLower(control.Implementation), cloudProvider) {
		result.Status = "not_applicable"
		result.Message = fmt.Sprintf("Control not applicable to %s", cloudProvider)
		return result
	}

	// Assess control based on evidence
	if control.Evidence != "" {
		evidence := findEvidence(moduleDir, control.Evidence)
		if evidence {
			result.Status = "pass"
			result.Evidence = control.Evidence
			result.Message = "Evidence found in module"
		} else {
			result.Status = "fail"
			result.Message = fmt.Sprintf("Evidence not found: %s", control.Evidence)
		}
	} else {
		result.Status = "warning"
		result.Message = "Manual review required"
		result.ManualReview = true
	}

	return result
}

// findEvidence searches for evidence of a control implementation in the module
func findEvidence(moduleDir, evidencePattern string) bool {
	// Search for evidence in terraform files
	files, err := filepath.Glob(filepath.Join(moduleDir, "*.tf"))
	if err != nil {
		return false
	}

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			continue
		}

		if strings.Contains(string(content), evidencePattern) {
			return true
		}
	}

	return false
}

// CostOptimizationReport represents cost optimization assessment results
type CostOptimizationReport struct {
	ModulePath         string  `json:"module_path"`
	HasCostEstimation  bool    `json:"has_cost_estimation"`
	HasBudgetControls  bool    `json:"has_budget_controls"`
	HasRightSizing     bool    `json:"has_right_sizing"`
	HasScheduling      bool    `json:"has_scheduling"`
	OptimizationScore  float64 `json:"optimization_score"`
}

// assessCostOptimization assesses cost optimization features of a module
func assessCostOptimization(t *testing.T, moduleDir string) *CostOptimizationReport {
	report := &CostOptimizationReport{
		ModulePath: moduleDir,
	}

	// Check for cost estimation
	report.HasCostEstimation = findEvidence(moduleDir, "monthly_cost_estimate") ||
		findEvidence(moduleDir, "pricing")

	// Check for budget controls
	report.HasBudgetControls = findEvidence(moduleDir, "budget") ||
		findEvidence(moduleDir, "cost_threshold")

	// Check for right-sizing
	report.HasRightSizing = findEvidence(moduleDir, "instance_type") ||
		findEvidence(moduleDir, "size")

	// Check for scheduling
	report.HasScheduling = findEvidence(moduleDir, "schedule") ||
		findEvidence(moduleDir, "auto_scaling")

	// Calculate optimization score
	score := 0.0
	if report.HasCostEstimation {
		score += 0.4
	}
	if report.HasBudgetControls {
		score += 0.3
	}
	if report.HasRightSizing {
		score += 0.2
	}
	if report.HasScheduling {
		score += 0.1
	}
	report.OptimizationScore = score

	return report
}

// SecurityComplianceReport represents security compliance assessment results
type SecurityComplianceReport struct {
	ModulePath        string  `json:"module_path"`
	HasEncryption     bool    `json:"has_encryption"`
	HasAccessControls bool    `json:"has_access_controls"`
	HasMonitoring     bool    `json:"has_monitoring"`
	HasNetworkSecurity bool   `json:"has_network_security"`
	SecurityScore     float64 `json:"security_score"`
}

// assessSecurityCompliance assesses security compliance of a module
func assessSecurityCompliance(t *testing.T, moduleDir string) *SecurityComplianceReport {
	report := &SecurityComplianceReport{
		ModulePath: moduleDir,
	}

	// Check for encryption
	report.HasEncryption = findEvidence(moduleDir, "kms_key") ||
		findEvidence(moduleDir, "encryption") ||
		findEvidence(moduleDir, "server_side_encryption")

	// Check for access controls
	report.HasAccessControls = findEvidence(moduleDir, "iam_") ||
		findEvidence(moduleDir, "policy") ||
		findEvidence(moduleDir, "role")

	// Check for monitoring
	report.HasMonitoring = findEvidence(moduleDir, "cloudwatch") ||
		findEvidence(moduleDir, "monitoring") ||
		findEvidence(moduleDir, "alarm")

	// Check for network security
	report.HasNetworkSecurity = findEvidence(moduleDir, "security_group") ||
		findEvidence(moduleDir, "network_acl") ||
		findEvidence(moduleDir, "firewall")

	// Calculate security score
	score := 0.0
	if report.HasEncryption {
		score += 0.3
	}
	if report.HasAccessControls {
		score += 0.3
	}
	if report.HasMonitoring {
		score += 0.2
	}
	if report.HasNetworkSecurity {
		score += 0.2
	}
	report.SecurityScore = score

	return report
}

// GovernanceComplianceReport represents governance compliance assessment results
type GovernanceComplianceReport struct {
	ModulePath            string  `json:"module_path"`
	HasTagging            bool    `json:"has_tagging"`
	HasAuditTrail         bool    `json:"has_audit_trail"`
	HasComplianceReporting bool   `json:"has_compliance_reporting"`
	HasResourceNaming     bool    `json:"has_resource_naming"`
	GovernanceScore       float64 `json:"governance_score"`
}

// assessGovernanceCompliance assesses governance compliance of a module
func assessGovernanceCompliance(t *testing.T, moduleDir string) *GovernanceComplianceReport {
	report := &GovernanceComplianceReport{
		ModulePath: moduleDir,
	}

	// Check for tagging
	report.HasTagging = findEvidence(moduleDir, "tags") ||
		findEvidence(moduleDir, "labels")

	// Check for audit trail
	report.HasAuditTrail = findEvidence(moduleDir, "cloudtrail") ||
		findEvidence(moduleDir, "audit") ||
		findEvidence(moduleDir, "logging")

	// Check for compliance reporting
	report.HasComplianceReporting = findEvidence(moduleDir, "compliance_report") ||
		findEvidence(moduleDir, "governance_metadata")

	// Check for resource naming
	report.HasResourceNaming = findEvidence(moduleDir, "name_prefix") ||
		findEvidence(moduleDir, "naming")

	// Calculate governance score
	score := 0.0
	if report.HasTagging {
		score += 0.3
	}
	if report.HasAuditTrail {
		score += 0.3
	}
	if report.HasComplianceReporting {
		score += 0.2
	}
	if report.HasResourceNaming {
		score += 0.2
	}
	report.GovernanceScore = score

	return report
}

// saveComplianceReport saves a compliance report to a JSON file
func saveComplianceReport(t *testing.T, report *ComplianceReport, filename string) {
	// Create reports directory if it doesn't exist
	reportsDir := "compliance-reports"
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Logf("Warning: Could not create reports directory: %v", err)
		return
	}

	// Save report to file
	reportPath := filepath.Join(reportsDir, filename)
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		t.Logf("Warning: Could not marshal compliance report: %v", err)
		return
	}

	err = os.WriteFile(reportPath, data, 0644)
	if err != nil {
		t.Logf("Warning: Could not save compliance report: %v", err)
		return
	}

	t.Logf("Compliance report saved to %s", reportPath)
}