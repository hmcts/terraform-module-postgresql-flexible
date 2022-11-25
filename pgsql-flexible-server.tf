locals {
  default_name           = var.component != "" ? "${var.product}-${var.component}" : var.product
  name                   = var.name != "" ? var.name : local.default_name
  server_name            = "${local.name}-${var.env}"
  postgresql_rg_name     = var.resource_group_name == null ? azurerm_resource_group.rg[0].name : var.resource_group_name
  postgresql_rg_location = var.resource_group_name == null ? azurerm_resource_group.rg[0].location : var.location
  vnet_rg_name           = var.project == "sds" ? "ss-${var.env}-network-rg" : "core-infra-${var.env}"
  vnet_name              = var.project == "sds" ? "ss-${var.env}-vnet" : "core-infra-vnet-${var.env}"

  private_dns_zone_id = "/subscriptions/1baf5470-1c3e-40d3-a6f7-74bfbce4b348/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/private.postgres.database.azure.com"
}

data "azurerm_subnet" "pg_subnet" {
  name                 = "postgresql"
  resource_group_name  = local.vnet_rg_name
  virtual_network_name = local.vnet_name

  count = var.pgsql_delegated_subnet_id == "" ? 1 : 0
}

data "azurerm_client_config" "current" {}

resource "random_password" "password" {
  length = 20
  # safer set of special characters for pasting in the shell
  override_special = "()-_"
}

resource "azurerm_postgresql_flexible_server" "pgsql_server" {
  name                = local.server_name
  resource_group_name = local.postgresql_rg_name
  location            = local.postgresql_rg_location
  version             = var.pgsql_version

  create_mode                       = var.create_mode
  point_in_time_restore_time_in_utc = var.restore_time
  source_server_id                  = var.source_server_id

  delegated_subnet_id = var.pgsql_delegated_subnet_id == "" ? data.azurerm_subnet.pg_subnet[0].id : var.pgsql_delegated_subnet_id
  private_dns_zone_id = local.private_dns_zone_id

  administrator_login    = var.pgsql_admin_username
  administrator_password = random_password.password.result

  storage_mb = var.pgsql_storage_mb

  sku_name = var.pgsql_sku

  dynamic "authentication" {

    # Include this block only if var.set_ad_admin is set to a non-null value.
    for_each = var.set_ad_admin[*]
    content {
      active_directory_auth_enabled = true
      tenant_id                     = data.azurerm_client_config.current.tenant_id
    }
  }

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

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backups

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


resource "azurerm_postgresql_flexible_server_active_directory_administrator" "pgsql_adadmin" {
  count               = var.set_ad_admin != null ? 1 : 0
  server_name         = azurerm_postgresql_flexible_server.pgsql_server.name
  resource_group_name = azurerm_postgresql_flexible_server.pgsql_server.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = var.ad_pricipal_name
  principal_type      = var.ad_principal_type
}
