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

variables.tf
```terraform
variable "postgres_geo_redundant_backups" {
  default = false
}
```

prod.tfvars
```terraform
postgres_geo_redundant_backups = true
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

  geo_redundant_backups = var.postgres_geo_redundant_backups

  # Changing the value of the trigger_password_reset variable will trigger Terraform to rotate the password of the pgadmin user.
  trigger_password_reset = "any value here"
  
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


## Access to databases

VNet injection is used to restrict network access to PostgreSQL flexible servers. This means that you can't access the database directly from your local machine. Typically, you will need to set up an SSH tunnel to access the database you want to.

All developers can access non production databases with reader access.

Security cleared developers can access production DBs using just in time access and an approved business justification.

_Note: access is only granted on a case by case basis, and is removed automatically_

More process details to follow, it's currently being worked out.

### Non production:

#### First time setup

1. Join either  'DTS CFT Developers' or 'DTS SDS Developers'  AAD group via [GitHub pull request](https://github.com/hmcts/devops-azure-ad/blob/master/users/prod_users.yml)

<details>

<summary>Bastion configuration</summary>

Ensure you have Azure CLI version 2.22.1 or later installed

Run `az login`

Ensure ssh extension for the Azure CLI is installed: 'az extension add --name ssh'

Run `az ssh config --ip \*.platform.hmcts.net --file ~/.ssh/config`

</details>

#### Steps to access

1. Connect to the VPN
2. Request access to the non production bastion via [JIT](https://myaccess.microsoft.com/@HMCTS.NET#/access-packages/4894e58f-920e-404d-9db4-dc2ab8513794),
this will be automatically approved, and lasts for 24 hours.
3. Copy below script, update the variables (search for all references to draft-store and replace with your DB) and run it

```bash
# If you haven't logged in before you may need to login, uncomment the below line:
# az login
# this should give you a long JWT token, you will need this later on
az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv

ssh bastion-nonprod.platform.hmcts.net

export PGPASSWORD=<result-from-earlier>

# you can get this from the portal, or determine it via the inputs your pass to this module in your code
POSTGRES_HOST=rpe-draft-store-aat.postgres.database.azure.com

# this matches the `database_name` parameter you pass in the module
DB_NAME=draftstore

DB_USER="DTS\ CFT\ DB\ Access\ Reader" # read access
#DB_USER="DTS\ Platform\ Operations" # operations team administrative access

psql "sslmode=require host=${POSTGRES_HOST} dbname=${DB_NAME} user=${DB_USER}"
```

_Note: it's also possible to tunnel the connection to your own machine and use other tools to log in, IntelliJ database tools works, pgAdmin 4 works with a workaround for the password field length limit, when creating a new connection untick the "Connect now?" option and don't set the password, save the connection, afterwards when trying to connect a newly created db connection, the password pop up will accept the long password token generated._

<details>

<summary>Tunnel version of the script</summary>

```shell
# you can get this from the portal, or determine it via the inputs your pass to this module in your code
POSTGRES_HOST=rpe-draft-store-aat.postgres.database.azure.com

ssh -N bastion-nonprod.platform.hmcts.net -L 5440:${POSTGRES_HOST}:5432
# expect no more output in this terminal you won't get an interactive prompt

# in a separate terminal run:
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
# this matches the `database_name` parameter you pass in the module
DB_NAME=draftstore

DB_USER="DTS\ CFT\ DB\ Access\ Reader" # read access
#DB_USER="DTS\ Platform\ Operations" # operations team administrative access

psql "sslmode=require host=localhost port=5440 dbname=${DB_NAME} user=${DB_USER}"
```

</details>

### Production

#### First time setup

1. Join either 'DTS CFT Developers' or 'DTS SDS Developers' AAD group via [GitHub pull request](https://github.com/hmcts/devops-azure-ad/blob/master/users/prod_users.yml)
2. Request access to production via [JIT](https://myaccess.microsoft.com/@HMCTS.NET#/access-packages/738a7496-7ad4-4004-8b05-0e98677f4a9f), this requires SC clearance, or an approved exception.
   _Note: after this is approved it can take some time for the other packages to show up, try logging out and back in._

<details>

Ensure you have Azure CLI version 2.22.1 or later installed

Run `az login`

Ensure ssh extension for the Azure CLI is installed: 'az extension add --name ssh'

Run `az ssh config --ip \*.platform.hmcts.net --file ~/.ssh/config`

</details>

#### Steps to access

1. Request access to the database that you need via [JIT](https://myaccess.microsoft.com/@CJSCommonPlatform.onmicrosoft.com#/access-packages),
   the naming convention is `Database - <product> (read|write) access`.
2. Wait till it's approved, you can also message in #db-self-service on slack.
3. Connect to the VPN
4. Copy below script, update the variables (search for all references to draft-store and replace with your DB), and run it

```bash
# If you haven't logged in before you may need to login, uncomment the below line:
# az login
# this should give you a long JWT token, you will need this later on
az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv

# follow the prompts to login
ssh bastion-prod.platform.hmcts.net

export PGPASSWORD=<result-from-earlier>

# you can get this from the portal, or determine it via the inputs your pass to this module in your code
POSTGRES_HOST=rpe-draft-store-prod.postgres.database.azure.com

# this matches the `database_name` parameter you pass in the module
DB_NAME=draftstore

# make sure you update the product name in the middle to your product
DB_USER="DTS\ JIT\ Access\ draft-store\ DB\ Reader\ SC" # read access
#DB_USER="DTS\ Platform\ Operations\ SC" # operations team administrative access

psql "sslmode=require host=${POSTGRES_HOST} dbname=${DB_NAME} user=${DB_USER}"
# note: some users have experienced caching issues with their AAD token:
# psql: error: FATAL:  Azure AD access token not valid for role DTS JIT Access send-letter DB Reader SC (does not contain group ID c9e865ee-bc88-40d9-a5c1-23831f0ce255)
# the fix is to clear the cache and login again: rm -rf ~/.azure && az login
```

_Note: it's also possible to tunnel the connection to your own machine and use other tools to log in, IntelliJ database tools works, pgAdmin 4 works with a workaround for the password field length limit, when creating a new connection untick the "Connect now?" option and don't set the password, save the connection, afterwards when trying to connect a newly created db connection, the password pop up will accept the long password token generated._

<details>

<summary>Tunnel version of the script</summary>

```shell
# you can get this from the portal, or determine it via the inputs your pass to this module in your code
POSTGRES_HOST=rpe-draft-store-prod.postgres.database.azure.com

ssh bastion-prod.platform.hmcts.net -L 5440:${POSTGRES_HOST}:5432
# expect no more output in this terminal you won't get an interactive prompt

# in a separate terminal run:
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

# this matches the `database_name` parameter you pass in the module
DB_NAME=draftstore

# make sure you update the product name in the middle to your product
DB_USER="DTS\ JIT\ Access\ draft-store\ DB\ Reader\ SC" # read access
#DB_USER="DTS\ Platform\ Operations\ SC" # operations team administrative access

psql "sslmode=require host=localhost port=5440 dbname=${DB_NAME} user=${DB_USER}"
```

</details>

<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_azurerm.postgres_network"></a> [azurerm.postgres\_network](#provider\_azurerm.postgres\_network) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_log_analytics_workspace.pgsql_log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_action_group.db-alerts-action-group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_diagnostic_setting.pgsql_diag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.db_alert_cpu](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.db_alert_memory](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.db_alert_storage_utilization](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_postgresql_flexible_server.pgsql_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_adadmin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_active_directory_administrator) | resource |
| [azurerm_postgresql_flexible_server_active_directory_administrator.pgsql_principal_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_active_directory_administrator) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgsql_server_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.pg_databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.pg_firewall_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [null_resource.set-schema-ownership](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.set-user-permissions-additionaldbs](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.trigger_password_reset](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azuread_group.db_admin](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) | data source |
| [azuread_service_principal.mi_name](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault_secret.email_address](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_subnet.pg_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action_group_name"></a> [action\_group\_name](#input\_action\_group\_name) | The name of the Action Group to create. | `string` | `"db_alerts_action_group_name"` | no |
| <a name="input_admin_user_object_id"></a> [admin\_user\_object\_id](#input\_admin\_user\_object\_id) | The ID of the principal to be granted admin access to the database server, should be the principal running this normally. If you are using Jenkins pass through the variable 'jenkins\_AAD\_objectId'. | `any` | `null` | no |
| <a name="input_alert_frequency"></a> [alert\_frequency](#input\_alert\_frequency) | The frequency of the alert check. | `string` | `"PT5M"` | no |
| <a name="input_alert_severity"></a> [alert\_severity](#input\_alert\_severity) | The severity level of the alert (1=Critical, 2=Warning ...). | `number` | `1` | no |
| <a name="input_alert_window_size"></a> [alert\_window\_size](#input\_alert\_window\_size) | The period over which the metric is evaluated. | `string` | `"PT15M"` | no |
| <a name="input_auto_grow_enabled"></a> [auto\_grow\_enabled](#input\_auto\_grow\_enabled) | Specifies whether the storage auto grow for PostgreSQL Flexible Server is enabled? Defaults to false. | `bool` | `false` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Backup retention period in days for the PGSql instance. Valid values are between 7 & 35 days | `number` | `35` | no |
| <a name="input_business_area"></a> [business\_area](#input\_business\_area) | business\_area name - sds or cft. | `any` | n/a | yes |
| <a name="input_charset"></a> [charset](#input\_charset) | Specifies the Charset for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Charset. | `string` | `"utf8"` | no |
| <a name="input_collation"></a> [collation](#input\_collation) | Specifies the Collation for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Collation. | `string` | `"en_GB.utf8"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tag to be applied to resources. | `map(string)` | n/a | yes |
| <a name="input_component"></a> [component](#input\_component) | https://hmcts.github.io/glossary/#component | `string` | n/a | yes |
| <a name="input_cpu_threshold"></a> [cpu\_threshold](#input\_cpu\_threshold) | Average CPU utilisation threshold | `number` | `80` | no |
| <a name="input_create_mode"></a> [create\_mode](#input\_create\_mode) | The creation mode which can be used to restore or replicate existing servers | `string` | `"Default"` | no |
| <a name="input_email_address_key"></a> [email\_address\_key](#input\_email\_address\_key) | Email address key in azure Key Vault. | `string` | `""` | no |
| <a name="input_email_address_key_vault_id"></a> [email\_address\_key\_vault\_id](#input\_email\_address\_key\_vault\_id) | Email address Key Vault Id. | `string` | `""` | no |
| <a name="input_email_receivers"></a> [email\_receivers](#input\_email\_receivers) | A map of email receivers, with keys as names and values as email addresses. | `map(string)` | `{}` | no |
| <a name="input_enable_qpi"></a> [enable\_qpi](#input\_enable\_qpi) | Enables Query Performance Insight. Creates Log Analytics workspace and diagnostic setting needed | `bool` | `false` | no |
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
| <a name="input_memory_threshold"></a> [memory\_threshold](#input\_memory\_threshold) | Average memory utilisation threshold | `number` | `80` | no |
| <a name="input_name"></a> [name](#input\_name) | The default name will be product+component+env, you can override the product+component part by setting this | `string` | `""` | no |
| <a name="input_pass_secret_name"></a> [pass\_secret\_name](#input\_pass\_secret\_name) | Update this with the name of the secret that stores the single server password. Defaults to product-componenet-POSTGRES-PASS. | `string` | `""` | no |
| <a name="input_pgsql_admin_username"></a> [pgsql\_admin\_username](#input\_pgsql\_admin\_username) | Admin username | `string` | `"pgadmin"` | no |
| <a name="input_pgsql_databases"></a> [pgsql\_databases](#input\_pgsql\_databases) | Databases for the pgsql instance. | `list(object({ name : string, collation : optional(string), charset : optional(string) }))` | n/a | yes |
| <a name="input_pgsql_delegated_subnet_id"></a> [pgsql\_delegated\_subnet\_id](#input\_pgsql\_delegated\_subnet\_id) | PGSql delegated subnet id. | `string` | `""` | no |
| <a name="input_pgsql_firewall_rules"></a> [pgsql\_firewall\_rules](#input\_pgsql\_firewall\_rules) | Postgres firewall rules | `list(object({ name : string, start_ip_address : string, end_ip_address : string }))` | `[]` | no |
| <a name="input_pgsql_server_configuration"></a> [pgsql\_server\_configuration](#input\_pgsql\_server\_configuration) | Postgres server configuration | `list(object({ name : string, value : string }))` | <pre>[<br/>  {<br/>    "name": "backslash_quote",<br/>    "value": "on"<br/>  }<br/>]</pre> | no |
| <a name="input_pgsql_sku"></a> [pgsql\_sku](#input\_pgsql\_sku) | The PGSql flexible server instance sku | `string` | `"GP_Standard_D2s_v3"` | no |
| <a name="input_pgsql_storage_mb"></a> [pgsql\_storage\_mb](#input\_pgsql\_storage\_mb) | Max storage allowed for the PGSql Flexibile instance | `number` | `65536` | no |
| <a name="input_pgsql_storage_tier"></a> [pgsql\_storage\_tier](#input\_pgsql\_storage\_tier) | The storage tier, this should be left as null but may need to be overriden to allow increased storage. | `string` | `null` | no |
| <a name="input_pgsql_version"></a> [pgsql\_version](#input\_pgsql\_version) | The PGSql flexible server instance version. | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | https://hmcts.github.io/glossary/#product | `string` | n/a | yes |
| <a name="input_public_access"></a> [public\_access](#input\_public\_access) | Specifies whether or not public access is allowed for this PostgreSQL Flexible Server. Defaults to false. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of existing resource group to deploy resources into | `string` | `null` | no |
| <a name="input_restore_time"></a> [restore\_time](#input\_restore\_time) | The point in time to restore. Only used when create mode is set to PointInTimeRestore | `any` | `null` | no |
| <a name="input_sms_receivers"></a> [sms\_receivers](#input\_sms\_receivers) | A map of SMS receivers, with keys as names and values as maps containing country code and phone number. | <pre>map(object({<br/>    country_code = string<br/>    phone_number = string<br/>  }))</pre> | `{}` | no |
| <a name="input_source_server_id"></a> [source\_server\_id](#input\_source\_server\_id) | Source server ID for point in time restore. Only used when create mode is set to PointInTimeRestore | `any` | `null` | no |
| <a name="input_storage_threshold"></a> [storage\_threshold](#input\_storage\_threshold) | Average storage utilisation threshold | `number` | `80` | no |
| <a name="input_subnet_suffix"></a> [subnet\_suffix](#input\_subnet\_suffix) | Suffix to append to the subnet name, the originally created one used by this module is full in a number of environments. | `string` | `null` | no |
| <a name="input_trigger_password_reset"></a> [trigger\_password\_reset](#input\_trigger\_password\_reset) | Setting this to a different value, e.g. '1' will trigger terraform to rotate the password. | `string` | `""` | no |
| <a name="input_user_secret_name"></a> [user\_secret\_name](#input\_user\_secret\_name) | Update this with the name of the secret that stores the single server username. Defaults to product-componenet-POSTGRES-USER. | `string` | `""` | no |
| <a name="input_webhook_receivers"></a> [webhook\_receivers](#input\_webhook\_receivers) | A map of webhook receivers, with keys as names and values as URLs. | `map(string)` | `{}` | no |

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
