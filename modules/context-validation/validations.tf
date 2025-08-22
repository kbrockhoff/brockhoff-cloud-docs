# Validation checks for multi-cloud context validation

# Name validation
check "name_validation" {
  assert {
    condition = !var.enabled || local.name_valid
    error_message = <<-EOT
      Generated name '${var.name_prefix}' is invalid for ${local.cloud_provider}.
      Names must match pattern: ${local.active_constraints.name_pattern}
      
      ${local.cloud_provider == "aws" ? "AWS names must start with a letter, contain only letters, numbers, and hyphens, and end with a letter or number." : ""}
      ${local.cloud_provider == "azure" ? "Azure names must start with a letter, contain only letters, numbers, hyphens, and underscores, and end with a letter or number." : ""}
      ${local.cloud_provider == "gcp" ? "GCP names must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number." : ""}
    EOT
  }
}

# Name length validation
check "name_length_validation" {
  assert {
    condition = !var.enabled || local.name_length_ok
    error_message = "Generated name '${var.name_prefix}' exceeds ${local.cloud_provider} maximum length of ${local.active_constraints.max_name_length} characters."
  }
}

# Metadata count validation
check "metadata_count_validation" {
  assert {
    condition = !var.enabled || local.metadata_count_ok
    error_message = <<-EOT
      ${local.cloud_provider == "gcp" ? "GCP resources support a maximum of ${local.active_constraints.max_labels} labels." : ""}
      ${local.cloud_provider != "gcp" ? "${title(local.cloud_provider)} resources support a maximum of ${local.active_constraints.max_tags} tags." : ""}
      Current count: ${local.cloud_provider == "gcp" ? length(local.gcp_labels) : length(var.tags)}
    EOT
  }
}

# Metadata validation
check "metadata_validation" {
  assert {
    condition = !var.enabled || local.metadata_valid
    error_message = <<-EOT
      ${local.cloud_provider} metadata validation failed. Please check:
      ${local.cloud_provider == "aws" ? "- Tag keys must be ≤128 chars, values ≤256 chars\n- Keys cannot start with 'aws:' or 'AWS:'" : ""}
      ${local.cloud_provider == "azure" ? "- Tag keys must be ≤512 chars, values ≤256 chars\n- Keys cannot be 'name', 'Name', or 'NAME'" : ""}
      ${local.cloud_provider == "gcp" ? "- Label keys and values must be ≤63 chars\n- Keys must match pattern: ${local.active_constraints.label_key_pattern}\n- Values must match pattern: ${local.active_constraints.label_value_pattern}\n- Keys cannot start with 'goog-' or 'google-'" : ""}
    EOT
  }
}

# Resource-specific validations
check "aws_s3_bucket_validation" {
  assert {
    condition = !var.enabled || local.aws_s3_bucket_valid
    error_message = "AWS S3 bucket name '${local.resource_names.aws_s3_bucket}' is invalid. Must be 3-63 characters, lowercase letters, numbers, and hyphens only, and cannot be formatted as an IP address."
  }
}

check "azure_storage_validation" {
  assert {
    condition = !var.enabled || local.azure_storage_valid
    error_message = "Azure storage account name '${local.resource_names.azure_storage_account}' is invalid. Must be 3-24 characters, lowercase letters and numbers only."
  }
}

check "gcp_bucket_validation" {
  assert {
    condition = !var.enabled || local.gcp_bucket_valid
    error_message = "GCP storage bucket name '${local.resource_names.gcp_storage_bucket}' is invalid. Must be 3-63 characters, start with lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }
}

# Cross-cloud compatibility validation
check "cross_cloud_compatibility" {
  assert {
    condition = !var.enabled || !var.enforce_cross_cloud_compatibility || local.cross_cloud_compatible
    error_message = <<-EOT
      Cross-cloud compatibility validation failed. For maximum compatibility:
      - Name must be ≤50 characters
      - Name must start with letter, contain only letters/numbers/hyphens, end with letter/number
      - Maximum 50 tags/labels
      - Tag/label keys and values must be ≤63 characters each
    EOT
  }
}