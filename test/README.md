# Testing Framework

This directory contains the testing framework for the Brockhoff Cloud Terraform module suite. We use a simplified, fast testing approach focused on plan validation rather than expensive integration tests.

## Testing Philosophy

Our testing strategy prioritizes:
- **Speed**: Tests complete in seconds, not minutes
- **Cost-Effectiveness**: No cloud resources are created during testing
- **Comprehensive Coverage**: All modules and examples are validated
- **CI/CD Integration**: Tests run automatically on every commit

## Test Structure

```
test/
├── README.md           # This file
├── go.mod              # Go module definition
├── go.sum              # Go module checksums
├── plan_test.go        # Main test file
├── helpers/            # Test helper functions
│   ├── terraform.go    # Terraform execution helpers
│   └── validation.go   # Validation utilities
└── fixtures/           # Test data and configurations
    ├── basic/          # Basic test scenarios
    ├── advanced/       # Advanced test scenarios
    └── invalid/        # Invalid configurations for negative testing
```

## Test Types

### Plan Tests
Validate that Terraform configurations are syntactically correct and can generate valid execution plans.

```go
func TestTerraformPlanExamples(t *testing.T) {
    examples := []string{"basic-compute", "basic-storage", "basic-networking"}
    
    for _, example := range examples {
        t.Run(example, func(t *testing.T) {
            // Run terraform init and plan
            // Validate plan succeeds without errors
        })
    }
}
```

### Validation Tests
Ensure modules follow coding standards and best practices.

```go
func TestModuleStandards(t *testing.T) {
    // Check required files exist
    // Validate variable descriptions
    // Verify output documentation
    // Confirm license headers
}
```

### Security Tests
Validate security configurations and compliance.

```go
func TestSecurityCompliance(t *testing.T) {
    // Check encryption configurations
    // Validate IAM policies
    // Verify network security
    // Confirm monitoring setup
}
```

### Cost Tests
Verify cost estimation and optimization features.

```go
func TestCostOptimization(t *testing.T) {
    // Validate cost estimation logic
    // Check budget-aware configurations
    // Verify resource right-sizing
}
```

## Running Tests

### Local Testing

```bash
# Run all tests
make test

# Run specific test categories
cd test
go test -v -run TestTerraformPlan
go test -v -run TestModuleStandards
go test -v -run TestSecurity

# Run tests with coverage
go test -v -cover ./...
```

### CI/CD Testing

Tests run automatically on:
- Every push to main/develop branches
- All pull requests
- Scheduled weekly runs

### Test Configuration

Configure tests using environment variables:
```bash
export TF_VERSION="1.6.0"          # Terraform version to test
export CLOUD_PROVIDER="aws"        # Primary cloud provider
export TEST_TIMEOUT="30m"          # Test timeout
export PARALLEL_TESTS="4"          # Number of parallel tests
```

## Test Data

### Fixtures
Test fixtures provide consistent test data:
- Valid configurations for positive testing
- Invalid configurations for negative testing
- Edge cases and boundary conditions
- Multi-cloud scenarios

### Mock Data
Mock data simulates cloud provider responses:
- Instance types and pricing
- Available regions and zones
- Service quotas and limits
- API responses

## Writing Tests

### Test Guidelines

1. **Fast Execution**: Tests should complete quickly
2. **No Cloud Resources**: Don't create actual cloud resources
3. **Comprehensive Coverage**: Test all code paths
4. **Clear Assertions**: Use descriptive test names and assertions
5. **Isolated Tests**: Tests should not depend on each other

### Test Template

```go
func TestModuleName(t *testing.T) {
    t.Parallel()
    
    testCases := []struct {
        name     string
        config   string
        expected string
        wantErr  bool
    }{
        {
            name:     "valid configuration",
            config:   "fixtures/valid-config.tf",
            expected: "expected-output",
            wantErr:  false,
        },
        {
            name:     "invalid configuration",
            config:   "fixtures/invalid-config.tf",
            wantErr:  true,
        },
    }
    
    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

### Helper Functions

Use helper functions for common operations:

```go
// terraform.go
func InitAndPlan(t *testing.T, dir string) *terraform.PlanStruct {
    // Initialize and plan Terraform configuration
}

func ValidatePlan(t *testing.T, plan *terraform.PlanStruct) {
    // Validate plan structure and content
}

// validation.go
func ValidateModuleStructure(t *testing.T, modulePath string) {
    // Check module follows standards
}

func ValidateVariables(t *testing.T, variablesFile string) {
    // Validate variable definitions
}
```

## Test Automation

### Makefile Integration

```makefile
test: ## Run all tests
	cd test && go test -v -timeout 30m ./...

test-plan: ## Run plan validation tests
	cd test && go test -v -run TestTerraformPlan

test-standards: ## Run standards compliance tests
	cd test && go test -v -run TestModuleStandards

test-security: ## Run security tests
	cd test && go test -v -run TestSecurity
```

### GitHub Actions

```yaml
- name: Run Tests
  run: |
    cd test
    go mod download
    go test -v -timeout 30m ./...
```

## Performance Testing

### Benchmarks
Measure test execution time and resource usage:

```go
func BenchmarkTerraformPlan(b *testing.B) {
    for i := 0; i < b.N; i++ {
        // Run terraform plan
    }
}
```

### Profiling
Profile test execution to identify bottlenecks:

```bash
go test -cpuprofile=cpu.prof -memprofile=mem.prof -bench=.
go tool pprof cpu.prof
```

## Troubleshooting

### Common Issues

1. **Terraform Not Found**: Ensure Terraform is installed and in PATH
2. **Module Not Found**: Check module source paths
3. **Provider Authentication**: Verify cloud provider credentials
4. **Timeout Errors**: Increase test timeout values

### Debug Mode

Enable debug output for troubleshooting:

```bash
export TF_LOG=DEBUG
export TEST_DEBUG=true
go test -v -run TestSpecificTest
```

### Test Isolation

Ensure tests don't interfere with each other:
- Use unique resource names
- Clean up temporary files
- Use separate working directories
- Avoid shared state

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Use descriptive test names
3. Include both positive and negative test cases
4. Add appropriate documentation
5. Ensure tests run quickly
6. Update this README if needed

## Metrics

Current test metrics:
- **Total Tests**: TBD
- **Coverage**: TBD%
- **Execution Time**: < 5 minutes
- **Success Rate**: TBD%

Test metrics are tracked and reported in CI/CD pipelines.