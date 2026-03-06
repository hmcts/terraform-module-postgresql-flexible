# Data sources for backup vault and policy
data "azurerm_data_protection_backup_vault" "main" {
  count               = local.enable_backup_enrollment ? 1 : 0
  name                = var.backup_vault_name
  resource_group_name = var.backup_vault_resource_group_name
}

data "azurerm_data_protection_backup_policy_postgresql_flexible_server" "main" {
  count     = local.enable_backup_enrollment ? 1 : 0
  name      = var.backup_policy_name
  vault_id  = data.azurerm_data_protection_backup_vault.main[0].id
}

locals {
  # Enrollment requires: criticality >= 4
  enable_backup_enrollment = var.service_criticality >= 4
}

# Reader role on the RG (opt-out via manage_reader_role_on_rg)
resource "azurerm_role_assignment" "backup_vault_rg_reader" {
  count                = local.enable_backup_enrollment && var.manage_reader_role_on_rg ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.postgresql_rg_name}"
  role_definition_name = "Reader"
  principal_id         = data.azurerm_data_protection_backup_vault.main[0].identity[0].principal_id

  lifecycle {
    create_before_destroy = true
  }
}

# LTR Backup role on the PostgreSQL server
resource "azurerm_role_assignment" "backup_vault_postgres_ltr" {
  count                = local.enable_backup_enrollment ? 1 : 0
  scope                = azurerm_postgresql_flexible_server.pgsql_server.id
  role_definition_name = "PostgreSQL Flexible Server Long Term Retention Backup Role"
  principal_id         = data.azurerm_data_protection_backup_vault.main[0].identity[0].principal_id

  lifecycle {
    create_before_destroy = true
  }
}

# Backup instance enrollment
resource "azurerm_data_protection_backup_instance_postgresql_flexible_server" "main" {
  count    = local.enable_backup_enrollment ? 1 : 0
  name     = "${local.server_name}-backup-instance"
  location = local.postgresql_rg_location

  vault_id         = data.azurerm_data_protection_backup_vault.main[0].id
  server_id        = azurerm_postgresql_flexible_server.pgsql_server.id
  backup_policy_id = data.azurerm_data_protection_backup_policy_postgresql_flexible_server.main[0].id

  depends_on = [
    azurerm_role_assignment.backup_vault_postgres_ltr,
    azurerm_role_assignment.backup_vault_rg_reader,
    azurerm_postgresql_flexible_server.pgsql_server
  ]
}
