resource "azurerm_postgresql_flexible_server_database" "pg_databases" {
  for_each = var.pgsql_databases

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.pgsql_server.id
  collation = each.value.collation
  charset   = each.value.charset
}
