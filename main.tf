# Define the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data resource for tenant ID
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "my_vpc" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Public Subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "publicSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_vpc.name
  address_prefixes     = var.public_subnet_prefix
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "privateSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_vpc.name
  address_prefixes     = var.private_subnet_prefix
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "myNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Public Subnet
resource "azurerm_subnet_network_security_group_association" "public_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Random DB Username
resource "random_string" "db_username" {
  length  = 16
  special = false
}

# Random DB Password
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "_%+=~"
}

# Key Vault for Storing DB Credentials
resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
}

# Access Policy for Terraform SPN to Access Key Vault
resource "azurerm_key_vault_access_policy" "terraform_access_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

# Store DB Username in Key Vault
resource "azurerm_key_vault_secret" "db_username" {
  name         = "dbUsername"
  value        = random_string.db_username.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform_access_policy]
}

# Store DB Password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "dbPassword"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_access_policy.terraform_access_policy]
}

# App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Web App (with Managed Identity)
resource "azurerm_linux_web_app" "app_service" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {}

  app_settings = {
    "DB_USERNAME" = azurerm_key_vault_secret.db_username.value
    "DB_PASSWORD" = azurerm_key_vault_secret.db_password.value
  }

  identity {
    type = "SystemAssigned"
  }
}

# Access Policy for Web App to Access Key Vault Secrets
resource "azurerm_key_vault_access_policy" "webapp_access_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app_service.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  administrator_login          = random_string.db_username.result
  administrator_login_password = random_password.db_password.result
  version                      = "12.0"
}

# SQL Database
resource "azurerm_mssql_database" "sql_database" {
  name       = "exampleDatabase"
  server_id  = azurerm_mssql_server.sql_server.id
  sku_name   = "S0"
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "sqlPrivateEndpoint"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.private_subnet.id

  private_service_connection {
    name                           = "sqlPrivateConnection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}
