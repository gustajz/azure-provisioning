resource "azurerm_virtual_network" "vn" {
  name                = "${var.commonname}-vn"
  address_space       = ["${var.vnet_cidr}"]
  location            = "${azurerm_resource_group.mygroup.location}"
  resource_group_name = "${azurerm_resource_group.mygroup.name}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.commonname}-nsg"
  location            = "${azurerm_resource_group.mygroup.location}"
  resource_group_name = "${azurerm_resource_group.mygroup.name}"

  security_rule {
    name                       = "ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 2100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.commonname}-subnet"
  resource_group_name  = "${azurerm_resource_group.mygroup.name}"
  virtual_network_name = "${azurerm_virtual_network.vn.name}"
  address_prefix       = "${var.subnet1_cidr}"

  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}