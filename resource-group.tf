resource "azurerm_resource_group" "automation_resource_group" {
  location = var.location
  name     = var.resource_group_name

  tags = var.common_tags
}
