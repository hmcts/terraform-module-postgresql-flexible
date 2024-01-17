provider "azurerm" {
  features {}
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "postgres_network"
  subscription_id            = var.aks_subscription_id
}
variables {
  source                        = "../"
  env                           = "test"
  product                       = "terraform-module-sql-managed-instance-tests"
  project                       = "sds"
  component                     = ""
  business_area                 = "sds"
  subnet_suffix                 = "expanded"
  enable_read_only_group_access = false
  common_tags                   = {}
  pgsql_databases               = [{ name = "application" }]
  pgsql_version                 = "16"
}

run "setup" {
  module {
    source = "./tests/modules/setup"
  }
}

run "default" {
  command = plan

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


