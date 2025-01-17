﻿# Configure the Azure Provider
#provider "azurerm" {
# whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
#subscription_id = "92235c65-e9e9-4882-b8e1-e70a270aa923"
#client_id = "97545937–XXXX–XXXX-XXXX-XXXXXXXXXXXX"
#client_secret = ".3GGR_XXXXX~XXXX-XXXXXXXXXXXXXXXX"
#tenant_id = "da07dd9c-80c4-4a13-94e9-a003e4f2c794"
#version = "=2.0.0"
#features {}
#}


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group

resource "azurerm_resource_group" "example_rg" {
name = "${var.resource_prefix}-RG"
location = var.node_location
}


# Create a virtual network within the resource group

resource "azurerm_virtual_network" "example_vnet" {
name = "${var.resource_prefix}-vnet"
resource_group_name = azurerm_resource_group.example_rg.name
location = var.node_location
address_space = var.node_address_space
}


# Create a subnets within the virtual network

resource "azurerm_subnet" "example_subnet" {
name = "${var.resource_prefix}-subnet"
resource_group_name = azurerm_resource_group.example_rg.name
virtual_network_name = azurerm_virtual_network.example_vnet.name
address_prefixes = [var.node_address_prefix]
}

# Create Windows Public IP

resource "azurerm_public_ip" "example_public_ip" {
count = var.node_count
name = "${var.resource_prefix}-${format("%02d", count.index)}-PublicIP"
#name = "${var.resource_prefix}-PublicIP"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name
allocation_method = var.Environment == "Test" ? "Static" : "Dynamic"

tags = {
environment = "Test"
}
}

# Create Network Interface Card
resource "azurerm_network_interface" "example_nic" {
count = var.node_count
#name = "${var.resource_prefix}-NIC"
name = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name


ip_configuration {
name = "internal"
subnet_id = azurerm_subnet.example_subnet.id
private_ip_address_allocation = "Dynamic"
public_ip_address_id = element(azurerm_public_ip.example_public_ip.*.id, count.index)

#public_ip_address_id = azurerm_public_ip.example_public_ip.id
#public_ip_address_id = azurerm_public_ip.example_public_ip.id
}
}

# Creating resource NSG

resource "azurerm_network_security_group" "example_nsg" {

name = "${var.resource_prefix}-NSG"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name

# Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
security_rule {
name = "Inbound"
priority = 100
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "*"
source_address_prefix = "*"
destination_address_prefix = "*"

}
tags = {
environment = "Test"
}
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "example_subnet_nsg_association" {
subnet_id = azurerm_subnet.example_subnet.id
network_security_group_id = azurerm_network_security_group.example_nsg.id

}

# Virtual Machine Creation — Windows
resource "azurerm_windows_virtual_machine" "example_Win_vm" {
count = var.node_count
 name = "${var.resource_prefix}-${format("%02d", count.index)}"
 resource_group_name = azurerm_resource_group.example_rg.name
 location = azurerm_resource_group.example_rg.location
 size ="Standard_DS1_v2"

 #vm_size = "Standard_A1_v2"

admin_username      = var.admin_username
admin_password      = var.admin_password

 network_interface_ids = [element(azurerm_network_interface.example_nic.*.id, count.index)]

 source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"
    version   = "latest"
  }
  
#test comment
#os_profile {
#computer_name = "Windowshost"
#admin_username      = var.admin_username
#admin_password      = var.admin_password
#}

 # os_profile_windows_config {
  #  enable_automatic_upgrades = false
   # provision_vm_agent       = true
  #}


 # name                  = "example-machine"
 #name = "${var.resource_prefix}-VM"
 #resource_group_name   = azurerm_resource_group.example.name
 # location              = azurerm_resource_group.example.location
 # network_interface_ids = [azurerm_network_interface.example.id]
 #size                  = "Standard_F2"
 
 #delete_os_disk_on_termination = true
  
 # os_disk {
 #   caching              = "ReadWrite"
 #   storage_account_type = "Standard_LRS"
 # }

os_disk {
name = "myosdisk-${count.index}"
caching = "ReadWrite"
#create_option = "FromImage"
storage_account_type  = "Premium_LRS" 
# You can change this to ""Premium_LRS" if needed
disk_size_gb      = 128               
# Adjust the disk size as needed
}
  

  #source_image_reference {
   # publisher = "MicrosoftWindowsDesktop"
   # offer     = "windows-10"
   # sku       = "19h2-pro-g2"
   # version   = "latest"
 # }
 # enable_automatic_updates = true
 # provision_vm_agent       = true


tags = {
environment = "Test"
}
#  source_image_id = data.azurerm_shared_image.example.id
}

