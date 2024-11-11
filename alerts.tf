resource "azurerm_monitor_metric_alert" "db_alert_cpu" {
  count               = var.env == "prod" ? 1 : 0
  name                = "db_cpu_percent_80_${local.server_name}"
  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the cpu utilization is greater than 80"
  frequency           = "PT1H"
  window_size         = "P1D"

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}

resource "azurerm_monitor_metric_alert" "db_alert_memory" {
  count               = var.env == "prod" ? 1 : 0
  name                = "db_memory_percent_80_${local.server_name}"
  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the memory utilization is greater than 80"
  frequency           = "PT1H"
  window_size         = "P1D"

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}

resource "azurerm_monitor_metric_alert" "db_alert_storage_utilization" {
  count               = var.env == "prod" ? 1 : 0
  name                = "db_storage_utilization_80_${local.server_name}"

  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the storage utilization is greater than 80"
  frequency           = "PT1H"
  window_size         = "P1D"

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}
