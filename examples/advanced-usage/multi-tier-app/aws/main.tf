# Multi-Tier Web Application - AWS Implementation
# This example demonstrates a production-ready, scalable web application
# using Brockhoff Cloud Terraform modules

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/external-context/terraform"
  
  name            = var.name
  environment     = var.environment
  cloud_provider  = "aws"
  
  context = var.context
}

# Foundation: Networking
module "networking" {
  source = "../../../../modules/foundation/networking/aws"
  
  name_prefix      = module.context.name_prefix
  tags            = module.context.tags
  environment_type = var.environment_type
  
  # VPC configuration
  vpc_cidr = var.vpc_cidr
  
  # Multi-AZ deployment
  availability_zones = var.availability_zones
  
  # Subnet configuration
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = var.environment_type == "Development"
  
  # VPC endpoints for cost optimization
  enable_s3_endpoint = true
  enable_dynamodb_endpoint = true
}

# Foundation: Security
module "security" {
  source = "../../../../modules/foundation/security/aws"
  
  name_prefix      = module.context.name_prefix
  tags            = module.context.tags
  environment_type = var.environment_type
  
  vpc_id = module.networking.vpc_id
  
  # Security group configurations
  web_tier_config = {
    allowed_cidr_blocks = ["0.0.0.0/0"]  # Public access via ALB
    allowed_ports      = [80, 443]
  }
  
  app_tier_config = {
    allowed_security_group_ids = [module.security.web_tier_security_group_id]
    allowed_ports             = [8080, 8443]
  }
  
  database_tier_config = {
    allowed_security_group_ids = [module.security.app_tier_security_group_id]
    allowed_ports             = [5432]  # PostgreSQL
  }
  
  # Admin access
  admin_cidr_blocks = var.admin_cidr_blocks
  ssh_key_name     = var.ssh_key_name
}

# Load Balancer
module "load_balancer" {
  source = "../../../../modules/services/load-balancer/aws"
  
  name_prefix      = module.context.name_prefix
  tags            = module.context.tags
  environment_type = var.environment_type
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids
  
  # SSL configuration
  ssl_certificate_arn = var.ssl_certificate_arn
  ssl_policy         = "ELBSecurityPolicy-TLS-1-2-2017-01"
  
  # WAF configuration
  enable_waf = var.enable_waf
  waf_rules  = var.waf_rules
  
  # Health check configuration
  health_check = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout            = 5
    interval           = 30
    path               = "/health"
    matcher            = "200"
  }
}

# Web Tier - Auto Scaling Group
module "web_tier" {
  source = "../../../../modules/services/compute/aws"
  
  name_prefix      = "${module.context.name_prefix}-web"
  tags            = merge(module.context.tags, { Tier = "Web" })
  environment_type = var.environment_type
  
  # Auto Scaling configuration
  auto_scaling_config = var.web_tier_scaling
  
  # Instance configuration
  instance_type = var.web_tier_instance_type
  ami_id       = var.web_tier_ami_id != "" ? var.web_tier_ami_id : data.aws_ami.web_tier.id
  
  # Network configuration
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  # Security configuration
  security_group_ids = [module.security.web_tier_security_group_id]
  
  # Load balancer integration
  target_group_arns = [module.load_balancer.target_group_arn]
  
  # User data script for web server setup
  user_data = base64encode(templatefile("${path.module}/scripts/web-tier-userdata.sh", {
    app_tier_endpoint = module.app_tier.internal_load_balancer_dns
  }))
  
  # Standard configuration objects
  encryption_config = var.encryption_config
  monitoring_config = var.monitoring_config
  alarms_config    = var.alarms_config
}

# Application Tier - Auto Scaling Group
module "app_tier" {
  source = "../../../../modules/services/compute/aws"
  
  name_prefix      = "${module.context.name_prefix}-app"
  tags            = merge(module.context.tags, { Tier = "Application" })
  environment_type = var.environment_type
  
  # Auto Scaling configuration
  auto_scaling_config = var.app_tier_scaling
  
  # Instance configuration
  instance_type = var.app_tier_instance_type
  ami_id       = var.app_tier_ami_id != "" ? var.app_tier_ami_id : data.aws_ami.app_tier.id
  
  # Network configuration
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  # Security configuration
  security_group_ids = [module.security.app_tier_security_group_id]
  
  # Internal load balancer for app tier
  create_internal_load_balancer = true
  
  # User data script for application server setup
  user_data = base64encode(templatefile("${path.module}/scripts/app-tier-userdata.sh", {
    database_endpoint = module.database.endpoint
    redis_endpoint   = module.cache.endpoint
    database_name    = var.database_config.name
    database_username = var.database_config.username
  }))
  
  # Standard configuration objects
  encryption_config = var.encryption_config
  monitoring_config = var.monitoring_config
  alarms_config    = var.alarms_config
}

# Database - RDS PostgreSQL
module "database" {
  source = "../../../../modules/services/database/aws"
  
  name_prefix      = "${module.context.name_prefix}-db"
  tags            = merge(module.context.tags, { Tier = "Database" })
  data_tags       = module.context.data_tags
  environment_type = var.environment_type
  
  # Database configuration
  engine         = "postgres"
  engine_version = var.database_config.engine_version
  instance_class = local.database_instance_class_map[var.database_config.instance_class]
  
  # Storage configuration
  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true
  
  # Database settings
  database_name = var.database_config.name
  username     = var.database_config.username
  
  # Network configuration
  vpc_id               = module.networking.vpc_id
  subnet_ids          = module.networking.database_subnet_ids
  vpc_security_group_ids = [module.security.database_tier_security_group_id]
  
  # High availability
  multi_az               = var.database_config.multi_az
  backup_retention_period = var.database_config.backup_retention_period
  backup_window          = var.database_config.backup_window
  maintenance_window     = var.database_config.maintenance_window
  
  # Read replicas
  read_replica_count = var.database_config.read_replica_count
  
  # Performance monitoring
  performance_insights_enabled = var.database_config.performance_insights_enabled
  monitoring_interval         = var.database_config.monitoring_interval
  
  # Standard configuration objects
  encryption_config = var.encryption_config
  monitoring_config = var.monitoring_config
  alarms_config    = var.alarms_config
}

# Cache - ElastiCache Redis
module "cache" {
  source = "../../../../modules/services/cache/aws"
  
  name_prefix      = "${module.context.name_prefix}-cache"
  tags            = merge(module.context.tags, { Tier = "Cache" })
  environment_type = var.environment_type
  
  # Redis configuration
  engine_version = var.cache_config.engine_version
  node_type     = local.cache_node_type_map[var.cache_config.node_type]
  
  # Cluster configuration
  num_cache_nodes = var.cache_config.num_cache_nodes
  
  # Network configuration
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  
  # Security configuration
  security_group_ids = [module.security.cache_security_group_id]
  
  # High availability
  automatic_failover_enabled = var.cache_config.automatic_failover_enabled
  multi_az_enabled          = var.cache_config.multi_az_enabled
  
  # Backup configuration
  snapshot_retention_limit = var.cache_config.snapshot_retention_limit
  snapshot_window         = var.cache_config.snapshot_window
  
  # Standard configuration objects
  encryption_config = var.encryption_config
  monitoring_config = var.monitoring_config
  alarms_config    = var.alarms_config
}

# Storage - S3 Bucket for static assets
module "storage" {
  source = "../../../../modules/services/storage/aws"
  
  name_prefix      = "${module.context.name_prefix}-assets"
  tags            = module.context.tags
  data_tags       = module.context.data_tags
  environment_type = var.environment_type
  
  # Bucket configuration
  versioning_enabled = true
  
  # CDN configuration
  enable_cdn = true
  cdn_config = {
    price_class = var.environment_type == "Development" ? "PriceClass_100" : "PriceClass_All"
    
    # Cache behaviors
    default_cache_behavior = {
      target_origin_id       = "S3-${module.context.name_prefix}-assets"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      compress              = true
      
      forwarded_values = {
        query_string = false
        cookies = {
          forward = "none"
        }
      }
      
      min_ttl     = 0
      default_ttl = 86400
      max_ttl     = 31536000
    }
  }
  
  # Standard configuration objects
  encryption_config = var.encryption_config
  monitoring_config = var.monitoring_config
  alarms_config    = var.alarms_config
}

# Monitoring and Alerting
module "monitoring" {
  source = "../../../../modules/governance/monitoring/aws"
  
  name_prefix      = module.context.name_prefix
  tags            = module.context.tags
  environment_type = var.environment_type
  
  # Application monitoring
  application_config = {
    load_balancer_arn = module.load_balancer.arn
    target_group_arn  = module.load_balancer.target_group_arn
    
    web_tier_asg_name = module.web_tier.auto_scaling_group_name
    app_tier_asg_name = module.app_tier.auto_scaling_group_name
    
    database_identifier = module.database.identifier
    cache_cluster_id   = module.cache.cluster_id
  }
  
  # Alert configuration
  alerts_config = var.alerts_config
  
  # Dashboard configuration
  create_dashboard = true
  dashboard_widgets = [
    "application_performance",
    "infrastructure_health",
    "database_performance",
    "cache_performance"
  ]
}

# Local mappings for AWS-specific configurations
locals {
  database_instance_class_map = {
    small  = "db.t3.micro"
    medium = "db.t3.small"
    large  = "db.t3.medium"
    xlarge = "db.t3.large"
  }
  
  cache_node_type_map = {
    small  = "cache.t3.micro"
    medium = "cache.t3.small"
    large  = "cache.t3.medium"
    xlarge = "cache.t3.large"
  }
}

# Data sources for AMI selection
data "aws_ami" "web_tier" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "app_tier" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}