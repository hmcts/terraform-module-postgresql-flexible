terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.2.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.17.1"
    }
  }
}
provider "postgresql" {
  host            = "${local.server_name}.postgres.database.azure.com"
  port            = "5432"
  database        = azurerm_postgresql_flexible_server_database.pg_databases[0].name
  username        = local.db_reader_user
  password        = random_password.password.result
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}