#checkov:skip=CKV2_AZURE_1:CMKs are not considered in this module
#checkov:skip=CKV2_AZURE_18:CMKs are not considered in this module
#checkov:skip=CKV_AZURE_33:Storage logging is not configured by default in this module
#tfsec:ignore:azure-storage-queue-services-logging-enabled tfsec:ignore:azure-storage-allow-microsoft-service-bypass
resource "azurerm_storage_account" "sa" {
  name                            = var.storage_account_name
  resource_group_name             = var.rg_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.replication_type
  access_tier                     = var.access_tier
  enable_https_traffic_only       = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  is_hns_enabled                  = var.is_hns_enabled
  nfsv3_enabled                   = var.nfsv3_enabled
  large_file_share_enabled        = var.large_file_share_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_keys_enabled

  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

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
    for_each = length(var.network_rules) > 0 || var.network_rules != "" ? var.network_rules : {}
    content {
      default_action             = lookup(network_rules.value, "default_action", null)
      bypass                     = toset(lookup(network_rules.value, "bypass", null))
      ip_rules                   = toset(lookup(network_rules.value, "ip_rules", null))
      virtual_network_subnet_ids = toset(lookup(network_rules.value, "subnet_ids", null))
    }
  }

  dynamic "custom_domain" {
    for_each = length(var.custom_domain) > 0 || var.custom_domain != "" ? var.custom_domain : {}
    content {
      name          = custom_domain.key
      use_subdomain = lookup(custom_domain.value, "use_subdomain", null)
    }
  }

  dynamic "blob_properties" {
    for_each = lookup(var.storage_account, "blob_properties", false) == false ? [] : [1]

    content {
      versioning_enabled       = try(var.storage_account.blob_properties.versioning_enabled, false)
      change_feed_enabled      = try(var.storage_account.blob_properties.change_feed_enabled, false)
      default_service_version  = try(var.storage_account.blob_properties.default_service_version, "2020-06-12")
      last_access_time_enabled = try(var.storage_account.blob_properties.last_access_time_enabled, false)

      dynamic "cors_rule" {
        for_each = lookup(var.storage_account.blob_properties, "cors_rule", false) == false ? [] : [1]

        content {
          allowed_headers    = var.storage_account.blob_properties.cors_rule.allowed_headers
          allowed_methods    = var.storage_account.blob_properties.cors_rule.allowed_methods
          allowed_origins    = var.storage_account.blob_properties.cors_rule.allowed_origins
          exposed_headers    = var.storage_account.blob_properties.cors_rule.exposed_headers
          max_age_in_seconds = var.storage_account.blob_properties.cors_rule.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = lookup(var.storage_account.blob_properties, "delete_retention_policy", false) == false ? [] : [1]

        content {
          days = try(var.storage_account.blob_properties.delete_retention_policy.delete_retention_policy, 7)
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = lookup(var.storage_account.blob_properties, "container_delete_retention_policy", false) == false ? [] : [1]

        content {
          days = try(var.storage_account.blob_properties.container_delete_retention_policy.container_delete_retention_policy, 7)
        }
      }
    }
  }

  dynamic "queue_properties" {
    for_each = lookup(var.storage_account, "queue_properties", false) == false ? [] : [1]

    content {
      dynamic "cors_rule" {
        for_each = lookup(var.storage_account.queue_properties, "cors_rule", false) == false ? [] : [1]

        content {
          allowed_headers    = var.storage_account.queue_properties.cors_rule.allowed_headers
          allowed_methods    = var.storage_account.queue_properties.cors_rule.allowed_methods
          allowed_origins    = var.storage_account.queue_properties.cors_rule.allowed_origins
          exposed_headers    = var.storage_account.queue_properties.cors_rule.exposed_headers
          max_age_in_seconds = var.storage_account.queue_properties.cors_rule.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = lookup(var.storage_account.queue_properties, "logging", false) == false ? [] : [1]

        content {
          delete                = var.storage_account.queue_properties.logging.delete
          read                  = var.storage_account.queue_properties.logging.read
          write                 = var.storage_account.queue_properties.logging.write
          version               = var.storage_account.queue_properties.logging.version
          retention_policy_days = try(var.storage_account.queue_properties.logging.retention_policy_days, 7)
        }
      }

      dynamic "minute_metrics" {
        for_each = lookup(var.storage_account.queue_properties, "minute_metrics", false) == false ? [] : [1]

        content {
          enabled               = var.storage_account.queue_properties.minute_metrics.enabled
          version               = var.storage_account.queue_properties.minute_metrics.version
          include_apis          = try(var.storage_account.queue_properties.minute_metrics.include_apis, null)
          retention_policy_days = try(var.storage_account.queue_properties.minute_metrics.retention_policy_days, 7)
        }
      }

      dynamic "hour_metrics" {
        for_each = lookup(var.storage_account.queue_properties, "hour_metrics", false) == false ? [] : [1]

        content {
          enabled               = var.storage_account.queue_properties.hour_metrics.enabled
          version               = var.storage_account.queue_properties.hour_metrics.version
          include_apis          = try(var.storage_account.queue_properties.hour_metrics.include_apis, null)
          retention_policy_days = try(var.storage_account.queue_properties.hour_metrics.retention_policy_days, 7)
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = lookup(var.storage_account, "static_website", false) == false ? [] : [1]

    content {
      index_document     = try(var.storage_account.static_website.index_document, null)
      error_404_document = try(var.storage_account.static_website.error_404_document, null)
    }
  }

  dynamic "azure_files_authentication" {
    for_each = lookup(var.storage_account, "azure_files_authentication", false) == false ? [] : [1]

    content {
      directory_type = var.storage_account.azure_files_authentication.directory_type

      dynamic "active_directory" {
        for_each = lookup(var.storage_account.azure_files_authentication, "active_directory", false) == false ? [] : [1]

        content {
          storage_sid         = var.storage_account.azure_files_authentication.active_directory.storage_sid
          domain_name         = var.storage_account.azure_files_authentication.active_directory.domain_name
          domain_sid          = var.storage_account.azure_files_authentication.active_directory.domain_sid
          domain_guid         = var.storage_account.azure_files_authentication.active_directory.domain_guid
          forest_name         = var.storage_account.azure_files_authentication.active_directory.forest_name
          netbios_domain_name = var.storage_account.azure_files_authentication.active_directory.netbios_domain_name
        }
      }
    }
  }

  dynamic "routing" {
    for_each = lookup(var.storage_account, "routing", false) == false ? [] : [1]

    content {
      publish_internet_endpoints  = try(var.storage_account.routing.publish_internet_endpoints, false)
      publish_microsoft_endpoints = try(var.storage_account.routing.publish_microsoft_endpoints, false)
      choice                      = try(var.storage_account.routing.choice, "MicrosoftRouting")
    }
  }

  tags = var.tags
}