# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

environment = "prod"
location    = "northeurope"

tags = {
  CostCenter = "Business"
  Team       = "Platform"
  Compliance = "SOC2"
}

# ---------------------------------------------------------------------------
# Naming
# ---------------------------------------------------------------------------

project_name = "dotnetapi"

# ---------------------------------------------------------------------------
# Microservices
# ---------------------------------------------------------------------------

microservices = {
  orders = {
    plan_sku          = "P1v3"
    instance_count    = 2
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/orders-service.git"
    repo_branch       = "main"
    sql_sku_name      = "GP_Gen5_8"
    sql_max_size_gb   = 100
    sql_database_name = "orders-db"
  }

  users = {
    plan_sku          = "P1v3"
    instance_count    = 2
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/users-service.git"
    repo_branch       = "main"
    sql_sku_name      = "GP_Gen5_8"
    sql_max_size_gb   = 100
    sql_database_name = "users-db"
  }

  payments = {
    plan_sku          = "P1v3"
    instance_count    = 2
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/payments-service.git"
    repo_branch       = "main"
    sql_sku_name      = "GP_Gen5_8"
    sql_max_size_gb   = 100
    sql_database_name = "payments-db"
  }
}

# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

frontend_repo_url    = "https://github.com/your-org/your-frontend.git"
frontend_repo_branch = "main"

# ---------------------------------------------------------------------------
# Azure SQL Server (shared)
# ---------------------------------------------------------------------------

sql_server_admin_user     = "sqladmin"
sql_server_admin_password = "REPLACE_WITH_KEYVAULT_SECRET"  # MUST come from Key Vault

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

key_vault_sku = "premium"

key_vault_access_policies = [
  {
    object_id    = "REPLACE_WITH_PROD_SPN_OBJECT_ID"
    keys         = []
    secrets      = ["get", "list"]
    certificates = []
  }
]

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

vnet_address_space       = "10.2.0.0/16"
subnet_address_space     = "10.2.1.0/24"
sql_subnet_address_space = "10.2.2.0/24"
