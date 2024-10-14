terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 4.5.0"
      configuration_aliases = [azurerm.postgres_network]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.2.0"
    }
  }
}
