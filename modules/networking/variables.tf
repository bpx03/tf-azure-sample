variable "name_prefix" {
  description = "Prefix for all networking resources"
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

variable "vnet_address_space" {
  description = "CIDR block for the VNet (e.g. 10.0.0.0/16)"
  type        = string
}

variable "subnet_address_space" {
  description = "CIDR block for the App Service subnet (e.g. 10.0.1.0/24)"
  type        = string
}

variable "sql_subnet_address_space" {
  description = "CIDR block for the SQL subnet (e.g. 10.0.2.0/24)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
