output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.kv.name
}

output "sql_server_name" {
  description = "Name of the SQL Server."
  value       = azurerm_mssql_server.sql_server.name
}
