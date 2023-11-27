# Configure the Azure Provider

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

# Create Windows Public IP

resource "azurerm_public_ip" "example_public_ip" {
count = var.node_count
name = "${var.resource_prefix}-${format("%02d", count.index+2)}-PublicIP"
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
name = "${var.resource_prefix}-${format("%02d", count.index+2)}-NIC"
location = azurerm_resource_group.example_rg.location
resource_group_name = azurerm_resource_group.example_rg.name


ip_configuration {
name = "internal"
subnet_id = azurerm_subnet.example_subnet.id
private_ip_address_allocation = "Dynamic"
public_ip_address_id = element(azurerm_public_ip.example_public_ip.*.id, count.index+2)

#public_ip_address_id = azurerm_public_ip.example_public_ip.id
#public_ip_address_id = azurerm_public_ip.example_public_ip.id
}


# Virtual Machine Creation — Windows
resource "azurerm_windows_virtual_machine" "example_Win_vm" {
count = var.node_count
 name = "${var.resource_prefix}-${format("%02d", count.index+2)}"
 resource_group_name = azurerm_resource_group.example_rg.name
 location = azurerm_resource_group.example_rg.location
 size ="Standard_DS1_v2"

 #vm_size = "Standard_A1_v2"

admin_username      = var.admin_username
admin_password      = var.admin_password

 network_interface_ids = [element(azurerm_network_interface.example_nic.*.id, count.index+2)]

 source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"
    version   = "latest"
  }
  
os_disk {
name = "myosdisk-${count.index+2}"
caching = "ReadWrite"

storage_account_type  = "Premium_LRS" 

disk_size_gb      = 128               
# Adjust the disk size as needed
}
}