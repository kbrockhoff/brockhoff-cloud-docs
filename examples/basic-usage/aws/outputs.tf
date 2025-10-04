# Basic AWS Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.main.arn
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.main.id
}

# Standard encryption outputs
output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = var.create_kms_key ? aws_kms_key.main[0].key_id : null
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = var.create_kms_key ? aws_kms_key.main[0].arn : null
}

# Standard monitoring outputs
output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.alarms_enabled ? aws_sns_topic.alarms[0].arn : null
}

# Standard cost estimation outputs (simplified)
output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value       = "~$8.50 (t3.micro in us-west-2)"
}

output "cost_breakdown" {
  description = "Detailed cost breakdown by service"
  value = {
    compute       = "~$8.50/month (t3.micro)"
    storage       = "~$2.00/month (20GB gp3)"
    data_transfer = "~$0.00/month (first 1GB free)"
  }
}

# Compliance and governance outputs (simplified)
output "compliance_report" {
  description = "Well-architected framework compliance assessment"
  value = {
    security = {
      encryption_at_rest = var.create_kms_key
      security_groups    = true
      iam_roles          = false
    }
    reliability = {
      multi_az = false
      backup   = false
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
    compliance_frameworks = ["AWS Well-Architected"]
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

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if key pair configured)"
  value       = var.ssh_key_name != "" ? "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.main.public_ip}" : "SSH key not configured"
}

output "web_url" {
  description = "URL to access the web application"
  value       = "http://${aws_instance.main.public_ip}"
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    instance_type        = var.instance_type
    actual_instance_type = local.actual_instance_type
    region               = var.aws_region
    environment          = var.environment
    monitoring           = var.monitoring_enabled
    encryption           = var.create_kms_key
    estimated_cost       = "~$8.50/month"
  }
}