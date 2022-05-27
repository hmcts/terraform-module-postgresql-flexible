module "postgresql" {
  source = "../"
  env    = var.env

  product   = "platops"
  component = "example"
  project   = "sds"

  common_tags = module.common_tags.common_tags
  pgsql_databases = [
    {
      name : "application"
    }
  ]
  pgsql_delegated_subnet_id = data.azurerm_subnet.this.id
  pgsql_version             = "12"
}

# only for use when building from ADO and as a quick example to get valid tags
# if you are building from Jenkins use `var.common_tags` provided by the pipeline
module "common_tags" {
  source = "github.com/hmcts/terraform-module-common-tags"

  builtFrom   = "hmcts/terraform-module-postgresql-flexible"
  environment = var.env
  product     = "sds-platform"
}
