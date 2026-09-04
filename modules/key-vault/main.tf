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
  rbac_authorization_enabled        = false
  soft_delete_retention_days        = 90
  purge_protection_enabled          = var.environment == "prod"
  enabled_for_deployment            = true
  enabled_for_disk_encryption       = true
  enabled_for_template_deployment   = true

  # Network: restrict to VNet only (no public access)
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = [var.subnet_id]
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
# Secrets — one per microservice (connection strings)
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "sql_connection_strings" {
  for_each = toset(keys(var.sql_connection_strings))

  name         = "sql-connection-string-${each.value}"
  value        = var.sql_connection_strings[each.value]
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
}
