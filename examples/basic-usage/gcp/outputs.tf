# Basic GCP Compute Example Outputs
# Following Brockhoff Cloud standardized output patterns

# Primary resource outputs
output "instance_id" {
  description = "Compute Engine instance ID"
  value       = google_compute_instance.main.instance_id
}

output "instance_name" {
  description = "Compute Engine instance name"
  value       = google_compute_instance.main.name
}

output "public_ip" {
  description = "External IP address of the instance"
  value       = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
}

output "private_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "firewall_rule_name" {
  description = "Firewall rule name"
  value       = google_compute_firewall.web.name
}

# Standard encryption outputs
output "kms_key_id" {
  description = "Cloud KMS key ID used for encryption"
  value       = var.create_kms_key ? google_kms_crypto_key.main[0].id : null
}

output "kms_key_name" {
  description = "Cloud KMS key name used for encryption"
  value       = var.create_kms_key ? google_kms_crypto_key.main[0].name : null
}

# Standard cost estimation outputs (simplified)
output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value       = "~$5.50 (e2-micro in us-west1)"
}

output "cost_breakdown" {
  description = "Detailed cost breakdown by service"
  value = {
    compute = "~$5.50/month (e2-micro)"
    storage = "~$2.00/month (20GB pd-standard)"
    network = "~$0.00/month (first 1GB free)"
  }
}

# Compliance and governance outputs (simplified)
output "compliance_report" {
  description = "Well-architected framework compliance assessment"
  value = {
    security = {
      encryption_at_rest = var.create_kms_key
      firewall_rules     = true
      iam_roles          = false
    }
    reliability = {
      multi_zone = false
      backup     = false
    }
    cost_optimization = {
      right_sizing          = true
      preemptible_instances = false
    }
  }
}

output "governance_metadata" {
  description = "Governance and audit metadata"
  value = {
    created_by            = "terraform"
    module_version        = "basic-usage-v1.0"
    compliance_frameworks = ["Google Cloud Architecture Framework"]
    labels                = module.context.tags
  }
}

# Context outputs for reference
output "name_prefix" {
  description = "Generated name prefix from context"
  value       = module.context.name_prefix
}

output "labels" {
  description = "Applied labels from context"
  value       = module.context.tags
}

# GCP-specific outputs
output "project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "zone" {
  description = "GCP zone"
  value       = var.gcp_zone
}

# Connection information
output "ssh_connection" {
  description = "SSH connection command (if SSH keys configured)"
  value       = length(var.ssh_public_keys) > 0 ? "gcloud compute ssh ${google_compute_instance.main.name} --zone=${var.gcp_zone}" : "SSH keys not configured"
}

output "web_url" {
  description = "URL to access the web application"
  value       = "http://${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}"
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    machine_type   = local.machine_type_map[var.instance_type]
    region         = var.gcp_region
    zone           = var.gcp_zone
    environment    = var.environment
    monitoring     = var.monitoring_enabled
    encryption     = var.create_kms_key
    estimated_cost = "~$5.50/month"
  }
}