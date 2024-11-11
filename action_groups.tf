resource "azurerm_monitor_action_group" "db-alerts-action-group" {
  name                = var.action_group_name
  resource_group_name = local.postgresql_rg_name
  short_name          = substr(var.action_group_name, 0, 12)

  tags = var.common_tags

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.key
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "sms_receiver" {
    for_each = var.sms_receivers
    content {
      name         = sms_receiver.key
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name        = webhook_receiver.key
      service_uri = webhook_receiver.value
    }
  }
}