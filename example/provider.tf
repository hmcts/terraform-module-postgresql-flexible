provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "postgres_network"
  subscription_id            = var.aks_subscription_id
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "backup"
  subscription_id            = var.backup_subscription_id
}
