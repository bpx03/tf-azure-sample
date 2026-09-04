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
  repository_url  = var.repo_url
  repository_branch = var.repo_branch
  repository_token = var.repo_token

  # App settings — inject API URL into the frontend
  app_settings = {
    "REACT_APP_API_URL" = var.api_url
  }

  identity {
    type = "SystemAssigned"
  }
}
