provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias = "peer"
}

locals {
  name        = "app"
  environment = "test"
  label_order = ["name", "environment"]
}

##-----------------------------------------------------------------------------
## Resource Group module call
## Resource group in which all resources will be deployed.
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "clouddrove/resource-group/azure"
  version     = "1.0.2"
  name        = local.name
  environment = local.environment
  label_order = local.label_order
  location    = "northeurope"
}

##-----------------------------------------------------------------------------
## Virtual Network module call.
##-----------------------------------------------------------------------------
module "vnet" {
  depends_on             = [module.resource_group]
  source                 = "clouddrove/vnet/azure"
  version                = "1.0.4"
  name                   = local.name
  environment            = local.environment
  resource_group_name    = module.resource_group.resource_group_name
  location               = module.resource_group.resource_group_location
  address_spaces         = ["10.30.0.0/22"]
  enable_network_watcher = true
}

##-----------------------------------------------------------------------------
## Subnet Module call.
## Subnet to which network security group will be attached.
##-----------------------------------------------------------------------------
module "subnet" {
  source               = "clouddrove/subnet/azure"
  version              = "1.2.1"
  name                 = local.name
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name
  # Subnet Configuration
  subnet_names    = ["subnet"]
  subnet_prefixes = ["10.30.0.0/24"]
  # routes
  enable_route_table = true
  route_table_name   = "default-subnet"
  # routes
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

##-----------------------------------------------------------------------------
## Log Analytics module call.
## Log Analytics workspace in which network security group diagnostic setting logs will be received.
##-----------------------------------------------------------------------------
module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "2.0.0"
  name                             = local.name
  environment                      = local.environment
  label_order                      = local.label_order
  create_log_analytics_workspace   = true
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location

  #### diagnostic setting
  log_analytics_workspace_id = module.log-analytics.workspace_id
}

##-----------------------------------------------------------------------------
## Storage Module call.
## Storage account in which network security group flow log will be received.
##-----------------------------------------------------------------------------
module "storage" {
  providers = {
    azurerm.main_sub = azurerm
    azurerm.dns_sub  = azurerm.peer
  }
  source               = "clouddrove/storage/azure"
  version              = "1.1.1"
  name                 = local.name
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  storage_account_name = "mystorage42343432"
  ##   Storage Container
  containers_list = [
    { name = "app-test", access_type = "private" },
    { name = "app2", access_type = "private" },
  ]
  ##   Storage File Share
  file_shares = [
    { name = "fileshare1", quota = 5 },
  ]
  ##   Storage Tables
  tables = ["table1"]
  ## Storage Queues
  queues                   = ["queue1"]
  management_policy_enable = true
  #enable private endpoint
  virtual_network_id                = module.vnet.vnet_id
  subnet_id                         = module.subnet.default_subnet_id[0]
  enable_diagnostic                 = false
  enable_advanced_threat_protection = false
}

##-----------------------------------------------------------------------------
## Network Security Group module call.
##-----------------------------------------------------------------------------
module "network_security_group" {
  depends_on                        = [module.subnet, module.storage]
  source                            = "../../"
  name                              = local.name
  environment                       = local.environment
  resource_group_name               = module.resource_group.resource_group_name
  location                          = module.resource_group.resource_group_location
  enable_flow_logs                  = true
  network_watcher_name              = module.vnet.network_watcher_name
  flow_log_storage_account_id       = module.storage.storage_account_id
  enable_traffic_analytics          = true
  flow_log_retention_policy_enabled = true
  enable_diagnostic                 = true
  resource_position_prefix          = true

  traffic_analytics_settings = {
    log_analytics_workspace_id          = module.log-analytics.workspace_id
    workspace_region                    = module.resource_group.resource_group_location
    log_analytics_workspace_resource_id = module.log-analytics.workspace_customer_id
    interval_in_minutes                 = 60
  }

  inbound_rules = [
    {
      name                       = "ssh"
      priority                   = 101
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "10.20.0.0/32"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "22"
      description                = "ssh allowed port"
    },
    {
      name                       = "https"
      priority                   = 102
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "0.0.0.0/0"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "80,443"
      description                = "https allowed port"
    }
  ]
  logs = [{
    category = "NetworkSecurityGroupEvent"
    },
    {
      category = "NetworkSecurityGroupRuleCounter"
    }
  ]
}
