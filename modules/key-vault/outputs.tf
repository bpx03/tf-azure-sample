output "vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "sql_connection_string_secret_id" {
  description = "Secret ID for the SQL connection string"
  value       = azurerm_key_vault_secret.sql_connection_string.id
}
