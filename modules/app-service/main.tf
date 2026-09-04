# ---------------------------------------------------------------------------
# App Service Plan
# ---------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = "${var.name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.plan_sku
  worker_count        = var.instance_count
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Linux Web App (.NET 10 API)
# ---------------------------------------------------------------------------

resource "azurerm_linux_web_app" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  tags                = var.tags
  https_only          = true
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    always_on           = true
    health_check_path   = "/health"

    application_stack {
      dotnet_version = var.dotnet_version
    }
  }

  app_settings = var.app_settings

  # VNet Integration
  virtual_network_subnet_id = var.subnet_id
}
