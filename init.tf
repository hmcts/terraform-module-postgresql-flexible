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
  }
}

provider "azurerm" {
  alias                      = "subscription"
  skip_provider_registration = "true"
  features {}
  subscription_id = var.business_area == "sds" ? local.sds_subscriptions[var.env].subscription : local.cft_subscriptions[var.env].subscription
}