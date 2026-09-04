variable "name" {
  description = "Name of the web app"
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

variable "plan_sku" {
  description = "App Service Plan SKU (e.g. B1, S1, P1v3)"
  type        = string
}

variable "instance_count" {
  description = "Number of App Service instances"
  type        = number
  default     = 1
}

variable "dotnet_version" {
  description = ".NET runtime version"
  type        = string
  default     = "v10.0"
}

variable "subnet_id" {
  description = "Subnet ID for VNet Integration"
  type        = string
}

variable "app_settings" {
  description = "App settings (key-value pairs)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
