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
    error_message = "Module stood up a AAD Administrator when not specified by default"
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
    error_message = "Module did not create the expected subnet."
  }
}




# run "pg_subnet" {
#   command = plan
# }

# variables {
#   common_tags               = run.setup.common_tags
#   pgsql_delegated_subnet_id = false
# }
# assert {
#   condition     = length(azurerm_subnet.pg_subnet) == 1
#   error_message = "Module did not create the expected subnet."
# }





# assert {
#   condition     = length(azurerm_postgresql_flexible_server_database.this) == 0
#   error_message = "Specified a managed database when none was provided"
# }

#   assert {
#     condition     = local.default_name == "terraform-module-sql-managed-instance-tests"
#     error_message = "Wrong default name specified when component is empty"
#   }

#   assert {
#     condition     = local.name == local.default_name
#     error_message = "Default name not used when custom name is empty"
#   }

#   assert {
#     condition     = length(azurerm_resource_group.new) == 1
#     error_message = "Did not specify a new resource group by default"
#   }

#   assert {
#     condition     = length(data.azurerm_resource_group.existing) == 0
#     error_message = "Using existing resource group when none was specified"
#   }

#   assert {
#     condition     = azurerm_resource_group.new[0].name == "terraform-module-sql-managed-instance-tests-test"
#     error_message = "Wpecified wrong name for new resource group"
#   }

#   assert {
#     condition     = local.resource_group == "terraform-module-sql-managed-instance-tests-test"
#     error_message = "Wrong resource group specified by default"
#   }

#   assert {
#     condition     = azurerm_resource_group.new[0].name == "terraform-module-sql-managed-instance-tests-test"
#     error_message = "Wpecified wrong name for new resource group"
#   }

#   assert {
#     condition     = local.location == "uksouth"
#     error_message = "Wrong region specified by default"
#   }

#   assert {
#     condition     = local.is_prod == false
#     error_message = "Specified prod in nonprod environment"
#   }

#   assert {
#     condition     = local.admin_group == "DTS Platform Operations"
#     error_message = "Specified wrong admin group for nonprod environment"
#   }

#   assert {
#     condition     = local.db_reader_user == "DTS SDS DB Access Reader"
#     error_message = "Specified wrong DB user for nonprod environment"
#   }

#   assert {
#     condition     = length(azurerm_virtual_network.new) == 1
#     error_message = "No new virtual network stood up by default"
#   }

#   assert {
#     condition     = length(azurerm_subnet.new) == 1
#     error_message = "No new subnet stood up by default"
#   }

#   assert {
#     condition     = local.vnet_name == "terraform-module-sql-managed-instance-tests-vnet-test"
#     error_message = "Wpecified wrong name for new vnet"
#   }

#   assert {
#     condition     = azurerm_mssql_managed_instance.sqlmi.name == "terraform-module-sql-managed-instance-tests-test"
#     error_message = "Specified wrong name for SQL managed instance"
#   }

#   assert {
#     condition     = azurerm_virtual_network.new[0].name == "terraform-module-sql-managed-instance-tests-vnet-test"
#     error_message = "Specified wrong name for new virtual network"
#   }

#   assert {
#     condition     = azurerm_subnet.new[0].name == "terraform-module-sql-managed-instance-tests-sqlmi-subnet-test"
#     error_message = "Specified wrong name for new subnet"
#   }

#   assert {
#     condition     = azurerm_network_security_group.this[0].name == "terraform-module-sql-managed-instance-tests-nsg-test"
#     error_message = "Specified wrong name for new network security group"
#   }

#   assert {
#     condition     = azurerm_route_table.this[0].name == "terraform-module-sql-managed-instance-tests-rt-test"
#     error_message = "Specified wrong name for new route table"
#   }
# }

# run "managed_identity" {
#   command = plan

#   variables {
#     common_tags                       = run.setup.common_tags
#     user_assigned_managed_identity_id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/example-resource-group/providers/Microsoft.ManagedIdentity/userAssignedIdentities/userAssignedIdentityValue"
#   }

#   assert {
#     condition     = length(azurerm_mssql_managed_instance_active_directory_administrator.sqlmi) == 1
#     error_message = "Did not stand up a AAD Administrator when specified"
#   }

#   assert {
#     condition     = length(azurerm_mssql_managed_instance.sqlmi.identity[0].identity_ids) == 1
#     error_message = "Specified the wrong identity id for the managed instance"
#   }

#   assert {
#     condition     = contains(azurerm_mssql_managed_instance.sqlmi.identity[0].identity_ids, "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/example-resource-group/providers/Microsoft.ManagedIdentity/userAssignedIdentities/userAssignedIdentityValue")
#     error_message = "Specified the wrong identity id for the managed instance"
#   }
# }

# run "managed_database" {
#   command = plan

#   variables {
#     common_tags = run.setup.common_tags
#     databases   = ["foodb", "bardb"]
#   }

#   assert {
#     condition     = length(azurerm_mssql_managed_database.this) == 2
#     error_message = "Specified wrong count of managed databases"
#   }

#   assert {
#     condition     = contains(keys(azurerm_mssql_managed_database.this), "foodb")
#     error_message = "Specified wrong name for managed database 1"
#   }

#   assert {
#     condition     = contains(keys(azurerm_mssql_managed_database.this), "bardb")
#     error_message = "Specified wrong name for managed database 2"
#   }
# }

# run "locals" {
#   command = plan

#   variables {
#     common_tags = run.setup.common_tags
#     component   = "example"
#     name        = "my-db"
#   }

#   assert {
#     condition     = local.default_name == "terraform-module-sql-managed-instance-tests-example"
#     error_message = "Wrong default name specified when component is specified"
#   }

#   assert {
#     condition     = local.name == "my-db"
#     error_message = "Custom database name not used when custom name is specified"
#   }
# }

# run "existing_rg" {
#   command = plan

#   variables {
#     common_tags                  = run.setup.common_tags
#     existing_resource_group_name = run.setup.resource_group
#   }

#   assert {
#     condition     = length(azurerm_resource_group.new) == 0
#     error_message = "Specified a new resource group when existing was provided"
#   }

#   assert {
#     condition     = length(data.azurerm_resource_group.existing) == 1
#     error_message = "Not using existing resource group when one was specified"
#   }

#   assert {
#     condition     = length(azurerm_virtual_network.new) == 1
#     error_message = "Did not specify new virtual network when none was provided"
#   }

#   assert {
#     condition     = length(azurerm_subnet.new) == 1
#     error_message = "Did not specify new subnet when none was provided"
#   }
# }

# run "prod_env" {
#   command = plan

#   variables {
#     common_tags = run.setup.common_tags
#     env         = "prod"
#   }

#   assert {
#     condition     = local.is_prod == true
#     error_message = "Specified nonprod in prod environment"
#   }

#   assert {
#     condition     = local.admin_group == "DTS Platform Operations SC"
#     error_message = "Specified wrong admin group for prod environment"
#   }

#   assert {
#     condition     = local.db_reader_user == "DTS JIT Access terraform-module-sql-managed-instance-tests DB Reader SC"
#     error_message = "Specified wrong DB user for prod environment"
#   }
# }

# run "existing_infra" {
#   command = plan

#   variables {
#     common_tags                  = run.setup.common_tags
#     existing_resource_group_name = run.setup.resource_group
#     vnet_name                    = run.setup.vnet
#     subnet_id                    = run.setup.subnet
#   }

#   assert {
#     condition     = length(azurerm_virtual_network.new) == 0
#     error_message = "Specified new virtual network when one was provided"
#   }

#   assert {
#     condition     = length(azurerm_subnet.new) == 0
#     error_message = "Specified new subnet when one was provided"
#   }

#   assert {
#     condition     = local.vnet_name == run.setup.vnet
#     error_message = "Specified incorrect vnet name"
#   }

#   assert {
#     condition     = local.subnet_id == run.setup.subnet
#     error_message = "Specified incorrect subnet id"
#   }
# }

