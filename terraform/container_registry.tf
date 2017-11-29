resource "azurerm_storage_account" "acr" {
  name                     = "acrsa${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.mygroup.name}"
  location                 = "${azurerm_resource_group.mygroup.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_container_registry" "test" {
  name                = "${var.commonname}"
  resource_group_name = "${azurerm_resource_group.mygroup.name}"
  location            = "${azurerm_resource_group.mygroup.location}"
  admin_enabled       = true
  sku                 = "Basic"
}