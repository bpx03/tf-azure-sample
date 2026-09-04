# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment name"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "northeurope"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Naming
# ---------------------------------------------------------------------------

variable "project_name" {
  description = "Base name for all resources (prefix)"
  type        = string
  default     = "dotnetapi"
}

# ---------------------------------------------------------------------------
# App Service (.NET 10 API)
# ---------------------------------------------------------------------------

variable "app_service_plan_sku" {
  description = "App Service Plan SKU (e.g. B1, S1, P1v3)"
  type        = string
}

variable "app_service_instance_count" {
  description = "Number of App Service instances"
  type        = number
  default     = 1
}

variable "dotnet_version" {
  description = ".NET runtime version for the API"
  type        = string
  default     = "v10.0"
}

variable "api_repo_url" {
  description = "Git repository URL for the .NET API (used by deployment ring)"
  type        = string
  default     = ""
}

variable "api_repo_branch" {
  description = "Git branch for the .NET API"
  type        = string
  default     = "main"
}

# ---------------------------------------------------------------------------
# Static Web App (React frontend)
# ---------------------------------------------------------------------------

variable "frontend_repo_url" {
  description = "Git repository URL for the React frontend"
  type        = string
  default     = ""
}

variable "frontend_repo_branch" {
  description = "Git branch for the React frontend"
  type        = string
  default     = "main"
}

variable "frontend_repo_token" {
  description = "GitHub PAT with repo access (for Static Web App auto-deploy)"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Azure SQL Database
# ---------------------------------------------------------------------------

variable "sql_server_admin_user" {
  description = "Admin username for the SQL server"
  type        = string
  default     = "sqladmin"
}

variable "sql_server_admin_password" {
  description = "Admin password for the SQL server"
  type        = string
  sensitive   = true
}

variable "sql_database_name" {
  description = "Name of the SQL database"
  type        = string
  default     = "appdb"
}

variable "sql_sku_name" {
  description = "SQL Database SKU (e.g. GP_Gen5_2, GP_Gen5_4)"
  type        = string
}

variable "sql_max_size_gb" {
  description = "Maximum database size in GB"
  type        = number
  default     = 25
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

variable "key_vault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "key_vault_access_policies" {
  description = "Key Vault access policies (object_id + permissions)"
  type = list(object({
    object_id = string
    keys      = list(string)
    secrets   = list(string)
    certificates = list(string)
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "CIDR block for the virtual network"
  type        = string
}

variable "subnet_address_space" {
  description = "CIDR block for the App Service subnet"
  type        = string
}

variable "sql_subnet_address_space" {
  description = "CIDR block for the SQL subnet"
  type        = string
}
