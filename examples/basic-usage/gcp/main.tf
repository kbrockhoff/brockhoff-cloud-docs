# Basic GCP Compute Example
# This example demonstrates a simple Compute Engine instance deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.11"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/context/external"

  name        = var.name
  environment = var.environment
}

# Firewall rule for HTTP/HTTPS access
resource "google_compute_firewall" "web" {
  name    = "${module.context.name_prefix}-web"
  network = var.network_name != "" ? var.network_name : "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.allowed_cidr_blocks
  target_tags   = ["${module.context.name_prefix}-web"]
}

# Firewall rule for SSH access (if SSH keys provided)
resource "google_compute_firewall" "ssh" {
  count = length(var.ssh_public_keys) > 0 ? 1 : 0

  name    = "${module.context.name_prefix}-ssh"
  network = var.network_name != "" ? var.network_name : "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_cidr_blocks
  target_tags   = ["${module.context.name_prefix}-ssh"]
}

# KMS key for disk encryption (if enabled)
resource "google_kms_key_ring" "main" {
  count = var.create_kms_key ? 1 : 0

  name     = "${module.context.name_prefix}-keyring"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "main" {
  count = var.create_kms_key ? 1 : 0

  name     = "${module.context.name_prefix}-key"
  key_ring = google_kms_key_ring.main[0].id

  lifecycle {
    prevent_destroy = false
  }
}

# Compute Engine instance
resource "google_compute_instance" "main" {
  name         = "${module.context.name_prefix}-instance"
  machine_type = local.machine_type_map[var.instance_type]
  zone         = var.gcp_zone

  tags = ["${module.context.name_prefix}-web", "${module.context.name_prefix}-ssh"]

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = 20
      type  = "pd-standard"
    }

    # Enable encryption if KMS key is created
    kms_key_self_link = var.create_kms_key ? google_kms_crypto_key.main[0].id : null
  }

  network_interface {
    network    = var.network_name != "" ? var.network_name : "default"
    subnetwork = var.subnet_name != "" ? var.subnet_name : null

    access_config {
      # Ephemeral public IP
    }
  }

  # SSH keys
  metadata = length(var.ssh_public_keys) > 0 ? {
    ssh-keys = join("\n", [for key in var.ssh_public_keys : "gcp-user:${key}"])
  } : {}

  # Startup script for basic setup
  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    name_prefix = module.context.name_prefix
  })

  labels = {
    for k, v in module.context.tags : lower(replace(k, "/[^a-z0-9_-]/", "_")) => lower(replace(v, "/[^a-z0-9_-]/", "_"))
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Local mappings for GCP-specific configurations
locals {
  machine_type_map = {
    small  = "e2-micro"      # 2 vCPU, 1 GB RAM (shared-core)
    medium = "e2-small"      # 2 vCPU, 2 GB RAM (shared-core)
    large  = "e2-standard-2" # 2 vCPU, 8 GB RAM
  }
}

# Data sources for defaults
data "google_client_config" "current" {}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

data "google_compute_network" "existing" {
  count = var.network_name != "" && var.network_name != "default" ? 1 : 0
  name  = var.network_name
}

data "google_compute_subnetwork" "existing" {
  count = var.subnet_name != "" ? 1 : 0

  name   = var.subnet_name
  region = var.gcp_region
}
