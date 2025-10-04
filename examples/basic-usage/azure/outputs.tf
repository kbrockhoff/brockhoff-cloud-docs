# Basic Azure Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "vm_id" {
  description = "Virtual machine ID"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "network_security_group_id" {
  description = "Network security group ID"
  value       = azurerm_network_security_group.main.id
}

# Standard encryption outputs
output "key_vault_id" {
  description = "Key Vault ID used for encryption"
  value       = var.create_key_vault ? azurerm_key_vault.main[0].id : null
}

output "key_vault_uri" {
  description = "Key Vault URI used for encryption"
  value       = var.create_key_vault ? azurerm_key_vault.main[0].vault_uri : null
}

# Standard cost estimation outputs (simplified)
output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value       = "~$13.50 (Standard_B1s in West US 2)"
}

output "cost_breakdown" {
  description = "Detailed cost breakdown by service"
  value = {
    compute = "~$13.50/month (Standard_B1s)"
    storage = "~$4.80/month (Premium SSD)"
    network = "~$0.00/month (first 5GB free)"
  }
}

# Compliance and governance outputs (simplified)
output "compliance_report" {
  description = "Well-architected framework compliance assessment"
  value = {
    security = {
      encryption_at_rest      = var.create_key_vault
      network_security_groups = true
      iam_roles               = false
    }
    reliability = {
      availability_zones = false
      backup             = false
    }
    cost_optimization = {
      right_sizing       = true
      reserved_instances = false
    }
  }
}

output "governance_metadata" {
  description = "Governance and audit metadata"
  value = {
    created_by            = "terraform"
    module_version        = "basic-usage-v1.0"
    compliance_frameworks = ["Azure Well-Architected Framework"]
    tags                  = module.context.tags
  }
}

# Context outputs for reference
output "name_prefix" {
  description = "Generated name prefix from context"
  value       = module.context.name_prefix
}

output "tags" {
  description = "Applied tags from context"
  value       = module.context.tags
}

# Resource group information
output "resource_group_name" {
  description = "Resource group name"
  value       = local.resource_group_name
}

output "resource_group_location" {
  description = "Resource group location"
  value       = var.azure_location
}

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if SSH key configured)"
  value       = var.ssh_public_key != "" ? "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}" : "SSH key not configured"
}

output "web_url" {
  description = "URL to access the web application"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    vm_size        = local.vm_size_map[var.instance_type]
    location       = var.azure_location
    environment    = var.environment
    monitoring     = var.monitoring_enabled
    encryption     = var.create_key_vault
    estimated_cost = "~$13.50/month"
  }
}