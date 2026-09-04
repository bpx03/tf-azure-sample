# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

environment = "dev"
location    = "northeurope"

tags = {
  CostCenter = "IT-Platform"
  Team       = "Platform"
}

# ---------------------------------------------------------------------------
# Naming
# ---------------------------------------------------------------------------

project_name = "dotnetapi"

# ---------------------------------------------------------------------------
# Microservices
#
# Each key = service name. To add a new service, just add a new entry.
# Set sql_enabled = false for services that don't need a database.
# ---------------------------------------------------------------------------

microservices = {
  orders = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/orders-service.git"
    repo_branch       = "main"
    sql_enabled       = true
    sql_sku_name      = "GP_Gen5_2"
    sql_max_size_gb   = 25
    sql_database_name = "orders-db"
  }

  users = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/users-service.git"
    repo_branch       = "main"
    sql_enabled       = true
    sql_sku_name      = "GP_Gen5_2"
    sql_max_size_gb   = 25
    sql_database_name = "users-db"
  }

  payments = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/payments-service.git"
    repo_branch       = "main"
    sql_enabled       = true
    sql_sku_name      = "GP_Gen5_2"
    sql_max_size_gb   = 25
    sql_database_name = "payments-db"
  }

  # Example: service WITHOUT a database (e.g. API gateway, cache, notification)
  gateway = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/api-gateway.git"
    repo_branch       = "main"
    sql_enabled       = false
    sql_sku_name      = ""
    sql_max_size_gb   = 0
    sql_database_name = ""
  }
}

# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

frontend_repo_url    = "https://github.com/your-org/your-frontend.git"
frontend_repo_branch = "main"

# NOTE: repo_token is NOT set here.
# Inject it via: -var "frontend_repo_token=ghp_xxx"

# ---------------------------------------------------------------------------
# Azure SQL Server (shared — only created if at least one service has sql_enabled)
# ---------------------------------------------------------------------------

sql_server_admin_user     = "sqladmin"
sql_server_admin_password = "Dev-Only-Pass-123!"  # CHANGE ME — use Key Vault in prod

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

key_vault_sku = "standard"

key_vault_access_policies = [
  {
    object_id    = "REPLACE_WITH_YOUR_SPN_OBJECT_ID"
    keys         = []
    secrets      = ["get", "list", "set"]
    certificates = []
  }
]

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

vnet_address_space       = "10.0.0.0/16"
subnet_address_space     = "10.0.1.0/24"
sql_subnet_address_space = "10.0.2.0/24"
