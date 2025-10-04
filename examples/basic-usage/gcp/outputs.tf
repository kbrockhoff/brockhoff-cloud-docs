# Basic GCP Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "instance_id" {
  description = "Compute Engine instance ID"
  value       = module.compute.instance_id
}

output "instance_name" {
  description = "Compute Engine instance name"
  value       = module.compute.instance_name
}

output "public_ip" {
  description = "External IP address of the instance"
  value       = module.compute.public_ip
}

output "private_ip" {
  description = "Internal IP address of the instance"
  value       = module.compute.private_ip
}

output "firewall_rule_name" {
  description = "Firewall rule name"
  value       = module.compute.firewall_rule_name
}

# Standard encryption outputs
output "kms_key_id" {
  description = "Cloud KMS key ID used for encryption"
  value       = module.compute.kms_key_id
}

output "kms_key_name" {
  description = "Cloud KMS key name used for encryption"
  value       = module.compute.kms_key_name
}

# Standard monitoring outputs
output "notification_channel_id" {
  description = "Notification channel ID for alerts"
  value       = module.compute.notification_channel_id
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

output "labels" {
  description = "Applied labels from context"
  value       = module.context.tags
}

# GCP-specific outputs
output "project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "zone" {
  description = "GCP zone"
  value       = var.gcp_zone != "" ? var.gcp_zone : data.google_compute_zones.available.names[0]
}

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if SSH keys configured)"
  value       = length(var.ssh_public_keys) > 0 ? "gcloud compute ssh ${module.compute.instance_name} --zone=${var.gcp_zone != "" ? var.gcp_zone : data.google_compute_zones.available.names[0]}" : "SSH keys not configured"
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    machine_type   = local.machine_type_map[var.instance_type]
    region         = var.gcp_region
    zone           = var.gcp_zone != "" ? var.gcp_zone : data.google_compute_zones.available.names[0]
    environment    = var.environment
    monitoring     = var.monitoring_enabled
    encryption     = var.create_kms_key
    estimated_cost = module.compute.monthly_cost_estimate
  }
}

# Local reference for output
locals {
  machine_type_map = {
    small  = "e2-micro"
    medium = "e2-small"
    large  = "e2-standard-2"
  }
}