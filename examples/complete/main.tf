locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  law_name = "log-${var.short}-${var.loc}-${terraform.workspace}-002"
  sa_name  = "st${var.short}${var.loc}${terraform.workspace}002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-storage-account" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# Destination for the storage account metrics.
module "log_analytics" {
  source  = "libre-devops/log-analytics-workspace/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  log_analytics_workspaces = { (local.law_name) = {} }
}

# Complete call: a zone-redundant account with blob versioning and soft-delete, a network allow-list, a
# Microsoft-managed encryption scope, and a lifecycle policy that tiers then deletes old blobs.
module "storage" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  storage_accounts = {
    (local.sa_name) = {
      account_replication_type = "ZRS"

      blob_properties = {
        versioning_enabled                = true
        change_feed_enabled               = true
        delete_retention_policy           = { days = 7 }
        container_delete_retention_policy = { days = 7 }
      }

      network_rules = {
        default_action = "Deny"
        bypass         = ["AzureServices"]
        ip_rules       = ["203.0.113.0/24"]
      }

      encryption_scopes = {
        "microsoftmanaged" = { source = "Microsoft.Storage" }
      }

      management_policy = {
        rules = [
          {
            name    = "tier-and-expire-logs"
            filters = { blob_types = ["blockBlob"], prefix_match = ["logs/"] }
            actions = {
              base_blob = {
                tier_to_cool_after_days_since_modification_greater_than    = 30
                tier_to_archive_after_days_since_modification_greater_than = 90
                delete_after_days_since_modification_greater_than          = 365
              }
              version = {
                delete_after_days_since_creation = 90
              }
            }
          }
        ]
      }
    }
  }
}

# Ship the account metrics to the workspace via the diagnostic-settings module (storage logs live on
# the per-service sub-resources, so this setting ships metrics only).
module "diagnostics" {
  source  = "libre-devops/diagnostic-settings/azurerm"
  version = "~> 4.0"

  log_analytics_workspace_id = module.log_analytics.workspace_ids[local.law_name]

  diagnostic_settings = {
    "storage" = {
      target_resource_id = module.storage.ids[local.sa_name]
      enable_all_logs    = false
    }
  }
}
