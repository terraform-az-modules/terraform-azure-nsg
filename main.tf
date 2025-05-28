##-----------------------------------------------------------------------------
# Standard Tagging Module – Applies standard tags to all resources for traceability
##-----------------------------------------------------------------------------
module "labels" {
  source          = "terraform-az-modules/tags/azure"
  version         = "1.0.0"
  name            = var.custom_name == "" ? var.name : var.custom_name
  location        = var.location
  environment     = var.environment
  managedby       = var.managedby
  label_order     = var.label_order
  repository      = var.repository
  deployment_mode = var.deployment_mode
  extra_tags      = var.extra_tags
}

##-----------------------------------------------------------------------------
# Network Security Group – Creates a NSG with proper tagging and timeouts
##-----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  count               = var.enabled ? 1 : 0
  name                = format(var.resource_position_prefix ? "nsg-%s" : "%s-nsg", local.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = module.labels.tags

  timeouts {
    create = var.create
    update = var.update
    read   = var.read
    delete = var.delete
  }
}

##-----------------------------------------------------------------------------
# Inbound NSG Rules – Manage granular inbound traffic control with flexible rule definitions
##-----------------------------------------------------------------------------
resource "azurerm_network_security_rule" "inbound" {
  for_each                     = var.enabled ? { for rule in var.inbound_rules : rule.name => rule } : {}
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg[0].name
  direction                    = "Inbound"
  name                         = each.value.name
  priority                     = each.value.priority
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)   // To be passed when only one source address or all address has to be passed or tag has to be passed
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null) // to be passed when 2 or more but not all address has to be passed
  source_port_range            = lookup(each.value, "source_port_range", "*") == "*" ? "*" : null
  source_port_ranges           = lookup(each.value, "source_port_range", "*") == "*" ? null : split(",", each.value.source_port_range)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", "*")    // To be passed when only one source address or all address has to be passed or tag has to be passed
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null) // to be passed when 2 or more but not all address has to be passed
  destination_port_range       = lookup(each.value, "destination_port_range", null) == "*" ? "*" : null
  destination_port_ranges      = lookup(each.value, "destination_port_range", "*") == "*" ? null : split(",", each.value.destination_port_range)
  description                  = lookup(each.value, "description", null)

  timeouts {
    create = var.create
    update = var.update
    read   = var.read
    delete = var.delete
  }
}

##-----------------------------------------------------------------------------
# Outbound NSG Rules – Manage granular outbound traffic control with flexible rule definitions
##-----------------------------------------------------------------------------
resource "azurerm_network_security_rule" "outbound" {
  for_each                     = var.enabled ? { for rule in var.outbound_rules : rule.name => rule } : {}
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.nsg[0].name
  direction                    = "Outbound"
  name                         = each.value.name
  priority                     = each.value.priority
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)   // To be passed when only one source address or all address has to be passed or tag has to be passed
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null) // to be passed when 2 or more but not all address has to be passed
  source_port_range            = lookup(each.value, "source_port_range", "*") == "*" ? "*" : null
  source_port_ranges           = lookup(each.value, "source_port_range", "*") == "*" ? null : split(",", each.value.source_port_range)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", "*")    // To be passed when only one source address or all address has to be passed or tag has to be passed
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null) // to be passed when 2 or more but not all address has to be passed
  destination_port_range       = lookup(each.value, "destination_port_range", null) == "*" ? "*" : null
  destination_port_ranges      = lookup(each.value, "destination_port_range", "*") == "*" ? null : split(",", each.value.destination_port_range)
  description                  = lookup(each.value, "description", null)

  timeouts {
    create = var.create
    update = var.update
    read   = var.read
    delete = var.delete
  }
}


##-----------------------------------------------------------------------------
# NSG Flow Logs – Enables logging of ingress and egress IP traffic for monitoring
##-----------------------------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "nsg_flow_logs" {
  count                = var.enabled && var.enable_flow_logs ? 1 : 0
  name                 = format(var.resource_position_prefix ? "flow_logs-%s" : "%s-flow_logs", local.name)
  enabled              = var.enabled
  version              = var.flow_log_version
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.resource_group_name
  target_resource_id   = azurerm_network_security_group.nsg[0].id
  storage_account_id   = var.flow_log_storage_account_id
  retention_policy {
    enabled = var.flow_log_retention_policy_enabled
    days    = var.flow_log_retention_policy_days
  }
  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics ? [1] : []
    content {
      enabled               = var.enable_traffic_analytics
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = 60
    }
  }
}

##-----------------------------------------------------------------------------
# Diagnostic Settings – Enables log collection for auditing and monitoring
##-----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "nsg_diagnostic" {
  count                          = var.enabled && var.enable_diagnostic ? 1 : 0
  name                           = format(var.resource_position_prefix ? "nsg-diagnostic-log-%s" : "%s-nsg-diagnostic-log", local.name)
  target_resource_id             = azurerm_network_security_group.nsg[0].id
  storage_account_id             = var.flow_log_storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = var.logs
    content {
      category_group = lookup(enabled_log.value, "category_group", null)
      category       = lookup(enabled_log.value, "category", null)
    }
  }

  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
