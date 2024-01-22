output "common_tags" {
  value = module.common_tags.common_tags
}

output "resource_group" {
  value = azurerm_resource_group.test-rg.name
}

output "location" {
  value = azurerm_resource_group.test-rg.location
}

output "vnet" {
  value = azurerm_virtual_network.test_vnet.name
}

output "subnet" {
  value = azurerm_subnet.test_snet.id
}
