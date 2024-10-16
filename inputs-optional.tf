variable "resource_group_name" {
  description = "Name of existing resource group to deploy resources into"
  type        = string
  default     = null
}

variable "location" {
  description = "Target Azure location to deploy the resource"
  type        = string
  default     = "UK South"
}

variable "pgsql_admin_username" {
  description = "Admin username"
  type        = string
  default     = "pgadmin"
}

variable "pgsql_sku" {
  description = "The PGSql flexible server instance sku"
  type        = string
  default     = "GP_Standard_D2s_v3"

  validation {
    condition = can(regex(".*(_v3|_v4|^B_.*$).*", var.pgsql_sku))
    # because v5 doesn't currently support reservations, if they are supported in the future this restriction should be removed
    # see https://azure.microsoft.com/en-gb/pricing/details/postgresql/flexible-server/
    # search Ddsv5 and Edsv5
    error_message = "The pgsql_sku value must use either a v3, v4 or Burstable SKU."
  }
}

variable "pgsql_storage_mb" {
  description = "Max storage allowed for the PGSql Flexibile instance"
  type        = number
  default     = 65536
}

variable "pgsql_storage_tier" {
  description = "The storage tier, this should be left as null but may need to be overriden to allow increased storage."
  type        = string
  default     = null
}

variable "pgsql_server_configuration" {
  description = "Postgres server configuration"
  type        = list(object({ name : string, value : string }))
  default = [{
    name  = "backslash_quote"
    value = "on"
  }]
}

variable "pgsql_firewall_rules" {
  description = "Postgres firewall rules"
  type        = list(object({ name : string, start_ip_address : string, end_ip_address : string }))
  default     = []
}

variable "name" {
  default     = ""
  description = "The default name will be product+component+env, you can override the product+component part by setting this"
}

variable "backup_retention_days" {
  default     = 35
  description = "Backup retention period in days for the PGSql instance. Valid values are between 7 & 35 days"
}

variable "geo_redundant_backups" {
  default     = false
  description = "Enable geo-redundant backups for the PGSql instance."
}

variable "create_mode" {
  default     = "Default"
  description = "The creation mode which can be used to restore or replicate existing servers"
}

variable "restore_time" {
  default     = null
  description = "The point in time to restore. Only used when create mode is set to PointInTimeRestore"
}

variable "source_server_id" {
  default     = null
  description = "Source server ID for point in time restore. Only used when create mode is set to PointInTimeRestore"
}

variable "admin_user_object_id" {
  default     = null
  description = "The ID of the principal to be granted admin access to the database server, should be the principal running this normally. If you are using Jenkins pass through the variable 'jenkins_AAD_objectId'."
}

variable "enable_read_only_group_access" {
  type        = bool
  default     = true
  description = "Enables read only group support for accessing the database"
}

variable "collation" {
  type        = string
  default     = "en_GB.utf8"
  description = "Specifies the Collation for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Collation."
}

variable "charset" {
  type        = string
  default     = "utf8"
  description = "Specifies the Charset for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Charset."
}

variable "high_availability" {
  type        = bool
  default     = null
  description = "Overrides the automatic selection of high availability mode for the PostgreSQL Flexible Server. Generally you shouldn't set this yourself."
}

variable "public_access" {
  type        = bool
  default     = false
  description = "Specifies whether or not public access is allowed for this PostgreSQL Flexible Server. Defaults to false."
}

variable "force_user_permissions_trigger" {
  default     = ""
  type        = string
  description = "Update this to a new value to force the user permissions script to run again"
}

variable "enable_schema_ownership" {
  type        = bool
  default     = false
  description = "Enables the schema ownership script. Change this to true if you want to use the script. Defaults to false"
}

variable "force_schema_ownership_trigger" {
  default     = ""
  type        = string
  description = "Update this to a new value to force the schema ownership script to run again."
}

variable "kv_subscription" {
  default     = "DCD-CNP-DEV"
  type        = string
  description = "Update this with the name of the subscription where the single server key vault is. Defaults to DCD-CNP-DEV."
}

variable "kv_name" {
  default     = ""
  type        = string
  description = "Update this with the name of the key vault that stores the single server secrets. Defaults to product-env."
}

variable "user_secret_name" {
  default     = ""
  type        = string
  description = "Update this with the name of the secret that stores the single server username. Defaults to product-componenet-POSTGRES-USER."
}

variable "pass_secret_name" {
  default     = ""
  type        = string
  description = "Update this with the name of the secret that stores the single server password. Defaults to product-componenet-POSTGRES-PASS."
}

variable "subnet_suffix" {
  default     = null
  type        = string
  description = "Suffix to append to the subnet name, the originally created one used by this module is full in a number of environments."
}

variable "auto_grow_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether the storage auto grow for PostgreSQL Flexible Server is enabled? Defaults to false."
}

variable "trigger_password_reset" {
  type        = string
  default     = ""
  description = "Setting this to a different value, e.g. '1' will trigger terraform to rotate the password."
}

variable "enable_qpi" {
  type        = bool
  default     = false
  description = "Enables Query Performance Insight. Creates Log Analytics workspace and diagnostic setting needed"
}