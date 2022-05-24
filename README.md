# terraform-module-postgresql-flexible
Terraform module for Azure PostgreSQL Flexible Server


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 2.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 2.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.pgsql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgsql_server_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.pg_databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.pg_firewall_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_resource_group.automation_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tag to be applied to resources. | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Target Azure location to deploy the resource. | `string` | `"UK South"` | no |
| <a name="input_pgsql_admin_password"></a> [pgsql\_admin\_password](#input\_pgsql\_admin\_password) | PGSql flexible server admin password. | `string` | `null` | no |
| <a name="input_pgsql_admin_username"></a> [pgsql\_admin\_username](#input\_pgsql\_admin\_username) | PGSql flexible server admin username. | `string` | `"pgadmin"` | no |
| <a name="input_pgsql_databases"></a> [pgsql\_databases](#input\_pgsql\_databases) | Databases for the pgsql instance. | `map(string)` | `null` | no |
| <a name="input_pgsql_delegated_subnet_id"></a> [pgsql\_delegated\_subnet\_id](#input\_pgsql\_delegated\_subnet\_id) | PGSql delegated subnet id. | `string` | `null` | no |
| <a name="input_pgsql_firewall_rules"></a> [pgsql\_firewall\_rules](#input\_pgsql\_firewall\_rules) | PGSql firewall rules. | `map(string)` | `{}` | no |
| <a name="input_pgsql_private_dns_zone_id"></a> [pgsql\_private\_dns\_zone\_id](#input\_pgsql\_private\_dns\_zone\_id) | PGSql private dns zone id. | `string` | `null` | no |
| <a name="input_pgsql_server_configuration"></a> [pgsql\_server\_configuration](#input\_pgsql\_server\_configuration) | The PGSql configuration. | `map(string)` | <pre>{<br>  "name": "backslash_quote",<br>  "value": "on"<br>}</pre> | no |
| <a name="input_pgsql_server_name"></a> [pgsql\_server\_name](#input\_pgsql\_server\_name) | The pgsql flexible server instance name. | `string` | `null` | no |
| <a name="input_pgsql_server_zone"></a> [pgsql\_server\_zone](#input\_pgsql\_server\_zone) | Specifies the Availability Zone in which the PGSql Flexible Server should be located. | `string` | `"1"` | no |
| <a name="input_pgsql_sku"></a> [pgsql\_sku](#input\_pgsql\_sku) | The PGSql flexible server instance sku. | `string` | `"Standard_D2s_v3"` | no |
| <a name="input_pgsql_storage_mb"></a> [pgsql\_storage\_mb](#input\_pgsql\_storage\_mb) | Max storage allowed for the PGSql Flexibile instance. | `number` | `65536` | no |
| <a name="input_pgsql_version"></a> [pgsql\_version](#input\_pgsql\_version) | The PGSql flexible server instance version. | `string` | `"12"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Enter Resource Group name. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->