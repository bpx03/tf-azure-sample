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
# App Service (.NET 10 API)
# ---------------------------------------------------------------------------

app_service_plan_sku       = "B1"
app_service_instance_count = 1
dotnet_version             = "v10.0"

api_repo_url    = "https://github.com/your-org/your-api.git"
api_repo_branch = "main"

# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

frontend_repo_url             = "https://github.com/your-org/your-frontend.git"
frontend_repo_branch          = "main"

# NOTE: repo_token is NOT set here.
# Inject it via: export ARM_STATIC_WEB_APP_TOKEN="ghp_xxx"
# Or in pipeline: -var "repo_token=$(github-pat)"

# ---------------------------------------------------------------------------
# Azure SQL Database
# ---------------------------------------------------------------------------

sql_server_admin_user     = "sqladmin"
sql_server_admin_password = "Dev-Only-Pass-123!"  # CHANGE ME — use Key Vault in prod
sql_database_name         = "appdb"
sql_sku_name              = "GP_Gen5_2"
sql_max_size_gb           = 25

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

key_vault_sku = "standard"

# NOTE: access_policies requires object_id of your SPN/user.
# Find it: az ad sp list --display-name "tf-dev-spn" --query "[].objectId" -o tsv
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
