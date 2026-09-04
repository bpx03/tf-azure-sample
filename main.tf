# ---------------------------------------------------------------------------
# Locals — computed values shared across modules
# ---------------------------------------------------------------------------

locals {
  # Unique suffix for globally-unique Azure resource names
  random_suffix = random_string.suffix.result

  # Environment-specific naming
  resource_group_name = "rg-${var.project_name}-${var.environment}"
  key_vault_name      = "kv-${var.project_name}-${var.environment}-${local.random_suffix}"
  sql_server_name     = "sql-${var.project_name}-${var.environment}-${local.random_suffix}"

  # Merged tags applied to every resource
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CostCenter  = var.environment == "prod" ? "Business" : "IT-Platform"
    }
  )

  # Per-service tags (adds service name)
  service_tags = { for name, cfg in var.microservices : name => merge(local.common_tags, {
    Service = name
  }) }

  # SQL connection strings per service (for Key Vault + app settings)
  sql_connection_strings = {
    for name, db in module.sql : name => db.connection_string
  }
}

# ---------------------------------------------------------------------------
# Random suffix — ensures globally-unique names
# ---------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# ---------------------------------------------------------------------------
# Networking (shared)
# ---------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  name_prefix              = "net-${var.project_name}-${var.environment}"
  resource_group_name      = local.resource_group_name
  location                 = var.location
  vnet_address_space       = var.vnet_address_space
  subnet_address_space     = var.subnet_address_space
  sql_subnet_address_space = var.sql_subnet_address_space
  tags                     = local.common_tags
}

# ---------------------------------------------------------------------------
# SQL Server (shared) + Databases (per service)
# ---------------------------------------------------------------------------

module "sql" {
  source   = "./modules/sql-database"
  for_each = var.microservices

  server_name           = local.sql_server_name
  database_name         = each.value.sql_database_name != "" ? each.value.sql_database_name : "${each.key}-db"
  resource_group_name   = local.resource_group_name
  location              = var.location
  admin_username        = var.sql_server_admin_user
  admin_password        = var.sql_server_admin_password
  sku_name              = each.value.sql_sku_name
  max_size_gb           = each.value.sql_max_size_gb
  app_service_subnet_cidr = module.networking.app_service_subnet_cidr
  tags                  = local.service_tags[each.key]
}

# ---------------------------------------------------------------------------
# Key Vault (shared, stores per-service secrets)
# ---------------------------------------------------------------------------

module "key_vault" {
  source = "./modules/key-vault"

  name                = local.key_vault_name
  resource_group_name = local.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku
  environment         = var.environment
  access_policies     = var.key_vault_access_policies
  subnet_id           = module.networking.app_service_subnet_id
  # Store connection strings for each service
  sql_connection_strings = local.sql_connection_strings
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# App Service (per microservice)
# ---------------------------------------------------------------------------

module "api" {
  source   = "./modules/app-service"
  for_each = var.microservices

  name                = "${each.key}-${var.project_name}-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = var.location
  plan_sku            = each.value.plan_sku
  instance_count      = each.value.instance_count
  dotnet_version      = each.value.dotnet_version != "" ? each.value.dotnet_version : var.dotnet_version_default
  subnet_id           = module.networking.app_service_subnet_id
  tags                = local.service_tags[each.key]

  # App settings — injected from SQL
  app_settings = {
    "ConnectionStrings__Default" = module.sql[each.key].connection_string
  }
}

# ---------------------------------------------------------------------------
# Static Web App (React frontend — single, calls all APIs)
# ---------------------------------------------------------------------------

module "frontend" {
  source = "./modules/static-web-app"

  name                = "fe-${var.project_name}-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = var.location
  repo_url            = var.frontend_repo_url
  repo_branch         = var.frontend_repo_branch
  repo_token          = var.frontend_repo_token
  # Expose all API URLs to the frontend
  api_urls = { for name, app in module.api : name => "https://${app.default_domain}" }
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Data — current Azure client config
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}
