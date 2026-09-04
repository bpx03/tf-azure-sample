# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

output "api_default_domain" {
  description = "FQDN of the .NET API"
  value       = module.api.default_domain
}

output "api_id" {
  description = "Resource ID of the App Service"
  value       = module.api.app_service_id
}

# ---------------------------------------------------------------------------
# Frontend
# ---------------------------------------------------------------------------

output "frontend_url" {
  description = "URL of the React frontend"
  value       = module.frontend.url
}

# ---------------------------------------------------------------------------
# SQL Database
# ---------------------------------------------------------------------------

output "sql_server_fqdn" {
  description = "FQDN of the SQL server"
  value       = module.sql.server_fqdn
}

output "sql_database_name" {
  description = "Name of the SQL database"
  value       = var.sql_database_name
}

# NOTE: connection_string is intentionally NOT exposed as an output.
# It contains credentials. Use the Key Vault reference in app settings instead.

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

output "vnet_id" {
  description = "Resource ID of the virtual network"
  value       = module.networking.vnet_id
}

output "app_service_subnet_id" {
  description = "Resource ID of the App Service subnet"
  value       = module.networking.app_service_subnet_id
}
