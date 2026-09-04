output "resource_group_id" {
  description = "Resource ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  description = "Resource ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "app_service_subnet_id" {
  description = "Resource ID of the App Service subnet"
  value       = azurerm_subnet.app_service.id
}

output "sql_subnet_id" {
  description = "Resource ID of the SQL subnet"
  value       = azurerm_subnet.sql.id
}

output "app_service_subnet_cidr" {
  description = "CIDR of the App Service subnet (for firewall rules)"
  value       = var.subnet_address_space
}
