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
# Microservices
# ---------------------------------------------------------------------------

variable "microservices" {
  description = "Map of microservices to deploy. Key = service name, value = config."
  type = map(object({
    plan_sku           = string  # App Service Plan SKU (B1, S1, P1v3)
    instance_count     = number  # Number of instances
    dotnet_version     = string  # .NET runtime version
    repo_url           = string  # Git repo for this service
    repo_branch        = string  # Git branch
    sql_sku_name       = string  # SQL Database SKU for this service
    sql_max_size_gb    = number  # Max DB size in GB
    sql_database_name  = string  # Database name (defaults to "<service>-db")
  }))

  validation {
    condition     = length(var.microservices) > 0
    error_message = "At least one microservice must be defined."
  }
}

# ---------------------------------------------------------------------------
# Shared App Service Settings
# ---------------------------------------------------------------------------

variable "dotnet_version_default" {
  description = "Default .NET runtime version (used if not specified per service)"
  type        = string
  default     = "v10.0"
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
# Azure SQL Server (shared across services)
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
    object_id    = string
    keys         = list(string)
    secrets      = list(string)
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
