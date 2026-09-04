output "url" {
  description = "Default host name of the Static Web App"
  value       = azurerm_static_web_app.main.default_host_name
}

output "static_app_id" {
  description = "Resource ID of the Static Web App"
  value       = azurerm_static_web_app.main.id
}

output "static_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_web_app.main.name
}
