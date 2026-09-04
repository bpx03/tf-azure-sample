output "server_fqdn" {
  description = "FQDN of the SQL server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "server_id" {
  description = "Resource ID of the SQL server"
  value       = azurerm_mssql_server.main.id
}

output "database_id" {
  description = "Resource ID of the SQL database"
  value       = azurerm_mssql_database.main.id
}

output "connection_string" {
  description = "SQL connection string (sensitive)"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${azurerm_mssql_server.main.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}
