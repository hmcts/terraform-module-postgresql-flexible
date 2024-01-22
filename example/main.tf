module "postgresql" {

  providers = {
    azurerm.postgres_network = azurerm.postgres_network
  }

  source = "../"
  env    = var.env

  product       = "platops"
  component     = "example"
  business_area = "sds"

  subnet_suffix = "expanded"

  enable_read_only_group_access = false

  common_tags = module.common_tags.common_tags
  pgsql_databases = [
    {
      name : "application"
    }
  ]
  pgsql_version = "16"
}

# only for use when building from ADO and as a quick example to get valid tags
# if you are building from Jenkins use `var.common_tags` provided by the pipeline
module "common_tags" {
  source = "github.com/hmcts/terraform-module-common-tags?ref=master"

  builtFrom   = "hmcts/terraform-module-postgresql-flexible"
  environment = var.env
  product     = "sds-platform"
}

locals {
  subnet_config = var.pgsql_delegated_subnet_id == "" ? {
    name                 = "expanded"
    resource_group_name  = azurerm_resource_group.test-rg.name
    virtual_network_name = azurerm_virtual_network.test_vnet.name
  } : null
}

data "azurerm_subnet" "pg_subnet" {
  count = local.subnet_config != null ? 1 : 0

  name                 = local.subnet_config.name
  resource_group_name  = local.subnet_config.resource_group_name
  virtual_network_name = local.subnet_config.virtual_network_name
}
