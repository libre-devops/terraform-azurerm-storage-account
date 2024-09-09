variable "storage_accounts" {
  type = list(object({
    name                              = string
    rg_name                           = string
    location                          = string
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "LRS")
    access_tier                       = optional(string, "Hot")
    account_kind                      = optional(string, "StorageV2")
    https_traffic_only_enabled        = optional(bool, true)
    min_tls_version                   = optional(string, "TLS1_2")
    is_hns_enabled                    = optional(bool, false)
    allowed_copy_scope                = optional(string)
    cross_tenant_replication_enabled  = optional(bool, false)
    edge_zone                         = optional(string, null)
    default_to_oauth_authentication   = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    large_file_share_enabled          = optional(bool, false)
    allow_nested_items_to_be_public   = optional(bool, false)
    shared_access_keys_enabled        = optional(bool, false)
    tags                              = map(string)
    sftp_enabled                      = optional(bool, false)
    queue_encryption_key_type         = optional(string)
    table_encryption_key_type         = optional(string)
    infrastructure_encryption_enabled = optional(bool)
    immutability_policy = optional(object({
      allow_protected_append_writes = optional(bool, false)
      period_since_creation_in_days = optional(number)
      state                         = optional(string)
    }))
    sas_policy = optional(object({
      expiration_period = optional(string)
      expiration_action = optional(string)
    }))
    identity_type = optional(string)
    identity_ids  = optional(list(string))
    network_rules = optional(object({
      bypass                     = optional(list(string))
      default_action             = optional(string)
      ip_rules                   = optional(list(string))
      virtual_network_subnet_ids = optional(list(string))
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = string
      })))
    }))
    custom_domain = optional(object({
      name          = string
      use_subdomain = optional(bool)
    }))
    blob_properties = optional(object({
      versioning_enabled       = optional(bool)
      change_feed_enabled      = optional(bool)
      default_service_version  = optional(string)
      last_access_time_enabled = optional(bool)
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })))
      delete_retention_policy = optional(object({
        days = optional(number)
      }))
      container_delete_retention_policy = optional(object({
        days = optional(number)
      }))
    }))
    share_properties = optional(object({
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })))
      smb = optional(object({
        versions                        = list(string)
        authentication_types            = list(string)
        kerberos_ticket_encryption_type = list(string)
        channel_encryption_type         = list(string)
      }))
      retention_policy = optional(object({
        days = number
      }))
    }))
    queue_properties = optional(object({
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })))
      logging = optional(object({
        delete                = bool
        read                  = bool
        write                 = bool
        version               = string
        retention_policy_days = optional(number)
      }))
      minute_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
      hour_metrics = optional(object({
        enabled               = bool
        version               = string
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
    }))
    static_website = optional(object({
      index_document     = optional(string)
      error_404_document = optional(string)
    }))
    azure_files_authentication = optional(object({
      directory_type = string
      active_directory = optional(object({
        storage_sid         = string
        domain_name         = string
        domain_sid          = string
        domain_guid         = string
        forest_name         = string
        netbios_domain_name = string
      }))
    }))
    customer_managed_key = optional(object({
      key_vault_key_id          = optional(string)
      user_assigned_identity_id = optional(string)
    }))
    routing = optional(object({
      publish_internet_endpoints  = optional(bool)
      publish_microsoft_endpoints = optional(bool)
      choice                      = optional(string)
    }))
    generate_sas_token = optional(bool, false)
    sas_config = optional(object({
      https_only     = optional(bool)
      signed_version = optional(string)
      service        = optional(bool)
      container      = optional(bool)
      object         = optional(bool)
      blob           = optional(bool)
      queue          = optional(bool)
      table          = optional(bool)
      file           = optional(bool)
      start          = optional(string)
      expiry         = optional(string)
      read           = optional(bool)
      write          = optional(bool)
      delete         = optional(bool)
      list           = optional(bool)
      add            = optional(bool)
      create         = optional(bool)
      update         = optional(bool)
      process        = optional(bool)
      tag            = optional(bool)
      filter         = optional(bool)
    }), null)
    create_diagnostic_settings = optional(bool, false)
    diagnostic_settings_enable_all_logs_and_metrics = optional(bool, false)
    diagnostic_settings               = optional(object({
      diagnostic_settings_name       = optional(string)
      storage_account_id             = optional(string)
      eventhub_name                  = optional(string)
      eventhub_authorization_rule_id = optional(string)
      law_id                         = optional(string)
      law_destination_type           = optional(string)
      partner_solution_id            = optional(string)
      enabled_log = optional(list(object({
        category       = string
        category_group = optional(string)
      })), [])
      metric = optional(list(object({
        category = string
        enabled  = optional(bool, true)
      })), [])
      enable_all_logs    = optional(bool, false)
      enable_all_metrics = optional(bool, false)
    }), null)
  }))
    description = "The storage accounts to create"
}
