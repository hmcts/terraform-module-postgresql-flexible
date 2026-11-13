resource "azurerm_monitor_metric_alert" "db_alert_cpu" {
  count               = can(var.email_address_key) || can(var.email_address_key_vault_id) ? 1 : 0
  name                = "db_cpu_percent_${local.server_name}"
  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the cpu utilization is greater than ${var.cpu_threshold}%"
  severity            = var.alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.cpu_threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}

resource "azurerm_monitor_metric_alert" "db_alert_memory" {
  count               = can(var.email_address_key) || can(var.email_address_key_vault_id) ? 1 : 0
  name                = "db_memory_percent_${local.server_name}"
  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the memory utilization is greater than ${var.memory_threshold}%"
  severity            = var.alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.memory_threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}

resource "azurerm_monitor_metric_alert" "db_alert_storage_utilization" {
  count               = can(var.email_address_key) || can(var.email_address_key_vault_id) ? 1 : 0
  name                = "db_storage_utilization_${local.server_name}"
  resource_group_name = local.postgresql_rg_name
  scopes              = [azurerm_postgresql_flexible_server.pgsql_server.id]
  description         = "Whenever the storage utilization is greater than ${var.storage_threshold}%"
  severity            = var.alert_severity
  frequency           = var.alert_frequency
  window_size         = var.alert_window_size

  tags = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = var.storage_threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.db-alerts-action-group[count.index].id
  }
}
