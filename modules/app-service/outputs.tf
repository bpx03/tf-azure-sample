output "app_service_id" {
  description = "Resource ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "default_domain" {
  description = "Default domain (FQDN) of the web app"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "service_plan_id" {
  description = "Resource ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}
