variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure location for resources."
  type        = string
  default     = "West US"
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "subnet_name" {
  description = "Name of the private subnet."
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the private subnet."
  type        = list(string)
}

variable "key_vault_name" {
  description = "Name of the Key Vault."
  type        = string
}

