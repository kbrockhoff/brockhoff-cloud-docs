# Module Composition Guide

## Overview

This guide provides structured documentation for AI agents on how Terraform modules in the Brockhoff Cloud suite integrate and compose together to build complete infrastructure solutions.

## Composition Patterns

### 1. Dependency Pattern

Modules that require outputs from other modules to function properly.

```hcl
# Network module provides foundation
module "network" {
  source = "kbrockhoff/networking/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
  }
}

# Compute module depends on network outputs
module "compute" {
  source = "kbrockhoff/compute-instance/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  # Dependency: requires network module outputs
  network_config = {
    vpc_id = module.network.vpc_id
    subnet_ids = module.network.private_subnet_ids
  }
  
  instance_config = {
    instance_type = "medium"
    min_size = 2
    max_size = 10
  }
}
```

**AI Agent Guidelines:**
- Always create dependency modules first
- Use module outputs as inputs to dependent modules
- Validate that required outputs exist before referencing

### 2. Reference Pattern

Modules that can optionally use outputs from other modules for enhanced functionality.

```hcl
# Security module creates shared security groups
module "security" {
  source = "kbrockhoff/security-groups/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  vpc_id = module.network.vpc_id
}

# Database module can reference security groups
module "database" {
  source = "kbrockhoff/rds-instance/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  # Reference: optional but recommended
  security_group_ids = [module.security.database_security_group_id]
  
  # Can also create its own security groups if not referenced
  create_security_group = length(var.security_group_ids) == 0
}
```

**AI Agent Guidelines:**
- Check if referenced modules exist in the configuration
- Provide fallback behavior when references are not available
- Use conditional logic to handle optional references

### 3. Composition Pattern

Higher-level modules that combine multiple lower-level modules into complete solutions.

```hcl
# Web application composition module
module "web_application" {
  source = "kbrockhoff/web-application/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  # This module internally composes:
  # - networking module
  # - security module  
  # - compute module
  # - load balancer module
  # - database module
  
  application_config = {
    instance_type = "medium"
    database_engine = "postgres"
    enable_cdn = true
  }
}
```

**AI Agent Guidelines:**
- Use composition modules for common architectural patterns
- Prefer composition over manual assembly for complex solutions
- Understand what sub-modules are included in compositions

### 4. Extension Pattern

Modules that extend the functionality of existing infrastructure.

```hcl
# Base infrastructure
module "base_app" {
  source = "kbrockhoff/web-application/terraform"
  # ... configuration
}

# Monitoring extension
module "monitoring" {
  source = "kbrockhoff/monitoring/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  # Extends base infrastructure with monitoring
  target_resources = {
    load_balancer_arn = module.base_app.load_balancer_arn
    auto_scaling_group_name = module.base_app.auto_scaling_group_name
    database_identifier = module.base_app.database_identifier
  }
}

# Backup extension
module "backup" {
  source = "kbrockhoff/backup/terraform"
  
  name_prefix = "myapp"
  environment_type = "Production"
  
  # Extends with backup capabilities
  backup_targets = {
    database_identifier = module.base_app.database_identifier
    file_system_id = module.base_app.efs_file_system_id
  }
}
```

**AI Agent Guidelines:**
- Use extension modules to add capabilities to existing infrastructure
- Extensions should be optional and not break existing functionality
- Consider the order of extension deployment

## Module Integration Matrix

### Foundation Layer

| Module | Provides | Required By | Optional For |
|--------|----------|-------------|--------------|
| networking | VPC, subnets, routing | compute, database, storage | monitoring, backup |
| security | Security groups, IAM roles | compute, database | storage, monitoring |
| encryption | KMS keys, certificates | storage, database | compute, monitoring |

### Service Layer

| Module | Depends On | Integrates With | Extends |
|--------|------------|-----------------|---------|
| compute-instance | networking, security | load-balancer, monitoring | backup, logging |
| rds-database | networking, security, encryption | compute, backup | monitoring, logging |
| s3-storage | encryption | compute, backup | monitoring, lifecycle |
| load-balancer | networking, security | compute | monitoring, waf |

### Composite Layer

| Module | Includes | Configures | Outputs |
|--------|----------|------------|---------|
| web-application | networking, security, compute, load-balancer | Full web stack | Application endpoints |
| data-platform | networking, security, database, storage | Data processing stack | Data access points |
| microservices | networking, security, compute, service-mesh | Container platform | Service endpoints |

## Integration Specifications

### Standard Integration Points

All modules follow these standard integration patterns:

#### 1. Network Integration

```hcl
# Input variables for network integration
variable "network_config" {
  description = "Network configuration for module integration"
  type = object({
    vpc_id = string
    subnet_ids = list(string)
    security_group_ids = optional(list(string), [])
    availability_zones = optional(list(string), [])
  })
  default = null
}

# Usage in module
locals {
  vpc_id = var.network_config != null ? var.network_config.vpc_id : data.aws_vpc.default.id
  subnet_ids = var.network_config != null ? var.network_config.subnet_ids : data.aws_subnets.default.ids
}
```

#### 2. Security Integration

```hcl
# Input variables for security integration
variable "security_config" {
  description = "Security configuration for module integration"
  type = object({
    security_group_ids = optional(list(string), [])
    iam_role_arn = optional(string, "")
    kms_key_id = optional(string, "")
  })
  default = {}
}
```

#### 3. Monitoring Integration

```hcl
# Input variables for monitoring integration
variable "monitoring_config" {
  description = "Monitoring configuration for module integration"
  type = object({
    enabled = bool
    dashboard_name = optional(string, "")
    alarm_topic_arn = optional(string, "")
    log_group_name = optional(string, "")
  })
  default = {
    enabled = false
  }
}
```

### Output Specifications

All modules provide standardized outputs for integration:

#### 1. Resource Identification Outputs

```hcl
# Primary resource identifiers
output "resource_id" {
  description = "Primary resource identifier"
  value = local.primary_resource_id
}

output "resource_arn" {
  description = "Primary resource ARN"
  value = local.primary_resource_arn
}

output "resource_name" {
  description = "Primary resource name"
  value = local.primary_resource_name
}
```

#### 2. Network Integration Outputs

```hcl
# Network-related outputs for integration
output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs where resources are deployed"
  value = local.subnet_ids
}

output "security_group_ids" {
  description = "Security group IDs attached to resources"
  value = local.security_group_ids
}
```

#### 3. Access Integration Outputs

```hcl
# Access-related outputs for integration
output "endpoint_url" {
  description = "Primary endpoint URL for accessing the resource"
  value = local.endpoint_url
}

output "connection_string" {
  description = "Connection string for database resources"
  value = local.connection_string
  sensitive = true
}

output "access_credentials" {
  description = "Access credentials for the resource"
  value = local.access_credentials
  sensitive = true
}
```

## AI Agent Integration Patterns

### 1. Dependency Resolution

AI agents should resolve dependencies in this order:

```python
# Pseudo-code for AI agent dependency resolution
def resolve_module_dependencies(modules):
    dependency_order = [
        "foundation",  # networking, security, encryption
        "service",     # compute, database, storage
        "composite",   # web-application, data-platform
        "extension"    # monitoring, backup, logging
    ]
    
    resolved_modules = []
    for tier in dependency_order:
        tier_modules = [m for m in modules if m.tier == tier]
        resolved_modules.extend(sort_by_dependencies(tier_modules))
    
    return resolved_modules
```

### 2. Configuration Generation

AI agents should generate configurations using this pattern:

```python
# Pseudo-code for configuration generation
def generate_module_configuration(module_name, requirements):
    # 1. Load module interface schema
    schema = load_module_schema(module_name)
    
    # 2. Identify dependencies
    dependencies = identify_dependencies(schema, requirements)
    
    # 3. Generate dependency configurations first
    dependency_configs = []
    for dep in dependencies:
        dep_config = generate_module_configuration(dep.module, dep.requirements)
        dependency_configs.append(dep_config)
    
    # 4. Generate main module configuration
    config = generate_from_template(
        module_name=module_name,
        dependencies=dependency_configs,
        requirements=requirements
    )
    
    # 5. Validate configuration
    validate_configuration(config, schema)
    
    return config
```

### 3. Cost Optimization Across Modules

AI agents should consider cross-module cost optimization:

```python
# Pseudo-code for cross-module cost optimization
def optimize_multi_module_costs(modules, budget_constraint):
    # 1. Get individual module costs
    module_costs = []
    for module in modules:
        cost = estimate_module_cost(module)
        module_costs.append(cost)
    
    total_cost = sum(cost.total for cost in module_costs)
    
    # 2. If over budget, apply optimization strategies
    if total_cost > budget_constraint:
        # Strategy 1: Reduce instance sizes
        optimized_modules = reduce_instance_sizes(modules)
        
        # Strategy 2: Share resources across modules
        optimized_modules = share_resources(optimized_modules)
        
        # Strategy 3: Use spot instances where appropriate
        optimized_modules = apply_spot_instances(optimized_modules)
    
    return optimized_modules
```

## Best Practices for AI Agents

### 1. Module Selection

- **Start with composition modules** for common patterns (web-application, data-platform)
- **Use foundation modules** when building custom architectures
- **Add extension modules** for additional capabilities
- **Prefer official modules** over custom implementations

### 2. Configuration Generation

- **Follow naming conventions** consistently across all modules
- **Use consistent environment_type** across related modules
- **Apply common tags** to all resources for cost tracking
- **Enable monitoring** for production environments

### 3. Dependency Management

- **Create dependencies first** in the correct order
- **Use module outputs** instead of hardcoded values
- **Validate dependencies** before creating dependent resources
- **Handle optional dependencies** gracefully

### 4. Error Handling

- **Validate inputs** before generating configurations
- **Check for circular dependencies** in module graphs
- **Provide clear error messages** with remediation steps
- **Test configurations** before deployment

### 5. Cost Optimization

- **Estimate costs** before generating configurations
- **Suggest alternatives** when over budget
- **Consider shared resources** to reduce costs
- **Apply environment-appropriate** sizing

## Example: Complete Web Application

Here's how an AI agent might generate a complete web application:

```hcl
# 1. Foundation: Networking
module "network" {
  source = "kbrockhoff/networking/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
  }
}

# 2. Foundation: Security
module "security" {
  source = "kbrockhoff/security-groups/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  vpc_id = module.network.vpc_id
  
  security_groups = {
    web = {
      ingress_rules = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
      ]
    }
    app = {
      ingress_rules = [
        { from_port = 8080, to_port = 8080, protocol = "tcp", source_security_group_id = "web" }
      ]
    }
    db = {
      ingress_rules = [
        { from_port = 5432, to_port = 5432, protocol = "tcp", source_security_group_id = "app" }
      ]
    }
  }
}

# 3. Service: Database
module "database" {
  source = "kbrockhoff/rds-postgres/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  network_config = {
    vpc_id = module.network.vpc_id
    subnet_ids = module.network.database_subnet_ids
  }
  
  security_config = {
    security_group_ids = [module.security.database_security_group_id]
  }
  
  database_config = {
    instance_class = "db.t3.medium"
    allocated_storage = 100
    multi_az = true
  }
}

# 4. Service: Application
module "application" {
  source = "kbrockhoff/compute-instance/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  network_config = {
    vpc_id = module.network.vpc_id
    subnet_ids = module.network.private_subnet_ids
  }
  
  security_config = {
    security_group_ids = [module.security.app_security_group_id]
  }
  
  instance_config = {
    instance_type = "medium"
    min_size = 2
    max_size = 10
    desired_size = 3
  }
  
  # Database connection
  environment_variables = {
    DATABASE_URL = module.database.connection_string
  }
}

# 5. Service: Load Balancer
module "load_balancer" {
  source = "kbrockhoff/application-load-balancer/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  network_config = {
    vpc_id = module.network.vpc_id
    subnet_ids = module.network.public_subnet_ids
  }
  
  security_config = {
    security_group_ids = [module.security.web_security_group_id]
  }
  
  target_config = {
    target_group_arn = module.application.target_group_arn
  }
}

# 6. Extension: Monitoring
module "monitoring" {
  source = "kbrockhoff/monitoring/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  target_resources = {
    load_balancer_arn = module.load_balancer.load_balancer_arn
    auto_scaling_group_name = module.application.auto_scaling_group_name
    database_identifier = module.database.database_identifier
  }
  
  monitoring_config = {
    create_dashboard = true
    enable_alarms = true
  }
}

# 7. Extension: Backup
module "backup" {
  source = "kbrockhoff/backup/terraform"
  
  name_prefix = "webapp"
  environment_type = "Production"
  
  backup_targets = {
    database_identifier = module.database.database_identifier
  }
  
  backup_config = {
    retention_days = 30
    backup_window = "03:00-04:00"
  }
}
```

This example demonstrates the complete integration pattern that AI agents should follow when generating complex infrastructure configurations.