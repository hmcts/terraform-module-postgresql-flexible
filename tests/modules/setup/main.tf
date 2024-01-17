module "common_tags" {
  source = "github.com/hmcts/terraform-module-common-tags?ref=master"

  builtFrom   = "hmcts/terraform-module-vm-bootstrap"
  environment = "ptlsbox"
  product     = "sds-platform"
}

resource "azurerm_resource_group" "test-rg" {
  name     = "terraform-module-s-managed-instance-tests-custom-rg"
  location = "uksouth"
}

resource "azurerm_virtual_network" "test_vnet" {
  name                = "custom-vnet"
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = module.common_tags.common_tags
}

resource "azurerm_subnet" "test_snet" {
  name                 = "custom-subnet"
  resource_group_name  = azurerm_resource_group.test-rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
