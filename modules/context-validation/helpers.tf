# Helper functions for cloud provider detection and configuration

locals {
  # Cloud provider detection helpers
  cloud_detection = {
    aws_available = length(data.aws_caller_identity.current) > 0
    azure_available = length(data.azurerm_client_config.current) > 0
    gcp_available = length(data.google_client_config.current) > 0
    
    # Get cloud provider information
    aws_info = length(data.aws_caller_identity.current) > 0 ? {
      account_id = data.aws_caller_identity.current[0].account_id
      user_id    = data.aws_caller_identity.current[0].user_id
      arn        = data.aws_caller_identity.current[0].arn
    } : null
    
    azure_info = length(data.azurerm_client_config.current) > 0 ? {
      client_id       = data.azurerm_client_config.current[0].client_id
      tenant_id       = data.azurerm_client_config.current[0].tenant_id
      subscription_id = data.azurerm_client_config.current[0].subscription_id
    } : null
    
    gcp_info = length(data.google_client_config.current) > 0 ? {
      project = data.google_client_config.current[0].project
      region  = data.google_client_config.current[0].region
      zone    = data.google_client_config.current[0].zone
    } : null
  }
  
  # Available providers list
  available_providers = [
    for provider in ["aws", "azure", "gcp"] :
    provider if (
      (provider == "aws" && local.cloud_detection.aws_available) ||
      (provider == "azure" && local.cloud_detection.azure_available) ||
      (provider == "gcp" && local.cloud_detection.gcp_available)
    )
  ]
  
  # Multi-cloud detection
  is_multi_cloud = length(local.available_providers) > 1
  
  # Configuration helpers for each cloud provider
  aws_config = {
    # Service-specific naming patterns
    naming_patterns = {
      s3_bucket     = "${lower(var.name_prefix)}-bucket-${var.random_suffix}"
      iam_role      = "${var.name_prefix}-role"
      lambda        = replace(var.name_prefix, "-", "_")
      rds_instance  = var.name_prefix
      ec2_instance  = var.name_prefix
      security_group = "${var.name_prefix}-sg"
      load_balancer = "${var.name_prefix}-lb"
    }
    
    # Standard tags
    standard_tags = merge(var.tags, {
      ManagedBy     = "Terraform"
      CloudProvider = "AWS"
      CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    })
  }
  
  azure_config = {
    # Service-specific naming patterns
    naming_patterns = {
      storage_account = substr(
        lower(replace("${var.name_prefix}sa${var.random_suffix}", "/[^a-z0-9]/", "")),
        0, 24
      )
      resource_group = "${var.name_prefix}-rg"
      key_vault     = "${var.name_prefix}-kv-${var.random_suffix}"
      vm            = var.name_prefix
      app_service   = "${var.name_prefix}-app"
      sql_server    = "${var.name_prefix}-sql"
    }
    
    # Standard tags
    standard_tags = merge(var.tags, {
      ManagedBy     = "Terraform"
      CloudProvider = "Azure"
      CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    })
  }
  
  gcp_config = {
    # Service-specific naming patterns
    naming_patterns = {
      storage_bucket   = "${lower(var.name_prefix)}-bucket-${var.random_suffix}"
      service_account  = "${lower(var.name_prefix)}-sa"
      compute_instance = lower(var.name_prefix)
      cloud_function   = lower(replace(var.name_prefix, "-", "_"))
      cloud_sql        = "${lower(var.name_prefix)}-db"
      gke_cluster      = "${lower(var.name_prefix)}-cluster"
    }
    
    # Standard labels (GCP uses labels instead of tags)
    standard_labels = {
      for key, value in var.tags :
      lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
    }
    
    # Enhanced labels with GCP-specific metadata
    enhanced_labels = merge(local.gcp_labels, {
      managed_by     = "terraform"
      cloud_provider = "gcp"
      created_date   = replace(formatdate("YYYY-MM-DD", timestamp()), "-", "_")
    })
  }
  
  # Cross-cloud compatibility helpers
  universal_name = lower(replace(var.name_prefix, "_", "-"))
  
  universal_metadata = {
    environment = lower(var.environment_type)
    managed_by  = "terraform"
    created     = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Convert tags to appropriate format for each cloud
  metadata_for_cloud = {
    aws   = merge(var.tags, local.universal_metadata)
    azure = merge(var.tags, local.universal_metadata)
    gcp   = {
      for key, value in merge(var.tags, local.universal_metadata) :
      lower(replace(key, " ", "_")) => lower(replace(value, " ", "_"))
    }
  }
  
  # Resource naming that works across clouds
  universal_resource_names = {
    storage    = "${local.universal_name}-storage-${var.random_suffix}"
    compute    = local.universal_name
    database   = "${local.universal_name}-db"
    network    = "${local.universal_name}-net"
    security   = "${local.universal_name}-sec"
    monitoring = "${local.universal_name}-mon"
    backup     = "${local.universal_name}-backup"
  }
}