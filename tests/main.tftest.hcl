
provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias = "postgres_network"
}

variables {
  source                        = "../"
  env                           = "test"
  product                       = "terraform-module-postgres-managed-instance-tests"
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

  variables {
    common_tags = run.setup.common_tags
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin) == 0
    error_message = "Module stood up a AAD Administrator when not specified by default"
  }
}

run "Test" {
  command = plan

  variables {
    common_tags                   = run.setup.common_tags
    enable_read_only_group_access = false
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin) == 0
    error_message = "module should not create an Azure Active Directory (AAD) Administrator when not explicitly specified"
  }
}

run "Subnet-id" {
  command = plan

  variables {
    common_tags = run.setup.common_tags
  }

  assert {
    condition     = length(data.azurerm_subnet.pg_subnet) == 1
    error_message = "Module stood up a subnet."
  }
}

run "pg_subnet" {
  command = plan

  variables {
    common_tags               = run.setup.common_tags
    pgsql_delegated_subnet_id = ""
  }

  assert {
    condition     = length(data.azurerm_subnet.pg_subnet) == 1
    error_message = "Module did not create the expected subnet"
  }
}

run "service_principal" {
  command = plan

  variables {
    common_tags = run.setup.common_tags
  }

  assert {
    condition     = length(data.azuread_service_principal.mi_name) == 0
    error_message = "Module stood up an Administrator when not specified by service_principal"
  }
}

run "Test_service_principal" {
  command = plan

  variables {
    common_tags                   = run.setup.common_tags
    enable_read_only_group_access = false
  }

  assert {
    condition     = length(data.azuread_service_principal.mi_name) == 0
    error_message = "Module stood up an Administrator when not specified by service_principal"
  }
}

