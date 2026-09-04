# ---------------------------------------------------------------------------
# Locals — computed values shared across modules
# ---------------------------------------------------------------------------

locals {
  # Unique suffix for globally-unique Azure resource names
  # (storage accounts, key vaults, etc. must be unique across ALL of Azure)
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
# Networking
# ---------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  name_prefix       = "net-${var.project_name}-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = var.location
  vnet_address_space       = var.vnet_address_space
  subnet_address_space     = var.subnet_address_space
  sql_subnet_address_space = var.sql_subnet_address_space
  tags                     = local.common_tags
}

# ---------------------------------------------------------------------------
# Key Vault
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
  sql_connection_string = module.sql.connection_string
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Azure SQL Database
# ---------------------------------------------------------------------------

module "sql" {
  source = "./modules/sql-database"

  server_name           = local.sql_server_name
  database_name         = var.sql_database_name
  resource_group_name   = local.resource_group_name
  location              = var.location
  admin_username        = var.sql_server_admin_user
  admin_password        = var.sql_server_admin_password
  sku_name              = var.sql_sku_name
  max_size_gb           = var.sql_max_size_gb
  app_service_subnet_cidr = module.networking.app_service_subnet_cidr
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# App Service (.NET 10 API)
# ---------------------------------------------------------------------------

module "api" {
  source = "./modules/app-service"

  name                = "api-${var.project_name}-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = var.location
  plan_sku            = var.app_service_plan_sku
  instance_count      = var.app_service_instance_count
  dotnet_version      = var.dotnet_version
  subnet_id           = module.networking.app_service_subnet_id
  tags                = local.common_tags

  # App settings — injected from Key Vault + SQL
  app_settings = {
    "ConnectionStrings__Default" = module.sql.connection_string
    "AzureWebJobsFeatureFlags__EnableWorkerIndexing" = "0"
  }
}

# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

module "frontend" {
  source = "./modules/static-web-app"

  name                = "fe-${var.project_name}-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = var.location
  repo_url            = var.frontend_repo_url
  repo_branch         = var.frontend_repo_branch
  repo_token          = var.frontend_repo_token
  api_url             = "https://${module.api.default_domain}"
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Data — current Azure client config (for tenant_id, subscription_id)
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}
