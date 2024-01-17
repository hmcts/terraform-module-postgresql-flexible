provider "azurerm" {
  features {}
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
    condition     = length(run.setup.azurerm_postgresql_flexible_server_database.pg_databases) == 0
    error_message = "Specified a managed database when none was provided"
  }
}

