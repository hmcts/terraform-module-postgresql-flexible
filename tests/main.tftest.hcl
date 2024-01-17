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
}

run "setup" {
  module {
    source = "./tests/modules/setup"
  }
}

run "default" {
  command = plan

  variables = {
    common_tags = run.setup.common_tags
  }

  providers = {
    azurerm.postgres_network = azurerm.postgres_network
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_database.pg_databases) == 0
    error_message = "Module stood up a database when not specified by default"
  }

  assert {
    condition     = length(run.setup.azurerm_postgresql_flexible_server_database) > 0
    error_message = "No managed databases specified, but module did not create any"
  }

  # Add conditions for specific databases, for example, "application"
  assert {
    condition     = length(run.setup.azurerm_postgresql_flexible_server_database["application"]) == 0
    error_message = "Module created the 'application' database when not specified by default"
  }
}


