resource "azurerm_log_analytics_workspace" "pgsql_log_analytics_workspace" {
  count               = var.enable_qpi ? 1 : 0
  name                = "${local.server_name}-workspace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "pgsql_diag" {
  count                      = var.enable_qpi ? 1 : 0
  name                       = "${local.server_name}-to-log-analytics"
  target_resource_id         = azurerm_postgresql_flexible_server.pgsql_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.pgsql_log_analytics_workspace.id

  enabled_log {
    category_group = "PostgreSQLLogs"
  }

  depends_on = [
    azurerm_postgresql_flexible_server.pgsql_server,
    azurerm_log_analytics_workspace.pgsql_log_analytics_workspace
  ]
}