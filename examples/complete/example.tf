provider "azurerm" {
  features {}
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
  location    = "canadacentral"
}

##-----------------------------------------------------------------------------
## Virtual Network module call.
##-----------------------------------------------------------------------------
module "vnet" {
  depends_on          = [module.resource_group]
  source              = "clouddrove/vnet/azure"
  version             = "1.0.4"
  name                = local.name
  environment         = local.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.30.0.0/22"]
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
## Network Security Group module call.
##-----------------------------------------------------------------------------
module "network_security_group" {
  depends_on               = [module.subnet]
  source                   = "../../"
  name                     = local.name
  environment              = local.environment
  resource_group_name      = module.resource_group.resource_group_name
  location                 = module.resource_group.resource_group_location
  resource_position_prefix = true
  inbound_rules = [
    {
      name                       = "ssh"
      priority                   = 101
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "22"
      description                = "ssh allowed port"
    },
    {
      name                       = "https"
      priority                   = 102
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "0.0.0.0/0"
      source_port_range          = "80,443"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "22"
      description                = "ssh allowed port"
    }
  ]
  enable_diagnostic                 = true
  log_analytics_workspace_id        = module.log-analytics.workspace_id
  flow_log_retention_policy_days    = 100
  flow_log_retention_policy_enabled = true
  logs = [{
    category = "NetworkSecurityGroupEvent"
    },
    {
      category = "NetworkSecurityGroupRuleCounter"
    }
  ]
}
