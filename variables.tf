variable "location" {
  description = "Azure region for the storage accounts."
  type        = string
}

variable "resource_group_id" {
  description = "Resource id of the resource group to create the storage accounts in. The name and subscription are parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "storage_accounts" {
  description = <<-EOT
    Storage accounts to create, keyed by account name. Exhaustive azurerm_storage_account surface plus
    optional per-account encryption_scopes and a management_policy (lifecycle rules).

    Secure defaults: min_tls_version TLS1_2, HTTPS only, infrastructure encryption on, anonymous nested
    (blob) access off, cross-tenant replication off, and a deny-by-default network_rules set with Azure
    services allowed to bypass (so the public endpoint is reachable only from allow-listed IPs/subnets;
    add ip_rules / virtual_network_subnet_ids or a private endpoint, or set public_network_access_enabled
    = false, for tighter isolation). Ship logs via the diagnostic-settings module rather than legacy
    storage analytics logging.

    To manage the firewall OUTSIDE this module (with the storage-account-network-rules module or a raw
    azurerm_storage_account_network_rules resource), set manage_network_rules = false: the inline
    network_rules block is then omitted entirely, since Azure allows only one rule set per account and
    an inline block would fight the standalone resource with perpetual diffs. Note that an explicit
    network_rules = null does NOT do this (Terraform replaces a null optional attribute with its
    default, so the deny-by-default block would still be rendered).

    NOTE: the inline queue_properties and static_website blocks are deprecated on azurerm_storage_account
    (removed in provider v5.0), and their replacements (azurerm_storage_account_queue_properties /
    azurerm_storage_account_static_website) are data-plane resources that clash with a deny-by-default
    network rule set, so they are intentionally out of scope here; configure them separately when needed.
  EOT
  type = map(object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    account_kind             = optional(string, "StorageV2")
    access_tier              = optional(string)

    min_tls_version                   = optional(string, "TLS1_2")
    https_traffic_only_enabled        = optional(bool, true)
    infrastructure_encryption_enabled = optional(bool, true)
    allow_nested_items_to_be_public   = optional(bool, false)
    cross_tenant_replication_enabled  = optional(bool, false)
    public_network_access_enabled     = optional(bool, true)
    shared_access_key_enabled         = optional(bool, true)
    default_to_oauth_authentication   = optional(bool, false)
    allowed_copy_scope                = optional(string)
    is_hns_enabled                    = optional(bool)
    nfsv3_enabled                     = optional(bool)
    sftp_enabled                      = optional(bool)
    large_file_share_enabled          = optional(bool)
    local_user_enabled                = optional(bool)
    queue_encryption_key_type         = optional(string)
    table_encryption_key_type         = optional(string)
    dns_endpoint_type                 = optional(string)
    edge_zone                         = optional(string)
    provisioned_billing_model_version = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    customer_managed_key = optional(object({
      user_assigned_identity_id = string
      key_vault_key_id          = optional(string)
      managed_hsm_key_id        = optional(string)
    }))

    manage_network_rules = optional(bool, true)
    network_rules = optional(object({
      default_action             = optional(string, "Deny")
      bypass                     = optional(set(string), ["AzureServices"])
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })), [])
    }), {})

    blob_properties = optional(object({
      versioning_enabled            = optional(bool)
      change_feed_enabled           = optional(bool)
      change_feed_retention_in_days = optional(number)
      default_service_version       = optional(string)
      last_access_time_enabled      = optional(bool)
      delete_retention_policy = optional(object({
        days                     = optional(number)
        permanent_delete_enabled = optional(bool)
      }))
      container_delete_retention_policy = optional(object({
        days = optional(number)
      }))
      restore_policy = optional(object({
        days = number
      }))
      cors_rules = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), [])
    }))

    share_properties = optional(object({
      retention_policy = optional(object({
        days = optional(number)
      }))
      smb = optional(object({
        versions                        = optional(set(string))
        authentication_types            = optional(set(string))
        kerberos_ticket_encryption_type = optional(set(string))
        channel_encryption_type         = optional(set(string))
        multichannel_enabled            = optional(bool)
      }))
      cors_rules = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })), [])
    }))

    azure_files_authentication = optional(object({
      directory_type                 = string
      default_share_level_permission = optional(string)
      active_directory = optional(object({
        domain_name         = string
        domain_guid         = string
        domain_sid          = optional(string)
        forest_name         = optional(string)
        netbios_domain_name = optional(string)
        storage_sid         = optional(string)
      }))
    }))

    routing = optional(object({
      choice                      = optional(string)
      publish_internet_endpoints  = optional(bool)
      publish_microsoft_endpoints = optional(bool)
    }))

    sas_policy = optional(object({
      expiration_period = string
      expiration_action = optional(string)
    }))

    custom_domain = optional(object({
      name          = string
      use_subdomain = optional(bool)
    }))

    immutability_policy = optional(object({
      state                         = string
      period_since_creation_in_days = number
      allow_protected_append_writes = bool
    }))

    encryption_scopes = optional(map(object({
      source                             = string
      key_vault_key_id                   = optional(string)
      infrastructure_encryption_required = optional(bool)
    })), {})

    management_policy = optional(object({
      rules = list(object({
        name    = string
        enabled = optional(bool, true)
        filters = object({
          blob_types   = list(string)
          prefix_match = optional(list(string), [])
          match_blob_index_tags = optional(list(object({
            name      = string
            value     = string
            operation = optional(string, "==")
          })), [])
        })
        actions = object({
          base_blob = optional(object({
            tier_to_cool_after_days_since_modification_greater_than        = optional(number)
            tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
            tier_to_cool_after_days_since_creation_greater_than            = optional(number)
            tier_to_cold_after_days_since_modification_greater_than        = optional(number)
            tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
            tier_to_cold_after_days_since_creation_greater_than            = optional(number)
            tier_to_archive_after_days_since_modification_greater_than     = optional(number)
            tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
            tier_to_archive_after_days_since_creation_greater_than         = optional(number)
            delete_after_days_since_modification_greater_than              = optional(number)
            delete_after_days_since_last_access_time_greater_than          = optional(number)
            delete_after_days_since_creation_greater_than                  = optional(number)
            auto_tier_to_hot_from_cool_enabled                             = optional(bool)
          }))
          snapshot = optional(object({
            change_tier_to_cool_after_days_since_creation                  = optional(number)
            change_tier_to_archive_after_days_since_creation               = optional(number)
            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
            tier_to_cold_after_days_since_creation_greater_than            = optional(number)
            delete_after_days_since_creation_greater_than                  = optional(number)
          }))
          version = optional(object({
            change_tier_to_cool_after_days_since_creation                  = optional(number)
            change_tier_to_archive_after_days_since_creation               = optional(number)
            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
            tier_to_cold_after_days_since_creation_greater_than            = optional(number)
            delete_after_days_since_creation                               = optional(number)
          }))
        })
      }))
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.storage_accounts) : contains(["Standard", "Premium"], s.account_tier)])
    error_message = "Each storage account account_tier must be Standard or Premium."
  }

  validation {
    condition     = alltrue([for s in values(var.storage_accounts) : contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], s.account_replication_type)])
    error_message = "Each account_replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }

  validation {
    condition     = alltrue([for s in values(var.storage_accounts) : contains(["TLS1_0", "TLS1_1", "TLS1_2"], s.min_tls_version)])
    error_message = "Each min_tls_version must be TLS1_0, TLS1_1, or TLS1_2 (TLS1_2 recommended)."
  }

  validation {
    condition     = alltrue([for s in values(var.storage_accounts) : contains(["Storage", "StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage"], s.account_kind)])
    error_message = "Each account_kind must be Storage, StorageV2, BlobStorage, BlockBlobStorage, or FileStorage."
  }

  validation {
    condition     = alltrue([for s in values(var.storage_accounts) : s.network_rules == null ? true : contains(["Allow", "Deny"], s.network_rules.default_action)])
    error_message = "network_rules.default_action must be Allow or Deny."
  }
}

variable "tags" {
  description = "Tags to apply to the storage accounts."
  type        = map(string)
  default     = {}
}
