variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "public_subnet_prefix" {
  type        = list(string)
  description = "CIDR block for the public subnet"
}

variable "private_subnet_prefix" {
  type        = list(string)
  description = "CIDR block for the private subnet"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Key Vault"
}

variable "app_service_plan_name" {
  type        = string
  description = "Name of the App Service Plan"
}

variable "app_service_name" {
  type        = string
  description = "Name of the App Service"
}

variable "sql_server_name" {
  type        = string
  description = "Name of the SQL Server"
}
