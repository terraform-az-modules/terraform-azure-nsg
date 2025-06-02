##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Override default naming convention"
}

variable "resource_position_prefix" {
  type        = bool
  default     = true
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "vnet", "ddospp") in the resource name.

- If true, the keyword is prepended: "vnet-core-dev".
- If false, the keyword is appended: "core-dev-vnet".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azure-nsg"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "location" {
  type        = string
  default     = ""
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

##-----------------------------------------------------------------------------
## Global Variables
##-----------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the network security group."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

##-----------------------------------------------------------------------------
## Network Security Groups
##-----------------------------------------------------------------------------
variable "inbound_rules" {
  type = list(object({
    name                         = string
    priority                     = number
    access                       = string
    protocol                     = string
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    source_port_range            = optional(string)
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    destination_port_range       = optional(string)
    description                  = optional(string)
  }))
  default     = []
  description = "List of objects that represent the configuration of each inbound rule."
}

variable "outbound_rules" {
  type = list(object({
    name                         = string
    priority                     = number
    access                       = string
    protocol                     = string
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    source_port_range            = optional(string)
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    destination_port_range       = optional(string)
    description                  = optional(string)
  }))
  default     = []
  description = "List of objects that represent the configuration of each outbound rule."
}

variable "create" {
  type        = string
  default     = "30m"
  description = "Used when creating the Resource Group."
}

variable "update" {
  type        = string
  default     = "30m"
  description = "Used when updating the Resource Group."
}

variable "read" {
  type        = string
  default     = "5m"
  description = "Used when retrieving the Resource Group."
}

variable "delete" {
  type        = string
  default     = "30m"
  description = "Used when deleting the Resource Group."
}

##-----------------------------------------------------------------------------
## Diagnostic Settings
##-----------------------------------------------------------------------------

variable "enable_diagnostic" {
  type        = bool
  default     = false
  description = "Set to false to prevent the module from creating the diagnosys setting for the NSG Resource.."
}

variable "eventhub_name" {
  type        = string
  default     = null
  description = "Eventhub Name to pass it to destination details of diagnosys setting of NSG."
}

variable "eventhub_authorization_rule_id" {
  type        = string
  default     = null
  description = "Eventhub authorization rule id to pass it to destination details of diagnosys setting of NSG."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "log analytics workspace id to pass it to destination details of diagnosys setting of NSG."
}

variable "log_analytics_destination_type" {
  type        = string
  default     = "AzureDiagnostics"
  description = "Possible values are AzureDiagnostics and Dedicated, default to AzureDiagnostics. When set to Dedicated, logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table."
}

##-----------------------------------------------------------------------------
## Network Watcher Variables
##-----------------------------------------------------------------------------
variable "enable_flow_logs" {
  type        = bool
  default     = false
  description = "Flag to be set true when network security group flow logging feature is to be enabled."
}

variable "traffic_analytics_settings" {
  type = object({
    log_analytics_workspace_id          = string
    workspace_region                    = string
    log_analytics_workspace_resource_id = string
    interval_in_minutes                 = number
  })
  default = {
    log_analytics_workspace_id          = null
    workspace_region                    = null
    log_analytics_workspace_resource_id = null
    interval_in_minutes                 = 60
  }
  description = "Settings for traffic analytics. This is used when enable_traffic_analytics is set to true."
}

variable "network_watcher_name" {
  type        = string
  default     = null
  description = "The name of the Network Watcher. Changing this forces a new resource to be created."
}

variable "flow_log_storage_account_id" {
  type        = string
  default     = null
  description = "The id of storage account in which flow logs will be received. Note: Currently, only standard-tier storage accounts are supported."
}

variable "flow_log_retention_policy_enabled" {
  type        = bool
  default     = false
  description = "Boolean flag to enable/disable retention."
}

variable "flow_log_retention_policy_days" {
  type        = number
  default     = 100
  description = "Flow log retention days must be between 0 and 365 for all configurations."
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  default     = null
  description = "The resource ID of the attached log analytics workspace."
}

variable "enable_traffic_analytics" {
  type        = bool
  default     = false
  description = "Boolean flag to enable/disable traffic analytics."
}

variable "flow_log_version" {
  type        = number
  default     = 1
  description = " The version (revision) of the flow log. Possible values are 1 and 2."
}

variable "logs" {
  type        = list(map(string))
  default     = []
  description = "List of log categories. Defaults to all available."
}

