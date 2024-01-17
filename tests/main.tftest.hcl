provider "azurerm" {
  features {}
}

variables {
  env                       = var.env
  common_tags               = var.common_tags
  pgsql_databases           = var.pgsql_databases
  pgsql_delegated_subnet_id = var.pgsql_delegated_subnet_id
  pgsql_version             = var.pgsql_version
  product                   = var.product
  business_area             = var.business_area
  component                 = var.component
  azurerm.postgres_network  = azurerm.postgres_network
}

run "setup" {
  module {
    source = "./tests/modules/setup"
  }
}

run "default" {
  command = plan

  variables {
    common_tags = run.setup.common_tags
  }

assert {
    condition     = length(azurerm_postgresql_flexible_server_database.pg_databases) == 0
    error_message = "Module stood up a database when not specified by default"
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_database.pg_databases) == 0
    condition     = length(.this) == 0
    error_message = "Specified a managed database when none was provided"
  }