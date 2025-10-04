# Multi-Tier Web Application - AWS Implementation
# This example demonstrates a production-ready, scalable web application

provider "aws" {
  region = "us-west-2"
}

# Pricing provider - always uses us-east-1 where the AWS Pricing API is available
provider "aws" {
  alias  = "pricing"
  region = "us-east-1"
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/context/external"

  name        = var.name
  environment = var.environment
}

# Foundation: Networking
module "networking" {
  source = "kbrockhoff/vpc/aws"

  providers = {
    aws         = aws
    aws.pricing = aws.pricing
  }

  name_prefix      = module.context.name_prefix
  tags             = module.context.tags
  data_tags        = module.context.data_tags
  environment_type = var.environment_type

  # VPC configuration
  cidr_primary = var.cidr_primary
}

# Security Groups
resource "aws_security_group" "lb" {
  name_prefix = "${module.context.name_prefix}-lb-"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.context.tags
}

resource "aws_security_group" "app" {
  name_prefix = "${module.context.name_prefix}-app-"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.context.tags
}

resource "aws_security_group" "db" {
  name_prefix = "${module.context.name_prefix}-db-"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = module.context.tags
}

# Load Balancer
module "load_balancer" {
  source = "terraform-aws-modules/alb/aws"

  name = module.context.name_prefix

  load_balancer_type = "application"

  vpc_id  = module.networking.vpc_id
  subnets = module.networking.public_subnets

  security_groups = [aws_security_group.lb.id]

  target_groups = {
    ex-instance = {
      name_prefix          = "h1"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }

  listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  tags = module.context.tags
}

# Web Tier - CloudFront Distribution
module "web_tier" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = []

  comment             = "${module.context.name_prefix} CloudFront Distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  origin = {
    alb = {
      domain_name = module.load_balancer.dns_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = false
  }

  tags = module.context.tags
}

# Database - RDS MySQL
module "database" {
  source = "terraform-aws-modules/rds/aws"

  identifier = module.context.name_prefix

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "demodb"
  username = "admin"
  port     = "3306"

  manage_master_user_password = true

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.db.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  monitoring_interval    = "30"
  monitoring_role_name   = "${module.context.name_prefix}-rds-monitoring-role"
  create_monitoring_role = true

  tags = module.context.tags

  create_db_subnet_group = true
  subnet_ids             = module.networking.database_subnets

  family               = "mysql8.0"
  major_engine_version = "8.0"

  deletion_protection = false

  parameters = [
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

# Cache - ElastiCache Redis
module "cache" {
  source = "cloudposse/elasticache-redis/aws"

  namespace   = module.context.name_prefix
  environment = var.environment
  name        = "cache"

  availability_zones         = var.availability_zones
  vpc_id                     = module.networking.vpc_id
  allowed_security_group_ids = [aws_security_group.app.id]
  subnets                    = module.networking.private_subnets
  cluster_size               = 1
  instance_type              = "cache.t3.micro"
  apply_immediately          = true
  automatic_failover_enabled = false
  engine_version             = "7.0"
  family                     = "redis7.x"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

  tags = module.context.tags
}
