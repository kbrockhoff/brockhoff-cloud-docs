# Multi-Cloud Integration Examples

This directory contains examples that demonstrate cross-cloud provider integration patterns, disaster recovery scenarios, and compliance framework implementations using Brockhoff Cloud Terraform modules.

## Overview

These examples showcase:
- Cross-cloud provider integration patterns
- Disaster recovery and backup strategies across clouds
- Hybrid and multi-cloud deployment architectures
- Compliance framework demonstrations across providers
- Data synchronization and replication patterns
- Unified monitoring and management across clouds

## Examples

### Cross-Cloud Backup and DR
- **Path**: `cross-cloud-backup/`
- **Providers**: Primary (any), Secondary (any)
- **Resources**: 15-25 resources per cloud
- **Estimated Cost**: $150-400/month
- **Complexity**: Advanced
- **Features**: Automated backup, failover, data sync

### Hybrid Cloud Architecture
- **Path**: `hybrid-deployment/`
- **Providers**: AWS + Azure or AWS + GCP
- **Resources**: 30-50 resources total
- **Estimated Cost**: $400-800/month
- **Complexity**: Expert
- **Features**: Workload distribution, unified networking, shared services

### Multi-Cloud Compliance
- **Path**: `compliance-demo/`
- **Providers**: AWS, Azure, GCP
- **Resources**: 20-30 resources per cloud
- **Estimated Cost**: $300-600/month
- **Complexity**: Advanced
- **Features**: Unified compliance reporting, cross-cloud auditing

### Global Load Balancing
- **Path**: `global-load-balancing/`
- **Providers**: AWS + Azure + GCP
- **Resources**: 10-20 resources per cloud
- **Estimated Cost**: $200-500/month
- **Complexity**: Advanced
- **Features**: DNS-based routing, health checks, failover

## Architecture Patterns

### Cross-Cloud Backup Pattern

```
┌─────────────────────────────────────────┐
│            Primary Cloud                │
│              (AWS)                      │
│  ┌─────────────────────────────────────┐│
│  │        Production Workload          ││
│  │  ┌─────────┐  ┌─────────┐         ││
│  │  │   App   │  │Database │         ││
│  │  │ Servers │  │ Primary │         ││
│  │  └─────────┘  └─────────┘         ││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │ Continuous Backup
              │ & Replication
┌─────────────▼───────────────────────────┐
│           Secondary Cloud               │
│             (Azure)                     │
│  ┌─────────────────────────────────────┐│
│  │         Backup & DR Site            ││
│  │  ┌─────────┐  ┌─────────┐         ││
│  │  │ Standby │  │Database │         ││
│  │  │ Servers │  │ Replica │         ││
│  │  └─────────┘  └─────────┘         ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Hybrid Cloud Pattern

```
┌─────────────────────────────────────────┐
│           On-Premises                   │
│  ┌─────────────────────────────────────┐│
│  │      Legacy Systems                 ││
│  │  ┌─────────┐  ┌─────────┐         ││
│  │  │Mainframe│  │Database │         ││
│  │  │Systems  │  │ Legacy  │         ││
│  │  └─────────┘  └─────────┘         ││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │ Private Connection
              │ (VPN/ExpressRoute/Interconnect)
┌─────────────▼───────────────────────────┐
│            Cloud Provider               │
│  ┌─────────────────────────────────────┐│
│  │       Modern Applications           ││
│  │  ┌─────────┐  ┌─────────┐         ││
│  │  │   API   │  │ Cloud   │         ││
│  │  │Gateway  │  │Services │         ││
│  │  └─────────┘  └─────────┘         ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Global Load Balancing Pattern

```
                    ┌─────────────┐
                    │   Global    │
                    │ DNS/Traffic │
                    │  Manager    │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼──────┐  ┌────────▼──────┐  ┌───────▼──────┐
│   AWS        │  │    Azure      │  │     GCP      │
│  us-west-2   │  │  West Europe  │  │ asia-east1   │
│              │  │               │  │              │
│ ┌──────────┐ │  │ ┌──────────┐  │  │ ┌──────────┐ │
│ │   App    │ │  │ │   App    │  │  │ │   App    │ │
│ │ Cluster  │ │  │ │ Cluster  │  │  │ │ Cluster  │ │
│ └──────────┘ │  │ └──────────┘  │  │ └──────────┘ │
└──────────────┘  └───────────────┘  └──────────────┘
```

## Cross-Cloud Integration Strategies

### 1. Data Synchronization

#### Real-Time Replication
```hcl
data_sync_config = {
  # Primary to secondary replication
  replication_strategy = "active-passive"
  
  # Replication methods by data type
  database_replication = {
    method = "logical_replication"  # PostgreSQL logical replication
    lag_threshold = 30  # seconds
    
    # Cross-cloud database replication
    source_cloud = "aws"
    target_cloud = "azure"
    
    # Encryption in transit
    ssl_mode = "require"
    ssl_cert_verification = true
  }
  
  # File synchronization
  file_sync = {
    # S3 to Azure Blob replication
    aws_to_azure = {
      source_bucket = "primary-data-bucket"
      target_container = "backup-data-container"
      sync_frequency = "hourly"
      
      # Delta sync for efficiency
      incremental_sync = true
    }
    
    # Azure to GCP replication
    azure_to_gcp = {
      source_container = "backup-data-container"
      target_bucket = "dr-data-bucket"
      sync_frequency = "daily"
    }
  }
}
```

#### Event-Driven Synchronization
```hcl
event_driven_sync = {
  # Cross-cloud event streaming
  event_bridge = {
    # AWS EventBridge to Azure Event Grid
    aws_to_azure = {
      source_bus = "primary-event-bus"
      target_namespace = "backup-event-namespace"
      
      # Event filtering
      event_patterns = [
        {
          source = ["myapp.orders"]
          detail-type = ["Order Created", "Order Updated"]
        }
      ]
    }
    
    # Message transformation
    transformation = {
      enabled = true
      lambda_function = "cross-cloud-event-transformer"
    }
  }
  
  # Message queues for reliable delivery
  message_queues = {
    # SQS to Service Bus relay
    cross_cloud_relay = {
      source_queue = "primary-processing-queue"
      target_queue = "backup-processing-queue"
      
      # Dead letter handling
      dead_letter_config = {
        max_receive_count = 3
        retention_period = 1209600  # 14 days
      }
    }
  }
}
```

### 2. Network Connectivity

#### VPN Connections
```hcl
vpn_connectivity = {
  # AWS to Azure VPN
  aws_azure_vpn = {
    # AWS side
    aws_customer_gateway = {
      bgp_asn = 65000
      ip_address = "203.0.113.12"  # Azure VPN Gateway public IP
      type = "ipsec.1"
    }
    
    # Azure side
    azure_vpn_gateway = {
      sku = "VpnGw1"
      vpn_type = "RouteBased"
      
      # Local network gateway for AWS
      local_network_gateway = {
        gateway_address = "203.0.113.10"  # AWS VPN Gateway public IP
        address_space = ["10.0.0.0/16"]   # AWS VPC CIDR
      }
    }
    
    # Connection configuration
    connection_config = {
      shared_key = var.vpn_shared_key
      ike_version = "IKEv2"
      
      # BGP configuration
      enable_bgp = true
      bgp_settings = {
        asn = 65515
        bgp_peering_address = "169.254.21.1"
      }
    }
  }
  
  # AWS to GCP VPN
  aws_gcp_vpn = {
    # Cloud VPN configuration
    gcp_vpn_gateway = {
      region = "us-central1"
      
      # Tunnels to AWS
      tunnels = [
        {
          peer_ip = "203.0.113.10"  # AWS VPN Gateway IP
          shared_secret = var.vpn_shared_key
          ike_version = 2
        }
      ]
    }
    
    # Route-based VPN
    routing = {
      type = "ROUTE_BASED"
      
      # Cloud Router for BGP
      cloud_router = {
        asn = 64512
        
        # BGP peers
        bgp_peers = [
          {
            name = "aws-peer"
            peer_ip_address = "169.254.21.2"
            peer_asn = 65000
          }
        ]
      }
    }
  }
}
```

#### Private Connectivity
```hcl
private_connectivity = {
  # AWS Direct Connect to Azure ExpressRoute
  aws_azure_private = {
    # AWS Direct Connect
    direct_connect = {
      connection_id = "dxcon-xxxxxxxxx"
      vlan = 100
      
      # Virtual interface
      virtual_interface = {
        vlan = 100
        bgp_asn = 65000
        address_family = "ipv4"
      }
    }
    
    # Azure ExpressRoute
    expressroute = {
      circuit_name = "cross-cloud-circuit"
      service_provider = "Equinix"
      peering_location = "Silicon Valley"
      bandwidth_in_mbps = 1000
      
      # Private peering
      private_peering = {
        peer_asn = 65000
        primary_peer_address_prefix = "192.168.1.0/30"
        secondary_peer_address_prefix = "192.168.1.4/30"
        vlan_id = 100
      }
    }
  }
  
  # GCP Partner Interconnect
  gcp_interconnect = {
    interconnect_attachment = {
      name = "cross-cloud-attachment"
      type = "PARTNER"
      
      # VLAN configuration
      vlan_tag8021q = 200
      
      # Cloud Router
      router = "cross-cloud-router"
      region = "us-central1"
    }
  }
}
```

### 3. Identity Federation

#### Cross-Cloud Identity Management
```hcl
identity_federation = {
  # SAML-based federation
  saml_federation = {
    # AWS IAM Identity Provider
    aws_identity_provider = {
      name = "AzureAD-SAML"
      saml_metadata_document = file("azure-ad-metadata.xml")
      
      # Roles for federated users
      federated_roles = [
        {
          role_name = "CrossCloudAdmin"
          principal_arn = "arn:aws:iam::account:saml-provider/AzureAD-SAML"
          
          # Trust policy
          trust_policy = {
            condition = {
              "StringEquals" = {
                "SAML:aud" = "https://signin.aws.amazon.com/saml"
              }
            }
          }
        }
      ]
    }
    
    # Azure AD Enterprise Application
    azure_enterprise_app = {
      name = "AWS-Cross-Cloud-Access"
      
      # SAML configuration
      saml_settings = {
        identifier = "urn:amazon:webservices"
        reply_url = "https://signin.aws.amazon.com/saml"
        
        # Attribute mapping
        attribute_mapping = {
          "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier" = "user.userprincipalname"
          "https://aws.amazon.com/SAML/Attributes/Role" = "user.assignedroles"
        }
      }
    }
  }
  
  # OIDC federation
  oidc_federation = {
    # GCP Workload Identity Federation
    gcp_workload_identity = {
      pool_id = "cross-cloud-pool"
      
      # AWS provider
      aws_provider = {
        provider_id = "aws-provider"
        
        # Attribute mapping
        attribute_mapping = {
          "google.subject" = "assertion.arn"
          "attribute.aws_role" = "assertion.arn.extract('assumed-role/{role}/')"
        }
        
        # Attribute conditions
        attribute_condition = "assertion.aud == 'sts.amazonaws.com'"
      }
    }
  }
}
```

### 4. Monitoring and Observability

#### Unified Monitoring
```hcl
unified_monitoring = {
  # Cross-cloud metrics aggregation
  metrics_aggregation = {
    # Prometheus federation
    prometheus_federation = {
      # Central Prometheus server
      central_server = {
        cloud_provider = "aws"
        instance_type = "t3.large"
        
        # Scrape configs for remote clouds
        scrape_configs = [
          {
            job_name = "azure-metrics"
            static_configs = [
              {
                targets = ["azure-prometheus.example.com:9090"]
              }
            ]
          },
          {
            job_name = "gcp-metrics"
            static_configs = [
              {
                targets = ["gcp-prometheus.example.com:9090"]
              }
            ]
          }
        ]
      }
      
      # Remote write configuration
      remote_write = [
        {
          url = "https://central-prometheus.example.com/api/v1/write"
          
          # Authentication
          basic_auth = {
            username = var.prometheus_username
            password = var.prometheus_password
          }
        }
      ]
    }
    
    # Grafana dashboards
    grafana_dashboards = {
      # Multi-cloud overview dashboard
      multi_cloud_overview = {
        title = "Multi-Cloud Infrastructure Overview"
        
        panels = [
          {
            title = "Cross-Cloud Resource Health"
            type = "stat"
            targets = [
              {
                expr = "up{job=~'aws-.*|azure-.*|gcp-.*'}"
                legend = "{{cloud}}-{{service}}"
              }
            ]
          },
          {
            title = "Cross-Cloud Latency"
            type = "graph"
            targets = [
              {
                expr = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
                legend = "{{cloud}}-{{region}}"
              }
            ]
          }
        ]
      }
    }
  }
  
  # Distributed tracing
  distributed_tracing = {
    # Jaeger deployment
    jaeger_config = {
      # Collector in each cloud
      collectors = [
        {
          cloud = "aws"
          endpoint = "jaeger-collector-aws.example.com:14268"
        },
        {
          cloud = "azure"
          endpoint = "jaeger-collector-azure.example.com:14268"
        },
        {
          cloud = "gcp"
          endpoint = "jaeger-collector-gcp.example.com:14268"
        }
      ]
      
      # Central query service
      query_service = {
        cloud = "aws"
        endpoint = "jaeger-query.example.com:16686"
        
        # Storage backend
        storage = {
          type = "elasticsearch"
          elasticsearch_url = "https://elasticsearch.example.com:9200"
        }
      }
    }
  }
}
```

## Disaster Recovery Strategies

### 1. Active-Passive DR

#### RTO/RPO Configuration
```hcl
active_passive_dr = {
  # Recovery objectives
  recovery_objectives = {
    rto = 3600  # 1 hour Recovery Time Objective
    rpo = 300   # 5 minutes Recovery Point Objective
  }
  
  # Primary site (AWS)
  primary_site = {
    cloud_provider = "aws"
    region = "us-west-2"
    
    # Production workload
    workload_config = {
      compute_instances = 6
      database_config = {
        instance_class = "db.r5.xlarge"
        multi_az = true
        backup_retention = 7
      }
      
      # Continuous backup to secondary
      backup_strategy = {
        frequency = "every_5_minutes"
        destination = "azure_secondary"
        encryption = true
      }
    }
  }
  
  # Secondary site (Azure)
  secondary_site = {
    cloud_provider = "azure"
    region = "West US 2"
    
    # Standby configuration
    standby_config = {
      # Minimal compute for cost optimization
      compute_instances = 2
      instance_size = "Standard_B2s"
      
      # Database replica
      database_config = {
        sku_name = "GP_Gen5_4"
        
        # Restore from backup capability
        restore_capability = {
          point_in_time_restore = true
          geo_restore = true
        }
      }
    }
    
    # Failover automation
    failover_automation = {
      # Health check triggers
      health_checks = [
        {
          type = "http"
          endpoint = "https://primary-app.example.com/health"
          timeout = 30
          interval = 60
          failure_threshold = 3
        }
      ]
      
      # Automated failover actions
      failover_actions = [
        "update_dns_records",
        "start_standby_instances",
        "promote_database_replica",
        "notify_operations_team"
      ]
    }
  }
}
```

### 2. Active-Active Multi-Region

#### Global Load Balancing
```hcl
active_active_dr = {
  # Global traffic distribution
  traffic_distribution = {
    # DNS-based routing
    dns_routing = {
      provider = "route53"  # or "azure_dns", "cloud_dns"
      
      # Health check configuration
      health_checks = [
        {
          region = "aws-us-west-2"
          endpoint = "https://aws-app.example.com/health"
          weight = 50
        },
        {
          region = "azure-west-us-2"
          endpoint = "https://azure-app.example.com/health"
          weight = 30
        },
        {
          region = "gcp-us-central1"
          endpoint = "https://gcp-app.example.com/health"
          weight = 20
        }
      ]
      
      # Failover policy
      failover_policy = {
        type = "weighted"
        
        # Automatic failover on health check failure
        automatic_failover = true
        
        # Failback configuration
        failback = {
          enabled = true
          delay = 300  # 5 minutes after health restoration
        }
      }
    }
  }
  
  # Data consistency
  data_consistency = {
    # Multi-master database replication
    database_replication = {
      type = "multi_master"
      
      # Conflict resolution
      conflict_resolution = "last_write_wins"
      
      # Replication topology
      topology = [
        {
          source = "aws-primary"
          targets = ["azure-replica", "gcp-replica"]
        },
        {
          source = "azure-primary"
          targets = ["aws-replica", "gcp-replica"]
        },
        {
          source = "gcp-primary"
          targets = ["aws-replica", "azure-replica"]
        }
      ]
    }
    
    # Eventual consistency for file storage
    file_consistency = {
      sync_strategy = "eventual_consistency"
      
      # Cross-region replication
      replication_rules = [
        {
          source = "s3://aws-primary-bucket"
          destinations = [
            "https://azureprimary.blob.core.windows.net/primary-container",
            "gs://gcp-primary-bucket"
          ]
          sync_frequency = "real_time"
        }
      ]
    }
  }
}
```

## Compliance Across Clouds

### Unified Compliance Framework
```hcl
unified_compliance = {
  # SOC 2 compliance across all clouds
  soc2_compliance = {
    # Common controls implementation
    common_controls = {
      cc1_1 = {
        control_name = "Control Environment"
        
        # Implementation per cloud
        implementations = {
          aws = "aws_organizations_scp"
          azure = "azure_policy"
          gcp = "gcp_organization_policy"
        }
        
        # Evidence collection
        evidence_collection = {
          automated = true
          frequency = "daily"
          
          # Cross-cloud evidence aggregation
          aggregation_service = "compliance-dashboard"
        }
      }
      
      cc6_1 = {
        control_name = "Logical Access Controls"
        
        implementations = {
          aws = "aws_iam_policies"
          azure = "azure_rbac"
          gcp = "gcp_iam_policies"
        }
        
        # Unified access review
        access_review = {
          frequency = "quarterly"
          automated_reporting = true
          
          # Cross-cloud access analysis
          cross_cloud_analysis = true
        }
      }
    }
  }
  
  # GDPR compliance
  gdpr_compliance = {
    # Data mapping across clouds
    data_mapping = {
      personal_data_inventory = {
        # Automated discovery
        discovery_tools = [
          "aws_macie",
          "azure_purview",
          "gcp_dlp"
        ]
        
        # Cross-cloud data catalog
        unified_catalog = {
          enabled = true
          
          # Data classification
          classification_levels = [
            "public",
            "internal",
            "confidential",
            "restricted"
          ]
        }
      }
    }
    
    # Right to be forgotten implementation
    data_deletion = {
      # Cross-cloud deletion workflow
      deletion_workflow = {
        trigger = "data_subject_request"
        
        # Deletion across all clouds
        deletion_targets = [
          "aws_s3_buckets",
          "azure_blob_storage",
          "gcp_cloud_storage",
          "aws_rds_databases",
          "azure_sql_databases",
          "gcp_cloud_sql"
        ]
        
        # Verification and reporting
        verification = {
          automated_verification = true
          compliance_report = true
        }
      }
    }
  }
}
```

## Cost Optimization Across Clouds

### Multi-Cloud Cost Management
```hcl
cost_optimization = {
  # Cross-cloud cost monitoring
  cost_monitoring = {
    # Unified cost dashboard
    unified_dashboard = {
      # Cost aggregation from all clouds
      cost_sources = [
        {
          cloud = "aws"
          api = "cost_explorer"
          credentials = "aws_cost_role"
        },
        {
          cloud = "azure"
          api = "consumption_api"
          credentials = "azure_cost_sp"
        },
        {
          cloud = "gcp"
          api = "billing_api"
          credentials = "gcp_cost_sa"
        }
      ]
      
      # Cost allocation and chargeback
      cost_allocation = {
        # Tag-based allocation
        allocation_tags = [
          "Environment",
          "Project",
          "Owner",
          "CostCenter"
        ]
        
        # Cross-cloud cost normalization
        currency_normalization = "USD"
        
        # Chargeback reports
        chargeback_frequency = "monthly"
      }
    }
  }
  
  # Workload placement optimization
  workload_placement = {
    # Cost-based placement decisions
    placement_algorithm = {
      # Factors for placement decisions
      factors = [
        "compute_cost",
        "storage_cost",
        "network_cost",
        "data_transfer_cost",
        "compliance_requirements",
        "performance_requirements"
      ]
      
      # Automated recommendations
      recommendations = {
        frequency = "weekly"
        
        # Cost savings threshold for recommendations
        min_savings_percentage = 10
        
        # Implementation automation
        auto_implementation = {
          enabled = false  # Manual approval required
          approval_workflow = "cost_optimization_approval"
        }
      }
    }
  }
}
```

## Quick Start Guide

### Prerequisites

1. **Multi-cloud accounts** with appropriate permissions
2. **Network connectivity** between clouds (VPN or private connections)
3. **Identity federation** setup (optional but recommended)
4. **Monitoring infrastructure** for cross-cloud observability

### Deployment Steps

1. **Choose your integration pattern**:
   ```bash
   cd examples/multi-cloud/cross-cloud-backup  # or other pattern
   ```

2. **Configure cross-cloud credentials**:
   ```bash
   # Set up provider credentials for all clouds
   export AWS_PROFILE=cross-cloud
   export ARM_SUBSCRIPTION_ID=your-azure-subscription
   export GOOGLE_APPLICATION_CREDENTIALS=gcp-service-account.json
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan -var-file="multi-cloud.tfvars"
   terraform apply
   ```

4. **Validate connectivity**:
   ```bash
   # Test cross-cloud connectivity
   ./scripts/test-connectivity.sh
   
   # Verify data replication
   ./scripts/verify-replication.sh
   ```

## Best Practices

### Multi-Cloud Architecture Principles

1. **Cloud-Agnostic Design**: Use standardized interfaces and avoid cloud-specific features where possible
2. **Data Sovereignty**: Understand data residency requirements and regulations
3. **Network Latency**: Consider geographic proximity for performance-critical workloads
4. **Cost Optimization**: Leverage each cloud's strengths and pricing advantages
5. **Vendor Lock-in Avoidance**: Maintain portability and avoid proprietary services
6. **Security Consistency**: Implement consistent security controls across all clouds
7. **Operational Simplicity**: Minimize complexity in multi-cloud operations

### Common Pitfalls to Avoid

- **Over-engineering**: Don't make it multi-cloud unless there's a clear business need
- **Data transfer costs**: Be aware of egress charges between clouds
- **Complexity overhead**: Multi-cloud adds operational complexity
- **Skill requirements**: Ensure team has expertise across all used clouds
- **Compliance gaps**: Ensure consistent compliance across all environments

## Support and Troubleshooting

### Common Issues

1. **Network connectivity problems**: Check VPN/private connection status
2. **Data synchronization lag**: Monitor replication metrics and adjust configuration
3. **Identity federation issues**: Verify SAML/OIDC configuration and certificates
4. **Cost overruns**: Monitor cross-cloud data transfer and optimize placement

### Monitoring and Alerting

- **Cross-cloud connectivity monitoring**
- **Data replication lag alerts**
- **Cost anomaly detection**
- **Security event correlation**
- **Compliance drift detection**

These multi-cloud examples provide proven patterns for implementing complex cross-cloud architectures while maintaining security, compliance, and cost-effectiveness.
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->