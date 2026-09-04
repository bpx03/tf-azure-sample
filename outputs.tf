# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group_name
}

# ---------------------------------------------------------------------------
# Microservices (App Service)
# ---------------------------------------------------------------------------

output "api_domains" {
  description = "Map of service name → FQDN"
  value       = { for name, app in module.api : name => app.default_domain }
}

output "api_ids" {
  description = "Map of service name → Resource ID"
  value       = { for name, app in module.api : name => app.app_service_id }
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
  description = "FQDN of the SQL server (shared)"
  value       = module.sql[keys(var.microservices)[0]].server_fqdn
}

output "sql_databases" {
  description = "Map of service name → database ID"
  value       = { for name, db in module.sql : name => db.database_id }
}

# NOTE: connection strings are intentionally NOT exposed as outputs.
# They contain credentials. Use Key Vault references in app settings instead.

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "key_vault_secret_ids" {
  description = "Map of service name → secret ID (SQL connection strings)"
  value       = module.key_vault.sql_connection_string_secret_ids
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
