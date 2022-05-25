locals {
  default_name = var.component != "" ? "${var.product}-${var.component}" : var.product
  name         = var.name != "" ? var.name : local.default_name
  server_name  = "${local.name}-${var.env}"

  private_dns_zone_id = "/subscriptions/1baf5470-1c3e-40d3-a6f7-74bfbce4b348/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/private.postgres.database.azure.com"
}

resource "random_password" "password" {
  length = 20
  # safer set of special characters for pasting in the shell
  override_special = "()-_"
}

resource "azurerm_postgresql_flexible_server" "pgsql_server" {
  name                = local.server_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  version             = var.pgsql_version

  delegated_subnet_id = var.pgsql_delegated_subnet_id
  private_dns_zone_id = local.private_dns_zone_id

  administrator_login    = var.pgsql_admin_username
  administrator_password = random_password.password.result

  storage_mb = var.pgsql_storage_mb

  sku_name = var.pgsql_sku

  tags = var.common_tags

  high_availability {
    mode = "ZoneRedundant"
  }

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "pgsql_server_config" {
  for_each = {
    for index, config in var.pgsql_server_configuration :
    config.name => config
  }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.pgsql_server.id
  value     = each.value.value
}
