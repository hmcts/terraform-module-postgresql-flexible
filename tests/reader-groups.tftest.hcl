# Offline plans: never creates Azure or database resources.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "33333333-3333-3333-3333-333333333333" }
  }
}
mock_provider "azurerm" { alias = "postgres_network" }
mock_provider "azuread" {
  mock_data "azuread_group" {
    defaults = { object_id = "44444444-4444-4444-4444-444444444444" }
  }
  mock_data "azuread_service_principal" {
    defaults = {
      object_id    = "11111111-1111-1111-1111-111111111111"
      display_name = "existing-jenkins"
    }
  }
}
mock_provider "random" {}
mock_provider "null" {}

variables {
  env                       = "test"
  product                   = "opal"
  component                 = "fines-service"
  business_area             = "sds"
  common_tags               = {}
  pgsql_databases           = [{ name = "opal-fines-db" }]
  pgsql_version             = "17"
  pgsql_delegated_subnet_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/postgresql"
  admin_user_object_id      = "22222222-2222-2222-2222-222222222222"
}

run "nonprod_defaults_unchanged" {
  command = plan
  assert {
    condition     = local.db_reader_user == "DTS SDS DB Access Reader" && local.principal_admin_object_id == var.admin_user_object_id && length(local.additional_admin_user_object_ids) == 0
    error_message = "Default reader group and principal administrator must remain unchanged for master consumers."
  }
}

run "prod_defaults_unchanged" {
  command = plan
  variables { env = "prod" }
  assert {
    condition     = local.db_reader_user == "DTS JIT Access opal DB Reader SC" && var.enable_write_group_access == false
    error_message = "Production must retain its product reader group without enabling writes."
  }
}

run "opal_reader_and_preserved_admin" {
  command = plan
  variables {
    reader_group_name             = "DTS JIT Access opal DB Reader NonProd"
    preserve_legacy_jenkins_admin = true
  }
  assert {
    condition     = null_resource.set-user-permissions-additionaldbs["opal-fines-db"].triggers.db_reader_user == "DTS JIT Access opal DB Reader NonProd"
    error_message = "The permission provisioner must use and track the OPAL-specific reader group."
  }
  assert {
    condition     = local.principal_admin_object_id == "11111111-1111-1111-1111-111111111111" && local.additional_admin_user_object_ids == toset([var.admin_user_object_id])
    error_message = "OPAL's opt-in migration must preserve the legacy admin and add the current identity once."
  }
  assert {
    condition     = local.db_writer_user == "DTS SDS DB Access Writer" && var.enable_write_group_access == false
    error_message = "A reader override must not enable or rename writer access."
  }
}

run "explicit_admin_deduplicated" {
  command = plan
  variables {
    existing_admin_user_object_id    = "11111111-1111-1111-1111-111111111111"
    additional_admin_user_object_ids = ["11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222", "22222222-2222-2222-2222-222222222222"]
  }
  assert {
    condition     = length(local.additional_admin_user_object_ids) == 1 && local.principal_admin_object_id == var.existing_admin_user_object_id
    error_message = "Repeated admin IDs must not create duplicate resources or replace the existing admin."
  }
}

run "disabled_access_with_preservation" {
  command = plan
  variables {
    preserve_legacy_jenkins_admin = true
    enable_read_only_group_access = false
    enable_write_group_access     = false
  }
  assert {
    condition     = length(azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin) == 0 && length(azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_additional_principal_admin) == 0
    error_message = "Disabled group access must not evaluate a missing legacy identity or create administrators."
  }
}

run "reject_invalid_group_name" {
  command = plan
  variables { reader_group_name = "invalid'group" }
  expect_failures = [var.reader_group_name]
}
