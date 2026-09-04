# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

resource "azurerm_static_web_app" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size

  # Git integration — auto-deploy on push
  repository_url   = var.repo_url
  repository_branch = var.repo_branch
  repository_token  = var.repo_token

  # App settings — inject all API URLs into the frontend
  # Each key becomes REACT_APP_API_<SERVICE_NAME>
  app_settings = merge(
    { for name, url in var.api_urls : "REACT_APP_API_${upper(replace(name, "-", "_"))}" => url },
    { "REACT_APP_API_BASE" = var.api_urls[lookup(var.api_urls, keys(var.api_urls)[0], "")] }
  )

  identity {
    type = "SystemAssigned"
  }
}
