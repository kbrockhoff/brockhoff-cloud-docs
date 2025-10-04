# Test configuration for context validation module

# Mock providers for testing
provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true

  # Mock configuration
  client_id       = "00000000-0000-0000-0000-000000000000"
  client_secret   = "mock_secret"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

provider "google" {
  project = "mock-project"
  region  = "us-central1"
  credentials = jsonencode({
    type           = "service_account"
    project_id     = "mock-project"
    private_key_id = "mock-key-id"
    private_key    = "-----BEGIN PRIVATE KEY-----\nMOCK_PRIVATE_KEY\n-----END PRIVATE KEY-----\n"
    client_email   = "mock@mock-project.iam.gserviceaccount.com"
    client_id      = "000000000000000000000"
    auth_uri       = "https://accounts.google.com/o/oauth2/auth"
    token_uri      = "https://oauth2.googleapis.com/token"
  })
}

# Test the module with AWS configuration
module "test_aws" {
  source = "./"

  name_prefix    = "test-aws-validation"
  cloud_provider = "aws"

  tags = {
    Environment = "Test"
    Project     = "ContextValidation"
    Owner       = "DevTeam"
  }

  random_suffix = "abcd1234"
}

# Test the module with Azure configuration
module "test_azure" {
  source = "./"

  name_prefix    = "test-azure-validation"
  cloud_provider = "azure"

  tags = {
    Environment = "Test"
    Project     = "ContextValidation"
    CostCenter  = "Engineering"
  }

  random_suffix = "abcd1234"
}

# Test the module with GCP configuration
module "test_gcp" {
  source = "./"

  name_prefix    = "test-gcp-validation"
  cloud_provider = "gcp"

  tags = {
    environment = "test"
    project     = "context-validation"
    team        = "devteam"
  }

  random_suffix = "abcd1234"
}

# Test cross-cloud compatibility
module "test_cross_cloud" {
  source = "./"

  name_prefix = "test-cross-cloud"

  tags = {
    Environment = "Test"
    Project     = "CrossCloud"
  }

  enforce_cross_cloud_compatibility = true
  random_suffix                     = "abcd1234"
}

# Outputs for testing
output "aws_test_results" {
  value = {
    cloud_provider     = module.test_aws.cloud_provider
    validation_results = module.test_aws.validation_results
    resource_names     = module.test_aws.resource_names
  }
}

output "azure_test_results" {
  value = {
    cloud_provider     = module.test_azure.cloud_provider
    validation_results = module.test_azure.validation_results
    resource_names     = module.test_azure.resource_names
  }
}

output "gcp_test_results" {
  value = {
    cloud_provider     = module.test_gcp.cloud_provider
    validation_results = module.test_gcp.validation_results
    resource_names     = module.test_gcp.resource_names
  }
}

output "cross_cloud_test_results" {
  value = {
    cloud_provider         = module.test_cross_cloud.cloud_provider
    cross_cloud_compatible = module.test_cross_cloud.cross_cloud_compatible
    validation_results     = module.test_cross_cloud.validation_results
  }
}