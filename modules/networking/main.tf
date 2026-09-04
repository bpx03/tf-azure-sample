# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Subnet — App Service (Virtual Network Integration)
# ---------------------------------------------------------------------------

resource "azurerm_subnet" "app_service" {
  name                 = "${var.name_prefix}-subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_space]

  # Required for App Service VNet Integration
  service_endpoint {
    service = "Microsoft.Sql"
  }
}

# ---------------------------------------------------------------------------
# Subnet — SQL Database (Private Endpoint)
# ---------------------------------------------------------------------------

resource "azurerm_subnet" "sql" {
  name                 = "${var.name_prefix}-subnet-sql"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.sql_subnet_address_space]

  # Required for SQL Private Endpoint
  service_endpoint {
    service = "Microsoft.Sql"
  }
}

# ---------------------------------------------------------------------------
# Network Security Group — App Service Subnet
# ---------------------------------------------------------------------------

resource "azurerm_network_security_group" "app_service" {
  name                = "${var.name_prefix}-nsg-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowAppServiceVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Rdp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}
