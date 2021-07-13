# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}


provider "azurerm" {
  features {}
}

## Create an Azure resource group  ##
resource "azurerm_resource_group" "nilavembuRG" {
  name     = var.resource_group
  location = var.location
}

## Create an availability set ##
resource "azurerm_availability_set" "nilavembu-as" {
  name                = "nilavembu-as"
  location            = azurerm_resource_group.nilavembuRG.location
  resource_group_name = azurerm_resource_group.nilavembuRG.name
}

## Create an Azure NSG ##
resource "azurerm_network_security_group" "nilavembunsg" {
  name                = "nsg"
  location            = azurerm_resource_group.nilavembuRG.location
  resource_group_name = azurerm_resource_group.nilavembuRG.name


## Create a rule to allow Ansible to connect to each VM ##
 security_rule {
    name                       = "allowWinRm"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = var.cloud_shell_source
    destination_address_prefix = "*"
  }
  
  
  
## Create a rule to allow your local machine ##

  security_rule {
    name                       = "allowWebDeploy"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8172"
    source_address_prefix      = var.management_ip
    destination_address_prefix = "*"
  }
  
  
  
  ## Create a rule to allow web clients to connect to the web app ## 
  security_rule {
    name                       = "allowPublicWeb"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  


  ## Create a rule to allow RDP to the VMs ##
  security_rule {
    name                       = "allowRDP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.management_ip
    destination_address_prefix = "*"
  }
  
    ## Create a rule to allow SFTP to the VMs ##
  security_rule {
    name                       = "allowSFTP"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "SFTP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.cloud_shell_source
    destination_address_prefix = "*"
  }
  
}

## Create Nilavembu Corporate vNet ##
resource "azurerm_virtual_network" "nilavembuCorpNet" {
  name                = "nilavembu-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.nilavembuRG.location
  resource_group_name = azurerm_resource_group.nilavembuRG.name
}


## Create a web subnet inside the vNet ##
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.nilavembuRG.name
  virtual_network_name = azurerm_virtual_network.nilavembuCorpNet.name
  address_prefixes        = ["10.0.2.0/24"]

  depends_on = [
    azurerm_virtual_network.nilavembuCorpNet
  ]
}

## Create public IP to assign to the load balancer  ##

resource "azurerm_public_ip" "lbIp" {
  name                    = "publicLbIp"
  location                = azurerm_resource_group.nilavembuRG.location
  resource_group_name     = azurerm_resource_group.nilavembuRG.name
  allocation_method       = "Static"
}


## Assign public IPs for each VM for Ansible to connect to and to deploy the web app ##
resource "azurerm_public_ip" "vmIps" {
  count                   = 2
  name                    = "publicVmIp-${count.index}"
  location                = azurerm_resource_group.nilavembuRG.location
  resource_group_name     = azurerm_resource_group.nilavembuRG.name
  allocation_method       = "Dynamic"
  domain_name_label      = "${var.domain_name_prefix}-${count.index}"
}


## Create a vNic for each VM ##
 
resource "azurerm_network_interface" "main" {
  count               = 2
  name                = "nilavembu-nic-${count.index}"
  location            = azurerm_resource_group.nilavembuRG.location
  resource_group_name = azurerm_resource_group.nilavembuRG.name
  
  ## Simple ip configuration for each vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmIps[count.index].id
  }
  
  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.internal
  ]
}


## Apply the NSG to each of the VMs' NICs ##
resource "azurerm_network_interface_security_group_association" "nsg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.nilavembunsg.id
}

## Create the load balancer with a frontend configuration using the public ##
resource "azurerm_lb" "LB" {
 name                = "nobsloadbalancer"
 location            = azurerm_resource_group.nilavembuRG.location
 resource_group_name = azurerm_resource_group.nilavembuRG.name

 frontend_ip_configuration {
   name                 = "lb_frontend"
   public_ip_address_id = azurerm_public_ip.lbIp.id
 }
}


## Create backend address pool holding both VMs ##
resource "azurerm_lb_backend_address_pool" "be_pool" {
 resource_group_name = azurerm_resource_group.nilavembuRG.name
 loadbalancer_id     = azurerm_lb.LB.id
 name                = "BackEndAddressPool"
}


## Assign both vNics on the VMs to the backend address pool ##
resource "azurerm_network_interface_backend_address_pool_association" "be_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "ip_config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

## Create a health probe which will periodically check for an open port 80 ##
resource "azurerm_lb_probe" "lbprobe" {
  resource_group_name = azurerm_resource_group.nilavembuRG.name
  loadbalancer_id     = azurerm_lb.LB.id
  name                = "http-running-probe"
  port                = 80
}


## Create a rule on the load balancer to forward all incoming traffic on port 80 using above health probe ## 
resource "azurerm_lb_rule" "lbrule" {
  resource_group_name            = azurerm_resource_group.nilavembuRG.name
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "LBRule"
  probe_id                       = azurerm_lb_probe.lbprobe.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.be_pool.id
  frontend_ip_configuration_name = "lb_frontend"
}

## Create the two Windows VMs associating the vNIcs created earlier ##
resource "azurerm_windows_virtual_machine" "nilavembuVMs" {
  count                 = 2
  name                  = "nilavembuvm-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.nilavembuRG.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  availability_set_id   = azurerm_availability_set.nilavembu-as.id
  computer_name         = "nilavembuvm-${count.index}"
  admin_username        = "vmadmin"
  admin_password        = "Vmadmin!2345"
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.main
  ]
}




output "VMIps" {
  value       = azurerm_public_ip.vmIps.*.ip_address
}

## Get the load balancer's public IP address ##
output "Load_Balancer_IP" {
  value       = azurerm_public_ip.lbIp.ip_address
}


