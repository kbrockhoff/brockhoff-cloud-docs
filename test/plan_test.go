package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformPlanExamples validates that all example configurations can be planned successfully
func TestTerraformPlanExamples(t *testing.T) {
	t.Parallel()

	// Dynamically discover all example directories
	examples := discoverExamples(t)
	
	if len(examples) == 0 {
		t.Skip("No example directories found")
		return
	}

	for _, example := range examples {
		example := example // capture range variable
		t.Run(example, func(t *testing.T) {
			t.Parallel()

			exampleDir := filepath.Join("../examples", example)
			
			terraformOptions := &terraform.Options{
				TerraformDir: exampleDir,
				PlanFilePath: filepath.Join(exampleDir, "plan.out"),
				// Disable backend to avoid state management in tests
				BackendConfig: map[string]interface{}{},
				// Use minimal variable values for testing
				Vars: getTestVariables(example),
			}

			// Run terraform init
			terraform.Init(t, terraformOptions)

			// Run terraform plan - this validates syntax and configuration
			terraform.Plan(t, terraformOptions)

			// If we get here, the plan succeeded
			assert.True(t, true, "Terraform plan completed successfully for %s example", example)
		})
	}
}

// TestTerraformPlanModules validates that all module configurations can be planned successfully
func TestTerraformPlanModules(t *testing.T) {
	t.Parallel()

	// Dynamically discover all module directories
	modules := discoverModules(t)
	
	if len(modules) == 0 {
		t.Skip("No module directories found")
		return
	}

	for _, module := range modules {
		module := module // capture range variable
		t.Run(module, func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)

			terraformOptions := &terraform.Options{
				TerraformDir: moduleDir,
				PlanFilePath: filepath.Join(moduleDir, "plan.out"),
				BackendConfig: map[string]interface{}{},
				Vars: getModuleTestVariables(module),
			}

			// Run terraform init
			terraform.Init(t, terraformOptions)

			// Run terraform plan
			terraform.Plan(t, terraformOptions)

			// If we get here, the plan succeeded
			assert.True(t, true, "Terraform plan completed successfully for %s module", module)
		})
	}
}

// TestModuleStandards validates that modules follow required standards
func TestModuleStandards(t *testing.T) {
	t.Parallel()

	// Define required files for each module
	requiredFiles := []string{
		"main.tf",
		"variables.tf", 
		"outputs.tf",
		"versions.tf",
		"README.md",
	}

	modules := discoverModules(t)
	
	if len(modules) == 0 {
		t.Skip("No module directories found")
		return
	}

	for _, module := range modules {
		module := module // capture range variable
		t.Run(module, func(t *testing.T) {
			t.Parallel()

			moduleDir := filepath.Join("..", module)

			// Check that all required files exist
			for _, file := range requiredFiles {
				filePath := filepath.Join(moduleDir, file)
				assert.FileExists(t, filePath, "Required file %s missing in module %s", file, module)
			}
		})
	}
}

// TestTerraformValidation validates terraform syntax for all configurations
func TestTerraformValidation(t *testing.T) {
	t.Parallel()

	// Test all directories with terraform files
	terraformDirs := discoverTerraformDirectories(t)
	
	if len(terraformDirs) == 0 {
		t.Skip("No terraform directories found")
		return
	}

	for _, dir := range terraformDirs {
		dir := dir // capture range variable
		t.Run(dir, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: filepath.Join("..", dir),
				BackendConfig: map[string]interface{}{},
			}

			// Run terraform init and validate
			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)

			assert.True(t, true, "Terraform validation completed successfully for %s", dir)
		})
	}
}

// TestTerraformFormat validates that all terraform files are properly formatted
func TestTerraformFormat(t *testing.T) {
	t.Parallel()

	// Check format for all terraform files
	terraformDirs := discoverTerraformDirectories(t)
	
	if len(terraformDirs) == 0 {
		t.Skip("No terraform directories found")
		return
	}

	for _, dir := range terraformDirs {
		dir := dir // capture range variable
		t.Run(dir, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: filepath.Join("..", dir),
			}

			// Check if files are formatted
			terraform.RunTerraformCommand(t, terraformOptions, "fmt", "-check", "-diff")

			assert.True(t, true, "Terraform format check completed successfully for %s", dir)
		})
	}
}

// Helper function to discover all example directories
func discoverExamples(t *testing.T) []string {
	var examples []string
	examplesDir := "../examples"
	
	err := filepath.Walk(examplesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip directories we can't access
		}
		
		if info.IsDir() && strings.Contains(path, "main.tf") {
			return nil
		}
		
		if filepath.Base(path) == "main.tf" {
			relPath, _ := filepath.Rel(examplesDir, filepath.Dir(path))
			if relPath != "." {
				examples = append(examples, relPath)
			}
		}
		
		return nil
	})
	
	if err != nil {
		t.Logf("Warning: Could not walk examples directory: %v", err)
	}
	
	return examples
}

// Helper function to discover all module directories
func discoverModules(t *testing.T) []string {
	var modules []string
	modulesDir := "../modules"
	
	err := filepath.Walk(modulesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip directories we can't access
		}
		
		if filepath.Base(path) == "main.tf" {
			relPath, _ := filepath.Rel("..", filepath.Dir(path))
			if relPath != "." && strings.HasPrefix(relPath, "modules/") {
				modules = append(modules, relPath)
			}
		}
		
		return nil
	})
	
	if err != nil {
		t.Logf("Warning: Could not walk modules directory: %v", err)
	}
	
	return modules
}

// Helper function to discover all terraform directories
func discoverTerraformDirectories(t *testing.T) []string {
	var dirs []string
	
	err := filepath.Walk("..", func(path string, info os.FileInfo, err error) error {
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
			relPath, _ := filepath.Rel("..", filepath.Dir(path))
			if relPath != "." {
				dirs = append(dirs, relPath)
			}
		}
		
		return nil
	})
	
	if err != nil {
		t.Logf("Warning: Could not walk directory tree: %v", err)
	}
	
	return dirs
}

// Helper function to get test variables for examples
func getTestVariables(example string) map[string]interface{} {
	baseVars := map[string]interface{}{
		"name":        "test-" + strings.ReplaceAll(example, "/", "-"),
		"environment": "test",
	}
	
	// Add example-specific variables
	switch {
	case strings.Contains(example, "context-integration"):
		baseVars["namespace"] = "test"
		baseVars["create_aws_resources"] = false
		baseVars["create_azure_resources"] = false
		baseVars["create_gcp_resources"] = false
	case strings.Contains(example, "multi-cloud"):
		baseVars["cloud_providers"] = []string{"aws"}
	case strings.Contains(example, "portal-integration"):
		baseVars["enable_portal_integration"] = true
	}
	
	return baseVars
}

// Helper function to get test variables for modules
func getModuleTestVariables(module string) map[string]interface{} {
	baseVars := map[string]interface{}{
		"name_prefix": "test-" + strings.ReplaceAll(module, "/", "-"),
		"tags": map[string]interface{}{
			"Environment": "Test",
			"Module":      module,
		},
	}
	
	// Add module-specific variables
	switch {
	case strings.Contains(module, "context-validation"):
		baseVars["cloud_provider"] = "aws"
		baseVars["random_suffix"] = "test1234"
	case strings.Contains(module, "compliance-reporting"):
		baseVars["compliance_frameworks"] = []string{"aws-waf"}
	case strings.Contains(module, "pricing"):
		baseVars["enable_cost_estimation"] = true
	}
	
	return baseVars
}