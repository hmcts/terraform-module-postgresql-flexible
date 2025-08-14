locals {
  default_name           = var.component != "" ? "${var.product}-${var.component}" : var.product
  name                   = var.name != "" ? var.name : local.default_name
  server_name            = "${local.name}-${var.env}"
  postgresql_rg_name     = var.resource_group_name == null ? azurerm_resource_group.rg[0].name : var.resource_group_name
  postgresql_rg_location = var.resource_group_name == null ? azurerm_resource_group.rg[0].location : var.location
  env_temp               = replace(var.env, "idam-", "")
  env                    = local.env_temp == "sandbox" ? "sbox" : local.env_temp
  vnet_rg_name           = var.business_area == "sds" ? "ss-${var.env}-network-rg" : "cft-${local.env}-network-rg"
  vnet_name              = var.business_area == "sds" ? "ss-${var.env}-vnet" : "cft-${local.env}-vnet"

  private_dns_zone_id = "/subscriptions/1baf5470-1c3e-40d3-a6f7-74bfbce4b348/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/private.postgres.database.azure.com"

  is_prod = length(regexall(".*(prod).*", var.env)) > 0

  admin_group     = local.is_prod ? "DTS Platform Operations SC" : "DTS Platform Operations"
  db_report_group = "DTS Production DB Reporting"
  db_reader_user  = local.is_prod ? "DTS JIT Access ${var.product} DB Reader SC" : "DTS ${upper(var.business_area)} DB Access Reader"


  high_availability_environments = ["ptl", "perftest", "stg", "aat", "prod"]
  high_availability              = var.high_availability == null ? contains(local.high_availability_environments, local.env) : var.high_availability

  subnet_name = var.subnet_suffix != null ? "postgres-${var.subnet_suffix}" : "postgresql"

  kv_name          = var.kv_name != "" ? var.kv_name : "${var.product}-${var.env}"
  user_secret_name = var.user_secret_name != "" ? var.user_secret_name : "${var.product}-${var.component}-POSTGRES-USER"
  pass_secret_name = var.pass_secret_name != "" ? var.pass_secret_name : "${var.product}-${var.component}-POSTGRES-PASS"
}

data "azurerm_key_vault_secret" "email_address" {
  count        = var.email_address_key == "" || var.email_address_key_vault_id == "" ? 0 : 1
  name         = var.email_address_key
  key_vault_id = var.email_address_key_vault_id
}

data "azurerm_subnet" "pg_subnet" {
  provider             = azurerm.postgres_network
  name                 = local.subnet_name
  resource_group_name  = local.vnet_rg_name
  virtual_network_name = local.vnet_name

  count = var.pgsql_delegated_subnet_id == "" ? 1 : 0
}

data "azurerm_client_config" "current" {}

data "azuread_group" "db_admin" {
  display_name     = local.admin_group
  security_enabled = true
}

data "azuread_group" "db_report_admin" {
  display_name     = local.db_report_group
  security_enabled = true
}

data "azuread_service_principal" "mi_name" {
  count     = var.enable_read_only_group_access ? 1 : 0
  object_id = var.admin_user_object_id
}

resource "terraform_data" "trigger_password_reset" {
  input = var.trigger_password_reset
}

resource "random_password" "password" {
  length = 20
  # safer set of special characters for pasting in the shell
  override_special = "()-_"

  lifecycle {
    replace_triggered_by = [terraform_data.trigger_password_reset]
  }
}

resource "azurerm_postgresql_flexible_server" "pgsql_server" {
  name                          = local.server_name
  resource_group_name           = local.postgresql_rg_name
  location                      = local.postgresql_rg_location
  version                       = var.pgsql_version
  public_network_access_enabled = var.public_access

  create_mode                       = var.create_mode
  point_in_time_restore_time_in_utc = var.restore_time
  source_server_id                  = var.source_server_id

  delegated_subnet_id = var.public_access == true ? null : var.pgsql_delegated_subnet_id == "" ? data.azurerm_subnet.pg_subnet[0].id : var.pgsql_delegated_subnet_id
  private_dns_zone_id = var.public_access == true ? null : local.private_dns_zone_id

  administrator_login    = var.pgsql_admin_username
  administrator_password = random_password.password.result

  storage_mb        = var.pgsql_storage_mb
  storage_tier      = var.pgsql_storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  sku_name = var.pgsql_sku

  authentication {
    active_directory_auth_enabled = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
    password_auth_enabled         = true
  }

  tags = var.common_tags

  dynamic "high_availability" {
    for_each = local.high_availability != false ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  maintenance_window {
    day_of_week  = "0"
    start_hour   = "03"
    start_minute = "00"
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
  for_each = merge(
    {
      for config in var.pgsql_server_configuration :
      config.name => config
    },
    var.enable_qpi ? {
      "pg_qs.query_capture_mode"              = { name = "pg_qs.query_capture_mode", value = "ALL" },
      "log_lock_waits"                        = { name = "log_lock_waits", value = "on" },
      "pgms_wait_sampling.query_capture_mode" = { name = "pgms_wait_sampling.query_capture_mode", value = "ALL" }
      "track_io_timing"                       = { name = "track_io_timing", value = "on" }
    } : {}
  )

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.pgsql_server.id
  value     = each.value.value
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "pgsql_adadmin" {
  server_name         = azurerm_postgresql_flexible_server.pgsql_server.name
  resource_group_name = azurerm_postgresql_flexible_server.pgsql_server.resource_group_name
  tenant_id           = "531ff96d-0ae9-462a-8d2d-bec7c0b42082"
  object_id           = local.is_prod ? "4d0554dd-fe60-424a-be9c-36636826d927" : "e7ea2042-4ced-45dd-8ae3-e051c6551789"
  principal_name      = local.admin_group
  principal_type      = "Group"
  depends_on = [
    azurerm_postgresql_flexible_server.pgsql_server
  ]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "pgsql_db_report_admin" {
  count               = local.is_prod && var.enable_db_report_privileges ? 1 : 0
  server_name         = azurerm_postgresql_flexible_server.pgsql_server.name
  resource_group_name = azurerm_postgresql_flexible_server.pgsql_server.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_group.db_report_admin.object_id
  principal_name      = local.db_report_group
  principal_type      = "Group"
  depends_on = [
    azurerm_postgresql_flexible_server.pgsql_server
  ]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "pgsql_principal_admin" {
  count               = var.enable_read_only_group_access ? 1 : 0
  server_name         = azurerm_postgresql_flexible_server.pgsql_server.name
  resource_group_name = azurerm_postgresql_flexible_server.pgsql_server.resource_group_name
  tenant_id           = "531ff96d-0ae9-462a-8d2d-bec7c0b42082"
  object_id           = var.admin_user_object_id
  principal_name      = "jenkins-cftptl-intsvc-mi"
  principal_type      = "ServicePrincipal"
  depends_on = [
    azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_adadmin
  ]
}

resource "null_resource" "set-user-permissions-additionaldbs" {
  for_each = var.enable_read_only_group_access ? { for index, db in var.pgsql_databases : db.name => db } : {}

  triggers = {
    script_hash    = filesha256("${path.module}/set-postgres-permissions.bash")
    name           = local.name
    db_reader_user = local.db_reader_user
    force_trigger  = var.force_user_permissions_trigger
  }

  provisioner "local-exec" {
    command = "${path.module}/set-postgres-permissions.bash"

    environment = {
      PGHOST         = azurerm_postgresql_flexible_server.pgsql_server.fqdn
      DB_USER        = data.azuread_service_principal.mi_name[0].display_name
      DB_ADMIN_GROUP = local.admin_group
      DB_READER_USER = local.db_reader_user
      DB_NAME        = each.value.name
      DB_ADMIN       = azurerm_postgresql_flexible_server.pgsql_server.administrator_login
      DB_PASSWORD    = nonsensitive(azurerm_postgresql_flexible_server.pgsql_server.administrator_password)
    }
  }
  depends_on = [
    azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin,
    azurerm_postgresql_flexible_server_database.pg_databases
  ]
}

resource "null_resource" "set-schema-ownership" {
  for_each = var.enable_schema_ownership ? { for index, db in var.pgsql_databases : db.name => db } : {}

  triggers = {
    script_hash   = filesha256("${path.module}/set-postgres-owner.bash")
    name          = local.name
    force_trigger = var.force_schema_ownership_trigger
  }

  provisioner "local-exec" {
    command = "${path.module}/set-postgres-owner.bash"

    environment = {
      PGHOST           = azurerm_postgresql_flexible_server.pgsql_server.fqdn
      DB_NAME          = each.value.name
      DB_ADMIN         = azurerm_postgresql_flexible_server.pgsql_server.administrator_login
      KV_NAME          = var.kv_name
      KV_SUBSCRIPTION  = var.kv_subscription
      USER_SECRET_NAME = local.user_secret_name
      PASS_SECRET_NAME = local.pass_secret_name
    }
  }
  depends_on = [
    azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin,
    azurerm_postgresql_flexible_server_database.pg_databases
  ]
}

resource "null_resource" "set-db-report-privileges" {
  for_each = local.is_prod && var.enable_db_report_privileges ? {
    for db in var.pgsql_databases :
    db.name => db
    if(
      try(length(db.report_privilege_schema), 0) > 0 &&
      try(length(db.report_privilege_tables), 0) > 0
    )
  } : {}
  triggers = {
    script_hash   = filesha256("${path.module}/set-postgres-db-report-privileges.bash")
    name          = local.name
    force_trigger = var.force_db_report_privileges_trigger
  }

  provisioner "local-exec" {
    command = "${path.module}/set-postgres-db-report-privileges.bash"

    environment = {
      PGHOST                  = azurerm_postgresql_flexible_server.pgsql_server.fqdn
      DB_NAME                 = each.value.name
      KV_NAME                 = local.kv_name
      KV_SUBSCRIPTION         = var.kv_subscription
      USER_SECRET_NAME        = local.user_secret_name
      PASS_SECRET_NAME        = local.pass_secret_name
      REPORT_GROUP            = local.db_report_group
      REPORT_PRIVILEGE_SCHEMA = try(each.value.report_privilege_schema, "")
      REPORT_PRIVILEGE_TABLES = join(" ", try(each.value.report_privilege_tables, []))
    }
  }
  depends_on = [
    azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin,
    azurerm_postgresql_flexible_server_database.pg_databases,
    azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_db_report_admin
  ]
}