# Basic Azure Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "vm_id" {
  description = "Virtual machine ID"
  value       = module.compute.vm_id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = module.compute.vm_name
}

output "public_ip" {
  description = "Public IP address of the VM"
  value       = module.compute.public_ip
}

output "private_ip" {
  description = "Private IP address of the VM"
  value       = module.compute.private_ip
}

output "network_security_group_id" {
  description = "Network security group ID"
  value       = module.compute.network_security_group_id
}

# Standard encryption outputs
output "key_vault_id" {
  description = "Key Vault ID used for encryption"
  value       = module.compute.key_vault_id
}

output "key_vault_uri" {
  description = "Key Vault URI used for encryption"
  value       = module.compute.key_vault_uri
}

# Standard monitoring outputs
output "action_group_id" {
  description = "Action group ID for alerts"
  value       = module.compute.action_group_id
}

# Standard cost estimation outputs
output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value       = module.compute.monthly_cost_estimate
}

output "cost_breakdown" {
  description = "Detailed cost breakdown by service"
  value       = module.compute.cost_breakdown
}

# Compliance and governance outputs
output "compliance_report" {
  description = "Well-architected framework compliance assessment"
  value       = module.compute.compliance_report
}

output "governance_metadata" {
  description = "Governance and audit metadata"
  value       = module.compute.governance_metadata
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
  value       = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}

output "resource_group_location" {
  description = "Resource group location"
  value       = var.azure_location
}

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if SSH key configured)"
  value       = var.ssh_public_key != "" ? "ssh ${var.admin_username}@${module.compute.public_ip}" : "SSH key not configured"
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
    estimated_cost = module.compute.monthly_cost_estimate
  }
}

# Local reference for output
locals {
  vm_size_map = {
    small  = "Standard_B1s"
    medium = "Standard_B2s"
    large  = "Standard_B4ms"
  }
}