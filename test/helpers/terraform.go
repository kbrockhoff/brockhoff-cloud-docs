package helpers

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TerraformTestOptions provides common configuration for terraform tests
type TerraformTestOptions struct {
	TerraformDir  string
	Vars          map[string]interface{}
	BackendConfig map[string]interface{}
	PlanFilePath  string
}

// NewTerraformTestOptions creates a new TerraformTestOptions with sensible defaults
func NewTerraformTestOptions(terraformDir string) *TerraformTestOptions {
	return &TerraformTestOptions{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"name":        "test-" + strings.ReplaceAll(filepath.Base(terraformDir), "/", "-"),
			"environment": "test",
		},
		BackendConfig: map[string]interface{}{},
		PlanFilePath:  filepath.Join(terraformDir, "plan.out"),
	}
}

// ToTerraformOptions converts TerraformTestOptions to terratest terraform.Options
func (opts *TerraformTestOptions) ToTerraformOptions() *terraform.Options {
	return &terraform.Options{
		TerraformDir:  opts.TerraformDir,
		Vars:          opts.Vars,
		BackendConfig: opts.BackendConfig,
		PlanFilePath:  opts.PlanFilePath,
	}
}

// InitAndPlan initializes terraform and runs plan, returning the plan struct
func InitAndPlan(t *testing.T, opts *TerraformTestOptions) *terraform.PlanStruct {
	terraformOptions := opts.ToTerraformOptions()
	
	// Initialize terraform
	terraform.Init(t, terraformOptions)
	
	// Run plan and return the plan struct
	return terraform.InitAndPlan(t, terraformOptions)
}

// ValidatePlan validates that a terraform plan is valid and contains expected resources
func ValidatePlan(t *testing.T, plan *terraform.PlanStruct, expectedResources int) {
	assert.NotNil(t, plan, "Plan should not be nil")
	
	if expectedResources > 0 {
		assert.GreaterOrEqual(t, len(plan.PlannedValues.RootModule.Resources), expectedResources,
			"Plan should contain at least %d resources", expectedResources)
	}
}

// ValidateNoDestroy validates that a terraform plan contains no destroy operations
func ValidateNoDestroy(t *testing.T, plan *terraform.PlanStruct) {
	for _, change := range plan.ResourceChanges {
		assert.NotEqual(t, "delete", change.Change.Actions[0],
			"Plan should not contain destroy operations for resource %s", change.Address)
	}
}

// ValidateResourceExists validates that a specific resource exists in the plan
func ValidateResourceExists(t *testing.T, plan *terraform.PlanStruct, resourceType, resourceName string) {
	resourceAddress := fmt.Sprintf("%s.%s", resourceType, resourceName)
	found := false
	
	for _, resource := range plan.PlannedValues.RootModule.Resources {
		if resource.Address == resourceAddress {
			found = true
			break
		}
	}
	
	assert.True(t, found, "Resource %s should exist in plan", resourceAddress)
}

// ValidateOutputExists validates that a specific output exists in the plan
func ValidateOutputExists(t *testing.T, plan *terraform.PlanStruct, outputName string) {
	_, exists := plan.PlannedValues.Outputs[outputName]
	assert.True(t, exists, "Output %s should exist in plan", outputName)
}

// RunTerraformCommand runs a terraform command and returns the output
func RunTerraformCommand(t *testing.T, opts *TerraformTestOptions, args ...string) string {
	terraformOptions := opts.ToTerraformOptions()
	return terraform.RunTerraformCommand(t, terraformOptions, args...)
}

// ValidateFormat validates that terraform files are properly formatted
func ValidateFormat(t *testing.T, terraformDir string) {
	opts := NewTerraformTestOptions(terraformDir)
	
	// Run terraform fmt -check
	output := RunTerraformCommand(t, opts, "fmt", "-check", "-diff")
	
	// If output is not empty, files are not formatted
	assert.Empty(t, strings.TrimSpace(output), 
		"Terraform files in %s are not properly formatted. Run 'terraform fmt' to fix.", terraformDir)
}

// ValidateSyntax validates terraform syntax by running terraform validate
func ValidateSyntax(t *testing.T, terraformDir string) {
	opts := NewTerraformTestOptions(terraformDir)
	terraformOptions := opts.ToTerraformOptions()
	
	// Initialize and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// DiscoverTerraformDirectories finds all directories containing terraform files
func DiscoverTerraformDirectories(rootDir string) ([]string, error) {
	var dirs []string
	
	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip directories we can't access
		}
		
		// Skip .git, .terraform, and test directories
		if info.IsDir() && (strings.Contains(path, ".git") || 
			strings.Contains(path, ".terraform") || 
			strings.Contains(path, "test")) {
			return filepath.SkipDir
		}
		
		if filepath.Base(path) == "main.tf" {
			relPath, _ := filepath.Rel(rootDir, filepath.Dir(path))
			if relPath != "." {
				dirs = append(dirs, relPath)
			}
		}
		
		return nil
	})
	
	return dirs, err
}

// GetTestVariablesForDirectory returns appropriate test variables based on directory type
func GetTestVariablesForDirectory(dir string) map[string]interface{} {
	baseVars := map[string]interface{}{
		"name":        "test-" + strings.ReplaceAll(dir, "/", "-"),
		"environment": "test",
	}
	
	// Add directory-specific variables
	switch {
	case strings.Contains(dir, "examples"):
		return getExampleVariables(dir, baseVars)
	case strings.Contains(dir, "modules"):
		return getModuleVariables(dir, baseVars)
	default:
		return baseVars
	}
}

// getExampleVariables returns variables specific to example directories
func getExampleVariables(dir string, baseVars map[string]interface{}) map[string]interface{} {
	switch {
	case strings.Contains(dir, "context-integration"):
		baseVars["namespace"] = "test"
		baseVars["create_aws_resources"] = false
		baseVars["create_azure_resources"] = false
		baseVars["create_gcp_resources"] = false
	case strings.Contains(dir, "multi-cloud"):
		baseVars["cloud_providers"] = []string{"aws"}
	case strings.Contains(dir, "portal-integration"):
		baseVars["enable_portal_integration"] = true
	}
	
	return baseVars
}

// getModuleVariables returns variables specific to module directories
func getModuleVariables(dir string, baseVars map[string]interface{}) map[string]interface{} {
	// Convert name to name_prefix for modules
	baseVars["name_prefix"] = baseVars["name"]
	delete(baseVars, "name")
	
	// Add standard module variables
	baseVars["tags"] = map[string]interface{}{
		"Environment": "Test",
		"Module":      dir,
	}
	
	switch {
	case strings.Contains(dir, "context-validation"):
		baseVars["cloud_provider"] = "aws"
		baseVars["random_suffix"] = "test1234"
	case strings.Contains(dir, "compliance-reporting"):
		baseVars["compliance_frameworks"] = []string{"aws-waf"}
	case strings.Contains(dir, "pricing"):
		baseVars["enable_cost_estimation"] = true
	}
	
	return baseVars
}