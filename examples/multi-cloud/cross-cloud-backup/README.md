# Cross-Cloud Backup and Disaster Recovery

This example demonstrates a comprehensive backup and disaster recovery solution that spans multiple cloud providers, ensuring business continuity and data protection across AWS, Azure, and GCP.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Primary Site (AWS)              │
│           us-west-2                     │
│  ┌─────────────────────────────────────┐│
│  │      Production Environment         ││
│  │                                     ││
│  │  ┌─────────┐  ┌─────────────────┐  ││
│  │  │   Web   │  │   Application   │  ││
│  │  │  Tier   │  │      Tier       │  ││
│  │  └─────────┘  └─────────────────┘  ││
│  │                                     ││
│  │  ┌─────────────────────────────────┐││
│  │  │        Database Tier            │││
│  │  │     PostgreSQL Primary          │││
│  │  │   - Continuous WAL shipping     │││
│  │  │   - Point-in-time recovery      │││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │
              │ Continuous Replication
              │ - Database WAL shipping
              │ - File sync every 15 minutes
              │ - Configuration backup hourly
              │
┌─────────────▼───────────────────────────┐
│      Secondary Site (Azure)             │
│          West US 2                      │
│  ┌─────────────────────────────────────┐│
│  │       Standby Environment           ││
│  │                                     ││
│  │  ┌─────────┐  ┌─────────────────┐  ││
│  │  │Standby  │  │    Standby      │  ││
│  │  │ Web     │  │  Application    │  ││
│  │  │ (Scaled │  │   (Minimal)     │  ││
│  │  │  Down)  │  │                 │  ││
│  │  └─────────┘  └─────────────────┘  ││
│  │                                     ││
│  │  ┌─────────────────────────────────┐││
│  │  │      Database Replica           │││
│  │  │   PostgreSQL Standby            │││
│  │  │ - Streaming replication         │││
│  │  │ - Read-only queries allowed     │││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │
              │ Backup Archive
              │ - Daily full backups
              │ - 30-day retention
              │ - Compliance archival
              │
┌─────────────▼───────────────────────────┐
│       Archive Site (GCP)                │
│         us-central1                     │
│  ┌─────────────────────────────────────┐│
│  │      Long-term Archive              ││
│  │                                     ││
│  │  ┌─────────────────────────────────┐││
│  │  │     Cold Storage Archive        │││
│  │  │  - Nearline/Coldline storage    │││
│  │  │  - 7-year retention             │││
│  │  │  - Compliance requirements      │││
│  │  │  - Encrypted at rest            │││
│  │  └─────────────────────────────────┘││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Recovery Objectives

### Service Level Objectives (SLOs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **RTO** (Recovery Time Objective) | < 1 hour | Time to restore service |
| **RPO** (Recovery Point Objective) | < 5 minutes | Maximum data loss |
| **Availability** | 99.9% | Monthly uptime |
| **Data Durability** | 99.999999999% | 11 nines durability |

### Recovery Scenarios

#### Scenario 1: Primary Site Failure
- **Trigger**: Complete AWS region outage
- **Action**: Automatic failover to Azure secondary site
- **RTO**: 45 minutes (automated)
- **RPO**: < 5 minutes (streaming replication)

#### Scenario 2: Database Corruption
- **Trigger**: Database corruption or accidental deletion
- **Action**: Point-in-time recovery from WAL archives
- **RTO**: 30 minutes (automated restore)
- **RPO**: < 1 minute (WAL shipping)

#### Scenario 3: Ransomware Attack
- **Trigger**: Malware detection or encryption
- **Action**: Restore from immutable backups
- **RTO**: 2 hours (full environment rebuild)
- **RPO**: < 15 minutes (backup frequency)

## Implementation Components

### 1. Database Replication

#### PostgreSQL Streaming Replication
```hcl
database_replication = {
  # Primary database (AWS RDS)
  primary_database = {
    engine = "postgres"
    engine_version = "14.9"
    instance_class = "db.r5.xlarge"
    
    # Replication configuration
    backup_retention_period = 7
    backup_window = "03:00-04:00"
    
    # WAL configuration for replication
    parameters = {
      wal_level = "replica"
      max_wal_senders = 10
      wal_keep_segments = 32
      
      # Streaming replication settings
      synchronous_commit = "remote_apply"
      synchronous_standby_names = "azure_replica"
    }
    
    # Cross-cloud replication user
    replication_user = {
      username = "replication_user"
      password = var.replication_password
      
      # Replication permissions
      permissions = [
        "REPLICATION",
        "LOGIN"
      ]
    }
  }
  
  # Replica database (Azure Database for PostgreSQL)
  replica_database = {
    sku_name = "GP_Gen5_4"
    
    # Replication configuration
    replication_mode = "streaming"
    
    # Connection to primary
    primary_connection = {
      host = module.primary_database.endpoint
      port = 5432
      username = "replication_user"
      password = var.replication_password
      
      # SSL configuration
      ssl_mode = "require"
      ssl_cert = file("client-cert.pem")
      ssl_key = file("client-key.pem")
      ssl_ca = file("ca-cert.pem")
    }
    
    # Standby configuration
    standby_mode = "on"
    recovery_target_timeline = "latest"
    
    # Hot standby for read queries
    hot_standby = "on"
    max_standby_streaming_delay = "30s"
  }
}
```

#### Cross-Cloud WAL Shipping
```hcl
wal_shipping = {
  # WAL archive configuration
  archive_command = {
    # Ship WAL files to multiple destinations
    destinations = [
      {
        type = "s3"
        bucket = "primary-wal-archive"
        path = "wal-files/"
        
        # Encryption
        encryption = "aws:kms"
        kms_key_id = "alias/wal-encryption"
      },
      {
        type = "azure_blob"
        container = "wal-archive-container"
        path = "wal-files/"
        
        # Cross-cloud transfer
        transfer_method = "azcopy"
        
        # Encryption
        encryption = "customer_managed"
        key_vault_key = "wal-encryption-key"
      },
      {
        type = "gcs"
        bucket = "wal-archive-bucket"
        path = "wal-files/"
        
        # Long-term archive
        storage_class = "NEARLINE"
        
        # Encryption
        encryption = "google_managed"
      }
    ]
  }
  
  # WAL restore configuration
  restore_command = {
    # Prioritized restore sources
    sources = [
      "azure_blob://wal-archive-container/wal-files/%f",
      "s3://primary-wal-archive/wal-files/%f",
      "gs://wal-archive-bucket/wal-files/%f"
    ]
    
    # Parallel restore for faster recovery
    parallel_jobs = 4
    
    # Verification
    verify_checksums = true
  }
}
```

### 2. File System Backup

#### Application Data Synchronization
```hcl
file_sync = {
  # Real-time file synchronization
  real_time_sync = {
    # Source: AWS EFS
    source = {
      type = "efs"
      file_system_id = module.primary_efs.id
      mount_path = "/app/data"
      
      # Sync triggers
      triggers = [
        "file_create",
        "file_modify",
        "file_delete"
      ]
    }
    
    # Destination: Azure Files
    destination = {
      type = "azure_files"
      storage_account = module.backup_storage.name
      share_name = "app-data-backup"
      
      # Sync method
      sync_method = "rsync"
      
      # Bandwidth throttling
      bandwidth_limit = "100MB/s"
      
      # Conflict resolution
      conflict_resolution = "source_wins"
    }
    
    # Sync schedule
    schedule = {
      # Continuous sync during business hours
      business_hours = "*/15 * 8-18 * * MON-FRI"
      
      # Hourly sync during off-hours
      off_hours = "0 * 19-7,0-7 * * *"
      
      # Full sync weekly
      full_sync = "0 2 * * SUN"
    }
  }
  
  # Backup verification
  verification = {
    # Checksum verification
    checksum_algorithm = "sha256"
    
    # Automated verification schedule
    verification_schedule = "0 4 * * *"  # Daily at 4 AM
    
    # Verification reports
    report_destination = "s3://backup-reports/file-verification/"
    
    # Alert on verification failures
    alert_on_failure = true
  }
}
```

#### Configuration Backup
```hcl
configuration_backup = {
  # Infrastructure as Code backup
  iac_backup = {
    # Terraform state backup
    terraform_state = {
      # Multiple backend copies
      backends = [
        {
          type = "s3"
          bucket = "terraform-state-backup"
          key = "production/terraform.tfstate"
          
          # Versioning and encryption
          versioning = true
          encryption = true
        },
        {
          type = "azurerm"
          storage_account_name = "tfstatebackup"
          container_name = "tfstate"
          key = "production.tfstate"
        }
      ]
      
      # State file verification
      verification = {
        checksum_validation = true
        backup_frequency = "hourly"
      }
    }
    
    # Configuration files backup
    config_files = {
      # Application configuration
      app_configs = [
        "/etc/myapp/",
        "/opt/myapp/config/",
        "/var/lib/myapp/settings/"
      ]
      
      # System configuration
      system_configs = [
        "/etc/nginx/",
        "/etc/ssl/",
        "/etc/systemd/system/"
      ]
      
      # Backup destination
      backup_destination = {
        primary = "s3://config-backup-primary/"
        secondary = "azure://configbackup/configs/"
        archive = "gs://config-archive/"
      }
    }
  }
}
```

### 3. Automated Failover

#### Health Monitoring
```hcl
health_monitoring = {
  # Multi-layer health checks
  health_checks = [
    {
      name = "application_health"
      type = "http"
      endpoint = "https://app.example.com/health"
      
      # Check configuration
      timeout = 30
      interval = 60
      failure_threshold = 3
      success_threshold = 2
      
      # Expected response
      expected_status = 200
      expected_body_contains = "healthy"
    },
    {
      name = "database_health"
      type = "tcp"
      endpoint = "db.example.com:5432"
      
      # Database-specific checks
      query = "SELECT 1"
      timeout = 10
      interval = 30
      failure_threshold = 2
    },
    {
      name = "replication_lag"
      type = "custom"
      script = "/opt/scripts/check-replication-lag.sh"
      
      # Lag thresholds
      warning_threshold = 30   # seconds
      critical_threshold = 300 # seconds
      
      interval = 60
    }
  ]
  
  # Health check aggregation
  aggregation = {
    # Overall health calculation
    algorithm = "weighted_average"
    
    # Component weights
    weights = {
      application_health = 40
      database_health = 40
      replication_lag = 20
    }
    
    # Failover threshold
    failover_threshold = 70  # Percentage
  }
}
```

#### Automated Failover Process
```hcl
failover_automation = {
  # Failover decision engine
  decision_engine = {
    # Failover triggers
    triggers = [
      {
        condition = "health_score < 70"
        duration = "5 minutes"
        action = "initiate_failover"
      },
      {
        condition = "primary_site_unreachable"
        duration = "2 minutes"
        action = "emergency_failover"
      },
      {
        condition = "replication_lag > 300"
        duration = "10 minutes"
        action = "investigate_and_alert"
      }
    ]
    
    # Failover steps
    failover_steps = [
      {
        step = 1
        action = "stop_primary_writes"
        timeout = "30 seconds"
        
        # Rollback on failure
        rollback_action = "restore_primary_writes"
      },
      {
        step = 2
        action = "promote_replica_database"
        timeout = "2 minutes"
        
        # Verification
        verification = "test_database_writes"
      },
      {
        step = 3
        action = "update_dns_records"
        timeout = "1 minute"
        
        # DNS propagation
        propagation_check = true
      },
      {
        step = 4
        action = "scale_up_secondary_infrastructure"
        timeout = "10 minutes"
        
        # Target capacity
        target_capacity = "production_level"
      },
      {
        step = 5
        action = "notify_operations_team"
        timeout = "immediate"
        
        # Notification channels
        channels = ["email", "slack", "pagerduty"]
      }
    ]
  }
  
  # Failback automation
  failback_automation = {
    # Failback conditions
    conditions = [
      "primary_site_healthy_for_30_minutes",
      "manual_approval_received",
      "data_consistency_verified"
    ]
    
    # Failback process
    failback_steps = [
      {
        step = 1
        action = "sync_data_to_primary"
        timeout = "30 minutes"
      },
      {
        step = 2
        action = "verify_data_consistency"
        timeout = "10 minutes"
      },
      {
        step = 3
        action = "switch_traffic_to_primary"
        timeout = "5 minutes"
        
        # Gradual traffic shift
        traffic_shift = {
          initial_percentage = 10
          increment = 10
          interval = "2 minutes"
        }
      }
    ]
  }
}
```

### 4. Compliance and Auditing

#### Backup Compliance
```hcl
backup_compliance = {
  # Regulatory requirements
  regulatory_requirements = {
    # SOX compliance
    sox = {
      retention_period = 2555  # 7 years
      
      # Immutable backups
      immutable_backups = true
      
      # Audit trail
      audit_trail = {
        backup_operations = true
        restore_operations = true
        access_logs = true
      }
    }
    
    # GDPR compliance
    gdpr = {
      # Data subject rights
      right_to_be_forgotten = {
        enabled = true
        
        # Cross-cloud deletion
        deletion_workflow = "gdpr_deletion_process"
      }
      
      # Data portability
      data_export = {
        format = "json"
        encryption = true
      }
    }
    
    # HIPAA compliance (if applicable)
    hipaa = {
      encryption_at_rest = true
      encryption_in_transit = true
      
      # Access controls
      access_controls = {
        mfa_required = true
        role_based_access = true
        
        # Audit logging
        audit_all_access = true
      }
    }
  }
  
  # Compliance monitoring
  compliance_monitoring = {
    # Automated compliance checks
    automated_checks = [
      {
        name = "backup_encryption_check"
        frequency = "daily"
        
        # Check all backup destinations
        scope = "all_backup_destinations"
      },
      {
        name = "retention_policy_check"
        frequency = "weekly"
        
        # Verify retention compliance
        check_type = "retention_compliance"
      },
      {
        name = "access_control_audit"
        frequency = "monthly"
        
        # Review access permissions
        scope = "backup_access_permissions"
      }
    ]
    
    # Compliance reporting
    reporting = {
      # Monthly compliance reports
      monthly_report = {
        enabled = true
        
        # Report contents
        include_sections = [
          "backup_status",
          "retention_compliance",
          "security_controls",
          "access_audit"
        ]
        
        # Distribution
        recipients = [
          "compliance@company.com",
          "security@company.com",
          "audit@company.com"
        ]
      }
    }
  }
}
```

## Cost Optimization

### Tiered Storage Strategy
```hcl
storage_optimization = {
  # Intelligent tiering
  intelligent_tiering = {
    # Hot tier (frequent access)
    hot_tier = {
      duration = "30 days"
      
      storage_classes = {
        aws = "STANDARD"
        azure = "Hot"
        gcp = "STANDARD"
      }
    }
    
    # Warm tier (infrequent access)
    warm_tier = {
      duration = "90 days"
      
      storage_classes = {
        aws = "STANDARD_IA"
        azure = "Cool"
        gcp = "NEARLINE"
      }
    }
    
    # Cold tier (archive)
    cold_tier = {
      duration = "365 days"
      
      storage_classes = {
        aws = "GLACIER"
        azure = "Archive"
        gcp = "COLDLINE"
      }
    }
    
    # Deep archive (long-term retention)
    deep_archive = {
      duration = "2555 days"  # 7 years
      
      storage_classes = {
        aws = "DEEP_ARCHIVE"
        azure = "Archive"
        gcp = "ARCHIVE"
      }
    }
  }
  
  # Cost monitoring
  cost_monitoring = {
    # Budget alerts
    budgets = [
      {
        name = "backup_storage_budget"
        amount = 1000  # USD per month
        
        # Alert thresholds
        alert_thresholds = [50, 80, 100]
        
        # Cost allocation
        cost_filters = {
          service = ["S3", "Blob Storage", "Cloud Storage"]
          tag = {
            Purpose = "Backup"
          }
        }
      }
    ]
    
    # Cost optimization recommendations
    optimization_recommendations = {
      frequency = "weekly"
      
      # Recommendation types
      recommendation_types = [
        "storage_class_optimization",
        "lifecycle_policy_optimization",
        "cross_cloud_cost_comparison"
      ]
    }
  }
}
```

## Testing and Validation

### Disaster Recovery Testing
```hcl
dr_testing = {
  # Automated DR tests
  automated_tests = [
    {
      name = "database_failover_test"
      frequency = "monthly"
      
      # Test steps
      steps = [
        "simulate_primary_database_failure",
        "verify_automatic_failover",
        "test_application_connectivity",
        "verify_data_consistency",
        "perform_failback"
      ]
      
      # Success criteria
      success_criteria = {
        rto_met = true
        rpo_met = true
        data_integrity = true
        application_functional = true
      }
    },
    {
      name = "full_site_failover_test"
      frequency = "quarterly"
      
      # Comprehensive test
      scope = "full_environment"
      
      # Test during maintenance window
      maintenance_window = "Saturday 2:00-6:00 AM"
    }
  ]
  
  # Manual testing procedures
  manual_tests = [
    {
      name = "annual_dr_exercise"
      frequency = "annually"
      
      # Full-scale exercise
      participants = [
        "operations_team",
        "development_team",
        "management",
        "external_stakeholders"
      ]
      
      # Scenario-based testing
      scenarios = [
        "natural_disaster",
        "cyber_attack",
        "hardware_failure",
        "human_error"
      ]
    }
  ]
}
```

## Quick Start

### Prerequisites
1. **Multi-cloud accounts** with appropriate permissions
2. **Network connectivity** between clouds (VPN recommended)
3. **DNS management** capability for failover
4. **Monitoring infrastructure** for health checks

### Deployment Steps

1. **Configure cross-cloud credentials**:
   ```bash
   # AWS credentials
   export AWS_PROFILE=backup-primary
   
   # Azure credentials
   export ARM_SUBSCRIPTION_ID=your-subscription-id
   export ARM_CLIENT_ID=your-client-id
   export ARM_CLIENT_SECRET=your-client-secret
   export ARM_TENANT_ID=your-tenant-id
   
   # GCP credentials
   export GOOGLE_APPLICATION_CREDENTIALS=gcp-service-account.json
   ```

2. **Deploy primary infrastructure**:
   ```bash
   cd primary-site/aws
   terraform init
   terraform apply -var-file="production.tfvars"
   ```

3. **Deploy secondary infrastructure**:
   ```bash
   cd ../secondary-site/azure
   terraform init
   terraform apply -var-file="dr.tfvars"
   ```

4. **Configure replication**:
   ```bash
   # Set up database replication
   ./scripts/setup-database-replication.sh
   
   # Configure file synchronization
   ./scripts/setup-file-sync.sh
   ```

5. **Test failover**:
   ```bash
   # Run DR test
   ./scripts/test-failover.sh
   ```

This cross-cloud backup and DR solution provides enterprise-grade business continuity with automated failover, comprehensive monitoring, and compliance-ready audit trails.