output "encryption_scope_ids" {
  description = "Map of \"<account>|<scope>\" to the encryption scope id."
  value       = { for k, s in azurerm_storage_encryption_scope.this : k => s.id }
}

output "identity_principal_ids" {
  description = "Map of account name to its identity principal id (only accounts with an identity)."
  value       = { for k, s in azurerm_storage_account.this : k => try(s.identity[0].principal_id, null) }
}

output "ids" {
  description = "Map of storage account name to its resource id."
  value       = { for k, s in azurerm_storage_account.this : k => s.id }
}

output "ids_zipmap" {
  description = "Map of storage account name to a { name, id } object, for passing where both are needed together."
  value       = { for k, s in azurerm_storage_account.this : k => { name = s.name, id = s.id } }
}

output "management_policy_ids" {
  description = "Map of account name to its management (lifecycle) policy id."
  value       = { for k, p in azurerm_storage_management_policy.this : k => p.id }
}

output "names" {
  description = "The storage account names."
  value       = keys(azurerm_storage_account.this)
}

output "primary_access_keys" {
  description = "Map of account name to its primary access key."
  value       = { for k, s in azurerm_storage_account.this : k => s.primary_access_key }
  sensitive   = true
}

output "primary_blob_endpoints" {
  description = "Map of account name to its primary blob endpoint."
  value       = { for k, s in azurerm_storage_account.this : k => s.primary_blob_endpoint }
}

output "primary_connection_strings" {
  description = "Map of account name to its primary connection string."
  value       = { for k, s in azurerm_storage_account.this : k => s.primary_connection_string }
  sensitive   = true
}

output "primary_web_endpoints" {
  description = "Map of account name to its primary static-website endpoint."
  value       = { for k, s in azurerm_storage_account.this : k => s.primary_web_endpoint }
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.resource_group_name
}

output "secondary_access_keys" {
  description = "Map of account name to its secondary access key."
  value       = { for k, s in azurerm_storage_account.this : k => s.secondary_access_key }
  sensitive   = true
}

output "storage_accounts" {
  description = "Map of account name to key attributes (id, name, tier, replication, kind, and blob/dfs/web endpoints)."
  value = { for k, s in azurerm_storage_account.this : k => {
    id                       = s.id
    name                     = s.name
    account_tier             = s.account_tier
    account_replication_type = s.account_replication_type
    account_kind             = s.account_kind
    primary_blob_endpoint    = s.primary_blob_endpoint
    primary_dfs_endpoint     = s.primary_dfs_endpoint
    primary_web_endpoint     = s.primary_web_endpoint
    primary_location         = s.primary_location
  } }
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The tags applied to the storage accounts."
  value       = var.tags
}
