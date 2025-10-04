# Brockhoff Cloud Terraform Modules Makefile
# This Makefile provides standardized commands for development and CI/CD

.DEFAULT_GOAL := help
.PHONY: help init validate plan test docs lint clean security format check-format

# Colors for output
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
RESET  := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Brockhoff Cloud Terraform Modules$(RESET)"
	@echo "$(BLUE)====================================$(RESET)"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

init: ## Initialize terraform and download dependencies
	@echo "$(BLUE)Initializing Terraform modules...$(RESET)"
	@find . -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "$(YELLOW)Initializing $$dir$(RESET)"; \
			cd "$$dir" && terraform init -backend=false && cd - > /dev/null; \
		fi \
	done
	@echo "$(GREEN)Initialization complete$(RESET)"

validate: init ## Validate terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(RESET)"
	@find . -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "$(YELLOW)Validating $$dir$(RESET)"; \
			cd "$$dir" && terraform validate && cd - > /dev/null; \
		fi \
	done
	@echo "$(GREEN)Validation complete$(RESET)"

format: ## Format terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive
	@echo "$(GREEN)Formatting complete$(RESET)"

check-format: ## Check if terraform files are formatted
	@echo "$(BLUE)Checking Terraform format...$(RESET)"
	@if ! terraform fmt -check -recursive; then \
		echo "$(RED)Files are not formatted. Run 'make format' to fix.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Format check passed$(RESET)"

plan: init ## Run terraform plan on all examples
	@echo "$(BLUE)Running terraform plan on examples...$(RESET)"
	@find . -path "*/examples/*" -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "$(YELLOW)Planning $$dir$(RESET)"; \
			cd "$$dir" && terraform init -backend=false && terraform plan && cd - > /dev/null; \
		fi \
	done
	@echo "$(GREEN)Planning complete$(RESET)"

test: ## Run all tests including plan validation
	@echo "$(BLUE)Running tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		echo "$(YELLOW)Running Go tests$(RESET)"; \
		cd test && go mod download && go test -v -timeout 30m ./...; \
	else \
		echo "$(YELLOW)No Go tests found, running plan validation$(RESET)"; \
		$(MAKE) plan; \
	fi
	@echo "$(GREEN)Tests complete$(RESET)"

test-plan: ## Run terraform plan validation tests only
	@echo "$(BLUE)Running plan validation tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 15m -run TestTerraformPlan; \
	else \
		$(MAKE) plan; \
	fi
	@echo "$(GREEN)Plan tests complete$(RESET)"

test-standards: ## Run module standards validation tests
	@echo "$(BLUE)Running standards validation tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 10m -run TestModuleStandards; \
	else \
		echo "$(YELLOW)No standards tests available$(RESET)"; \
	fi
	@echo "$(GREEN)Standards tests complete$(RESET)"

test-validation: ## Run terraform validation tests
	@echo "$(BLUE)Running validation tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 10m -run TestTerraformValidation; \
	else \
		$(MAKE) validate; \
	fi
	@echo "$(GREEN)Validation tests complete$(RESET)"

test-format: ## Run terraform format validation tests
	@echo "$(BLUE)Running format validation tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 5m -run TestTerraformFormat; \
	else \
		$(MAKE) check-format; \
	fi
	@echo "$(GREEN)Format tests complete$(RESET)"

test-compliance: ## Run compliance validation tests
	@echo "$(BLUE)Running compliance validation tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 20m -run TestCompliance; \
	else \
		echo "$(YELLOW)No compliance tests available$(RESET)"; \
	fi
	@echo "$(GREEN)Compliance tests complete$(RESET)"

test-security: ## Run security compliance tests
	@echo "$(BLUE)Running security compliance tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 15m -run TestSecurity; \
	else \
		echo "$(YELLOW)No security tests available$(RESET)"; \
	fi
	@echo "$(GREEN)Security tests complete$(RESET)"

test-cost: ## Run cost optimization tests
	@echo "$(BLUE)Running cost optimization tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 10m -run TestCost; \
	else \
		echo "$(YELLOW)No cost optimization tests available$(RESET)"; \
	fi
	@echo "$(GREEN)Cost optimization tests complete$(RESET)"

test-governance: ## Run governance compliance tests
	@echo "$(BLUE)Running governance compliance tests...$(RESET)"
	@if [ -d "test" ] && [ -f "test/go.mod" ]; then \
		cd test && go test -v -timeout 10m -run TestGovernance; \
	else \
		echo "$(YELLOW)No governance tests available$(RESET)"; \
	fi
	@echo "$(GREEN)Governance tests complete$(RESET)"

docs: ## Generate documentation using terraform-docs
	@echo "$(BLUE)Generating documentation...$(RESET)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		find . -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
			if [ -f "$$dir/main.tf" ] && [ -f "$$dir/variables.tf" ]; then \
				echo "$(YELLOW)Generating docs for $$dir$(RESET)"; \
				cd "$$dir" && terraform-docs markdown table --output-file README.md . && cd - > /dev/null; \
			fi \
		done; \
		echo "$(GREEN)Documentation generation complete$(RESET)"; \
	else \
		echo "$(RED)terraform-docs not found. Please install it first.$(RESET)"; \
		echo "$(YELLOW)Install with: brew install terraform-docs$(RESET)"; \
		exit 1; \
	fi

lint: check-format validate ## Run terraform linting and validation
	@echo "$(BLUE)Running linting...$(RESET)"
	@if command -v tflint >/dev/null 2>&1; then \
		echo "$(YELLOW)Running tflint$(RESET)"; \
		find . -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
			if [ -f "$$dir/main.tf" ]; then \
				echo "$(YELLOW)Linting $$dir$(RESET)"; \
				cd "$$dir" && tflint && cd - > /dev/null; \
			fi \
		done; \
	else \
		echo "$(YELLOW)tflint not found, skipping advanced linting$(RESET)"; \
	fi
	@echo "$(GREEN)Linting complete$(RESET)"

security: ## Run security scans
	@echo "$(BLUE)Running security scans...$(RESET)"
	@if command -v trivy >/dev/null 2>&1; then \
		echo "$(YELLOW)Running Trivy scan$(RESET)"; \
		trivy fs --security-checks vuln,config .; \
	else \
		echo "$(YELLOW)Trivy not found, skipping vulnerability scan$(RESET)"; \
	fi
	@if command -v tfsec >/dev/null 2>&1; then \
		echo "$(YELLOW)Running TFSec scan$(RESET)"; \
		tfsec .; \
	else \
		echo "$(YELLOW)TFSec not found, skipping security scan$(RESET)"; \
	fi
	@echo "$(GREEN)Security scans complete$(RESET)"

clean: ## Clean up temporary files and .terraform directories
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "*.tfstate*" -delete 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete$(RESET)"

install-tools: ## Install required development tools
	@echo "$(BLUE)Installing development tools...$(RESET)"
	@echo "$(YELLOW)Installing terraform-docs...$(RESET)"
	@if command -v brew >/dev/null 2>&1; then \
		brew install terraform-docs tflint trivy; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "$(YELLOW)Please install terraform-docs, tflint, and trivy manually on Ubuntu$(RESET)"; \
	else \
		echo "$(YELLOW)Please install terraform-docs, tflint, and trivy manually$(RESET)"; \
	fi
	@echo "$(GREEN)Tool installation complete$(RESET)"

ci: check-format validate test security ## Run all CI checks
	@echo "$(GREEN)All CI checks passed$(RESET)"

# Release Management
release-patch: ## Create a patch release (x.y.Z)
	@echo "$(BLUE)Creating patch release...$(RESET)"
	@./scripts/release.sh patch

release-minor: ## Create a minor release (x.Y.0)
	@echo "$(BLUE)Creating minor release...$(RESET)"
	@./scripts/release.sh minor

release-major: ## Create a major release (X.0.0)
	@echo "$(BLUE)Creating major release...$(RESET)"
	@./scripts/release.sh major

release-prerelease: ## Create a prerelease (x.y.z-alpha.N)
	@echo "$(BLUE)Creating prerelease...$(RESET)"
	@./scripts/release.sh prerelease

release-dry-run: ## Show what a patch release would do (dry run)
	@echo "$(BLUE)Dry run for patch release...$(RESET)"
	@./scripts/release.sh patch --dry-run

release-custom: ## Create a custom release (specify version with VERSION=x.y.z)
	@echo "$(BLUE)Creating custom release...$(RESET)"
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Please specify VERSION=x.y.z$(RESET)"; \
		exit 1; \
	fi
	@./scripts/release.sh custom -v $(VERSION)

check-version: ## Show current version information
	@echo "$(BLUE)Version Information:$(RESET)"
	@echo "Current Version: $(shell cat VERSION 2>/dev/null || echo 'Not set')"
	@echo "Latest Git Tag:  $(shell git describe --tags --abbrev=0 2>/dev/null || echo 'No tags')"
	@echo "Git Commit:      $(shell git rev-parse --short HEAD 2>/dev/null || echo 'Not a git repo')"
	@echo "Git Branch:      $(shell git branch --show-current 2>/dev/null || echo 'Not a git repo')"

changelog: ## Generate changelog for current version
	@echo "$(BLUE)Generating changelog...$(RESET)"
	@./scripts/release.sh patch --dry-run --skip-tests

# Registry and Documentation
publish-docs: ## Publish documentation to GitHub Pages
	@echo "$(BLUE)Publishing documentation...$(RESET)"
	@if [ -f ".github/workflows/docs.yml" ]; then \
		echo "$(YELLOW)Triggering documentation workflow...$(RESET)"; \
		gh workflow run docs.yml || echo "$(YELLOW)Please trigger manually or push to main branch$(RESET)"; \
	else \
		echo "$(RED)Documentation workflow not found$(RESET)"; \
	fi

validate-registry: ## Validate module for Terraform Registry requirements
	@echo "$(BLUE)Validating Terraform Registry requirements...$(RESET)"
	@echo "$(YELLOW)Checking required files...$(RESET)"
	@required_files="README.md LICENSE main.tf variables.tf outputs.tf"; \
	for file in $$required_files; do \
		if [ ! -f "$$file" ]; then \
			echo "$(RED)Missing required file: $$file$(RESET)"; \
			exit 1; \
		else \
			echo "$(GREEN)✓ $$file$(RESET)"; \
		fi \
	done
	@echo "$(YELLOW)Checking examples directory...$(RESET)"
	@if [ ! -d "examples" ]; then \
		echo "$(RED)Missing examples directory$(RESET)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ examples directory$(RESET)"; \
	fi
	@echo "$(YELLOW)Checking example structure...$(RESET)"
	@find examples -mindepth 1 -maxdepth 1 -type d | while read example_dir; do \
		if [ ! -f "$$example_dir/main.tf" ]; then \
			echo "$(RED)Missing main.tf in $$example_dir$(RESET)"; \
			exit 1; \
		else \
			echo "$(GREEN)✓ $$example_dir/main.tf$(RESET)"; \
		fi \
	done
	@echo "$(YELLOW)Checking version format...$(RESET)"
	@version=$$(cat VERSION 2>/dev/null || echo "0.0.0"); \
	if echo "$$version" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$$' > /dev/null; then \
		echo "$(GREEN)✓ Version format: $$version$(RESET)"; \
	else \
		echo "$(RED)Invalid version format: $$version$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Registry validation passed$(RESET)"

# Development Helpers
dev-setup: install-tools init ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing pre-commit hooks...$(RESET)"; \
		pre-commit install; \
	else \
		echo "$(YELLOW)pre-commit not found, skipping hooks setup$(RESET)"; \
	fi
	@echo "$(GREEN)Development setup complete$(RESET)"

dev-test: ## Run quick development tests
	@echo "$(BLUE)Running quick development tests...$(RESET)"
	@$(MAKE) check-format
	@$(MAKE) validate
	@$(MAKE) test-plan
	@echo "$(GREEN)Quick tests passed$(RESET)"

dev-full-test: ## Run comprehensive development tests
	@echo "$(BLUE)Running comprehensive development tests...$(RESET)"
	@$(MAKE) ci
	@$(MAKE) test-compliance
	@$(MAKE) test-security
	@echo "$(GREEN)Comprehensive tests passed$(RESET)"