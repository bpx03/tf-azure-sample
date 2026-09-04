variable "server_name" {
  description = "SQL Server name (must be globally unique)"
  type        = string
}

variable "database_name" {
  description = "SQL Database name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "admin_username" {
  description = "SQL admin username"
  type        = string
}

variable "admin_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "Database SKU (e.g. GP_Gen5_2, GP_Gen5_4)"
  type        = string
}

variable "max_size_gb" {
  description = "Maximum database size in GB"
  type        = number
  default     = 25
}

variable "app_service_subnet_cidr" {
  description = "CIDR of the App Service subnet (for firewall rule)"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
