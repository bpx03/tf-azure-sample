# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name
  tags                = var.tags

  # Security settings
  rbac_authorization_enabled        = false # Using access policies (simpler for small teams)
  soft_delete_retention_days        = 90
  purge_protection_enabled          = var.environment == "prod"
  enabled_for_deployment            = true
  enabled_for_disk_encryption       = true
  enabled_for_template_deployment   = true

  # Network: restrict to VNet only (no public access)
  network_acls {
    default_action                = "Deny"
    bypass                        = "AzureServices"
    ip_rules                      = []
    virtual_network_subnet_ids    = [var.subnet_id]
  }
}

# ---------------------------------------------------------------------------
# Key Vault Access Policies
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "main" {
  for_each = { for policy in var.access_policies : policy.object_id => policy }

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.keys
  secret_permissions      = each.value.secrets
  certificate_permissions = each.value.certificates
}

# ---------------------------------------------------------------------------
# Secrets — injected into App Service via key_vault_secret_name_ref
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = var.sql_connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
}
