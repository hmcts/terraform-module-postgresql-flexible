variable "location" {
  description = "Target Azure location to deploy the resource."
  type        = string
  default     = "UK South"
}

variable "common_tags" {
  description = "Common tag to be applied to resources."
  type        = map(string)
  default     = {}
}

variable "pgsql_admin_username" {
  description = "PGSql flexible server admin username."
  type        = string
  default     = "pgadmin"
}

variable "pgsql_version" {
  description = "The pgsql flexible server instance version."
  type        = string
  default     = "12"
}

variable "pgsql_sku" {
  description = "The pgsql flexible server instance sku."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "pgsql_storage_mb" {
  description = "Max storage allowed for the PGSql Flexibile instance."
  type        = number
  default     = 65536
}

variable "pgsql_server_zone" {
  description = "Specifies the Availability Zone in which the PostgreSQL Flexible Server should be located."
  type        = number
  default     = "1"
}
