provider "azurerm" {
  features {}
  version = "2.6.0"
}

resource "azurerm_resource_group" "rgrp" {
  name     = "hpe-test2"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "hpe-network"
  address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name
}

resource "azurerm_subnet" "snet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rgrp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "nic" {
  name                = "hpe-nic"
  location            = azurerm_resource_group.rgrp.location
  resource_group_name = azurerm_resource_group.rgrp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "container-machine1"
  resource_group_name = azurerm_resource_group.rgrp.name
  location            = azurerm_resource_group.rgrp.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }

}

resource "azurerm_managed_disk" "example" {
  name                 = "cont1"
  location             = azurerm_resource_group.rgrp.location
  resource_group_name  = azurerm_resource_group.rgrp.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "staging"
  }
}

#resource "azurerm_managed_disk" "copy" {
#  name                 = "cont2"
#  location             = azurerm_resource_group.rgrp.location
#  resource_group_name  = azurerm_resource_group.rgrp.name
#  storage_account_type = "Standard_LRS"
#  create_option        = "Copy"
#  source_resource_id   = azurerm_managed_disk.example.id
#  disk_size_gb         = "1"
#
#  tags = {
#    environment = "staging"
#  }
#}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.example.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "10"
  caching            = "ReadWrite"
}








