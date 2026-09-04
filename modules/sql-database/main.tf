# ---------------------------------------------------------------------------
# Azure SQL Server
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Azure SQL Database
# ---------------------------------------------------------------------------

resource "azurerm_mssql_database" "main" {
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id
  sku_name  = var.sku_name
  max_size_gb = var.max_size_gb
  tags      = var.tags

  short_term_retention_policy {
    retention_days = 7
  }
}

# ---------------------------------------------------------------------------
# Firewall Rule — allow App Service subnet
# ---------------------------------------------------------------------------

resource "azurerm_mssql_firewall_rule" "app_service" {
  name             = "allow-app-service"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.app_service_subnet_cidr
  end_ip_address   = var.app_service_subnet_cidr
}
