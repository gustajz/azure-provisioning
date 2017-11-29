resource "azurerm_public_ip" "gitlab" {
  name                         = "gitlab-pip"
  location                     = "${azurerm_resource_group.mygroup.location}"
  resource_group_name          = "${azurerm_resource_group.mygroup.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 5
  domain_name_label            = "${var.commonname}"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_network_interface" "gitlab" {
  name                = "${var.commonname}-ni"
  location            = "${azurerm_resource_group.mygroup.location}"
  resource_group_name = "${azurerm_resource_group.mygroup.name}"

  ip_configuration {
    name                          = "gitlab-config"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.gitlab.id}"
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = "${azurerm_resource_group.mygroup.name}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "diagsa" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.mygroup.name}"
  location                 = "${azurerm_resource_group.mygroup.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_virtual_machine" "gitlab" {
  name                  = "gitlab-vm"
  location              = "${azurerm_resource_group.mygroup.location}"
  resource_group_name   = "${azurerm_resource_group.mygroup.name}"
  network_interface_ids = ["${azurerm_network_interface.gitlab.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  plan {
    name      = "8-5"
    publisher = "bitnami"
    product   = "gitlab"
  }

  storage_image_reference {
    publisher = "bitnami"
    offer     = "gitlab"
    sku       = "8-5"
    version   = "latest"
  }

  storage_os_disk {
    name              = "gitlab-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "fndmnts-ngnhr"
    admin_username = "azureuser"
    admin_password = "2017@Password"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.diagsa.primary_blob_endpoint}"
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_virtual_machine_extension" "gitlab" {
  name                 = "gitlab-vme"
  location             = "${azurerm_resource_group.mygroup.location}"
  resource_group_name  = "${azurerm_resource_group.mygroup.name}"
  virtual_machine_name = "${azurerm_virtual_machine.gitlab.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://gist.githubusercontent.com/gustajz/c5a29692cd588cd016c8fc9c8a2ea46a/raw/378e6fb7b5fafd1513a61a9696d94e46a2ec1552/disable_https.sh"],
        "commandToExecute": "sh disable_https.sh"
    }
SETTINGS

  tags {
    environment = "${var.environment}"
  }
}

resource "null_resource" "gitlab-bd" {
  provisioner "local-exec" {
    command = "az vm boot-diagnostics get-boot-log --resource-group ${azurerm_resource_group.mygroup.name} --name ${azurerm_virtual_machine.gitlab.name}"
  }

  depends_on = ["azurerm_virtual_machine_extension.gitlab"]
}


resource "azurerm_network_interface" "gitlab-ci" {
  name                = "gitlab-ci-ni"
  location            = "${azurerm_resource_group.mygroup.location}"
  resource_group_name = "${azurerm_resource_group.mygroup.name}"

  ip_configuration {
    name                          = "gitlab-ci-config"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_virtual_machine" "gitlab-ci" {
  name                  = "gitlab-ci-vm"
  location              = "${azurerm_resource_group.mygroup.location}"
  resource_group_name   = "${azurerm_resource_group.mygroup.name}"
  network_interface_ids = ["${azurerm_network_interface.gitlab-ci.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.4"
    version   = "latest"
  }

  storage_os_disk {
    name              = "gitlab-ci-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "gitlab-ci"
    admin_username = "azureuser"
    admin_password = "2017@Password"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.diagsa.primary_blob_endpoint}"
  }

  tags {
    environment = "${var.environment}"
  }

}

resource "azurerm_virtual_machine_extension" "gitlab-ci" {
  name                 = "gitlab-ci-vme"
  location             = "${azurerm_resource_group.mygroup.location}"
  resource_group_name  = "${azurerm_resource_group.mygroup.name}"
  virtual_machine_name = "${azurerm_virtual_machine.gitlab-ci.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://gist.githubusercontent.com/gustajz/5f521c1d1c289f0c55375cade2e176dd/raw/e1bd89edda181b12977882cbd07a409583d053e0/gitlab-ci-runner-install.sh"],
        "commandToExecute": "sh gitlab-ci-runner-install.sh"
    }
SETTINGS

  tags {
    environment = "${var.environment}"
  }
}

resource "null_resource" "k8s-create" {
  provisioner "local-exec" {
    command = "az aks create --resource-group ${azurerm_resource_group.mygroup.name} --name k8s-dev --location ${azurerm_resource_group.mygroup.location} --kubernetes-version 1.8.2 --node-vm-size Standard_A0 --node-count 2"
  }

  depends_on = ["azurerm_resource_group.mygroup"]
}

resource "null_resource" "k8s-credentials" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.mygroup.name} --name k8s-dev --admin --file - > k8s-dev.conf"
  }

  depends_on = ["null_resource.k8s-create"]
}
                    