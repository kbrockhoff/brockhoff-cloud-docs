output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnets
}

output "database_subnets" {
  description = "List of database subnet IDs"
  value       = module.networking.database_subnets
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.load_balancer.zone_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.web_tier.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.web_tier.cloudfront_distribution_domain_name
}

output "security_groups" {
  description = "Security group IDs"
  value = {
    lb  = aws_security_group.lb.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.db_instance_port
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.cache.endpoint
  sensitive   = true
}

output "application_url" {
  description = "Application URL via CloudFront"
  value       = "https://${module.web_tier.cloudfront_distribution_domain_name}"
}

output "context" {
  description = "Context information"
  value = {
    name_prefix = module.context.name_prefix
    tags        = module.context.tags
  }
}