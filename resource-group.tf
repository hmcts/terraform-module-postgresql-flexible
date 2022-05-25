resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-data-${var.env}"
  location = var.location

  tags = var.common_tags
}
