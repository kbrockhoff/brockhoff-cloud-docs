# Basic Azure Compute Example
# This example demonstrates a simple Virtual Machine deployment using
# the Brockhoff Cloud standardized module interface

terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Context module for standardized naming and tagging
module "context" {
  source = "kbrockhoff/context/external"

  name        = var.name
  environment = var.environment
}

# Get the resource group (either existing or created)
locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}

# Virtual Network (if not using existing)
resource "azurerm_virtual_network" "main" {
  count = var.vnet_name == "" ? 1 : 0

  name                = "${module.context.name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_location
  resource_group_name = local.resource_group_name

  tags = module.context.tags
}

# Subnet (if not using existing)
resource "azurerm_subnet" "main" {
  count = var.subnet_name == "" ? 1 : 0

  name                 = "${module.context.name_prefix}-subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.vnet_name != "" ? var.vnet_name : azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${module.context.name_prefix}-nsg"
  location            = var.azure_location
  resource_group_name = local.resource_group_name

  # HTTP access
  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.allowed_cidr_blocks
    destination_address_prefix = "*"
  }

  # HTTPS access
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.allowed_cidr_blocks
    destination_address_prefix = "*"
  }

  # SSH access (if SSH key provided)
  dynamic "security_rule" {
    for_each = var.ssh_public_key != "" ? [1] : []
    content {
      name                       = "SSH"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.allowed_cidr_blocks
      destination_address_prefix = "*"
    }
  }

  tags = module.context.tags
}

# Key Vault for encryption (if enabled)
resource "azurerm_key_vault" "main" {
  count = var.create_key_vault ? 1 : 0

  name                = "${module.context.name_prefix}-kv"
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = var.environment_type == "Development" ? 7 : 30

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create", "Delete", "Get", "List", "Update", "Encrypt", "Decrypt"
    ]
  }

  tags = module.context.tags
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${module.context.name_prefix}-pip"
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = module.context.tags
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${module.context.name_prefix}-nic"
  location            = var.azure_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_name != "" ? data.azurerm_subnet.existing[0].id : azurerm_subnet.main[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = module.context.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${module.context.name_prefix}-vm"
  location            = var.azure_location
  resource_group_name = local.resource_group_name
  size                = local.vm_size_map[var.instance_type]
  admin_username      = var.admin_username

  disable_password_authentication = var.ssh_public_key != "" ? true : false

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # SSH key configuration
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  # Custom data for setup
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    name_prefix = module.context.name_prefix
  }))

  tags = module.context.tags
}

# Create resource group if not provided
resource "azurerm_resource_group" "main" {
  count = var.resource_group_name == "" ? 1 : 0

  name     = "${module.context.name_prefix}-rg"
  location = var.azure_location

  tags = module.context.tags
}

# Local mappings for Azure-specific configurations
locals {
  vm_size_map = {
    small  = "Standard_B1s"  # 1 vCPU, 1 GB RAM
    medium = "Standard_B2s"  # 2 vCPU, 4 GB RAM
    large  = "Standard_B4ms" # 4 vCPU, 16 GB RAM
  }
}

# Data sources for defaults
data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "existing" {
  count = var.vnet_name != "" ? 1 : 0

  name                = var.vnet_name
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}

data "azurerm_subnet" "existing" {
  count = var.subnet_name != "" ? 1 : 0

  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.main[0].name
}