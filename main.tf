provider "azurerm" {
 features{} 
}

locals {
  common_tags = {
  Department = "RnD"
  }
}

resource "azurerm_resource_group" "dev_ops_project" {
  name = "${var.prefix}-resources"
      location =  var.location
}

resource "azurerm_virtual_network" "dev_ops_project" {
  name = "${var.prefix}-network"
  address_space = [ "10.0.0.0/16" ]
  location = azurerm_resource_group.dev_ops_project.location
  resource_group_name = azurerm_resource_group.dev_ops_project.name
}

resource "azurerm_subnet" "dev_ops_project" {
  name = "${var.prefix}-primary"
  resource_group_name = azurerm_resource_group.dev_ops_project.name
  virtual_network_name = azurerm_virtual_network.dev_ops_project.name
  address_prefixes = [ "10.0.2.0/24" ]
}

resource "azurerm_network_interface" "dev_ops_project" {
  count = var.instance_count
  name = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.dev_ops_project.name
  location = azurerm_resource_group.dev_ops_project.location
  ip_configuration {
    name = "${var.prefix}-primary"
    subnet_id = azurerm_subnet.dev_ops_project.id
    private_ip_address_allocation = "Dynamic"

  }  
}

# Packer Image Reference
data "azurerm_image" "packer-image" {
  name                = "myPackerProjectImage"
  resource_group_name = "UdacityDevOpsResourceGroup"
}


resource "azurerm_linux_virtual_machine" "dev_ops_project" {
  count = var.instance_count
  name = "${var.prefix}-vm${count.index}"
  resource_group_name = azurerm_resource_group.dev_ops_project.name
  location = azurerm_resource_group.dev_ops_project.location
  size = "Standard_B1s"
  admin_username = "administrator2"
  admin_password = "uDAc1t1Pass"
  disable_password_authentication = false
  availability_set_id = azurerm_availability_set.dev_ops_project.id 
  network_interface_ids = [
    azurerm_network_interface.dev_ops_project[count.index].id,
  ]
  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
  os_disk {
      storage_account_type = "Standard_LRS"
      caching              = "ReadWrite"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.dev_ops_project.name
  location            = azurerm_resource_group.dev_ops_project.location
  allocation_method   = "Dynamic"
}


resource "azurerm_network_security_group" "webserver" {
  name                = "${var.prefix}-tls_webserver"
  location            = azurerm_resource_group.dev_ops_project.location
  resource_group_name = azurerm_resource_group.dev_ops_project.name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "AllowIncomingFromSubnetVMs"
    priority                   = 100
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_port_range     = "*"
    destination_address_prefixes = azurerm_network_interface.dev_ops_project[*].private_ip_address
  }
  
  security_rule {
    access                     = "Allow"
    direction                  = "Outbound"
    name                       = "AllowOutgoingToSubmnetVMs"
    priority                   = 100
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_port_range     = "*"
    destination_address_prefixes = azurerm_network_interface.dev_ops_project[*].private_ip_address
  }

   security_rule {
    access                     = "Deny"
    direction                  = "Inbound"
    name                       = "DenyIncomingFromInternet"
    priority                   = 101
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = "*"
    destination_address_prefixes = azurerm_network_interface.dev_ops_project[*].private_ip_address
  }
  
  security_rule {
    access                     = "Deny"
    direction                  = "Outbound"
    name                       = "DenyOutgoingToInternet"
    priority                   = 101
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = "*"
    destination_address_prefixes = azurerm_network_interface.dev_ops_project[*].private_ip_address
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.instance_count
  network_interface_id      = azurerm_network_interface.dev_ops_project[count.index].id
  network_security_group_id = azurerm_network_security_group.webserver.id

}

resource "azurerm_availability_set" "dev_ops_project" {
  name                         = "${var.prefix}-avset"
  location                     = azurerm_resource_group.dev_ops_project.location
  resource_group_name          = azurerm_resource_group.dev_ops_project.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_lb" "dev_ops_project" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.dev_ops_project.location
  resource_group_name = azurerm_resource_group.dev_ops_project.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "dev_ops_project" {
  resource_group_name = azurerm_resource_group.dev_ops_project.name
  loadbalancer_id     = azurerm_lb.dev_ops_project.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "dev_ops_project" {  
  resource_group_name            = azurerm_resource_group.dev_ops_project.name
  loadbalancer_id                = azurerm_lb.dev_ops_project.id
  name                           = "${var.prefix}-HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.dev_ops_project.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_backend_address_pool_association" "dev_ops_project" {
  count                   = var.instance_count
  backend_address_pool_id = azurerm_lb_backend_address_pool.dev_ops_project.id
  ip_configuration_name   = "${var.prefix}-primary"
  network_interface_id    = element(azurerm_network_interface.dev_ops_project.*.id, count.index)
}

resource "azurerm_managed_disk" "dev_ops_project" {
  count                = var.instance_count 
  name                 = "${var.prefix}-data${count.index}"
  location             = azurerm_resource_group.dev_ops_project.location
  resource_group_name  = azurerm_resource_group.dev_ops_project.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.managed_disks_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count                = var.instance_count 
  virtual_machine_id = azurerm_linux_virtual_machine.dev_ops_project[count.index].id
  managed_disk_id    = azurerm_managed_disk.dev_ops_project[count.index].id
  lun                = count.index 
  caching            = "None"
}