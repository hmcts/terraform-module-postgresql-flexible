resource "azurerm_monitor_action_group" "db-alerts-action-group" {
  for_each            = local.email_address_key_vault_data != {} ? { "email_address" : local.email_address_key_vault_data } : {}
  name                = var.action_group_name
  resource_group_name = local.postgresql_rg_name
  short_name          = substr(var.action_group_name, 0, 12)

  tags = var.common_tags

  email_receiver {
    name                    = "Email Receiver"
    email_address           = data.azurerm_key_vault_secret.email_address[each.key].value
    use_common_alert_schema = true
  }
}