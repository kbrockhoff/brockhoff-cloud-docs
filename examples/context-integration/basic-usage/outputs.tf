# Basic Context Integration Example Outputs

# Context Outputs
output "context_name_prefix" {
  description = "Generated name prefix from context module"
  value       = module.context.name_prefix
}

output "context_tags" {
  description = "Generated tags from context module"
  value       = module.context.tags
}

output "context_environment_type" {
  description = "Environment type from context module"
  value       = module.context.environment_type
}

# Web Server Instance Outputs
output "web_server_instance_id" {
  description = "EC2 instance ID of the web server"
  value       = var.create_ec2_instance ? aws_instance.web_server[0].id : null
}

output "web_server_instance_arn" {
  description = "EC2 instance ARN of the web server"
  value       = var.create_ec2_instance ? aws_instance.web_server[0].arn : null
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = var.create_ec2_instance ? aws_instance.web_server[0].public_ip : null
}

output "web_server_private_ip" {
  description = "Private IP of the web server"
  value       = var.create_ec2_instance ? aws_instance.web_server[0].private_ip : null
}

# Direct Resource Outputs
output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = var.create_s3_bucket ? aws_s3_bucket.example[0].bucket : null
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = var.create_s3_bucket ? aws_s3_bucket.example[0].arn : null
}

output "iam_role_name" {
  description = "Name of the created IAM role"
  value       = var.create_iam_role ? aws_iam_role.example[0].name : null
}

output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = var.create_iam_role ? aws_iam_role.example[0].arn : null
}

output "kms_key_id" {
  description = "ID of the created KMS key"
  value       = var.create_kms_key ? aws_kms_key.example[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the created KMS key"
  value       = var.create_kms_key ? aws_kms_key.example[0].arn : null
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = var.create_kms_key ? aws_kms_alias.example[0].name : null
}

# Configuration Outputs
output "effective_environment_config" {
  description = "Environment-specific configuration applied"
  value       = local.effective_config
}

output "cloud_provider" {
  description = "Detected cloud provider"
  value       = local.cloud_provider
}

# Debug Information (useful for troubleshooting)
output "debug_info" {
  description = "Debug information for context integration"
  value = {
    name_prefix      = local.name_prefix
    environment_type = var.environment_type
    cloud_provider   = local.cloud_provider
    tags_count       = length(local.tags)
    context_enabled  = module.context.context.enabled
  }
}