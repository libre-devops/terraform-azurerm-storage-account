module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "sn1-${module.network.vnet_name}" = {
      address_prefixes  = ["10.0.0.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "uid-${var.short}-${var.loc}-${var.env}-01"
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags
}

locals {
  now                 = timestamp()
  seven_days_from_now = timeadd(timestamp(), "168h")
}

module "law" {
  source = "registry.terraform.io/libre-devops/log-analytics-workspace/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  create_new_workspace       = true
  law_name                   = "law-${var.short}-${var.loc}-${var.env}-01"
  law_sku                    = "PerGB2018"
  retention_in_days          = "30"
  daily_quota_gb             = "0.5"
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}


module "sa" {
  source = "../../"
  storage_accounts = [
    {
      name     = "sa${var.short}${var.loc}${var.env}01"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      identity_type = "SystemAssigned, UserAssigned"
      identity_ids  = [azurerm_user_assigned_identity.uid.id]

      create_diagnostic_settings                      = true
      diagnostic_settings_enable_all_logs_and_metrics = false
      diagnostic_settings = {
        law_id = module.law.law_id
        metric = [
          {
            category = "Transaction"
          }
        ]
      }

      network_rules = {
        bypass                     = ["AzureServices"]
        default_action             = "Deny"
        ip_rules                   = [chomp(data.http.client_ip.response_body)]
        virtual_network_subnet_ids = [module.network.subnets_ids["sn1-${module.network.vnet_name}"]]
      }
    },
    {
      name     = "sa${var.short}${var.loc}${var.env}02"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      shared_access_keys_enabled = true
      generate_sas_token         = true
      create_diagnostic_settings = false

      sas_config = {
        https_only     = true
        signed_version = "2019-12-12"
        service        = true
        container      = true
        object         = true
        blob           = true
        queue          = true
        table          = true
        file           = true
        start          = local.now
        expiry         = local.seven_days_from_now
        read           = true
        write          = true
        delete         = true
        list           = true
        add            = true
        create         = true
        update         = true
        process        = true
        tag            = true
        filter         = true
      }
    },
  ]
}


output "sas_token" {
  value     = module.sa.sas_tokens["sa${var.short}${var.loc}${var.env}02"]
  sensitive = true
}
