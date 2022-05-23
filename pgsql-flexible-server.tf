resource "azurerm_postgresql_flexible_server" "pgsql_server" {
  name                = var.pgsql_server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.pgsql_version

  delegated_subnet_id = var.pgsql_delegated_subnet_id
  private_dns_zone_id = var.pgsql_private_dns_zone_id

  administrator_login    = var.pgsql_admin_username
  administrator_password = var.pgsql_admin_password
  zone                   = var.pgsql_server_zone

  storage_mb = var.pgsql_storage_mb

  sku_name = var.pgsql_sku

  common_tags = var.common_tags
}

resource "azurerm_postgresql_flexible_server_configuration" "pgsql_server_config" {
  for_each = var.pgsql_server_configuration

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.pgsql_server.id
  value     = each.value.value
}
