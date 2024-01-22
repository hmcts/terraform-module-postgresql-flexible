module "common_tags" {
  source = "github.com/hmcts/terraform-module-common-tags?ref=master"

  builtFrom   = "hmcts/terraform-module-vm-bootstrap"
  environment = "ptlsbox"
  product     = "sds-platform"
}

# Define the resource group
resource "azurerm_resource_group" "test-rg" {
  name     = "terraform-module-managed-instance-tests-custom-rg"
  location = "uksouth"
}

# Define the virtual network
resource "azurerm_virtual_network" "test_vnet" {
  name                = "custom-vnet"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = module.common_tags.common_tags
}

# Define the subnet within the virtual network
resource "azurerm_subnet" "test_snet" {
  name                 = "expanded"
  resource_group_name  = azurerm_resource_group.test-rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

######## New #################

# Fetch data about an existing subnet (replace this with your specific requirements)
# data "azurerm_subnet" "backend-postgresql" {
#   name                 = "test_snet-2"
#   resource_group_name  = "test-rg-2"
#   virtual_network_name = "test_vnet-2"
# }


# data "azurerm_subnet" "backend-postgresql" {
#   name                 = "test_snet-2"
#   resource_group_name  = "test-rg-2"
#   virtual_network_name = "test_vnet-2"
# }

# resource "azurerm_resource_group" "test-rg" {
#   name     = "terraform-module-managed-instance-tests-custom-rg"
#   location = "uksouth"
# }

# resource "azurerm_virtual_network" "test_vnet" {
#   name                = "custom-vnet"
#   location            = azurerm_resource_group.test-rg.location
#   resource_group_name = azurerm_resource_group.test-rg.name
#   address_space       = ["10.0.0.0/16"]

#   tags = module.common_tags.common_tags
# }

# resource "azurerm_subnet" "test_snet" {
#   name                 = "expanded"
#   resource_group_name  = azurerm_resource_group.test-rg.name
#   virtual_network_name = azurerm_virtual_network.test_vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

############# End ###############

# resource "azurerm_subnet" "test" {
#   name                 = "vm-module-test-subnet"
#   resource_group_name  = "ss-test-network-rg"
#   virtual_network_name = "ss-test-vnet"
#   address_prefixes     = ["10.0.1.0/22"]
# }

# data "azurerm_subnet" "backend-postgresql" {
#   name                 = "expanded" # Update to the correct subnet name
#   resource_group_name  = azurerm_resource_group.test-rg.name
#   virtual_network_name = azurerm_virtual_network.test_vnet.name
# }




# module "postgresql" {
#   source = "../"
# }

# locals {
#   pg_databases = {
#     for db in var.pgsql_databases : db.name => db
#   }
# }

# Other configuration, resources, etc.


# data "azurerm_subnet" "pg_subnet" {
#   name                 = "postgres-expanded"
#   resource_group_name  = "ss-test-network-rg"
#   virtual_network_name = "ss-test-vnet"
# }

# dynamic "azurerm_subnet" {
#   for_each = var.pgsql_delegated_subnet_id == "" ? [1] : []
#   content {
#     provider             = azurerm.postgres_network
#     name                 = local.subnet_name
#     resource_group_name  = local.vnet_rg_name
#     virtual_network_name = local.vnet_name
#   }
# }

