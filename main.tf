
# Create a resource group for network
resource "azurerm_resource_group" "network-rg" {
  name     = "${lower(replace(var.app_name," ","-"))}-${var.environment}-network-rg"
  location = var.location
  tags = {
    application = var.app_name
    environment = var.environment
  }
}


resource "azurerm_virtual_network" "network-app-vnet" {
  name                = "${lower(replace(var.app_name," ","-"))}-${var.environment}-app-vnet"
  address_space       = [var.network-app-vnet-cidr]
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  tags = {
    application = var.app_name
    environment = var.environment
  }
}


resource "azurerm_subnet" "network-app-subnet" {
  name                 = "${lower(replace(var.app_name," ","-"))}-${var.environment}-app-subnet2"
  address_prefixes       = [var.network-app-subnet-cidr]
  virtual_network_name = azurerm_virtual_network.network-app-vnet.name
  resource_group_name  = azurerm_resource_group.network-rg.name
}



# Create a subnet for Network

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.network-app-vnet.name
  address_prefixes     = [var.network-bastion-subnet-cidr]
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastionpip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "bastion" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  #*********** IN-BOUND Traffic *************#

  security_rule {
    name                       = "Allow_HTTPS_internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS_GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_BastionHost_comm"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny_BastionHost_comm"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  #*********** OT-BOUND Traffic *************#

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow_bastion"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }


  tags = {
    application = var.app_name
    environment = var.environment
  }
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "azurebastion"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}


resource "azurerm_route_table" "rt" {
  name                = "${lower(replace(var.app_name," ","-"))}-${var.environment}-route-table"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
   route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "association" {
  subnet_id      = azurerm_subnet.network-app-subnet.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_resource_group" "app-rg" {
  name     = "${lower(replace(var.app_name," ","-"))}-${var.environment}-app-rg"
  location = var.location
  tags = {
    application = var.app_name
    environment = var.environment
  }
}

resource "azurerm_log_analytics_workspace" "test" {
  location            = azurerm_resource_group.app-rg.location
  name                = "testLogAnalyticsWorkspaceName"
  resource_group_name = azurerm_resource_group.app-rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "test" {
  location              = azurerm_log_analytics_workspace.test.location
  resource_group_name   = azurerm_resource_group.app-rg.name
  solution_name         = "ContainerInsights"
  workspace_name        = azurerm_log_analytics_workspace.test.name
  workspace_resource_id = azurerm_log_analytics_workspace.test.id

  plan {
    product   = "OMSGallery/ContainerInsights"
    publisher = "Microsoft"
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.app-rg.location
  name                = "${lower(replace(var.app_name," ","-"))}-${var.environment}-aks"
  resource_group_name = azurerm_resource_group.app-rg.name
  dns_prefix          = "dev-aks"

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = 1
  }
  # linux_profile {
  #   admin_username = "ubuntu"

  #   ssh_key {
  #     key_data = file(var.ssh_public_key)
  #   }
  # }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  service_principal {
    client_id     = var.aks_service_principal_app_id
    client_secret = var.aks_service_principal_client_secret
  }
  
  tags                = {
    Environment = "Dev"
  }
}

###################
# Windows Machine
##################

resource "azurerm_network_interface" "jumphost" {
  name                = "${lower(replace(var.app_name," ","-"))}-${var.environment}-jumphost-nic"
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name

  ip_configuration {
    name                          = "${lower(replace(var.app_name," ","-"))}-${var.environment}-ip-configuration"
    subnet_id                     = azurerm_subnet.network-app-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "jumphost" {
  name                = "${lower(replace(var.app_name," ","-"))}-${var.environment}-jumphost-nsg"
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name

  security_rule {
    name                       = "Allow_HTTPS_internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.1.1.0/26"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.1.1.0/26"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jumphost" {
  network_interface_id      = azurerm_network_interface.jumphost.id
  network_security_group_id = azurerm_network_security_group.jumphost.id
}


resource "azurerm_windows_virtual_machine" "jumphost" {
  name                  = "${lower(replace(var.app_name," ","-"))}-${var.environment}-jumphost"
  location              = azurerm_resource_group.app-rg.location
  resource_group_name   = azurerm_resource_group.app-rg.name
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "${var.vm_password}"
  computer_name         = "jumphost-vm"
  enable_automatic_updates = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [
    azurerm_network_interface.jumphost.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}