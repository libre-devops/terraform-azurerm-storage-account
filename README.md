```hcl
resource "azurerm_storage_account" "sa" {
  for_each                          = { for sa in var.storage_accounts : sa.name => sa }
  name                              = each.value.name
  resource_group_name               = each.value.rg_name
  location                          = each.value.location
  account_kind                      = each.value.account_kind
  account_tier                      = each.value.account_tier
  account_replication_type          = upper(each.value.account_replication_type)
  access_tier                       = title(each.value.access_tier)
  https_traffic_only_enabled        = each.value.https_traffic_only_enabled
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

module "diagnostic_settings_custom" {
  source = "libre-devops/diagnostic-settings/azurerm"

  for_each = {
    for sa in var.storage_accounts : sa.name => sa
    if sa.create_diagnostic_settings == true && sa.diagnostic_settings != null
  }

  diagnostic_settings = merge(
    each.value.diagnostic_settings,
    {
      target_resource_id = azurerm_storage_account.sa[each.key].id,
    }
  )
}

module "diagnostic_settings_enable_all" {
  source = "libre-devops/diagnostic-settings/azurerm"

  for_each = {
    for sa in var.storage_accounts : sa.name => sa
    if sa.diagnostic_settings_enable_all_logs_and_metrics == true
  }

  diagnostic_settings = {
    target_resource_id             = azurerm_storage_account.sa[each.key].id
    law_id                         = try(each.value.diagnostic_settings.law_id, null)
    diagnostic_settings_name       = "${azurerm_storage_account.sa[each.key].name}-diagnostics"
    enable_all_logs                = true
    enable_all_metrics             = true
    storage_account_id             = try(each.value.diagnostic_settings.storage_account_id, null)
    eventhub_name                  = try(each.value.diagnostic_settings.eventhub_name, null)
    eventhub_authorization_rule_id = try(each.value.diagnostic_settings.eventhub_authorization_rule_id, null)
    law_destination_type           = "Dedicated"
    partner_solution_id            = try(each.value.diagnostic_settings.partner_solution_id, null)
  }
}


```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_diagnostic_settings_custom"></a> [diagnostic\_settings\_custom](#module\_diagnostic\_settings\_custom) | libre-devops/diagnostic-settings/azurerm | n/a |
| <a name="module_diagnostic_settings_enable_all"></a> [diagnostic\_settings\_enable\_all](#module\_diagnostic\_settings\_enable\_all) | libre-devops/diagnostic-settings/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_storage_account.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_sas.sas](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_sas) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_storage_accounts"></a> [storage\_accounts](#input\_storage\_accounts) | The storage accounts to create | <pre>list(object({<br>    name                              = string<br>    rg_name                           = string<br>    location                          = string<br>    account_tier                      = optional(string, "Standard")<br>    account_replication_type          = optional(string, "LRS")<br>    access_tier                       = optional(string, "Hot")<br>    account_kind                      = optional(string, "StorageV2")<br>    https_traffic_only_enabled        = optional(bool, true)<br>    min_tls_version                   = optional(string, "TLS1_2")<br>    is_hns_enabled                    = optional(bool, false)<br>    allowed_copy_scope                = optional(string)<br>    cross_tenant_replication_enabled  = optional(bool, false)<br>    edge_zone                         = optional(string, null)<br>    default_to_oauth_authentication   = optional(bool, false)<br>    nfsv3_enabled                     = optional(bool, false)<br>    large_file_share_enabled          = optional(bool, false)<br>    allow_nested_items_to_be_public   = optional(bool, false)<br>    shared_access_keys_enabled        = optional(bool, false)<br>    tags                              = map(string)<br>    sftp_enabled                      = optional(bool, false)<br>    queue_encryption_key_type         = optional(string)<br>    table_encryption_key_type         = optional(string)<br>    infrastructure_encryption_enabled = optional(bool)<br>    immutability_policy = optional(object({<br>      allow_protected_append_writes = optional(bool, false)<br>      period_since_creation_in_days = optional(number)<br>      state                         = optional(string)<br>    }))<br>    sas_policy = optional(object({<br>      expiration_period = optional(string)<br>      expiration_action = optional(string)<br>    }))<br>    identity_type = optional(string)<br>    identity_ids  = optional(list(string))<br>    network_rules = optional(object({<br>      bypass                     = optional(list(string))<br>      default_action             = optional(string)<br>      ip_rules                   = optional(list(string))<br>      virtual_network_subnet_ids = optional(list(string))<br>      private_link_access = optional(list(object({<br>        endpoint_resource_id = string<br>        endpoint_tenant_id   = string<br>      })))<br>    }))<br>    custom_domain = optional(object({<br>      name          = string<br>      use_subdomain = optional(bool)<br>    }))<br>    blob_properties = optional(object({<br>      versioning_enabled       = optional(bool)<br>      change_feed_enabled      = optional(bool)<br>      default_service_version  = optional(string)<br>      last_access_time_enabled = optional(bool)<br>      cors_rule = optional(list(object({<br>        allowed_headers    = list(string)<br>        allowed_methods    = list(string)<br>        allowed_origins    = list(string)<br>        exposed_headers    = list(string)<br>        max_age_in_seconds = number<br>      })))<br>      delete_retention_policy = optional(object({<br>        days = optional(number)<br>      }))<br>      container_delete_retention_policy = optional(object({<br>        days = optional(number)<br>      }))<br>    }))<br>    share_properties = optional(object({<br>      cors_rule = optional(list(object({<br>        allowed_headers    = list(string)<br>        allowed_methods    = list(string)<br>        allowed_origins    = list(string)<br>        exposed_headers    = list(string)<br>        max_age_in_seconds = number<br>      })))<br>      smb = optional(object({<br>        versions                        = list(string)<br>        authentication_types            = list(string)<br>        kerberos_ticket_encryption_type = list(string)<br>        channel_encryption_type         = list(string)<br>      }))<br>      retention_policy = optional(object({<br>        days = number<br>      }))<br>    }))<br>    queue_properties = optional(object({<br>      cors_rule = optional(list(object({<br>        allowed_headers    = list(string)<br>        allowed_methods    = list(string)<br>        allowed_origins    = list(string)<br>        exposed_headers    = list(string)<br>        max_age_in_seconds = number<br>      })))<br>      logging = optional(object({<br>        delete                = bool<br>        read                  = bool<br>        write                 = bool<br>        version               = string<br>        retention_policy_days = optional(number)<br>      }))<br>      minute_metrics = optional(object({<br>        enabled               = bool<br>        version               = string<br>        include_apis          = optional(bool)<br>        retention_policy_days = optional(number)<br>      }))<br>      hour_metrics = optional(object({<br>        enabled               = bool<br>        version               = string<br>        include_apis          = optional(bool)<br>        retention_policy_days = optional(number)<br>      }))<br>    }))<br>    static_website = optional(object({<br>      index_document     = optional(string)<br>      error_404_document = optional(string)<br>    }))<br>    azure_files_authentication = optional(object({<br>      directory_type = string<br>      active_directory = optional(object({<br>        storage_sid         = string<br>        domain_name         = string<br>        domain_sid          = string<br>        domain_guid         = string<br>        forest_name         = string<br>        netbios_domain_name = string<br>      }))<br>    }))<br>    customer_managed_key = optional(object({<br>      key_vault_key_id          = optional(string)<br>      user_assigned_identity_id = optional(string)<br>    }))<br>    routing = optional(object({<br>      publish_internet_endpoints  = optional(bool)<br>      publish_microsoft_endpoints = optional(bool)<br>      choice                      = optional(string)<br>    }))<br>    generate_sas_token = optional(bool, false)<br>    sas_config = optional(object({<br>      https_only     = optional(bool)<br>      signed_version = optional(string)<br>      service        = optional(bool)<br>      container      = optional(bool)<br>      object         = optional(bool)<br>      blob           = optional(bool)<br>      queue          = optional(bool)<br>      table          = optional(bool)<br>      file           = optional(bool)<br>      start          = optional(string)<br>      expiry         = optional(string)<br>      read           = optional(bool)<br>      write          = optional(bool)<br>      delete         = optional(bool)<br>      list           = optional(bool)<br>      add            = optional(bool)<br>      create         = optional(bool)<br>      update         = optional(bool)<br>      process        = optional(bool)<br>      tag            = optional(bool)<br>      filter         = optional(bool)<br>    }), null)<br>    create_diagnostic_settings                      = optional(bool, false)<br>    diagnostic_settings_enable_all_logs_and_metrics = optional(bool, false)<br>    diagnostic_settings = optional(object({<br>      diagnostic_settings_name       = optional(string)<br>      storage_account_id             = optional(string)<br>      eventhub_name                  = optional(string)<br>      eventhub_authorization_rule_id = optional(string)<br>      law_id                         = optional(string)<br>      law_destination_type           = optional(string)<br>      partner_solution_id            = optional(string)<br>      enabled_log = optional(list(object({<br>        category       = string<br>        category_group = optional(string)<br>      })), [])<br>      metric = optional(list(object({<br>        category = string<br>        enabled  = optional(bool, true)<br>      })), [])<br>      enable_all_logs    = optional(bool, false)<br>      enable_all_metrics = optional(bool, false)<br>    }), null)<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_primary_access_keys"></a> [primary\_access\_keys](#output\_primary\_access\_keys) | The primary access keys of the storage accounts. |
| <a name="output_primary_blob_connection_strings"></a> [primary\_blob\_connection\_strings](#output\_primary\_blob\_connection\_strings) | The primary connection strings for blob storage of the storage accounts. |
| <a name="output_primary_blob_endpoints"></a> [primary\_blob\_endpoints](#output\_primary\_blob\_endpoints) | The primary blob endpoints of the storage accounts. |
| <a name="output_primary_file_endpoints"></a> [primary\_file\_endpoints](#output\_primary\_file\_endpoints) | The primary file endpoints of the storage accounts. |
| <a name="output_primary_queue_endpoints"></a> [primary\_queue\_endpoints](#output\_primary\_queue\_endpoints) | The primary queue endpoints of the storage accounts. |
| <a name="output_primary_table_endpoints"></a> [primary\_table\_endpoints](#output\_primary\_table\_endpoints) | The primary table endpoints of the storage accounts. |
| <a name="output_sas_tokens"></a> [sas\_tokens](#output\_sas\_tokens) | The SAS tokens for the storage accounts. |
| <a name="output_secondary_access_keys"></a> [secondary\_access\_keys](#output\_secondary\_access\_keys) | The secondary access keys of the storage accounts. |
| <a name="output_secondary_table_endpoints"></a> [secondary\_table\_endpoints](#output\_secondary\_table\_endpoints) | The secondary table endpoints of the storage accounts. |
| <a name="output_storage_account_identities"></a> [storage\_account\_identities](#output\_storage\_account\_identities) | The identities of the Storage Accounts. |
| <a name="output_storage_account_ids"></a> [storage\_account\_ids](#output\_storage\_account\_ids) | The IDs of the storage accounts. |
| <a name="output_storage_account_locations"></a> [storage\_account\_locations](#output\_storage\_account\_locations) | The locations of the storage accounts. |
| <a name="output_storage_account_names"></a> [storage\_account\_names](#output\_storage\_account\_names) | The names of the storage accounts. |
| <a name="output_storage_account_resource_groups"></a> [storage\_account\_resource\_groups](#output\_storage\_account\_resource\_groups) | The resource group names of the storage accounts. |
