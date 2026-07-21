# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"

  storage_accounts = {
    "stldoukstst001" = {}
  }
}

run "creates_account_with_secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this["stldoukstst001"].min_tls_version == "TLS1_2" && azurerm_storage_account.this["stldoukstst001"].https_traffic_only_enabled == true
    error_message = "Accounts should default to TLS1_2 and HTTPS-only."
  }

  assert {
    condition     = azurerm_storage_account.this["stldoukstst001"].infrastructure_encryption_enabled == true && azurerm_storage_account.this["stldoukstst001"].allow_nested_items_to_be_public == false
    error_message = "Infrastructure encryption should default on and anonymous nested access off."
  }

  assert {
    condition     = one(azurerm_storage_account.this["stldoukstst001"].network_rules).default_action == "Deny"
    error_message = "The default network rule set should deny by default."
  }

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-001"
    error_message = "resource_group_name should be parsed from resource_group_id."
  }
}

run "manage_network_rules_false_omits_inline_block" {
  command = plan

  variables {
    storage_accounts = {
      "stldoukstst001" = {
        manage_network_rules = false
      }
    }
  }

  assert {
    condition     = length(azurerm_storage_account.this["stldoukstst001"].network_rules) == 0
    error_message = "manage_network_rules = false should omit the inline network_rules block, leaving the firewall to the storage-account-network-rules module."
  }
}

run "creates_blob_props_encryption_scope_and_management_policy" {
  command = plan

  variables {
    storage_accounts = {
      "stldoukstst002" = {
        account_replication_type = "GRS"
        blob_properties = {
          versioning_enabled      = true
          delete_retention_policy = { days = 7 }
          cors_rules = [{
            allowed_headers    = ["*"]
            allowed_methods    = ["GET"]
            allowed_origins    = ["https://example.com"]
            exposed_headers    = ["*"]
            max_age_in_seconds = 3600
          }]
        }
        encryption_scopes = {
          "microsoftmanaged" = { source = "Microsoft.Storage" }
        }
        management_policy = {
          rules = [{
            name    = "tier-and-expire"
            filters = { blob_types = ["blockBlob"], prefix_match = ["logs/"] }
            actions = {
              base_blob = {
                tier_to_cool_after_days_since_modification_greater_than = 30
                delete_after_days_since_modification_greater_than       = 365
              }
            }
          }]
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_storage_encryption_scope.this) == 1 && length(azurerm_storage_management_policy.this) == 1
    error_message = "One encryption scope and one management policy should be created."
  }

  assert {
    condition     = length(one(azurerm_storage_account.this["stldoukstst002"].blob_properties).cors_rule) == 1
    error_message = "The blob CORS rule should be created."
  }
}

run "rejects_invalid_replication" {
  command = plan

  variables {
    storage_accounts = { "stbad" = { account_replication_type = "MEGA" } }
  }

  expect_failures = [var.storage_accounts]
}

run "rejects_invalid_tls" {
  command = plan

  variables {
    storage_accounts = { "stbad" = { min_tls_version = "TLS1_3" } }
  }

  expect_failures = [var.storage_accounts]
}
