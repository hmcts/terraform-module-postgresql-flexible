resource "azurerm_monitor_action_group" "db-alerts-action-group" {
  count               = var.env == "prod" ? 1 : 0
  name                = "CriticalAlertsAction"
  resource_group_name = local.postgresql_rg_name
  short_name          = "db-alerts-action-group"

  tags = var.common_tags

  email_receiver {
    name          = "DB Alert Mailing List"
    email_address = data.azurerm_key_vault_secret.slack_monitoring_address.value
  }
}

