resource "azurerm_virtual_network" "terra_vnet" {

  for_each = var.vnet

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  # resource_group_name = azurerm_resource_group.terra_rg.name       #implicit dependency ( jo argument level pr lgty h)
  address_space       = each.value.address_space


}