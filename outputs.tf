output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.name
}

output "password" {
  value = azurerm_postgresql_flexible_server.pgsql_server.administrator_password
}
