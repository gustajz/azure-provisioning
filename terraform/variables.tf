variable "environment" {
  default = "Dev"
}

variable "commonname" {
  default = "fndmnts"
}

variable "vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "location" {
  default = "East US"
}

variable "subnet1_cidr" {
  default = "10.0.2.0/24"
}

variable "vm_username" {
  default = "azureuser"
}

variable "vm_password" {
  default = "Password!1234"
}

resource "azurerm_resource_group" "mygroup" {
  name     = "rg-${var.commonname}"
  location = "${var.location}"

  tags {
    environment = "${var.environment}"
  }
}
