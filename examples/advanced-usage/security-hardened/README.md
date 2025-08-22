# Security-Hardened Deployment Example

This example demonstrates a security-first architecture that implements defense-in-depth principles, zero-trust networking, and comprehensive compliance controls suitable for highly regulated environments.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│              WAF + Shield               │
│         (DDoS Protection)               │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          DMZ Network                    │
│      (Public Subnet)                    │
│  ┌─────────────────────────────────────┐│
│  │       Bastion Hosts                 ││
│  │    (Hardened Jump Boxes)            ││
│  │  - MFA Required                     ││
│  │  - Session Recording               ││
│  │  - Time-based Access               ││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │ (VPN/Private Link Only)
┌─────────────▼───────────────────────────┐
│        Application Network              │
│      (Private Subnets)                  │
│  ┌─────────────────────────────────────┐│
│  │     Application Servers             ││
│  │  - Encrypted at Rest/Transit        ││
│  │  - Runtime Security                 ││
│  │  - Vulnerability Scanning           ││
│  │  - Compliance Monitoring            ││
│  └─────────────────────────────────────┘│
└─────────────┬───────────────────────────┘
              │ (Database VPC Peering)
┌─────────────▼───────────────────────────┐
│         Database Network                │
│    (Isolated Subnets)                   │
│  ┌─────────────────────────────────────┐│
│  │      Encrypted Databases            ││
│  │  - TDE + Column Encryption          ││
│  │  - Database Activity Monitoring     ││
│  │  - Backup Encryption               ││
│  │  - Access Logging                  ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         Security Services               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │   KMS   │ │  SIEM   │ │ Secrets │   │
│  │Key Mgmt │ │Security │ │Manager  │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │Inspector│ │GuardDuty│ │Config   │   │
│  │Vuln Scan│ │Threat   │ │Compliance│   │
│  └─────────┘ └─────────┘ └─────────┘   │
└─────────────────────────────────────────┘
```

## Security Controls

### 1. Network Security (Defense in Depth)

#### Perimeter Security
- **AWS WAF**: Application-layer protection with OWASP Top 10 rules
- **AWS Shield Advanced**: DDoS protection with 24/7 response team
- **CloudFront**: Geographic restrictions and bot protection
- **Network ACLs**: Subnet-level stateless filtering

#### Network Segmentation
- **VPC Isolation**: Separate VPCs for different security zones
- **Private Subnets**: No direct internet access for application tiers
- **Security Groups**: Least-privilege, application-aware rules
- **VPC Flow Logs**: Network traffic monitoring and analysis

#### Zero-Trust Architecture
```hcl
zero_trust_config = {
  # No implicit trust - verify everything
  default_deny_all = true
  
  # Micro-segmentation
  security_groups = {
    web_tier = {
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]  # Only HTTPS from internet
        }
      ]
      egress_rules = [
        {
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["app_tier_sg"]  # Only to app tier
        }
      ]
    }
    
    app_tier = {
      ingress_rules = [
        {
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["web_tier_sg"]  # Only from web tier
        }
      ]
      egress_rules = [
        {
          from_port       = 5432
          to_port         = 5432
          protocol        = "tcp"
          security_groups = ["db_tier_sg"]   # Only to database
        }
      ]
    }
  }
}
```

### 2. Identity and Access Management

#### Principle of Least Privilege
```hcl
iam_security_config = {
  # Role-based access control
  roles = {
    web_tier_role = {
      policies = [
        "CloudWatchAgentServerPolicy",
        "AmazonSSMManagedInstanceCore"
      ]
      # No S3 or database access
    }
    
    app_tier_role = {
      policies = [
        "CloudWatchAgentServerPolicy",
        "AmazonSSMManagedInstanceCore"
      ]
      inline_policies = [
        {
          name = "DatabaseAccess"
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "rds-db:connect"
                ]
                Resource = "arn:aws:rds-db:region:account:dbuser:db-instance/*"
              }
            ]
          })
        }
      ]
    }
  }
  
  # Multi-factor authentication required
  mfa_required = true
  
  # Session duration limits
  max_session_duration = 3600  # 1 hour
  
  # Cross-account access controls
  cross_account_trust = {
    enabled = false  # Disabled by default
    trusted_accounts = []
  }
}
```

#### Secrets Management
```hcl
secrets_config = {
  # AWS Secrets Manager for database credentials
  database_secrets = {
    automatic_rotation = true
    rotation_interval = 30  # days
    
    # Multi-region replication
    replica_regions = ["us-east-1", "us-west-2"]
  }
  
  # Application secrets
  application_secrets = {
    encryption_key_id = "alias/application-secrets"
    
    # Automatic secret rotation
    lambda_rotation_function = "rotate-app-secrets"
  }
  
  # API keys and certificates
  certificate_management = {
    auto_renewal = true
    notification_days_before_expiry = 30
  }
}
```

### 3. Data Protection

#### Encryption Everywhere
```hcl
encryption_config = {
  # Encryption at rest
  at_rest = {
    # EBS volumes
    ebs_encryption = {
      enabled = true
      kms_key_id = "alias/ebs-encryption"
      
      # Enforce encryption for all volumes
      enforce_encryption = true
    }
    
    # RDS databases
    rds_encryption = {
      enabled = true
      kms_key_id = "alias/rds-encryption"
      
      # Transparent Data Encryption
      tde_enabled = true
    }
    
    # S3 buckets
    s3_encryption = {
      sse_algorithm = "aws:kms"
      kms_key_id = "alias/s3-encryption"
      
      # Bucket key for cost optimization
      bucket_key_enabled = true
    }
  }
  
  # Encryption in transit
  in_transit = {
    # TLS 1.2 minimum
    min_tls_version = "1.2"
    
    # Certificate management
    acm_certificates = {
      domain_validation = false  # Use DNS validation
      
      # Certificate transparency logging
      certificate_transparency_logging_preference = "ENABLED"
    }
    
    # Application-level encryption
    application_encryption = {
      # End-to-end encryption for sensitive data
      field_level_encryption = true
      
      # Message encryption for queues
      sqs_encryption = true
      sns_encryption = true
    }
  }
  
  # Key management
  key_management = {
    # Automatic key rotation
    automatic_rotation = true
    rotation_interval = 365  # days
    
    # Multi-region keys for disaster recovery
    multi_region_keys = true
    
    # Key usage monitoring
    cloudtrail_logging = true
  }
}
```

#### Data Loss Prevention (DLP)
```hcl
dlp_config = {
  # Amazon Macie for data discovery
  macie = {
    enabled = true
    
    # Sensitive data types to detect
    sensitive_data_types = [
      "PII",
      "PHI",
      "FINANCIAL",
      "CREDENTIALS"
    ]
    
    # Automated remediation
    auto_remediation = {
      quarantine_sensitive_objects = true
      notify_security_team = true
    }
  }
  
  # Data classification
  classification = {
    # Automatic tagging based on content
    auto_tagging = true
    
    # Classification levels
    levels = ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"]
    
    # Retention policies by classification
    retention_policies = {
      "PUBLIC" = 2555  # 7 years
      "INTERNAL" = 1825  # 5 years
      "CONFIDENTIAL" = 2555  # 7 years
      "RESTRICTED" = 3650  # 10 years
    }
  }
}
```

### 4. Monitoring and Incident Response

#### Security Information and Event Management (SIEM)
```hcl
siem_config = {
  # AWS Security Hub as central dashboard
  security_hub = {
    enabled = true
    
    # Enable all security standards
    standards = [
      "aws-foundational-security-standard",
      "cis-aws-foundations-benchmark",
      "pci-dss"
    ]
    
    # Custom insights
    custom_insights = [
      {
        name = "High Severity Findings"
        filters = {
          severity_label = ["HIGH", "CRITICAL"]
        }
      }
    ]
  }
  
  # CloudTrail for audit logging
  cloudtrail = {
    # Multi-region trail
    is_multi_region_trail = true
    
    # Log file validation
    enable_log_file_validation = true
    
    # Data events logging
    include_global_service_events = true
    
    # Insight selectors for anomaly detection
    insight_selectors = [
      {
        insight_type = "ApiCallRateInsight"
      }
    ]
  }
  
  # GuardDuty for threat detection
  guardduty = {
    enabled = true
    
    # Malware protection
    malware_protection = {
      scan_ec2_instance_with_findings = true
      scan_ebs_volumes = true
    }
    
    # S3 protection
    s3_protection = true
    
    # Kubernetes protection
    kubernetes_protection = true
  }
}
```

#### Automated Incident Response
```hcl
incident_response_config = {
  # Lambda functions for automated response
  automated_responses = {
    # Isolate compromised instances
    isolate_instance = {
      trigger_events = ["GuardDuty Finding", "Security Hub Finding"]
      severity_threshold = "HIGH"
      
      actions = [
        "create_forensic_snapshot",
        "isolate_security_groups",
        "notify_security_team"
      ]
    }
    
    # Block malicious IPs
    block_malicious_ips = {
      trigger_events = ["WAF Block", "GuardDuty Finding"]
      
      actions = [
        "update_waf_rules",
        "update_security_groups",
        "create_incident_ticket"
      ]
    }
  }
  
  # Incident management integration
  incident_management = {
    # ServiceNow integration
    servicenow_integration = {
      enabled = true
      webhook_url = var.servicenow_webhook
    }
    
    # PagerDuty integration
    pagerduty_integration = {
      enabled = true
      service_key = var.pagerduty_service_key
    }
  }
}
```

### 5. Compliance and Governance

#### Compliance Frameworks
```hcl
compliance_config = {
  # SOC 2 Type II
  soc2 = {
    enabled = true
    
    controls = {
      # Security controls
      cc6_1 = "logical_access_controls"
      cc6_2 = "authentication_controls"
      cc6_3 = "authorization_controls"
      
      # Availability controls
      cc7_1 = "system_monitoring"
      cc7_2 = "incident_response"
    }
  }
  
  # PCI DSS
  pci_dss = {
    enabled = true
    
    requirements = {
      req_1 = "firewall_configuration"
      req_2 = "default_password_changes"
      req_3 = "cardholder_data_protection"
      req_4 = "encryption_transmission"
    }
  }
  
  # HIPAA (if applicable)
  hipaa = {
    enabled = false  # Enable if handling PHI
    
    safeguards = {
      administrative = "access_management"
      physical = "facility_controls"
      technical = "encryption_controls"
    }
  }
  
  # GDPR
  gdpr = {
    enabled = true
    
    requirements = {
      data_protection_by_design = true
      right_to_be_forgotten = true
      data_portability = true
      breach_notification = true
    }
  }
}
```

#### Configuration Management
```hcl
config_management = {
  # AWS Config for compliance monitoring
  aws_config = {
    enabled = true
    
    # Configuration rules
    rules = [
      "encrypted-volumes",
      "rds-encryption-enabled",
      "s3-bucket-ssl-requests-only",
      "cloudtrail-enabled",
      "mfa-enabled-for-iam-console-access"
    ]
    
    # Remediation actions
    remediation_configurations = [
      {
        config_rule_name = "s3-bucket-public-read-prohibited"
        automatic = true
        maximum_automatic_attempts = 3
      }
    ]
  }
  
  # Systems Manager for patch management
  systems_manager = {
    # Patch baselines
    patch_baselines = {
      linux = {
        operating_system = "AMAZON_LINUX_2"
        approval_rules = [
          {
            patch_filters = [
              {
                key = "CLASSIFICATION"
                values = ["Security", "Bugfix", "Critical"]
              }
            ]
            approve_after_days = 0  # Immediate for security patches
          }
        ]
      }
    }
    
    # Maintenance windows
    maintenance_windows = [
      {
        name = "security-patching"
        schedule = "cron(0 2 ? * SUN *)"  # Sunday 2 AM
        duration = 4  # hours
        cutoff = 1    # hour before end
      }
    ]
  }
}
```

## Security Testing and Validation

### Vulnerability Management
```hcl
vulnerability_management = {
  # Amazon Inspector for vulnerability assessment
  inspector = {
    enabled = true
    
    # Assessment targets
    assessment_targets = ["web-tier", "app-tier", "database-tier"]
    
    # Assessment templates
    assessment_templates = [
      {
        name = "security-assessment"
        rules_package_arns = [
          "arn:aws:inspector:region:account:rulespackage/security-best-practices",
          "arn:aws:inspector:region:account:rulespackage/network-reachability",
          "arn:aws:inspector:region:account:rulespackage/runtime-behavior-analysis"
        ]
        duration = 3600  # 1 hour
      }
    ]
    
    # Automated scheduling
    schedule = "rate(7 days)"  # Weekly scans
  }
  
  # Third-party vulnerability scanning
  external_scanning = {
    # Qualys integration
    qualys = {
      enabled = true
      scan_frequency = "weekly"
    }
    
    # Nessus integration
    nessus = {
      enabled = true
      scan_frequency = "monthly"
    }
  }
}
```

### Penetration Testing
```hcl
penetration_testing = {
  # Automated penetration testing
  automated_testing = {
    # OWASP ZAP integration
    zap_scanning = {
      enabled = true
      scan_frequency = "weekly"
      
      scan_types = [
        "baseline",
        "full-scan",
        "api-scan"
      ]
    }
  }
  
  # Manual penetration testing
  manual_testing = {
    frequency = "quarterly"
    scope = ["external", "internal", "wireless", "social-engineering"]
    
    # Approved testing companies
    approved_vendors = [
      "vendor1",
      "vendor2"
    ]
  }
}
```

## Deployment and Operations

### Secure Deployment Pipeline
```hcl
secure_pipeline = {
  # Security gates in CI/CD
  security_gates = [
    {
      stage = "source"
      checks = ["secret-scanning", "dependency-check"]
    },
    {
      stage = "build"
      checks = ["sast", "container-scanning"]
    },
    {
      stage = "test"
      checks = ["dast", "infrastructure-scanning"]
    },
    {
      stage = "deploy"
      checks = ["compliance-validation", "security-approval"]
    }
  ]
  
  # Approval workflows
  approval_workflows = {
    production_deployment = {
      required_approvers = 2
      security_team_approval = true
      
      # Automated security checks must pass
      automated_checks_required = true
    }
  }
}
```

### Security Operations
```hcl
security_operations = {
  # 24/7 monitoring
  monitoring = {
    # Security Operations Center (SOC)
    soc_integration = {
      enabled = true
      
      # Alert escalation
      escalation_matrix = [
        {
          severity = "LOW"
          response_time = "24 hours"
          assignee = "tier1_analyst"
        },
        {
          severity = "MEDIUM"
          response_time = "4 hours"
          assignee = "tier2_analyst"
        },
        {
          severity = "HIGH"
          response_time = "1 hour"
          assignee = "tier3_analyst"
        },
        {
          severity = "CRITICAL"
          response_time = "15 minutes"
          assignee = "security_manager"
        }
      ]
    }
  }
  
  # Incident response procedures
  incident_response = {
    # Playbooks for different incident types
    playbooks = [
      "data_breach_response",
      "malware_infection",
      "ddos_attack",
      "insider_threat",
      "supply_chain_compromise"
    ]
    
    # Communication plans
    communication_plan = {
      internal_notifications = ["security_team", "management", "legal"]
      external_notifications = ["customers", "regulators", "law_enforcement"]
      
      # Notification templates
      templates = {
        data_breach = "data_breach_notification_template"
        service_disruption = "service_disruption_template"
      }
    }
  }
}
```

## Cost Considerations

### Security Investment vs Risk
```hcl
security_budget = {
  # Security services costs (monthly estimates)
  aws_security_services = {
    guardduty = 50      # Based on data volume
    security_hub = 25   # Per security check
    inspector = 30      # Per assessment
    config = 40         # Per configuration item
    cloudtrail = 20     # Per event
    waf = 60           # Per web ACL and rules
    shield_advanced = 3000  # Fixed monthly cost
  }
  
  # Third-party security tools
  third_party_tools = {
    vulnerability_scanner = 500
    siem_solution = 1000
    endpoint_protection = 300
    security_training = 200
  }
  
  # Total monthly security budget
  total_monthly = 5225  # USD
  
  # ROI calculation
  risk_mitigation_value = {
    data_breach_prevention = 1000000  # Potential cost of breach
    compliance_fines_avoidance = 500000
    reputation_protection = 2000000
    
    # Security investment ROI
    annual_roi_percentage = 400  # 4x return on investment
  }
}
```

## Quick Start

### Prerequisites
1. **Security clearance** for team members
2. **Compliance requirements** documentation
3. **Security policies** and procedures
4. **Incident response plan** established

### Deployment Steps

1. **Security assessment**:
   ```bash
   # Run security baseline assessment
   ./scripts/security-baseline-check.sh
   ```

2. **Deploy with security hardening**:
   ```bash
   terraform init
   terraform plan -var="security_level=maximum"
   terraform apply
   ```

3. **Validate security controls**:
   ```bash
   # Run compliance validation
   ./scripts/compliance-check.sh
   
   # Perform security testing
   ./scripts/security-test.sh
   ```

This security-hardened architecture provides enterprise-grade security suitable for highly regulated industries while maintaining operational efficiency and compliance with major security frameworks.