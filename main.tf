# create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# create vNet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# create Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]
}

# create the nics
resource "azurerm_network_interface" "nics" {
  count               = var.instance_count
  name                = "${var.prefix}-vm${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
  }
}

# create the pips
resource "azurerm_public_ip" "pip" {
  count               = var.instance_count
  name                = "${var.prefix}-vm${count.index}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# create the nsg
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# associate the ngg with the nics
resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  count = var.instance_count
  network_interface_id      = element(azurerm_network_interface.nics.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# create the vms
resource "azurerm_linux_virtual_machine" "vms" {
  name                  = "${var.prefix}-vm${count.index}"
  count                 = var.instance_count
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_ds1_v2"
  admin_username        = "admin-user"
  network_interface_ids = [
    element(azurerm_network_interface.nics.*.id, count.index)
,
  ]
  
  admin_ssh_key {
    username   = "admin-user"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "19.04"
    version   = "latest"
  }
}