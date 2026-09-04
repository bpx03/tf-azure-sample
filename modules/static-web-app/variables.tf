variable "name" {
  description = "Name of the Static Web App"
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

variable "sku_tier" {
  description = "SKU tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "sku_size" {
  description = "SKU size (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "repo_url" {
  description = "Git repository URL for the React frontend"
  type        = string
}

variable "repo_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "repo_token" {
  description = "GitHub PAT with repo access (for auto-deploy)"
  type        = string
  sensitive   = true
}

variable "api_url" {
  description = "URL of the backend API (injected as REACT_APP_API_URL)"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
