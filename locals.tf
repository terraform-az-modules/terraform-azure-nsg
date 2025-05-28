##-----------------------------------------------------------------------------
## Locals declaration for determining the id of ddos protection plan.
##-----------------------------------------------------------------------------

locals {
  name = var.custom_name != null ? var.custom_name : module.labels.id
}
