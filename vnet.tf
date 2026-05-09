resource "azurerm_resource_group" "rg" {
  name     = "rg_1"
  location = "eastus"

  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = local.address_space
  tags                = local.tags
}

resource "azurerm_subnet" "sub" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.address_prefixes
}