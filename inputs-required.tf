variable "resource_group_name" {
  description = "Enter Resource Group name."
  type        = string
  default     = null
}

variable "env" {
  description = "Environment value."
}

variable "pgsql_server_name" {
  description = "The pgsql flexible server instance name."
  type        = string
  default     = null
}

variable "pgsql_databases" {
  description = "Databases for the pgsql instance."
  type        = map(string)
  default     = null
}

variable "pgsql_admin_password" {
  description = "PGSql flexible server admin password."
  type        = string
  default     = null
}

variable "pgsql_delegated_subnet_id" {
  description = "PGSql delegated subnet id."
  type        = string
  default     = null
}

variable "pgsql_private_dns_zone_id" {
  description = "PGSql private dns zone id."
  type        = string
  default     = null
}
