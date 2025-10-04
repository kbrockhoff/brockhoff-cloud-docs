# Compliance Reporting Module
# This module provides automated compliance assessment and reporting capabilities
# for Terraform modules against well-architected frameworks

terraform {
  required_version = ">= 1.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}

# Load compliance framework configuration
locals {
  # Determine cloud provider from context
  cloud_provider = var.cloud_provider != "" ? var.cloud_provider : (
    can(regex("aws", var.context.cloud_provider)) ? "aws" :
    can(regex("azure|az", var.context.cloud_provider)) ? "azure" :
    can(regex("gcp|google", var.context.cloud_provider)) ? "gcp" : "aws"
  )

  # Map cloud provider to framework file
  framework_files = {
    aws   = "compliance/aws-waf.yaml"
    azure = "compliance/azure-waf.yaml"
    gcp   = "compliance/gcp-caf.yaml"
  }

  framework_file = local.framework_files[local.cloud_provider]

  # Load framework configuration
  framework_config = yamldecode(file("${path.root}/${local.framework_file}"))

  # Module metadata
  module_metadata = {
    name              = var.module_name
    version           = var.module_version
    cloud_provider    = local.cloud_provider
    environment       = var.environment_type
    assessment_date   = timestamp()
    terraform_version = "1.0+" # Could be enhanced to get actual version
  }

  # Collect evidence from provided resource data
  compliance_evidence = var.enabled ? {
    for pillar_name, pillar in local.framework_config.pillars : pillar_name => {
      for control in pillar.controls : control.id => {
        title          = control.title
        implementation = control.implementation
        evidence_fields = {
          for field in control.evidence_fields : field =>
          lookup(var.resource_evidence, field, {
            found   = false
            value   = null
            message = "Evidence not provided"
          })
        }
        has_evidence = anytrue([
          for field in control.evidence_fields :
          lookup(var.resource_evidence, field, { found = false }).found
        ])
      }
    }
  } : {}

  # Calculate compliance scores
  pillar_scores = var.enabled ? {
    for pillar_name, pillar_evidence in local.compliance_evidence : pillar_name => {
      control_scores = [
        for control_id, control_evidence in pillar_evidence :
        control_evidence.has_evidence ? 1.0 : 0.0
      ]
      score = length(control_scores) > 0 ? (
        sum(control_scores) / length(control_scores)
      ) : 0.0
    }
  } : {}

  # Calculate overall score using framework weights
  framework_weights = lookup(local.framework_config, "assessment", {
    scoring = { weights = {} }
  }).scoring.weights

  overall_score = var.enabled && length(local.pillar_scores) > 0 ? (
    length(local.framework_weights) > 0 ? sum([
      for pillar, weight in local.framework_weights :
      lookup(local.pillar_scores, pillar, 0.0) * weight
    ]) : sum(values(local.pillar_scores)) / length(local.pillar_scores)
  ) : 0.0

  # Determine compliance status
  assessment_config = lookup(local.framework_config, "assessment", {})
  thresholds        = lookup(local.assessment_config, "thresholds", {})
  environment_thresholds = lookup(local.thresholds, var.environment_type,
    lookup(local.thresholds, "development", { minimum_score = 0.7 })
  )

  minimum_score = lookup(local.environment_thresholds, "minimum_score", 0.7)
  is_compliant  = local.overall_score >= local.minimum_score

  # Generate recommendations for failing controls
  recommendations = var.enabled ? flatten([
    for pillar_name, pillar_evidence in local.compliance_evidence : [
      for control_id, control_evidence in pillar_evidence : {
        pillar        = pillar_name
        control_id    = control_id
        control_title = control_evidence.title
        issue         = control_evidence.has_evidence ? "Partial implementation" : "Not implemented"
        remediation   = "Implement ${control_evidence.implementation}"
        priority = pillar_name == "security" ? "high" : (
          pillar_name == "reliability" ? "medium" : "low"
        )
      } if !control_evidence.has_evidence
    ]
  ]) : []

  # Security control documentation
  security_controls = var.enabled ? {
    for control in lookup(local.framework_config.pillars, "security", { controls = [] }).controls :
    control.id => {
      title             = control.title
      implementation    = control.implementation
      evidence_required = control.evidence_fields
      validation_checks = lookup(control, "validation_checks", [])
      implemented       = lookup(local.compliance_evidence.security, control.id, { has_evidence = false }).has_evidence
    }
  } : {}

  # Governance metadata
  governance_metadata = {
    compliance_framework   = local.framework_config.framework.name
    assessment_date        = local.module_metadata.assessment_date
    overall_score          = local.overall_score
    compliance_status      = local.is_compliant ? "compliant" : "non-compliant"
    environment_type       = var.environment_type
    minimum_required_score = local.minimum_score
    module_name            = var.module_name
    module_version         = var.module_version
    cloud_provider         = local.cloud_provider
    total_controls = sum([
      for pillar in values(local.framework_config.pillars) : length(pillar.controls)
    ])
    implemented_controls = sum([
      for pillar_evidence in values(local.compliance_evidence) : length([
        for control_evidence in values(pillar_evidence) : 1
        if control_evidence.has_evidence
      ])
    ])
    tags = merge(var.tags, {
      ComplianceFramework = local.framework_config.framework.name
      ComplianceScore     = "${floor(local.overall_score * 100)}%"
      ComplianceStatus    = local.is_compliant ? "compliant" : "non-compliant"
      LastAssessed        = formatdate("YYYY-MM-DD", timestamp())
    })
  }
}

# Generate compliance report as JSON file
resource "local_file" "compliance_report" {
  count = var.enabled && var.generate_report_file ? 1 : 0

  filename = "${var.output_path}/compliance-report-${local.cloud_provider}.json"
  content = jsonencode({
    framework = local.framework_config.framework
    assessment = {
      date        = local.module_metadata.assessment_date
      module      = local.module_metadata
      environment = var.environment_type
    }
    scores = {
      overall_score    = local.overall_score
      pillar_scores    = local.pillar_scores
      minimum_required = local.minimum_score
    }
    compliance_status = {
      compliant            = local.is_compliant
      total_controls       = local.governance_metadata.total_controls
      implemented_controls = local.governance_metadata.implemented_controls
      implementation_percentage = local.governance_metadata.total_controls > 0 ? (
        local.governance_metadata.implemented_controls / local.governance_metadata.total_controls * 100
      ) : 0
    }
    evidence            = local.compliance_evidence
    security_controls   = local.security_controls
    recommendations     = local.recommendations
    governance_metadata = local.governance_metadata
  })

  file_permission = "0644"
}

# Generate security controls documentation
resource "local_file" "security_controls_doc" {
  count = var.enabled && var.generate_security_docs ? 1 : 0

  filename = "${var.output_path}/security-controls-${local.cloud_provider}.md"
  content = templatefile("${path.module}/templates/security-controls.md.tpl", {
    framework_name    = local.framework_config.framework.name
    framework_url     = local.framework_config.framework.url
    security_controls = local.security_controls
    module_name       = var.module_name
    assessment_date   = local.module_metadata.assessment_date
    cloud_provider    = local.cloud_provider
  })

  file_permission = "0644"
}

# External data source for advanced compliance assessment
data "external" "compliance_assessment" {
  count = var.enabled && var.run_advanced_assessment ? 1 : 0

  program = ["python3", "${path.module}/../../scripts/assess-compliance.py",
    "--framework", "${path.root}/${local.framework_file}",
    "--resources", var.terraform_plan_file,
  "--format", "json"]

  # Only run if terraform plan file is provided
  depends_on = [local_file.compliance_report]
}

# Parse advanced assessment results
locals {
  advanced_assessment = var.enabled && var.run_advanced_assessment && length(data.external.compliance_assessment) > 0 ? (
    jsondecode(data.external.compliance_assessment[0].result.report)
  ) : null

  # Merge basic and advanced assessment results
  final_compliance_report = local.advanced_assessment != null ? local.advanced_assessment : {
    framework = local.framework_config.framework
    assessment = {
      date   = local.module_metadata.assessment_date
      module = local.module_metadata
      type   = "basic"
    }
    scores = {
      overall_score = local.overall_score
      pillar_scores = local.pillar_scores
    }
    compliance_status = {
      compliant = local.is_compliant
    }
    evidence            = local.compliance_evidence
    recommendations     = local.recommendations
    governance_metadata = local.governance_metadata
  }
}