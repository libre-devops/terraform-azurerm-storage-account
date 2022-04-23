resource "azurerm_storage_account" "sa" {
  name                      = var.storage_account_name
  resource_group_name       = var.rg_name
  location                  = var.location
  account_tier              = var.account_tier
  account_replication_type  = var.replication_type
  access_tier               = var.access_tier
  enable_https_traffic_only = var.enable_https_traffic_only
  min_tls_version           = var.min_tls_version
  is_hns_enabled            = var.is_hns_enabled
  nfsv3_enabled             = var.nfsv3_enabled
  large_file_share_enabled  = var.large_file_share_enabled

  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []
    content {
      type = var.identity_type
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules
    content {
      default_action             = lookup(network_rules.value, "default_action", null)
      bypass                     = toset(lookup(network_rules.value, "bypass", null))
      ip_rules                   = toset(lookup(network_rules.value, "ip_rules", null))
      virtual_network_subnet_ids = toset(lookup(network_rules.value, "subnet_ids", null))
    },
  }

  tags = var.tags
}