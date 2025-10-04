package helpers

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

// ModuleStandards defines the required files and structure for a terraform module
type ModuleStandards struct {
	RequiredFiles     []string
	RequiredDirs      []string
	OptionalFiles     []string
	ForbiddenFiles    []string
	NamingPatterns    map[string]*regexp.Regexp
	ContentValidators map[string]func(content string) error
}

// DefaultModuleStandards returns the default standards for Brockhoff Cloud modules
func DefaultModuleStandards() *ModuleStandards {
	return &ModuleStandards{
		RequiredFiles: []string{
			"main.tf",
			"variables.tf",
			"outputs.tf",
			"versions.tf",
			"README.md",
		},
		RequiredDirs: []string{},
		OptionalFiles: []string{
			"locals.tf",
			"data.tf",
			"kms.tf",
			"alarms.tf",
			"pricing.tf",
			"LICENSE",
			"CHANGELOG.md",
			"Makefile",
			".terraform-docs.yml",
			".tflint.hcl",
		},
		ForbiddenFiles: []string{
			".terraform.lock.hcl",
			"terraform.tfstate",
			"terraform.tfstate.backup",
		},
		NamingPatterns: map[string]*regexp.Regexp{
			"variables.tf": regexp.MustCompile(`variable\s+"[a-z_]+"`),
			"outputs.tf":   regexp.MustCompile(`output\s+"[a-z_]+"`),
		},
		ContentValidators: map[string]func(content string) error{
			"variables.tf": validateVariablesFile,
			"outputs.tf":   validateOutputsFile,
			"versions.tf":  validateVersionsFile,
			"README.md":    validateReadmeFile,
		},
	}
}

// ValidateModuleStructure validates that a module follows the required standards
func ValidateModuleStructure(t *testing.T, modulePath string, standards *ModuleStandards) {
	if standards == nil {
		standards = DefaultModuleStandards()
	}
	
	// Check required files exist
	for _, file := range standards.RequiredFiles {
		filePath := filepath.Join(modulePath, file)
		assert.FileExists(t, filePath, "Required file %s missing in module %s", file, modulePath)
	}
	
	// Check required directories exist
	for _, dir := range standards.RequiredDirs {
		dirPath := filepath.Join(modulePath, dir)
		assert.DirExists(t, dirPath, "Required directory %s missing in module %s", dir, modulePath)
	}
	
	// Check forbidden files don't exist
	for _, file := range standards.ForbiddenFiles {
		filePath := filepath.Join(modulePath, file)
		assert.NoFileExists(t, filePath, "Forbidden file %s found in module %s", file, modulePath)
	}
	
	// Validate file contents
	for file, validator := range standards.ContentValidators {
		filePath := filepath.Join(modulePath, file)
		if _, err := os.Stat(filePath); err == nil {
			content, err := os.ReadFile(filePath)
			assert.NoError(t, err, "Failed to read file %s", filePath)
			
			if err == nil {
				err = validator(string(content))
				assert.NoError(t, err, "Content validation failed for %s: %v", filePath, err)
			}
		}
	}
}

// ValidateVariables validates variable definitions in a terraform file
func ValidateVariables(t *testing.T, variablesFile string) {
	content, err := os.ReadFile(variablesFile)
	assert.NoError(t, err, "Failed to read variables file %s", variablesFile)
	
	if err == nil {
		err = validateVariablesFile(string(content))
		assert.NoError(t, err, "Variables file validation failed: %v", err)
	}
}

// ValidateOutputs validates output definitions in a terraform file
func ValidateOutputs(t *testing.T, outputsFile string) {
	content, err := os.ReadFile(outputsFile)
	assert.NoError(t, err, "Failed to read outputs file %s", outputsFile)
	
	if err == nil {
		err = validateOutputsFile(string(content))
		assert.NoError(t, err, "Outputs file validation failed: %v", err)
	}
}

// ValidateNamingConventions validates that resource names follow conventions
func ValidateNamingConventions(t *testing.T, terraformDir string) {
	// Check for consistent naming patterns
	files, err := filepath.Glob(filepath.Join(terraformDir, "*.tf"))
	assert.NoError(t, err, "Failed to list terraform files in %s", terraformDir)
	
	for _, file := range files {
		content, err := os.ReadFile(file)
		assert.NoError(t, err, "Failed to read file %s", file)
		
		if err == nil {
			validateNamingInFile(t, file, string(content))
		}
	}
}

// ValidateLicenseHeaders validates that files contain proper license headers
func ValidateLicenseHeaders(t *testing.T, terraformDir string) {
	files, err := filepath.Glob(filepath.Join(terraformDir, "*.tf"))
	assert.NoError(t, err, "Failed to list terraform files in %s", terraformDir)
	
	for _, file := range files {
		content, err := os.ReadFile(file)
		assert.NoError(t, err, "Failed to read file %s", file)
		
		if err == nil {
			// Check for license header or copyright notice
			contentStr := string(content)
			hasLicense := strings.Contains(contentStr, "Licensed under") ||
				strings.Contains(contentStr, "Copyright") ||
				strings.Contains(contentStr, "Apache License")
			
			// For now, just log if no license found (not required for all files)
			if !hasLicense {
				t.Logf("No license header found in %s", file)
			}
		}
	}
}

// validateVariablesFile validates the content of a variables.tf file
func validateVariablesFile(content string) error {
	// Check for required variable patterns
	requiredPatterns := []string{
		`variable\s+"enabled"`,           // enabled variable
		`variable\s+"name_prefix"`,       // name_prefix variable
		`variable\s+"tags"`,              // tags variable
		`variable\s+"environment_type"`,  // environment_type variable
	}
	
	for _, pattern := range requiredPatterns {
		matched, err := regexp.MatchString(pattern, content)
		if err != nil {
			return fmt.Errorf("regex error for pattern %s: %v", pattern, err)
		}
		if !matched {
			return fmt.Errorf("required variable pattern not found: %s", pattern)
		}
	}
	
	// Check for variable descriptions
	if !strings.Contains(content, "description") {
		return fmt.Errorf("variables should have descriptions")
	}
	
	return nil
}

// validateOutputsFile validates the content of an outputs.tf file
func validateOutputsFile(content string) error {
	// Check that outputs have descriptions
	outputPattern := regexp.MustCompile(`output\s+"([^"]+)"\s*{`)
	outputs := outputPattern.FindAllStringSubmatch(content, -1)
	
	for _, output := range outputs {
		outputName := output[1]
		// Check if this output has a description
		descPattern := fmt.Sprintf(`output\s+"%s"\s*{[^}]*description\s*=`, outputName)
		matched, err := regexp.MatchString(descPattern, content)
		if err != nil {
			return fmt.Errorf("regex error checking description for output %s: %v", outputName, err)
		}
		if !matched {
			return fmt.Errorf("output %s should have a description", outputName)
		}
	}
	
	return nil
}

// validateVersionsFile validates the content of a versions.tf file
func validateVersionsFile(content string) error {
	// Check for terraform version constraint
	if !strings.Contains(content, "required_version") {
		return fmt.Errorf("versions.tf should specify required_version")
	}
	
	// Check for required providers
	if !strings.Contains(content, "required_providers") {
		return fmt.Errorf("versions.tf should specify required_providers")
	}
	
	return nil
}

// validateReadmeFile validates the content of a README.md file
func validateReadmeFile(content string) error {
	// Check for basic sections
	requiredSections := []string{
		"# ",           // Title
		"## Usage",     // Usage section
		"## Inputs",    // Inputs section
		"## Outputs",   // Outputs section
	}
	
	for _, section := range requiredSections {
		if !strings.Contains(content, section) {
			return fmt.Errorf("README.md should contain section: %s", section)
		}
	}
	
	return nil
}

// validateNamingInFile validates naming conventions within a terraform file
func validateNamingInFile(t *testing.T, filename, content string) {
	// Check resource naming conventions
	resourcePattern := regexp.MustCompile(`resource\s+"([^"]+)"\s+"([^"]+)"`)
	resources := resourcePattern.FindAllStringSubmatch(content, -1)
	
	for _, resource := range resources {
		resourceType := resource[1]
		resourceName := resource[2]
		
		// Resource names should be snake_case
		if !regexp.MustCompile(`^[a-z][a-z0-9_]*$`).MatchString(resourceName) {
			t.Errorf("Resource name %s in %s should be snake_case", resourceName, filename)
		}
		
		// Common resource names should follow patterns
		switch resourceType {
		case "aws_s3_bucket", "azurerm_storage_account", "google_storage_bucket":
			if !strings.Contains(resourceName, "main") && !strings.Contains(resourceName, "bucket") {
				t.Logf("Storage resource %s might benefit from more descriptive naming", resourceName)
			}
		}
	}
	
	// Check variable naming conventions
	variablePattern := regexp.MustCompile(`variable\s+"([^"]+)"`)
	variables := variablePattern.FindAllStringSubmatch(content, -1)
	
	for _, variable := range variables {
		variableName := variable[1]
		
		// Variable names should be snake_case
		if !regexp.MustCompile(`^[a-z][a-z0-9_]*$`).MatchString(variableName) {
			t.Errorf("Variable name %s in %s should be snake_case", variableName, filename)
		}
	}
}

// ValidateExampleStructure validates that examples follow the required structure
func ValidateExampleStructure(t *testing.T, examplePath string) {
	requiredFiles := []string{
		"main.tf",
		"variables.tf",
		"outputs.tf",
		"README.md",
	}
	
	optionalFiles := []string{
		"terraform.tfvars.example",
		"versions.tf",
	}
	
	// Check required files
	for _, file := range requiredFiles {
		filePath := filepath.Join(examplePath, file)
		assert.FileExists(t, filePath, "Required file %s missing in example %s", file, examplePath)
	}
	
	// Log optional files that exist
	for _, file := range optionalFiles {
		filePath := filepath.Join(examplePath, file)
		if _, err := os.Stat(filePath); err == nil {
			t.Logf("Optional file %s found in example %s", file, examplePath)
		}
	}
}

// ValidateDocumentation validates that documentation is comprehensive
func ValidateDocumentation(t *testing.T, moduleOrExamplePath string) {
	readmePath := filepath.Join(moduleOrExamplePath, "README.md")
	
	if _, err := os.Stat(readmePath); os.IsNotExist(err) {
		t.Errorf("README.md missing in %s", moduleOrExamplePath)
		return
	}
	
	content, err := os.ReadFile(readmePath)
	assert.NoError(t, err, "Failed to read README.md in %s", moduleOrExamplePath)
	
	if err == nil {
		err = validateReadmeFile(string(content))
		assert.NoError(t, err, "README.md validation failed in %s: %v", moduleOrExamplePath, err)
	}
}