resource "azurerm_storage_account" "sa" {
  for_each                          = { for sa in var.storage_accounts : sa.name => sa }
  name                              = each.value.name
  resource_group_name               = each.value.rg_name
  location                          = each.value.location
  account_kind                      = each.value.account_kind
  account_tier                      = each.value.account_tier
  account_replication_type          = upper(each.value.account_replication_type)
  access_tier                       = title(each.value.access_tier)
  https_traffic_only_enabled        = each.value.enable_https_traffic_only
  min_tls_version                   = each.value.min_tls_version
  is_hns_enabled                    = each.value.is_hns_enabled
  cross_tenant_replication_enabled  = each.value.cross_tenant_replication_enabled
  edge_zone                         = each.value.edge_zone
  default_to_oauth_authentication   = each.value.default_to_oauth_authentication
  nfsv3_enabled                     = each.value.nfsv3_enabled
  large_file_share_enabled          = each.value.large_file_share_enabled
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled         = each.value.shared_access_keys_enabled
  tags                              = each.value.tags
  queue_encryption_key_type         = each.value.queue_encryption_key_type
  table_encryption_key_type         = each.value.table_encryption_key_type
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  allowed_copy_scope                = each.value.allowed_copy_scope
  sftp_enabled                      = each.value.sftp_enabled

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }


  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [each.value.network_rules] : []
    content {
      bypass                     = try(toset(network_rules.value.bypass), ["AzureServices"])
      default_action             = network_rules.value.default_action
      ip_rules                   = toset(network_rules.value.ip_rules)
      virtual_network_subnet_ids = try(toset(network_rules.value.virtual_network_subnet_ids))

      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access != null ? [network_rules.value.private_link_access] : []
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  dynamic "custom_domain" {
    for_each = each.value.custom_domain != null ? [each.value.custom_domain] : []
    content {
      name          = custom_domain.value.name
      use_subdomain = try(custom_domain.value.use_subdomain, null)
    }
  }

  dynamic "immutability_policy" {
    for_each = each.value.immutability_policy != null ? [each.value.immutability_policy] : []
    content {
      allow_protected_append_writes = immutability_policy.value.allow_protected_append_writes
      period_since_creation_in_days = immutability_policy.value.period_since_creation_in_days
      state                         = immutability_policy.value.state
    }
  }

  dynamic "sas_policy" {
    for_each = each.value.sas_policy != null ? [each.value.sas_policy] : []
    content {
      expiration_period = sas_policy.value.expiration_period
      expiration_action = sas_policy.value.expiration_action
    }
  }

  dynamic "blob_properties" {
    for_each = each.value.blob_properties != null ? [each.value.blob_properties] : []
    content {
      versioning_enabled       = try(blob_properties.value.versioning_enabled, false)
      change_feed_enabled      = try(blob_properties.value.change_feed_enabled, false)
      default_service_version  = try(blob_properties.value.default_service_version, "2020-06-12")
      last_access_time_enabled = try(blob_properties.value.last_access_time_enabled, false)

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule != null ? [blob_properties.value.cors_rule] : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = try(delete_retention_policy.value.days, 7)
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = try(container_delete_retention_policy.value.days, 7)
        }
      }
    }
  }

  dynamic "share_properties" {
    for_each = each.value.share_properties != null ? [each.value.share_properties] : []
    content {

      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rule != null ? [share_properties.value.cors_rule] : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "smb" {
        for_each = share_properties.value.smb != null ? [share_properties.value.smb] : []
        content {
          versions                        = toset(smb.value.versions)
          authentication_types            = toset(smb.value.authentication_types)
          kerberos_ticket_encryption_type = toset(smb.value.kerberos_ticket_encryption_type)
          channel_encryption_type         = toset(smb.value.channel_encryption_type)
        }
      }

      dynamic "retention_policy" {
        for_each = share_properties.value.retention_policy != null ? [share_properties.value.retention_policy] : []
        content {
          days = retention_policy.value.days
        }
      }
    }
  }

  dynamic "queue_properties" {
    for_each = each.value.queue_properties != null ? [each.value.queue_properties] : []
    content {
      dynamic "cors_rule" {
        for_each = queue_properties.value.cors_rule != null ? [queue_properties.value.cors_rule] : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }

      dynamic "logging" {
        for_each = queue_properties.value.logging != null ? [queue_properties.value.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          write                 = logging.value.write
          version               = logging.value.version
          retention_policy_days = try(logging.value.retention_policy_days, 7)
        }
      }

      dynamic "minute_metrics" {
        for_each = queue_properties.value.minute_metrics != null ? [queue_properties.value.minute_metrics] : []
        content {
          enabled               = minute_metrics.value.enabled
          version               = minute_metrics.value.version
          include_apis          = try(minute_metrics.value.include_apis, null)
          retention_policy_days = try(minute_metrics.value.retention_policy_days, 7)
        }
      }

      dynamic "hour_metrics" {
        for_each = queue_properties.value.hour_metrics != null ? [queue_properties.value.hour_metrics] : []
        content {
          enabled               = hour_metrics.value.enabled
          version               = hour_metrics.value.version
          include_apis          = try(hour_metrics.value.include_apis, null)
          retention_policy_days = try(hour_metrics.value.retention_policy_days, 7)
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = each.value.static_website != null ? [each.value.static_website] : []
    content {
      index_document     = try(static_website.value.index_document, null)
      error_404_document = try(static_website.value.error_404_document, null)
    }
  }

  dynamic "azure_files_authentication" {
    for_each = each.value.azure_files_authentication != null ? [each.value.azure_files_authentication] : []
    content {
      directory_type = azure_files_authentication.value.directory_type

      dynamic "active_directory" {
        for_each = azure_files_authentication.value.active_directory != null ? [azure_files_authentication.value.active_directory] : []
        content {
          storage_sid         = active_directory.value.storage_sid
          domain_name         = active_directory.value.domain_name
          domain_sid          = active_directory.value.domain_sid
          domain_guid         = active_directory.value.domain_guid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
        }
      }
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key != null ? [each.value.customer_managed_key] : []
    content {
      key_vault_key_id          = try(customer_managed_key.value.key_vault_key_id, null)
      user_assigned_identity_id = try(customer_managed_key.value.user_assigned_identity_id, null)
    }
  }

  dynamic "routing" {
    for_each = each.value.routing != null ? [each.value.routing] : []
    content {
      publish_internet_endpoints  = try(routing.value.publish_internet_endpoints, false)
      publish_microsoft_endpoints = try(routing.value.publish_microsoft_endpoints, false)
      choice                      = try(routing.value.choice, "MicrosoftRouting")
    }
  }
}

data "azurerm_storage_account_sas" "sas" {
  for_each = { for sa in var.storage_accounts : sa.name => sa if sa.shared_access_keys_enabled == true && sa.generate_sas_token == true }

  connection_string = azurerm_storage_account.sa[each.key].primary_connection_string
  https_only        = each.value.sas_config.https_only
  signed_version    = each.value.sas_config.signed_version

  resource_types {
    service   = each.value.sas_config.service
    container = each.value.sas_config.container
    object    = each.value.sas_config.object
  }

  services {
    blob  = each.value.sas_config.blob
    queue = each.value.sas_config.queue
    table = each.value.sas_config.table
    file  = each.value.sas_config.file
  }

  start  = each.value.sas_config.start
  expiry = each.value.sas_config.expiry

  permissions {
    read    = each.value.sas_config.read
    write   = each.value.sas_config.write
    delete  = each.value.sas_config.delete
    list    = each.value.sas_config.list
    add     = each.value.sas_config.add
    create  = each.value.sas_config.create
    update  = each.value.sas_config.update
    process = each.value.sas_config.process
    tag     = each.value.sas_config.tag
    filter  = each.value.sas_config.filter
  }
}
