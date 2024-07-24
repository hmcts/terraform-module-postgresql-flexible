# terraform-module-postgresql-flexible
Terraform module for [Azure Database for PostgreSQL - Flexible Server](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)

## Example

provider.tf
```terraform
provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "postgres_network"
  subscription_id            = var.aks_subscription_id
}
```

postgres.tf
```terraform
module "postgresql" {

  providers = {
    azurerm.postgres_network = azurerm.postgres_network
  }
  
  source = "git@github.com:hmcts/terraform-module-postgresql-flexible?ref=master"
  env    = var.env

  product       = var.product
  component     = var.component
  business_area = "sds" # sds or cft

  # The original subnet is full, this is required to use the new subnet for new databases
  subnet_suffix = "expanded"

  pgsql_databases = [
    {
      name : "application"
    }
  ]

  pgsql_sku     = "GP_Standard_D2ds_v4"
  pgsql_version = "16"
  
  # The ID of the principal to be granted admin access to the database server.
  # On Jenkins it will be injected for you automatically as jenkins_AAD_objectId.
  # Otherwise change the below:
  admin_user_object_id = var.jenkins_AAD_objectId
  
  common_tags = var.common_tags
}
```

variables.tf
```hcl
variable "aks_subscription_id" {} # provided by the Jenkins library, ADO users will need to specify this
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.106.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.106.0 |
| <a name="provider_azurerm.postgres_network"></a> [azurerm.postgres\_network](#provider\_azurerm.postgres\_network) | 3.106.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.2.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.pgsql_server](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_adadmin](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server_active_directory_administrator) | resource |
| [azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server_active_directory_administrator) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgsql_server_config](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.pg_databases](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.pg_firewall_rules](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/resources/resource_group) | resource |
| [null_resource.set-schema-ownership](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.set-user-permissions-additionaldbs](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.trigger_password_reset](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azuread_group.db_admin](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.mi_name](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/data-sources/client_config) | data source |
| [azurerm_subnet.pg_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/data-sources/subnet) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/3.106.0/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_user_object_id"></a> [admin\_user\_object\_id](#input\_admin\_user\_object\_id) | The ID of the principal to be granted admin access to the database server, should be the principal running this normally. If you are using Jenkins pass through the variable 'jenkins\_AAD\_objectId'. | `any` | `null` | no |
| <a name="input_auto_grow_enabled"></a> [auto\_grow\_enabled](#input\_auto\_grow\_enabled) | Specifies whether the storage auto grow for PostgreSQL Flexible Server is enabled? Defaults to false. | `bool` | `false` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Backup retention period in days for the PGSql instance. Valid values are between 7 & 35 days | `number` | `35` | no |
| <a name="input_business_area"></a> [business\_area](#input\_business\_area) | business\_area name - sds or cft. | `any` | n/a | yes |
| <a name="input_charset"></a> [charset](#input\_charset) | Specifies the Charset for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Charset. | `string` | `"utf8"` | no |
| <a name="input_collation"></a> [collation](#input\_collation) | Specifies the Collation for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Collation. | `string` | `"en_GB.utf8"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tag to be applied to resources. | `map(string)` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | https://hmcts.github.io/glossary/#component | `string` | n/a | yes |
| <a name="input_create_mode"></a> [create\_mode](#input\_create\_mode) | The creation mode which can be used to restore or replicate existing servers | `string` | `"Default"` | no |
| <a name="input_enable_read_only_group_access"></a> [enable\_read\_only\_group\_access](#input\_enable\_read\_only\_group\_access) | Enables read only group support for accessing the database | `bool` | `true` | no |
| <a name="input_enable_schema_ownership"></a> [enable\_schema\_ownership](#input\_enable\_schema\_ownership) | Enables the schema ownership script. Change this to true if you want to use the script. Defaults to false | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment value. | `string` | n/a | yes |
| <a name="input_force_schema_ownership_trigger"></a> [force\_schema\_ownership\_trigger](#input\_force\_schema\_ownership\_trigger) | Update this to a new value to force the schema ownership script to run again. | `string` | `""` | no |
| <a name="input_force_user_permissions_trigger"></a> [force\_user\_permissions\_trigger](#input\_force\_user\_permissions\_trigger) | Update this to a new value to force the user permissions script to run again | `string` | `""` | no |
| <a name="input_geo_redundant_backups"></a> [geo\_redundant\_backups](#input\_geo\_redundant\_backups) | Enable geo-redundant backups for the PGSql instance. | `bool` | `false` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | Overrides the automatic selection of high availability mode for the PostgreSQL Flexible Server. Generally you shouldn't set this yourself. | `bool` | `null` | no |
| <a name="input_kv_name"></a> [kv\_name](#input\_kv\_name) | Update this with the name of the key vault that stores the single server secrets. Defaults to product-env. | `string` | `""` | no |
| <a name="input_kv_subscription"></a> [kv\_subscription](#input\_kv\_subscription) | Update this with the name of the subscription where the single server key vault is. Defaults to DCD-CNP-DEV. | `string` | `"DCD-CNP-DEV"` | no |
| <a name="input_location"></a> [location](#input\_location) | Target Azure location to deploy the resource | `string` | `"UK South"` | no |
| <a name="input_name"></a> [name](#input\_name) | The default name will be product+component+env, you can override the product+component part by setting this | `string` | `""` | no |
| <a name="input_pass_secret_name"></a> [pass\_secret\_name](#input\_pass\_secret\_name) | Update this with the name of the secret that stores the single server password. Defaults to product-componenet-POSTGRES-PASS. | `string` | `""` | no |
| <a name="input_pgsql_admin_username"></a> [pgsql\_admin\_username](#input\_pgsql\_admin\_username) | Admin username | `string` | `"pgadmin"` | no |
| <a name="input_pgsql_databases"></a> [pgsql\_databases](#input\_pgsql\_databases) | Databases for the pgsql instance. | `list(object({ name : string, collation : optional(string), charset : optional(string) }))` | n/a | yes |
| <a name="input_pgsql_delegated_subnet_id"></a> [pgsql\_delegated\_subnet\_id](#input\_pgsql\_delegated\_subnet\_id) | PGSql delegated subnet id. | `string` | `""` | no |
| <a name="input_pgsql_firewall_rules"></a> [pgsql\_firewall\_rules](#input\_pgsql\_firewall\_rules) | Postgres firewall rules | `list(object({ name : string, start_ip_address : string, end_ip_address : string }))` | `[]` | no |
| <a name="input_pgsql_server_configuration"></a> [pgsql\_server\_configuration](#input\_pgsql\_server\_configuration) | Postgres server configuration | `list(object({ name : string, value : string }))` | <pre>[<br>  {<br>    "name": "backslash_quote",<br>    "value": "on"<br>  }<br>]</pre> | no |
| <a name="input_pgsql_sku"></a> [pgsql\_sku](#input\_pgsql\_sku) | The PGSql flexible server instance sku | `string` | `"GP_Standard_D2s_v3"` | no |
| <a name="input_pgsql_storage_mb"></a> [pgsql\_storage\_mb](#input\_pgsql\_storage\_mb) | Max storage allowed for the PGSql Flexibile instance | `number` | `65536` | no |
| <a name="input_pgsql_storage_tier"></a> [pgsql\_storage\_tier](#input\_pgsql\_storage\_tier) | The storage tier, this should be left as null but may need to be overriden to allow increased storage. | `string` | `null` | no |
| <a name="input_pgsql_version"></a> [pgsql\_version](#input\_pgsql\_version) | The PGSql flexible server instance version. | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | https://hmcts.github.io/glossary/#product | `string` | n/a | yes |
| <a name="input_public_access"></a> [public\_access](#input\_public\_access) | Specifies whether or not public access is allowed for this PostgreSQL Flexible Server. Defaults to false. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of existing resource group to deploy resources into | `string` | `null` | no |
| <a name="input_restore_time"></a> [restore\_time](#input\_restore\_time) | The point in time to restore. Only used when create mode is set to PointInTimeRestore | `any` | `null` | no |
| <a name="input_source_server_id"></a> [source\_server\_id](#input\_source\_server\_id) | Source server ID for point in time restore. Only used when create mode is set to PointInTimeRestore | `any` | `null` | no |
| <a name="input_subnet_suffix"></a> [subnet\_suffix](#input\_subnet\_suffix) | Suffix to append to the subnet name, the originally created one used by this module is full in a number of environments. | `string` | `null` | no |
| <a name="input_trigger_password_reset"></a> [trigger\_password\_reset](#input\_trigger\_password\_reset) | Setting this to a different value will trigge the module to rotate the password. | `string` | `""` | no |
| <a name="input_user_secret_name"></a> [user\_secret\_name](#input\_user\_secret\_name) | Update this with the name of the secret that stores the single server username. Defaults to product-componenet-POSTGRES-USER. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | n/a |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_username"></a> [username](#output\_username) | n/a |
<!-- END_TF_DOCS -->

## Contributing

We use pre-commit hooks for validating the terraform format and maintaining the documentation automatically.
Install it with:

```shell
$ brew install pre-commit terraform-docs
$ pre-commit install
```

If you add a new hook make sure to run it against all files:
```shell
$ pre-commit run --all-files
```
