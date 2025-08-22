# Compliance Reporting Module Outputs

output "compliance_report" {
  description = "Complete compliance assessment report"
  value       = var.enabled ? local.final_compliance_report : null
}

output "compliance_score" {
  description = "Overall compliance score (0.0 to 1.0)"
  value       = var.enabled ? local.overall_score : 0.0
}

output "pillar_scores" {
  description = "Compliance scores by framework pillar"
  value       = var.enabled ? local.pillar_scores : {}
}

output "compliance_status" {
  description = "Overall compliance status and details"
  value = var.enabled ? {
    compliant              = local.is_compliant
    overall_score         = local.overall_score
    minimum_required      = local.minimum_score
    environment_type      = var.environment_type
    total_controls        = local.governance_metadata.total_controls
    implemented_controls  = local.governance_metadata.implemented_controls
    implementation_percentage = local.governance_metadata.total_controls > 0 ? (
      local.governance_metadata.implemented_controls / local.governance_metadata.total_controls * 100
    ) : 0
  } : null
}

output "security_controls" {
  description = "Security controls implementation status"
  value       = var.enabled ? local.security_controls : {}
}

output "recommendations" {
  description = "Compliance improvement recommendations"
  value       = var.enabled ? local.recommendations : []
}

output "governance_metadata" {
  description = "Governance and audit metadata for compliance tracking"
  value       = var.enabled ? local.governance_metadata : {}
}

output "compliance_tags" {
  description = "Tags for compliance tracking and governance"
  value       = var.enabled ? local.governance_metadata.tags : {}
}

output "framework_info" {
  description = "Information about the compliance framework used"
  value = var.enabled ? {
    name           = local.framework_config.framework.name
    version        = local.framework_config.framework.version
    url            = local.framework_config.framework.url
    cloud_provider = local.cloud_provider
    framework_file = local.framework_file
  } : null
}

output "evidence_summary" {
  description = "Summary of evidence collection results"
  value = var.enabled ? {
    total_evidence_fields = length(var.resource_evidence)
    evidence_found = length([
      for field, evidence in var.resource_evidence : field if evidence.found
    ])
    evidence_missing = length([
      for field, evidence in var.resource_evidence : field if !evidence.found
    ])
    evidence_coverage_percentage = length(var.resource_evidence) > 0 ? (
      length([for field, evidence in var.resource_evidence : field if evidence.found]) / 
      length(var.resource_evidence) * 100
    ) : 0
  } : null
}

output "report_files" {
  description = "Paths to generated compliance report files"
  value = var.enabled ? {
    compliance_report = var.generate_report_file ? (
      "${var.output_path}/compliance-report-${local.cloud_provider}.json"
    ) : null
    security_controls_doc = var.generate_security_docs ? (
      "${var.output_path}/security-controls-${local.cloud_provider}.md"
    ) : null
  } : null
}