# Basic AWS Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = module.compute.instance_arn
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = module.compute.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = module.compute.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.compute.security_group_id
}

# Standard encryption outputs
output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = module.compute.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = module.compute.kms_key_arn
}

# Standard monitoring outputs
output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.compute.alarm_sns_topic_arn
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

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if key pair configured)"
  value       = var.ssh_key_name != "" ? "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${module.compute.public_ip}" : "SSH key not configured"
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    instance_type  = var.instance_type
    region         = var.aws_region
    environment    = var.environment
    monitoring     = var.monitoring_enabled
    encryption     = var.create_kms_key
    estimated_cost = module.compute.monthly_cost_estimate
  }
}