output "resource_group_name" {
  value = local.postgresql_rg_name
}

output "resource_group_location" {
  value = local.postgresql_rg_location
}

output "username" {
  value = azurerm_postgresql_flexible_server.pgsql_server.administrator_login
}

output "password" {
  value     = azurerm_postgresql_flexible_server.pgsql_server.administrator_password
  sensitive = true
}

output "fqdn" {
  value = azurerm_postgresql_flexible_server.pgsql_server.fqdn
}

output "instance_id" {
  value = azurerm_postgresql_flexible_server.pgsql_server.id
}

output "backup_instance_id" {
  description = "The ID of the backup instance. Null if not enrolled."
  value       = try(azurerm_data_protection_backup_instance_postgresql_flexible_server.main[0].id, null)
}

output "backup_instance_name" {
  description = "The name of the backup instance. Null if not enrolled."
  value       = try(azurerm_data_protection_backup_instance_postgresql_flexible_server.main[0].name, null)
}

output "is_enrolled_in_backup_vault" {
  description = "Whether this PostgreSQL server is enrolled in a backup vault."
  value       = local.enable_backup_enrollment
}
