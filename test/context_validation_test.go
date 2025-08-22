package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestContextValidationAWS tests AWS-specific context validation
func TestContextValidationAWS(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "myorg-prod-webapp",
			"cloud_provider": "aws",
			"tags": map[string]interface{}{
				"Environment": "Production",
				"Project":     "WebApp",
				"Owner":       "DevTeam",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	// Initialize and plan
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	// Apply to get outputs
	terraform.Apply(t, terraformOptions)

	// Test outputs
	cloudProvider := terraform.Output(t, terraformOptions, "cloud_provider")
	assert.Equal(t, "aws", cloudProvider)

	validationResults := terraform.OutputMap(t, terraformOptions, "validation_results")
	assert.Equal(t, "true", validationResults["all_valid"])
	assert.Equal(t, "true", validationResults["name_valid"])
	assert.Equal(t, "true", validationResults["name_length_ok"])

	resourceNames := terraform.OutputMap(t, terraformOptions, "resource_names")
	assert.Contains(t, resourceNames["aws_s3_bucket"], "myorg-prod-webapp-bucket")
	assert.Equal(t, "myorg-prod-webapp-role", resourceNames["aws_iam_role"])
}

// TestContextValidationAzure tests Azure-specific context validation
func TestContextValidationAzure(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "myorg-prod-webapp",
			"cloud_provider": "azure",
			"tags": map[string]interface{}{
				"Environment": "Production",
				"Project":     "WebApp",
				"CostCenter":  "Engineering",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	cloudProvider := terraform.Output(t, terraformOptions, "cloud_provider")
	assert.Equal(t, "azure", cloudProvider)

	validationResults := terraform.OutputMap(t, terraformOptions, "validation_results")
	assert.Equal(t, "true", validationResults["all_valid"])

	resourceNames := terraform.OutputMap(t, terraformOptions, "resource_names")
	assert.Regexp(t, "^[a-z0-9]{3,24}$", resourceNames["azure_storage_account"])
	assert.Equal(t, "myorg-prod-webapp-rg", resourceNames["azure_resource_group"])
}

// TestContextValidationGCP tests GCP-specific context validation
func TestContextValidationGCP(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "myorg-prod-webapp",
			"cloud_provider": "gcp",
			"tags": map[string]interface{}{
				"environment": "production",
				"project":     "webapp",
				"team":        "devteam",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	cloudProvider := terraform.Output(t, terraformOptions, "cloud_provider")
	assert.Equal(t, "gcp", cloudProvider)

	validationResults := terraform.OutputMap(t, terraformOptions, "validation_results")
	assert.Equal(t, "true", validationResults["all_valid"])

	resourceNames := terraform.OutputMap(t, terraformOptions, "resource_names")
	assert.Contains(t, resourceNames["gcp_storage_bucket"], "myorg-prod-webapp-bucket")
	assert.Equal(t, "myorg-prod-webapp-sa", resourceNames["gcp_service_account"])
}

// TestContextValidationInvalidAWSName tests AWS name validation failure
func TestContextValidationInvalidAWSName(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "-invalid-aws-name-",  // Invalid: starts and ends with hyphen
			"cloud_provider": "aws",
			"tags": map[string]interface{}{
				"Environment": "Test",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	// This should fail during plan due to validation
	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Generated name")
}

// TestContextValidationInvalidAzureStorageName tests Azure storage name validation
func TestContextValidationInvalidAzureStorageName(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "MyOrg-With-Hyphens-That-Will-Be-Too-Long-For-Azure-Storage",
			"cloud_provider": "azure",
			"tags": map[string]interface{}{
				"Environment": "Test",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	// Should still validate overall, but storage name should be truncated
	validationResults := terraform.OutputMap(t, terraformOptions, "validation_results")
	assert.Equal(t, "true", validationResults["all_valid"])

	resourceNames := terraform.OutputMap(t, terraformOptions, "resource_names")
	storageAccountName := resourceNames["azure_storage_account"]
	assert.LessOrEqual(t, len(storageAccountName), 24)
	assert.Regexp(t, "^[a-z0-9]+$", storageAccountName)
}

// TestContextValidationInvalidGCPName tests GCP name validation failure
func TestContextValidationInvalidGCPName(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "MyOrg-UPPERCASE-Name",  // Invalid: GCP requires lowercase
			"cloud_provider": "gcp",
			"tags": map[string]interface{}{
				"environment": "test",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "lowercase")
}

// TestContextValidationTooManyTags tests tag limit validation
func TestContextValidationTooManyTags(t *testing.T) {
	t.Parallel()

	// Create more than 50 tags
	tags := make(map[string]interface{})
	for i := 0; i < 55; i++ {
		tags[fmt.Sprintf("Tag%d", i)] = fmt.Sprintf("Value%d", i)
	}

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "test-too-many-tags",
			"cloud_provider": "aws",
			"tags":           tags,
			"random_suffix":  "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "maximum")
}

// TestContextValidationCrossCloudCompatibility tests cross-cloud compatibility validation
func TestContextValidationCrossCloudCompatibility(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix": "myorg-prod-webapp",
			"tags": map[string]interface{}{
				"Environment": "Production",
				"Project":     "WebApp",
				"Owner":       "DevTeam",
			},
			"enforce_cross_cloud_compatibility": true,
			"random_suffix":                     "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	crossCloudCompatible := terraform.Output(t, terraformOptions, "cross_cloud_compatible")
	assert.Equal(t, "true", crossCloudCompatible)

	validationResults := terraform.OutputMap(t, terraformOptions, "validation_results")
	assert.Equal(t, "true", validationResults["all_valid"])
}

// TestContextValidationIncompatibleCrossCloud tests cross-cloud compatibility failure
func TestContextValidationIncompatibleCrossCloud(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix": "this-is-a-very-long-name-that-exceeds-fifty-characters-and-should-fail-cross-cloud-validation",
			"tags": map[string]interface{}{
				"Environment": "Test",
			},
			"enforce_cross_cloud_compatibility": true,
			"random_suffix":                     "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Cross-cloud compatibility")
}

// TestContextValidationHelperFunctions tests helper function outputs
func TestContextValidationHelperFunctions(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix":    "test-helpers",
			"cloud_provider": "aws",
			"tags": map[string]interface{}{
				"Environment": "Test",
				"Project":     "Helpers",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	helperFunctions := terraform.OutputMap(t, terraformOptions, "helper_functions")
	assert.NotEmpty(t, helperFunctions)

	// Test naming utilities
	namingUtilities := helperFunctions["naming_utilities"].(map[string]interface{})
	assert.Equal(t, "test-helpers", namingUtilities["aws_format"])
	assert.Equal(t, "test-helpers", namingUtilities["azure_format"])
	assert.Equal(t, "test-helpers", namingUtilities["gcp_format"])

	// Test metadata utilities
	metadataUtilities := helperFunctions["metadata_utilities"].(map[string]interface{})
	assert.NotEmpty(t, metadataUtilities["aws_tags"])
	assert.NotEmpty(t, metadataUtilities["required_metadata"])
}

// TestContextValidationRecommendations tests recommendation outputs
func TestContextValidationRecommendations(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "context-validation"),
		Vars: map[string]interface{}{
			"name_prefix": "this-is-a-very-long-name-that-should-generate-recommendations",
			"tags": map[string]interface{}{
				"Environment": "Test",
			},
			"random_suffix": "abcd1234",
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	recommendations := terraform.OutputMap(t, terraformOptions, "recommendations")
	assert.NotEmpty(t, recommendations)

	nameRecommendations := recommendations["name_recommendations"].([]interface{})
	assert.NotEmpty(t, nameRecommendations)
	assert.Contains(t, nameRecommendations[0].(string), "shortening")
}

// TestMultiCloudContextIntegration tests the multi-cloud example integration
func TestMultiCloudContextIntegration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: filepath.Join("..", "examples", "context-integration", "multi-cloud"),
		Vars: map[string]interface{}{
			"namespace":             "test",
			"environment":           "ci",
			"name":                  "validation",
			"create_aws_resources":   true,
			"create_azure_resources": false,
			"create_gcp_resources":   false,
		},
		BackendConfig: map[string]interface{}{},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	// Verify plan succeeds - this validates the integration
	assert.True(t, true, "Multi-cloud context integration plan completed successfully")
}