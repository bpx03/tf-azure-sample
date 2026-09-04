variable "name" {
  description = "Key Vault name (must be globally unique)"
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VNet restriction"
  type        = string
}

variable "access_policies" {
  description = "Key Vault access policies"
  type = list(object({
    object_id    = string
    keys         = list(string)
    secrets      = list(string)
    certificates = list(string)
  }))
  default = []
}

variable "sql_connection_string" {
  description = "SQL connection string to store as a secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
